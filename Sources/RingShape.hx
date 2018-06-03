package;

import haxebullet.Bullet;
import kha.graphics4.CompareMode;
import kha.graphics4.ConstantLocation;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Graphics;
import kha.graphics4.PipelineState;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.Shaders;
import kha.math.FastMatrix4;
import kha.math.FastVector3;
import kha.System;
import kha.math.Quaternion;

class RingShape {
	private var pipeline: PipelineState;
	private var vertexBuffer: VertexBuffer;
	private var indexBuffer: IndexBuffer;
	private var rotationLocation: ConstantLocation;
	private var projectionLocation: ConstantLocation;
	private var viewLocation: ConstantLocation;
	private var modelLocation: ConstantLocation;
	private var modelMatrix: FastMatrix4 = FastMatrix4.identity();
	private var ringRigidBody: BtRigidBody;
	
	public function new(outerDiameter:Float, innerDiameter:Float, height:Float, renderResolution:Int, physicsResolution:Int, dynamicsWorld:BtDiscreteDynamicsWorld) {
		var physicsVertices = createVertices(outerDiameter, innerDiameter, height, physicsResolution, false);
		registerPhysicsObject(physicsVertices, dynamicsWorld);
		var renderVertices = createVertices(outerDiameter, innerDiameter, height, renderResolution, true);
		prepareRenderObject(renderVertices, renderResolution);
	}

	private function createVertices(outerDiameter:Float, innerDiameter:Float, height:Float, segments:Int, usageRender:Bool): Array<Float> {
		var vertices = new Array<Float>();

		for (i in 0...segments) {
			var angle:Float = (2 * Math.PI / segments) * i;

			for (j in 0...4) {
				var is_lower = Std.int(j / 2);
				var is_outer = if(j == 1 || j == 2) 1 else 0;

				var x = Math.cos(angle) * (innerDiameter * (1 - is_outer) + outerDiameter * is_outer);
				var y = Math.pow(-1.0, is_lower) * height / 2.0;
				var z = Math.sin(angle) * (innerDiameter * (1 - is_outer) + outerDiameter * is_outer);
				vertices.push(x);
				vertices.push(y);
				vertices.push(z);
				if (usageRender) {
					var lengthXZ = Math.sqrt(x*x + z*z);
					var xn = ((is_outer * 2 - 1) * x / lengthXZ) / Math.sqrt(2.0);
					var zn = ((is_outer * 2 - 1) * z / lengthXZ) / Math.sqrt(2.0);
					var yn = -(is_lower * 2 - 1) / Math.sqrt(2.0);
					vertices.push(xn);
					vertices.push(yn);
					vertices.push(zn);
				}
			}

			if (usageRender) {
				angle = (2 * Math.PI / segments) * (i + 0.5);
				var avgDiameter = (outerDiameter + innerDiameter) / 2.0;
				// top
				vertices.push(Math.cos(angle) * avgDiameter);
				vertices.push(height / 2.0);
				vertices.push(Math.sin(angle) * avgDiameter);
				vertices.push(0.0);
				vertices.push(1.0);
				vertices.push(0.0);
				// out
				var x = Math.cos(angle) * outerDiameter;
				var z = Math.sin(angle) * outerDiameter;
				var lengthXZ = Math.sqrt(x*x + z*z);
				vertices.push(x);
				vertices.push(0.0);
				vertices.push(z);
				vertices.push(x / lengthXZ);
				vertices.push(0.0);
				vertices.push(z / lengthXZ);
				// bottom
				vertices.push(Math.cos(angle) * avgDiameter);
				vertices.push(height / -2.0);
				vertices.push(Math.sin(angle) * avgDiameter);
				vertices.push(0.0);
				vertices.push(-1.0);
				vertices.push(0.0);
				// in
				var x = Math.cos(angle) * innerDiameter;
				var z = Math.sin(angle) * innerDiameter;
				var lengthXZ = Math.sqrt(x*x + z*z);
				vertices.push(x);
				vertices.push(0.0);
				vertices.push(z);
				vertices.push(-x / lengthXZ);
				vertices.push(0.0);
				vertices.push(-z / lengthXZ);
			}		
		}
		return vertices;
	}
	
	private function registerPhysicsObject(vertices:Array<Float>, dynamicsWorld: BtDiscreteDynamicsWorld): Void {
		var compoundShape:BtCompoundShape = BtCompoundShape.create();
		for (i in 0...Std.int(vertices.length / 12)) {
			var convexHull = BtConvexHullShape.create();
			for (j in (i * 4)...((i + 2) * 4)) {
				var index = Std.int(j % (vertices.length / 3));
				var vector0 = BtVector3.create(vertices[index * 3 + 0], vertices[index * 3 + 1], vertices[index * 3 + 2]);
				convexHull.addPoint(vector0, true);
			}
			var childTransform = BtTransform.create();
			childTransform.setIdentity();
			compoundShape.addChildShape(childTransform, convexHull);
		}

		var ringTransform = BtTransform.create();
		ringTransform.setIdentity();
		ringTransform.setOrigin(BtVector3.create(0, 100, 0));
		var centerOfMassOffsetRingTransform = BtTransform.create();
		centerOfMassOffsetRingTransform.setIdentity();
		var ringMotionState = BtDefaultMotionState.create(ringTransform, centerOfMassOffsetRingTransform);
		var ringInertia = BtVector3.create(0, 0, 0);
		compoundShape.calculateLocalInertia(1, ringInertia);
		var ringRigidBodyCI = BtRigidBodyConstructionInfo.create(1, ringMotionState, compoundShape, ringInertia);
		ringRigidBody = BtRigidBody.create(ringRigidBodyCI);
		dynamicsWorld.addRigidBody(ringRigidBody);
	}

	private function prepareRenderObject(vertices:Array<Float>, numSegments:Int): Void {
		// create vertex buffer
		var structure = new VertexStructure();
		structure.add('pos', VertexData.Float3);
		structure.add('normal', VertexData.Float3);
		vertexBuffer = new VertexBuffer(Std.int(vertices.length / 6), structure, Usage.StaticUsage);
		var buffer = vertexBuffer.lock();
		for (i in 0...vertices.length) {
			buffer.set(i, vertices[i]);
		}
		vertexBuffer.unlock();

		// calculate indices
		var indices = new Array<Int>();
		var numVertices = numSegments * 8;
		for (segment in 0...numSegments) {
			var segment_indices = new Array<Int>();
			segment_indices.push(segment * 8);
			segment_indices.push(segment * 8 + 1);
			segment_indices.push(segment * 8 + 2);
			segment_indices.push(segment * 8 + 3);
			segment_indices.push(segment * 8 + 4);
			segment_indices.push(segment * 8 + 5);
			segment_indices.push(segment * 8 + 6);
			segment_indices.push(segment * 8 + 7);
			segment_indices.push((segment * 8 + 8) % numVertices);
			segment_indices.push((segment * 8 + 9) % numVertices);
			segment_indices.push((segment * 8 + 10) % numVertices);
			segment_indices.push((segment * 8 + 11) % numVertices);

			// add all 16 triangles of the ring segment
			for (i in 0...4) {
				indices.push(segment_indices[i]);
				indices.push(segment_indices[(i + 1) % 4]);
				indices.push(segment_indices[i + 4]);

				indices.push(segment_indices[(i + 1) % 4]);
				indices.push(segment_indices[(i + 1) % 4 + 8]);
				indices.push(segment_indices[i + 4]);

				indices.push(segment_indices[(i + 1) % 4 + 8]);
				indices.push(segment_indices[i + 8]);
				indices.push(segment_indices[i + 4]);

				indices.push(segment_indices[i + 8]);
				indices.push(segment_indices[i]);
				indices.push(segment_indices[i + 4]);
			}
		}

		// create index buffer
		indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
		var ibuffer = indexBuffer.lock();
		for (i in 0...indices.length) {
			ibuffer[i] = indices[i];
		}
		indexBuffer.unlock();

		// create pipeline
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Shaders.mesh_vert;
		pipeline.fragmentShader = Shaders.mesh_frag;
		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		// pipeline.cullMode = CullMode.None;
		pipeline.compile();
		
		projectionLocation = pipeline.getConstantLocation("projection");
		viewLocation = pipeline.getConstantLocation("view");
		modelLocation = pipeline.getConstantLocation("model");
	}
	
	public function updatePosition(): Void {
		var trans = BtTransform.create();
		ringRigidBody.getMotionState().getWorldTransform(trans);
		var origin = trans.getOrigin();
		var rot = trans.getRotation();
		var rotKha = new Quaternion(rot.x(), rot.y(), rot.z(), rot.w());
		var rotMat = FastMatrix4.fromMatrix4(rotKha.matrix());
		modelMatrix = FastMatrix4.translation(origin.x(), origin.y(), origin.z()).multmat(rotMat);
		trace(origin.y());
	}

	public function setPosition(x:Float, y:Float, z:Float): Void {
		var trans = BtTransform.create();
		trans.setIdentity();
		trans.setOrigin(BtVector3.create(x, y, z));
		ringRigidBody.setCenterOfMassTransform(trans);
	}

	public function render(g:Graphics): Void {
		g.setPipeline(pipeline);
		g.setMatrix(projectionLocation, FastMatrix4.perspectiveProjection(45, System.windowWidth(0) / System.windowHeight(0), 0.1, 1000));
		g.setMatrix(viewLocation, FastMatrix4.lookAt(new FastVector3(0, 800, -500), new FastVector3(0, 0, 0), new FastVector3(0, 1, 0)));
		g.setMatrix(modelLocation, modelMatrix);
		
		g.setIndexBuffer(indexBuffer);
		g.setVertexBuffer(vertexBuffer);
		g.drawIndexedVertices();
	}
}
