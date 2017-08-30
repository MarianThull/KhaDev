package;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexStructure;
import kha.math.FastMatrix4;
import kha.math.FastVector3;

/**
 * ...
 * @author Dmitry Hryppa	http://themozokteam.com/
 */
class Terrain 
{
    private static inline var SIZE:Int = 50;
    private static inline var VERTEX_COUNT:Int = 64;
    
    public var vertexBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;
    public var modelMatrix(default, null):FastMatrix4;
    
    public function new(vertexStructure:VertexStructure) 
    {
        var count:Int = VERTEX_COUNT * VERTEX_COUNT;
        var length:Int = 3 + 3 + 2;
        var data:Array<Float> = [];
        

        var indices:Array<Int> = [];
        
        for (i in 0...VERTEX_COUNT){
            for (j in 0...VERTEX_COUNT){
                var vx:Float = (j / (VERTEX_COUNT - 1)) * SIZE;
                var vy:Float = Math.random();
                var vz:Float = (i / (VERTEX_COUNT - 1)) * SIZE;

                data.push(vx);
                data.push(vy);
                data.push(vz);
                
                data.push(0.0);
                data.push(vy);
                data.push(1.0);
                
                
                data.push(j / (VERTEX_COUNT - 1));
                data.push(i / (VERTEX_COUNT - 1));
            }
        }
        
        var pointer:Int = 0;
        for (z in 0...VERTEX_COUNT - 1){
            for (x in 0...VERTEX_COUNT - 1){
                var topLeft:Int = (z * VERTEX_COUNT) + x;
                var topRight:Int = topLeft + 1;
                var bottomLeft:Int = ((z + 1) * VERTEX_COUNT) + x;
                var bottomRight:Int = bottomLeft + 1;
                
                indices.push(topLeft);
                indices.push(bottomLeft);
                indices.push(topRight);
                indices.push(topRight);
                indices.push(bottomLeft);
                indices.push(bottomRight);
            }
        }
        
        
        vertexBuffer = new VertexBuffer(Std.int(data.length / vertexStructure.byteSize() * 4), vertexStructure, Usage.StaticUsage);
        var vbData:Float32Array = vertexBuffer.lock();
        for (i in 0...vbData.length) {
            vbData.set(i, data[i]);
        }
        vertexBuffer.unlock();

        indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
        var iData:Uint32Array = indexBuffer.lock();
        for (i in 0...iData.length) {
            iData[i] = indices[i];
        }
        indexBuffer.unlock();
        
        
        setPosition();
    }
    
    
    public function setPosition(x:Float = 0, y:Float = 0, z:Float = 0):Void
    {
        modelMatrix = FastMatrix4.translation(x, y, z);
    }
}