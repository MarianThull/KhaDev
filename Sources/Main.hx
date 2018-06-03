package;

import haxebullet.Bullet;
import kha.Color;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.Assets;
import kha.math.FastMatrix4;
import kha.math.FastVector3;

class Main {
	static var meshes = new Array<MyShape>();
	static var dynamicsWorld;
	static var viewMatrix = FastMatrix4.lookAt(new FastVector3(0, 50, -25), new FastVector3(0, 0, 0), new FastVector3(0, 1, 0));
	static var projectionMatrix: FastMatrix4;

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
		projectionMatrix = FastMatrix4.perspectiveProjection(45, System.windowWidth(0) / System.windowHeight(0), 0.1, 1000);
		
		initPhysics();

		for (i in 0...4) {
			var mesh = new MeshLoader(Assets.blobs.body_ogex, dynamicsWorld, 0.02);
			meshes.push(mesh);
			mesh.setPosition(0.0, 15.0 + i * 5.0, 0.0);	
		}

		for (i in 0...5) {
			var ring = new RingShape(2.0, 1.0, 0.5, 16, 16, dynamicsWorld);
			meshes.push(ring);
			ring.setPosition(0, 17.5 + i * 5.0, 0);
		}

		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
	}

	

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
	}

	static function update(): Void {
		dynamicsWorld.stepSimulation(1 / 60);
	
		for (i in 0...meshes.length) {
			meshes[i].updatePosition();
		}
	}

	static function render(framebuffer: Framebuffer): Void {
		var g = framebuffer.g4;
		g.begin();
		g.clear(Color.Black, Math.POSITIVE_INFINITY);

		for (i in 0...meshes.length) {
			meshes[i].render(g, projectionMatrix, viewMatrix);
		}

		g.end();
	}
}
