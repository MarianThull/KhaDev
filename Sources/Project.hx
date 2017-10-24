package;

import kha.Assets;
import kha.Canvas;
import kha.Framebuffer;
import kha.Image;
import kha.Scheduler;
import kha.Shaders;
import kha.System;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.Graphics;
import kha.graphics4.TextureFormat;
import kha.graphics4.BlendingFactor;
import kha.graphics4.CompareMode;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CubeMap;
import kha.graphics4.CullMode;
import kha.graphics4.Graphics;
import kha.graphics4.MipMapFilter;
import kha.graphics4.PipelineState;
import kha.graphics4.Usage;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.TextureUnit;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.math.FastMatrix4;


class Project 
{
    private var camera:Camera;
    private var terrain:Terrain;
    
    private var bb1:Image;
    private var bb2:Image;
    private var targets:Array<Canvas>;
    
    /* pipeline stuff */
    private var projectionMatrixID:ConstantLocation;
    private var viewMatrixID:ConstantLocation;
    private var modelMatrixID:ConstantLocation;
    private var texID:TextureUnit;
    private var pipeline:PipelineState;
    private var vertexStructure:VertexStructure;
    /* cubemap pipeline stuff */
    private var texFaceID:TextureUnit;
    private var vertexStructureFace:VertexStructure;
    private var vertexBufferFace:VertexBuffer;
    private var indexBufferFace:IndexBuffer;
    private var pipelineFace:PipelineState;
    /* skybox pipeline stuff */
    private var projectionMatrixSkyID:ConstantLocation;
    private var viewMatrixSkyID:ConstantLocation;
    private var pipelineSky:PipelineState;
    private var texSkyID:TextureUnit;
    private var vertexStructureSky:VertexStructure;
    private var vertexBufferSky:VertexBuffer;
    private var indexBufferSky:IndexBuffer;
    private var cubemapSky:CubeMap;

    public function new() 
    {
        Assets.loadEverything(function():Void {
        });

        camera = new Camera();
        
        
        targets = new Array<Canvas>();
        bb1 = Image.createRenderTarget(Main.width, Main.height, TextureFormat.RGBA32, DepthStencilFormat.DepthAutoStencilAuto);
        bb2 = Image.createRenderTarget(Main.width, Main.height, TextureFormat.RGBA32, DepthStencilFormat.DepthAutoStencilAuto);
        targets.push(bb2);
        
        
        /* prepare all pipeline stuff */
        vertexStructure = new VertexStructure();
        vertexStructure.add("vertexPosition", VertexData.Float3);
        vertexStructure.add("vertexColor", VertexData.Float3);
        vertexStructure.add("texPosition", VertexData.Float2);
        
        pipeline = new PipelineState();
        pipeline.inputLayout = [vertexStructure];
        pipeline.vertexShader = Shaders.terrain_vert;
        pipeline.fragmentShader = Shaders.terrain_frag;
        
        pipeline.depthWrite = true;
        pipeline.depthMode = CompareMode.Less;
        pipeline.cullMode = CullMode.Clockwise;
        
        pipeline.blendSource = BlendingFactor.BlendOne;
        pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.alphaBlendSource = BlendingFactor.SourceAlpha;
        pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
        
        pipeline.compile();
        
        projectionMatrixID = pipeline.getConstantLocation("projectionMatrix");
        modelMatrixID = pipeline.getConstantLocation("modelMatrix");
        viewMatrixID = pipeline.getConstantLocation("viewMatrix");

        /* prepare pipeline for cubemap faces */
        vertexStructureFace = new VertexStructure();
        vertexStructureFace.add("vertexPosition", VertexData.Float3);

        pipelineFace = new PipelineState();
        pipelineFace.inputLayout = [vertexStructureFace];
        pipelineFace.vertexShader = Shaders.texToFace_vert;
        pipelineFace.fragmentShader = Shaders.texToFace_frag;
        pipelineFace.depthWrite = false;

        pipelineFace.compile();

        texFaceID = pipelineFace.getTextureUnit("tex");

        /* prepare pipeline for skybox */
        vertexStructureSky = new VertexStructure();
        vertexStructureSky.add("vertexPosition", VertexData.Float3);

        pipelineSky = new PipelineState();
        pipelineSky.inputLayout = [vertexStructureSky];
        pipelineSky.vertexShader = Shaders.skybox_vert;
        pipelineSky.fragmentShader = Shaders.skybox_frag;

        pipelineSky.depthWrite = false;
        pipelineSky.depthMode = CompareMode.Always;
        pipelineSky.cullMode = CullMode.None;
        pipelineSky.blendSource = BlendingFactor.BlendOne;
        pipelineSky.blendDestination = BlendingFactor.InverseSourceAlpha;
        pipelineSky.alphaBlendSource = BlendingFactor.SourceAlpha;
        pipelineSky.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;

        pipelineSky.compile();

        projectionMatrixSkyID = pipelineSky.getConstantLocation("projectionMatrix");
        viewMatrixSkyID = pipelineSky.getConstantLocation("viewMatrix");
        texSkyID = pipelineSky.getTextureUnit("cubemap");

        cubemapSky = CubeMap.createRenderTarget(2048);
        
        /* create indexed vertices for cube face */
        var dataCube:Array<Float> = [];
        var indicesCube:Array<Int> = [];

        for (x in -1...2) {
            if (x == 0) continue;
            for (y in -1...2) {
                if (y == 0) continue;
                dataCube.push(x);
                dataCube.push(y);
                dataCube.push(1);
            }
        }
        indicesCube.push(0);
        indicesCube.push(2);
        indicesCube.push(1);
        indicesCube.push(2);
        indicesCube.push(3);
        indicesCube.push(1);

        vertexBufferFace = new VertexBuffer(Std.int(dataCube.length / vertexStructureFace.byteSize() * 4), vertexStructureFace, Usage.StaticUsage);
        var vbData:Float32Array;
        vbData = vertexBufferFace.lock();
        for (i in 0...vbData.length) {
            vbData.set(i, dataCube[i]);
        }
        vertexBufferFace.unlock();

        indexBufferFace = new IndexBuffer(indicesCube.length, Usage.StaticUsage);
        var iData:Uint32Array;
        iData = indexBufferFace.lock();
        for (i in 0...iData.length) {
            iData[i] = indicesCube[i];
        }
        indexBufferFace.unlock();

        /* create indexed vertices for unit cube */
        var data:Array<Float> = [];
        var indices:Array<Int> = [];

        for (x in -1...2) {
            if (x == 0) continue;
            for (y in -1...2) {
                if (y == 0) continue;
                for (z in -1...2) {
                    if (z == 0) continue;
                    data.push(x * 10.0);
                    data.push(y * 10.0);
                    data.push(z * 10.0);
                }
            }
        }
        var faces:Array<Array<Int>> = [[0, 1, 3, 2], [1, 5, 6, 3], [5, 4, 6, 7],
                                       [4, 0, 2, 6], [2, 3, 7, 6], [0, 4, 5, 1]];
        for (face in faces) {
            indices.push(face[0]);
            indices.push(face[1]);
            indices.push(face[3]);

            indices.push(face[1]);
            indices.push(face[2]);
            indices.push(face[3]);
        }

        vertexBufferSky = new VertexBuffer(Std.int(data.length / vertexStructureSky.byteSize() * 4), vertexStructureSky, Usage.StaticUsage);
        vbData = vertexBufferSky.lock();
        for (i in 0...vbData.length) {
            vbData.set(i, data[i]);
        }
        vertexBufferSky.unlock();

        indexBufferSky = new IndexBuffer(indices.length, Usage.StaticUsage);
        iData = indexBufferSky.lock();
        for (i in 0...iData.length) {
            iData[i] = indices[i];
        }
        indexBufferSky.unlock();

        //---------------------------------------------------------------------
        terrain = new Terrain(vertexStructure);
        
        System.notifyOnRender(render);
    }
    
    
    private function render(framebuffer: Framebuffer): Void 
    {
        camera.update(0.16);
     
        // render skybox faces
        cubemapSky.g4.beginFace(0);
        cubemapSky.g4.clear(0xFFFFFFFF, 1.0);
        cubemapSky.g4.setPipeline(pipelineFace);
        cubemapSky.g4.setIndexBuffer(indexBufferFace);
        cubemapSky.g4.setVertexBuffer(vertexBufferFace);
        cubemapSky.g4.setTexture(texFaceID, Assets.images.posx);
        cubemapSky.g4.drawIndexedVertices();
        cubemapSky.g4.end();

        cubemapSky.g4.beginFace(1);
        cubemapSky.g4.clear(0xFFFFFFFF, 1.0);
        cubemapSky.g4.setPipeline(pipelineFace);
        cubemapSky.g4.setIndexBuffer(indexBufferFace);
        cubemapSky.g4.setVertexBuffer(vertexBufferFace);
        cubemapSky.g4.setTexture(texFaceID, Assets.images.negx);
        cubemapSky.g4.drawIndexedVertices();
        cubemapSky.g4.end();

        cubemapSky.g4.beginFace(2);
        cubemapSky.g4.clear(0xFFFFFFFF, 1.0);
        cubemapSky.g4.setPipeline(pipelineFace);
        cubemapSky.g4.setIndexBuffer(indexBufferFace);
        cubemapSky.g4.setVertexBuffer(vertexBufferFace);
        cubemapSky.g4.setTexture(texFaceID, Assets.images.posy);
        cubemapSky.g4.drawIndexedVertices();
        cubemapSky.g4.end();

        cubemapSky.g4.beginFace(3);
        cubemapSky.g4.clear(0xFFFFFFFF, 1.0);
        cubemapSky.g4.setPipeline(pipelineFace);
        cubemapSky.g4.setIndexBuffer(indexBufferFace);
        cubemapSky.g4.setVertexBuffer(vertexBufferFace);
        cubemapSky.g4.setTexture(texFaceID, Assets.images.negy);
        cubemapSky.g4.drawIndexedVertices();
        cubemapSky.g4.end();

        cubemapSky.g4.beginFace(4);
        cubemapSky.g4.clear(0xFFFFFFFF, 1.0);
        cubemapSky.g4.setPipeline(pipelineFace);
        cubemapSky.g4.setIndexBuffer(indexBufferFace);
        cubemapSky.g4.setVertexBuffer(vertexBufferFace);
        cubemapSky.g4.setTexture(texFaceID, Assets.images.posz);
        cubemapSky.g4.drawIndexedVertices();
        cubemapSky.g4.end();

        cubemapSky.g4.beginFace(5);
        cubemapSky.g4.clear(0xFFFFFFFF, 1.0);
        cubemapSky.g4.setPipeline(pipelineFace);
        cubemapSky.g4.setIndexBuffer(indexBufferFace);
        cubemapSky.g4.setVertexBuffer(vertexBufferFace);
        cubemapSky.g4.setTexture(texFaceID, Assets.images.negz);
        cubemapSky.g4.drawIndexedVertices();
        cubemapSky.g4.end();

        // begin rendering to frame
        var g4:Graphics = bb1.g4;
        
        g4.begin(targets);
        g4.clear(0xFFFFFFFF, 1.0);

        // render skybox
        g4.setPipeline(pipelineSky);
        g4.setMatrix(viewMatrixSkyID, camera.viewMatrix);
        g4.setMatrix(projectionMatrixSkyID, camera.projectionMatrix);
        g4.setCubeMap(texSkyID, cubemapSky);
        g4.setIndexBuffer(indexBufferSky);
        g4.setVertexBuffer(vertexBufferSky);
        g4.drawIndexedVertices();

        // draw terrain
        g4.setPipeline(pipeline);
        g4.setMatrix(modelMatrixID, terrain.modelMatrix);
        g4.setMatrix(viewMatrixID, camera.viewMatrix);
        g4.setMatrix(projectionMatrixID, camera.projectionMatrix);
        g4.setIndexBuffer(terrain.indexBuffer);
        g4.setVertexBuffer(terrain.vertexBuffer);
        g4.drawIndexedVertices();
        
        g4.end();
        
        
        framebuffer.g2.begin();
        //render targets not worked as expected:
        var posX:Int = 0;
        var posY:Int = 0;
        if (g4.renderTargetsInvertedY()){
            framebuffer.g2.drawScaledImage(bb1, 0, Main.height, Main.width, -Main.height);
            // framebuffer.g2.drawScaledImage(bb2, 0, 144, 256, -144); 
        } else {
            framebuffer.g2.drawImage(bb1, 0, 0);
            // framebuffer.g2.drawScaledImage(bb2, 0, 0, 256, 144); 
        }
        

        framebuffer.g2.end();
    }
}
