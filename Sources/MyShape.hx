package;

import haxebullet.Bullet;
import kha.graphics4.CompareMode;
import kha.graphics4.ConstantLocation;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Graphics;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexStructure;
import kha.Shaders;
import kha.math.FastMatrix4;
import kha.System;
import kha.math.Quaternion;

class MyShape {
	private var pipeline: PipelineState;
	private var vertexBuffer: VertexBuffer;
	private var indexBuffer: IndexBuffer;
	private var projectionLocation: ConstantLocation;
	private var viewLocation: ConstantLocation;
	private var modelLocation: ConstantLocation;
	private var modelMatrix: FastMatrix4 = FastMatrix4.identity();
	private var rigidBody: BtRigidBody;
	private var shape:BtCollisionShape;

	public function new(dynamicsWorld:BtDynamicsWorld) {
		initPhysicsObject(dynamicsWorld);
		initRenderPipeline();
	}

	private function initPhysicsObject(dynamicsWorld:BtDynamicsWorld): Void {
		calcCollisionShape();

		var trans = BtTransform.create();
		trans.setIdentity();
		trans.setOrigin(BtVector3.create(0, 100, 0));
		var centerOfMassOffsetTransform = BtTransform.create();
		centerOfMassOffsetTransform.setIdentity();
		var motionState = BtDefaultMotionState.create(trans, centerOfMassOffsetTransform);
		var inertia = BtVector3.create(0, 0, 0);
		shape.calculateLocalInertia(1, inertia);
		var rigidBodyCI = BtRigidBodyConstructionInfo.create(1, motionState, shape, inertia);
		rigidBody = BtRigidBody.create(rigidBodyCI);
		dynamicsWorld.addRigidBody(rigidBody);
	}

	private function calcCollisionShape(): Void {

	}

	private function initRenderPipeline(): Void {
		var structure = prepareBuffer();

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
	}

	private function prepareBuffer(): VertexStructure {
		return new VertexStructure();
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