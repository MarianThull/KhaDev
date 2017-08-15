package;

import kha.Assets;
import kha.Framebuffer;
import kha.Image;
import kha.Scheduler;
import kha.System;
import kha.Scaler;

class Project {
	private var image: Image;
	public static inline var width = 1920;
	public static inline var height = 1080;
	private var backbuffer: Image;

	public function new() {
		 backbuffer = Image.createRenderTarget(width, height);
		
		 Assets.loadImageFromPath('wall.k', true, function(i: Image) {
		 	image = i;
		 });
		// trace('width: ${image.width}, height: ${image.height}');
		
		//Assets.loadImage(Assets.images.wallName ,function(i: kha.Image) {
			//this.image = i;
		//});
		
		


		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
	}

	function update(): Void {

	}

	function render(framebuffer: Framebuffer): Void {
		var g = backbuffer.g2;
		g.begin();
		g.drawImage(image, 0, 0);
		g.end();

		framebuffer.g2.begin();
		Scaler.scale(backbuffer, framebuffer, System.screenRotation);
		framebuffer.g2.end();
	}
}
