package;

import haxebullet.Bullet;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;

class RingShape extends MyShape {
	var physicsVertices: Array<Float>;
	var renderVertices: Array<Float>;
	var numSegments: Int;

	public function new(outerDiameter:Float, innerDiameter:Float, height:Float, renderResolution:Int, physicsResolution:Int, dynamicsWorld:BtDiscreteDynamicsWorld) {
		numSegments = renderResolution;
		physicsVertices = createVerticesPhysics(outerDiameter, innerDiameter, height, physicsResolution);
		renderVertices = createVerticesRender(outerDiameter, innerDiameter, height, renderResolution);
		super(dynamicsWorld);
	}

	private function createVerticesPhysics(outerDiameter:Float, innerDiameter:Float, height:Float, segments:Int): Array<Float> {
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
			}
		}
		return vertices;
	}

	private function createVerticesRender(outerDiameter:Float, innerDiameter:Float, height:Float, segments:Int): Array<Float> {
		var vertices = new Array<Float>();

		for (i in 0...segments) {
			var angle:Float = (2 * Math.PI / segments) * i;

			for (j in 0...4) {
				var is_lower = Std.int(j / 2);
				var is_outer = if(j == 1 || j == 2) 1 else 0;

				var x = Math.cos(angle) * (innerDiameter * (1 - is_outer) + outerDiameter * is_outer);
				var y = Math.pow(-1.0, is_lower) * height / 2.0;
				var z = Math.sin(angle) * (innerDiameter * (1 - is_outer) + outerDiameter * is_outer);

				var lengthXZ = Math.sqrt(x*x + z*z);
				var xn = ((is_outer * 2 - 1) * x / lengthXZ);
				var zn = ((is_outer * 2 - 1) * z / lengthXZ);
				var yn = -(is_lower * 2 - 1);

				for (k in 0...2) {
					// vertex
					vertices.push(x);
					vertices.push(y);
					vertices.push(z);
					// normal
					var is_up_down_normal = (is_lower + is_outer + k) % 2;
					if (is_up_down_normal == 1) {
						vertices.push(0.0);
						vertices.push(yn);
						vertices.push(0.0);
					}
					else {
						vertices.push(xn);
						vertices.push(0.0);
						vertices.push(zn);
					}
					
				}
			}

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
		return vertices;
	}
	
	override function calcCollisionShape(): Void {
		shape = BtCompoundShape.create();
		for (i in 0...Std.int(physicsVertices.length / 12)) {
			var convexHull = BtConvexHullShape.create();
			for (j in (i * 4)...((i + 2) * 4)) {
				var index = Std.int(j % (physicsVertices.length / 3));
				var vector0 = BtVector3.create(physicsVertices[index * 3 + 0], physicsVertices[index * 3 + 1], physicsVertices[index * 3 + 2]);
				convexHull.addPoint(vector0, true);
			}
			var childTransform = BtTransform.create();
			childTransform.setIdentity();
			cast(shape, BtCompoundShape).addChildShape(childTransform, convexHull);
		}
	}

	override function prepareBuffer(): VertexStructure {
		// create vertex buffer
		var structure = new VertexStructure();
		structure.add('pos', VertexData.Float3);
		structure.add('normal', VertexData.Float3);
		vertexBuffer = new VertexBuffer(Std.int(renderVertices.length / 6), structure, Usage.StaticUsage);
		var buffer = vertexBuffer.lock();
		for (i in 0...renderVertices.length) {
			buffer.set(i, renderVertices[i]);
		}
		vertexBuffer.unlock();

		// calculate indices
		var indices = new Array<Int>();
		var numVertices = numSegments * 12;
		for (segment in 0...numSegments) {
			var segment_indices = new Array<Int>();
			for (v in 0...20) {
				segment_indices.push((segment * 12 + v) % numVertices);
			}

			// add all 16 triangles of the ring segment
			for (i in 0...4) {
				/*

				i0 -- i3
				| \  / |
				|  i4  |
				| /  \ |
				i1 -- i2

				*/
				var i0 = 2 * i + 1;
				var i1 = (2 * (i + 1)) % 8;
				var i2 = (2 * (i + 1)) % 8 + 12;
				var i3 = 2 * i + 13;
				var i4 = i + 8;

				indices.push(segment_indices[i0]);
				indices.push(segment_indices[i1]);
				indices.push(segment_indices[i4]);

				indices.push(segment_indices[i1]);
				indices.push(segment_indices[i2]);
				indices.push(segment_indices[i4]);

				indices.push(segment_indices[i2]);
				indices.push(segment_indices[i3]);
				indices.push(segment_indices[i4]);

				indices.push(segment_indices[i3]);
				indices.push(segment_indices[i0]);
				indices.push(segment_indices[i4]);
			}
		}

		// create index buffer
		indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
		var ibuffer = indexBuffer.lock();
		for (i in 0...indices.length) {
			ibuffer[i] = indices[i];
		}
		indexBuffer.unlock();

		return structure;
	}
}
