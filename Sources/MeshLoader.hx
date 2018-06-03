package;

import haxebullet.Bullet;
import kha.Blob;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;

class MeshLoader extends MyShape {
	private var started: Bool = false;
	private var structure: VertexStructure;
	
	public function new(ogexAsset:Blob, dynamicsWorld:BtDiscreteDynamicsWorld, scale:Float=1.0) {
		loadOgex(ogexAsset, scale);
		super(dynamicsWorld);
	}
	
	private function loadOgex(ogexAsset:Blob, scale:Float): Void {
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
		shape = BtConvexHullShape.create();
		for (i in 0...Std.int(vertices.length / 3)) {
			var vector0 = BtVector3.create(vertices[i * 3 + 0], vertices[i * 3 + 1], vertices[i * 3 + 2]);
			cast(shape, BtConvexHullShape).addPoint(vector0, true);
		}
		
		// init render object
		structure = new VertexStructure();
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
		
		started = true;
	}

	override function prepareBuffer(): VertexStructure {
		return structure;
	}
}
