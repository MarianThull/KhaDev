package;

import kha.Framebuffer;
import kha.Scheduler;
import kha.Sound;
import kha.System;
import kha.Assets;
import kha.audio1.Audio;
import kha.audio1.AudioChannel;
import kha.graphics2.Graphics;
import kha.math.FastMatrix3;
import kha.Image;
import kha.Scaler;

class Empty {
	public static inline var width = 1920;
	public static inline var height = 1080;
	private var backbuffer: Image;
	private var g: Graphics;
	private var ac: AudioChannel;
	private var startTime: Float;
	private var time: Float;
	private var paused = false;
	
	public function new() {
		Assets.loadEverything(function () {
			return null;
		});
		
		backbuffer = Image.createRenderTarget(width, height);
		g = backbuffer.g2;

		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
		ac = createAudioChannel(Assets.sounds.bills, false);
		startTime = Scheduler.realTime();
	}
	
	private function createAudioChannel(s: Sound, loop: Bool): AudioChannel {
		var ac = Audio.play(s, loop);
		if (ac == null) {
			ac = Audio.stream(s, loop);
		}
		return ac;
	}

	function update(): Void {
		time = Scheduler.realTime() - startTime;
		if (time > 1 && time < 2 && !paused) {
			ac.pause();
			paused = true;
		}
		else if (time > 2 && paused) {
			ac.volume = 0.5;
			ac.play();
			paused = false;
		}
		else if (time > 6) {
			trace('Time: ${ac.position}/${ac.length}\tfinished: ${ac.finished}');
		}
	}

	function render(framebuffer: Framebuffer): Void {		
		g.begin();
		g.clear(kha.Color.Black);
		g.imageScaleQuality = kha.graphics2.ImageScaleQuality.High;

		// test android project
		g.drawImage(Assets.images.testbild, 0, 0);

		g.end();
		framebuffer.g2.begin();
		Scaler.scale(backbuffer, framebuffer, System.screenRotation);
		framebuffer.g2.end();
	}
}
