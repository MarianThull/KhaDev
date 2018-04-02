package;

import haxebullet.Bullet;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {
	public static function main() {
		System.init({title: "PhysicsSample", width: 1024, height: 768}, function () {
			#if js
			//haxe.macro.Compiler.includeFile("../Libraries/Bullet/js/ammo/ammo.wasm.js");
			kha.LoaderImpl.loadBlobFromDescription({ files: ["ammo.js"] }, function(b: kha.Blob) {
				var print = function(s:String) { trace(s); };
				var loaded = function() { print("ammo ready"); };
				untyped __js__("(1, eval)({0})", b.toString());
				untyped __js__("Ammo({print:print}).then(loaded)");
				init();
			});
			#else
			init();
			#end
		});
	}

	static function init(): Void {
		initPhysics();
		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
	}

	static var dynamicsWorld;
	static var fallRigidBody;

	static function initPhysics(): Void {
		var collisionConfiguration = BtDefaultCollisionConfiguration.create();
		var dispatcher = BtCollisionDispatcher.create(collisionConfiguration);
		var broadphase = BtDbvtBroadphase.create();
		var solver = BtSequentialImpulseConstraintSolver.create();
		dynamicsWorld = BtDiscreteDynamicsWorld.create(dispatcher, broadphase, solver, collisionConfiguration);

		var groundShape = BtStaticPlaneShape.create(BtVector3.create(0, 1, 0), 1);
		var groundTransform = BtTransform.create();
		groundTransform.setIdentity();
		groundTransform.setOrigin(BtVector3.create(0, -1, 0));
		var centerOfMassOffsetTransform = BtTransform.create();
		centerOfMassOffsetTransform.setIdentity();
		var groundMotionState = BtDefaultMotionState.create(groundTransform, centerOfMassOffsetTransform);

		var groundRigidBodyCI = BtRigidBodyConstructionInfo.create(0, groundMotionState, groundShape, BtVector3.create(0, 0, 0));
		var groundRigidBody = BtRigidBody.create(groundRigidBodyCI);
		dynamicsWorld.addRigidBody(groundRigidBody);

		var fallShape = BtSphereShape.create(1);
		var fallTransform = BtTransform.create();
		fallTransform.setIdentity();
		fallTransform.setOrigin(BtVector3.create(0, 50, 0));
		var centerOfMassOffsetFallTransform = BtTransform.create();
		centerOfMassOffsetFallTransform.setIdentity();
		var fallMotionState = BtDefaultMotionState.create(fallTransform, centerOfMassOffsetFallTransform);

		var fallInertia = BtVector3.create(0, 0, 0);
		fallShape.calculateLocalInertia(1, fallInertia);
		var fallRigidBodyCI = BtRigidBodyConstructionInfo.create(1, fallMotionState, fallShape, fallInertia);
		fallRigidBody = BtRigidBody.create(fallRigidBodyCI);
		dynamicsWorld.addRigidBody(fallRigidBody);
	}

	static function update(): Void {
		dynamicsWorld.stepSimulation(1 / 60);
	
		var trans = BtTransform.create();
		var m = fallRigidBody.getMotionState();
		m.getWorldTransform(trans);
		trace(trans.getOrigin().y());
	}

	static function render(framebuffer: Framebuffer): Void {
		
	}
}
