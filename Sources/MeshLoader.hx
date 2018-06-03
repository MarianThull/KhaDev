package;

import haxebullet.Bullet;
import kha.Blob;
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
import kha.System;
import kha.math.Quaternion;

class MeshLoader {
	private var rigidBody: BtRigidBody;
	private var convexHull: BtConvexHullShape;
	private var pipeline: PipelineState;
	private var vertexBuffer: VertexBuffer;
	private var indexBuffer: IndexBuffer;
	private var rotationLocation: ConstantLocation;
	private var projectionLocation: ConstantLocation;
	private var viewLocation: ConstantLocation;
	private var modelLocation: ConstantLocation;
	private var modelMatrix: FastMatrix4 = FastMatrix4.identity();
	public var started: Bool = false;
	
	public function new(ogexAsset:Blob, scale:Float=1.0, dynamicsWorld:BtDiscreteDynamicsWorld) {
		start(ogexAsset, scale, dynamicsWorld);
	}
	
	private function start(ogexAsset:Blob, scale:Float, dynamicsWorld:BtDiscreteDynamicsWorld): Void {
		// load data
		var data = new OgexData(ogexAsset.toString());
		var vertices = data.geometryObjects[0].mesh.vertexArrays[0].values;
		var normals = data.geometryObjects[0].mesh.vertexArrays[1].values;
		var indices = data.geometryObjects[0].mesh.indexArray.values;

		// scale the mesh
		for (i in 0...vertices.length) {
			vertices[i] = vertices[i] * scale;
		}

		// init physics object
		convexHull = BtConvexHullShape.create();
		for (i in 0...Std.int(vertices.length / 3)) {
			var vector0 = BtVector3.create(vertices[i * 3 + 0], vertices[i * 3 + 1], vertices[i * 3 + 2]);
			convexHull.addPoint(vector0, true);
		}
		var trans = BtTransform.create();
		trans.setIdentity();
		trans.setOrigin(BtVector3.create(0, 0, 0));
		var centerOfMassOffsetTransform = BtTransform.create();
		centerOfMassOffsetTransform.setIdentity();
		var motionState = BtDefaultMotionState.create(trans, centerOfMassOffsetTransform);

		var inertia = BtVector3.create(0, 0, 0);
		convexHull.calculateLocalInertia(1, inertia);
		var rigidBodyCI = BtRigidBodyConstructionInfo.create(1, motionState, convexHull, inertia);
		rigidBody = BtRigidBody.create(rigidBodyCI);
		dynamicsWorld.addRigidBody(rigidBody);
		
		// init render object
		var structure = new VertexStructure();
		structure.add('pos', VertexData.Float3);
		structure.add('normal', VertexData.Float3);
		vertexBuffer = new VertexBuffer(vertices.length, structure, Usage.StaticUsage);
		var buffer = vertexBuffer.lock();
		for (i in 0...Std.int(vertices.length / 3)) {
			buffer.set(i * 6 + 0, vertices[i * 3 + 0]);
			buffer.set(i * 6 + 1, vertices[i * 3 + 1]);
			buffer.set(i * 6 + 2, vertices[i * 3 + 2]);
			buffer.set(i * 6 + 3, normals[i * 3 + 0]);
			buffer.set(i * 6 + 4, normals[i * 3 + 1]);
			buffer.set(i * 6 + 5, normals[i * 3 + 2]);
		}
		vertexBuffer.unlock();
		
		indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
		var ibuffer = indexBuffer.lock();
		for (i in 0...indices.length) {
			ibuffer[i] = indices[i];
		}
		indexBuffer.unlock();
		
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Shaders.mesh_vert;
		pipeline.fragmentShader = Shaders.mesh_frag;
		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		pipeline.compile();
		
		projectionLocation = pipeline.getConstantLocation("projection");
		viewLocation = pipeline.getConstantLocation("view");
		modelLocation = pipeline.getConstantLocation("model");
		
		started = true;
	}
	
	public function updatePosition(): Void {
		var trans = BtTransform.create();
		rigidBody.getMotionState().getWorldTransform(trans);
		var origin = trans.getOrigin();
		var rot = trans.getRotation();
		var rotKha = new Quaternion(rot.x(), rot.y(), rot.z(), rot.w());
		var rotMat = FastMatrix4.fromMatrix4(rotKha.matrix());
		modelMatrix = FastMatrix4.translation(origin.x(), origin.y(), origin.z()).multmat(rotMat);
	}

	public function setPosition(x:Float, y:Float, z:Float): Void {
		var trans = BtTransform.create();
		trans.setIdentity();
		trans.setOrigin(BtVector3.create(x, y, z));
		rigidBody.setCenterOfMassTransform(trans);
	}

	public function render(g:Graphics, view:FastMatrix4): Void {
		if (started) {
			g.setPipeline(pipeline);
			g.setMatrix(projectionLocation, FastMatrix4.perspectiveProjection(45, System.windowWidth(0) / System.windowHeight(0), 0.1, 1000));
			g.setMatrix(viewLocation, view);
			g.setMatrix(modelLocation, modelMatrix);
			
			g.setIndexBuffer(indexBuffer);
			g.setVertexBuffer(vertexBuffer);
			g.drawIndexedVertices();
		}
	}
}
