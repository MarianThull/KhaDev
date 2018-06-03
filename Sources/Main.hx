package;

import haxebullet.Bullet;
import kha.Color;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.Assets;

class Main {
	static var meshes = new Array<MeshLoader>();
	static var ring;

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
			}, function(ae: kha.AssetError) {
				return;
			});
			#else
			init();
			#end
		});
	}
	
	static function init(): Void {
		Assets.loadEverything(init2);
	}

	static function init2(): Void {
		var mesh = new MeshLoader();
		var mesh2 = new MeshLoader();
		var mesh3 = new MeshLoader();
		meshes.push(mesh);
		meshes.push(mesh2);
		meshes.push(mesh3);

		initPhysics();

		ring = new RingShape(100.0, 50.0, 30.0, 16, 10, dynamicsWorld);
		ring.setPosition(0, 300, 0);

		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
	}

	static var dynamicsWorld;
	static var fallRigidBodies = new Array<BtRigidBody>();

	static function initPhysics(): Void {
		var collisionConfiguration = BtDefaultCollisionConfiguration.create();
		var dispatcher = BtCollisionDispatcher.create(collisionConfiguration);
		var broadphase = BtDbvtBroadphase.create();
		var solver = BtSequentialImpulseConstraintSolver.create();
		dynamicsWorld = BtDiscreteDynamicsWorld.create(dispatcher, broadphase, solver, collisionConfiguration);
		dynamicsWorld.setGravity(BtVector3.create(0, -10, 0));

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

		for (i in 0...3) {
			while (!meshes[i].started) {
				continue;
			}
			var fallShape = meshes[i].convexHull;
			var fallTransform = BtTransform.create();
			fallTransform.setIdentity();
			fallTransform.setOrigin(BtVector3.create(i * 10 * Math.pow(-1, i), 100 + i * 100, i * 10 * Math.pow(-1, i)));
			var centerOfMassOffsetFallTransform = BtTransform.create();
			centerOfMassOffsetFallTransform.setIdentity();
			var fallMotionState = BtDefaultMotionState.create(fallTransform, centerOfMassOffsetFallTransform);

			var fallInertia = BtVector3.create(0, 0, 0);
			fallShape.calculateLocalInertia(1, fallInertia);
			var fallRigidBodyCI = BtRigidBodyConstructionInfo.create(1, fallMotionState, fallShape, fallInertia);
			var fallRigidBody = BtRigidBody.create(fallRigidBodyCI);
			dynamicsWorld.addRigidBody(fallRigidBody);
			fallRigidBodies.push(fallRigidBody);
		}
	}

	static function update(): Void {
		dynamicsWorld.stepSimulation(1 / 60);
	
		for (i in 0...meshes.length) {
			var trans = BtTransform.create();
			var m = fallRigidBodies[i].getMotionState();
			m.getWorldTransform(trans);
			meshes[i].updatePosition(trans);
			// meshes[i].updatePosition(trans.getOrigin().x(), trans.getOrigin().y(), trans.getOrigin().z());
		}
		ring.updatePosition();
	}

	static function render(framebuffer: Framebuffer): Void {
		var g = framebuffer.g4;
		g.begin();
		g.clear(Color.Black, Math.POSITIVE_INFINITY);

		for (i in 0...meshes.length) {
			meshes[i].render(g);
		}
		ring.render(g);

		g.end();
	}
}
