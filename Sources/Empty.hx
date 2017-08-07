package;

import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.Assets;
import kha.audio2.Audio1;
import kha.audio1.AudioChannel;
import kha.math.FastMatrix3;
import kha.Image;
import kha.Scaler;

class Empty {
	public static inline var width = 1920;
	public static inline var height = 1080;
	private var backbuffer: Image;
	private var musicChannel: AudioChannel;
	
	public function new() {
		Assets.loadEverything(function () {
			return null;
		});
		
		backbuffer = Image.createRenderTarget(width, height);

		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
		musicChannel = Audio1.play(Assets.sounds.pigeon);
	}

	function update(): Void {
		
	}

	function render(framebuffer: Framebuffer): Void {
		var g = backbuffer.g2;
		
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
