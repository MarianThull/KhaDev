package;

import kha.graphics4.CompareMode;
import kha.graphics4.ConstantLocation;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Graphics;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.Usage;
import kha.Shaders;
import kha.math.FastMatrix4;

class Floor {
	private var pipeline: PipelineState;
	private var projectionLocation: ConstantLocation;
	private var viewLocation: ConstantLocation;
	private var modelLocation: ConstantLocation;
	private var modelMatrix = FastMatrix4.identity();
	private var indexBuffer: IndexBuffer;
	private var vertexBuffer: VertexBuffer;

	public function new(size:Float) {
		init(size);
	}

	private function init(size:Float) {
		var structure = new VertexStructure();
		structure.add('pos', VertexData.Float3);
		vertexBuffer = new VertexBuffer(4, structure, Usage.StaticUsage);
		var buffer = vertexBuffer.lock();
		for (i in 0...4) {
			buffer.set(i * 3 + 0, if(i < 2) size else -size);
			buffer.set(i * 3 + 1, 0.0);
			buffer.set(i * 3 + 2, if(i > 0 && i < 3) size else -size);
		}
		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(6, Usage.StaticUsage);
		var ibuffer = indexBuffer.lock();
		ibuffer[0] = 0;
		ibuffer[1] = 1;
		ibuffer[2] = 2;
		ibuffer[3] = 0;
		ibuffer[4] = 2;
		ibuffer[5] = 3;
		indexBuffer.unlock();

		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Shaders.floor_vert;
		pipeline.fragmentShader = Shaders.floor_frag;
		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		pipeline.compile();
		
		projectionLocation = pipeline.getConstantLocation("projection");
		viewLocation = pipeline.getConstantLocation("view");
		modelLocation = pipeline.getConstantLocation("model");
	}

	public function render(g:Graphics, projection:FastMatrix4, view:FastMatrix4): Void {
		g.setPipeline(pipeline);
		g.setMatrix(projectionLocation, projection);
		g.setMatrix(viewLocation, view);
		g.setMatrix(modelLocation, modelMatrix);
		
		g.setIndexBuffer(indexBuffer);
		g.setVertexBuffer(vertexBuffer);
		g.drawIndexedVertices();
	}
}