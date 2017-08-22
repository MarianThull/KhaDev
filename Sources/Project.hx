package;

import kha.Assets;
import kha.Framebuffer;
import kha.Image;
import kha.Scheduler;
import kha.System;
import kha.Scaler;

class Project {
	public static inline var width = 1024;
	public static inline var height = 768;
	private var backbuffer: Image;

	private var globScale: Float = 1;
	private var lineX0 = 0;
	private var lineY0 = 0;
	private var lineX1 = width/2;
	private var lineY1 = height/2;
	private var posX:Float = 0;
	private var posY:Float = 0;
	private var sumDX:Float = 0;
	private var sumDY:Float = 0;
	private var lastX:Float = 0;
	private var lastY:Float = 0;
	private var lastDX:Float = 0;
	private var hold = false;

	public function new() {
		backbuffer = Image.createRenderTarget(width, height);
		//Assets.loadEverything(function() {});

		kha.input.Mouse.get().notify(mouseDown, mouseUp, mouseMove, null);
		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
	}

	private function mouseDown(button: Int, x: Int, y: Int): Void {
		hold = true;
	}

	private function mouseUp(button: Int, x: Int, y: Int): Void {
		hold = false;
		if (!kha.input.Mouse.get().isLocked()) {
			kha.input.Mouse.get().lock();
		}
		else {
			kha.input.Mouse.get().unlock();
		}
	}

	private function mouseMove(x:Float, y:Float, dx:Float, dy:Float): Void {
		if (hold) {
			lineX1 += dx * globScale;
			lineY1 += dy * globScale;
		}
		sumDX += dx;
		sumDY += dy;
		lastX = posX;
		lastY = posY;
		lastDX = dx;
		posX = x;
		posY = y;
	}

	private function updateGlobScale(): Void {
		
	}

	function update(): Void {
		updateGlobScale();
	}

	function render(framebuffer: Framebuffer): Void {
		var g = backbuffer.g2;
		//g.font = Assets.fonts.arial;
		g.fontSize = 18;
		g.begin();
		g.color = kha.Color.Orange;
		g.drawRect(0, 0, width, height, 4);
		//g.drawLine(lineX0, lineY0, lineX1, lineY1, 4);
		//g.drawString('(${posX}, ${posY})', 920, 730);
		trace('sumdx: ${sumDX}, sumdy: ${sumDY}');
		trace('x - last: ${posX - lastX}, dx: ${lastDX}');
		g.color = kha.Color.Black;
		g.end();

		framebuffer.g2.begin();
		Scaler.scale(backbuffer, framebuffer, System.screenRotation);
		framebuffer.g2.end();
	}
}
