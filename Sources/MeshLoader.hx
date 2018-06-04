package;

import haxebullet.Bullet;
import kha.Blob;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.math.FastMatrix4;
import kha.math.FastVector4;

class MeshLoader extends MyShape {
	private var started: Bool = false;
	private var structure: VertexStructure;
	
	public function new(ogexAsset:Blob, mass:Float, dynamicsWorld:BtDiscreteDynamicsWorld, scale:Float=1.0) {
		loadOgex(ogexAsset, scale);
		super(mass, dynamicsWorld);
	}
	
	private function loadOgex(ogexAsset:Blob, scale:Float): Void {
		// load data
		var data = new OgexData(ogexAsset.toString());
		var vertices = data.geometryObjects[0].mesh.vertexArrays[0].values;
		var normals = data.geometryObjects[0].mesh.vertexArrays[1].values;
		var indices = data.geometryObjects[0].mesh.indexArray.values;

		// apply transform
		var transformedVertices = new Array<Float>();
		var transformedNormals = new Array<Float>();
		var transMat = FastMatrix4.identity();
		transMat._00 = data.children[0].transform.values[0];
		transMat._01 = data.children[0].transform.values[1];
		transMat._02 = data.children[0].transform.values[2];
		transMat._03 = data.children[0].transform.values[3];
		transMat._10 = data.children[0].transform.values[4];
		transMat._11 = data.children[0].transform.values[5];
		transMat._12 = data.children[0].transform.values[6];
		transMat._13 = data.children[0].transform.values[7];
		transMat._20 = data.children[0].transform.values[8];
		transMat._21 = data.children[0].transform.values[9];
		transMat._22 = data.children[0].transform.values[10];
		transMat._23 = data.children[0].transform.values[11];
		transMat._30 = data.children[0].transform.values[12];
		transMat._31 = data.children[0].transform.values[13];
		transMat._32 = data.children[0].transform.values[14];
		transMat._33 = data.children[0].transform.values[15];

		for (i in 0...Std.int(vertices.length / 3)) {
			var vec = new FastVector4(vertices[i * 3 + 0], vertices[i * 3 + 1], vertices[i * 3 + 2], 1.0);
			var res = transMat.multvec(vec);
			transformedVertices.push(res.x);
			transformedVertices.push(res.y);
			transformedVertices.push(res.z);
		}

		for (i in 0...Std.int(normals.length / 3)) {
			var vec = new FastVector4(normals[i * 3 + 0], normals[i * 3 + 1], normals[i * 3 + 2], 1.0);
			var res = transMat.multvec(vec);
			transformedNormals.push(res.x);
			transformedNormals.push(res.y);
			transformedNormals.push(res.z);
		}

		// scale the mesh
		for (i in 0...transformedVertices.length) {
			transformedVertices[i] = transformedVertices[i] * scale;
		}

		// init physics object
		shape = BtConvexHullShape.create();
		for (i in 0...Std.int(transformedVertices.length / 3)) {
			var vector0 = BtVector3.create(transformedVertices[i * 3 + 0], transformedVertices[i * 3 + 1], transformedVertices[i * 3 + 2]);
			cast(shape, BtConvexHullShape).addPoint(vector0, true);
		}
		
		// init render object
		structure = new VertexStructure();
		structure.add('pos', VertexData.Float3);
		structure.add('normal', VertexData.Float3);
		vertexBuffer = new VertexBuffer(transformedVertices.length, structure, Usage.StaticUsage);
		var buffer = vertexBuffer.lock();
		for (i in 0...Std.int(transformedVertices.length / 3)) {
			buffer.set(i * 6 + 0, transformedVertices[i * 3 + 0]);
			buffer.set(i * 6 + 1, transformedVertices[i * 3 + 1]);
			buffer.set(i * 6 + 2, transformedVertices[i * 3 + 2]);
			buffer.set(i * 6 + 3, transformedNormals[i * 3 + 0]);
			buffer.set(i * 6 + 4, transformedNormals[i * 3 + 1]);
			buffer.set(i * 6 + 5, transformedNormals[i * 3 + 2]);
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
