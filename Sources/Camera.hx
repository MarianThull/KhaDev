package;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.math.FastMatrix4;
import kha.math.FastVector3;
import kha.System;

/**
 * ...
 * @author Dmitry Hryppa	http://themozokteam.com/
 */
 
class Camera 
{
    public var nearPlane:Float = 0.1;
    public var farPlane:Float = 1000;
    public var position(default, null):FastVector3;
    public var viewMatrix(default, null):FastMatrix4;
    public var projectionMatrix(default, null):FastMatrix4;
    
    private var speed:Float = 7.5;
    private var mouseSpeed:Float = 0.01;
    private var horizontalAngle:Float = 0; // 3.14; 
    private var verticalAngle:Float = -0.75; 
    private var mouseX:Float = 0.0;
    private var mouseY:Float = 0.0;
    private var mouseDeltaX:Float = 0.0;
    private var mouseDeltaY:Float = 0.0;
    private var dx:Float = 0;
    private var dy:Float = -0.75;
    private var moveForward:Bool = false;
    private var moveBackward:Bool = false;
    private var strafeLeft:Bool = false;
    private var strafeRight:Bool = false;
    private var isMouseDown:Bool = false;
    private var look:FastVector3;
    private var direction:FastVector3;
    
    public function new() 
    {
        position = new FastVector3(0, 25, -25);
        viewMatrix = FastMatrix4.identity();
        projectionMatrix = FastMatrix4.perspectiveProjection(45, System.windowWidth(0) / System.windowHeight(0), nearPlane, farPlane);
        viewMatrix = FastMatrix4.lookAt(position, new FastVector3(0, 0, 0), new FastVector3(0, 1, 0));
        
        look = new FastVector3();
        direction = new FastVector3();

		update(0);
        
        Mouse.get().notify(mouseDown, mouseUp, mouseMove, null, null);
        Keyboard.get().notify(keyDown, keyUp);
    }
    
    public function mouseDown(button:Int, x:Int, y:Int):Void 
    {
        isMouseDown = true;
    }

    public function mouseUp(button:Int, x:Int, y:Int):Void 
    {
        isMouseDown = false;
        mouseDeltaX = 0;
        mouseDeltaY = 0;
    }

    public function mouseMove(x:Int, y:Int, deltaX:Int, deltaY:Int):Void 
    {
        mouseDeltaX = x - mouseX;
        mouseDeltaY = y - mouseY;

        mouseX = x;
        mouseY = y;
    }

    public function keyDown(key:KeyCode):Void 
    {
        switch(key) {
            case W:
                moveForward = true;
            case S:
                moveBackward = true;
            case A:
                strafeLeft = true;
            case D:
                strafeRight = true;
            default:
                return;
        }
    }

    public function keyUp(key:KeyCode):Void  
    {
        switch(key) {
            case W:
                moveForward = false;
            case S:
                moveBackward = false;
            case A:
                strafeLeft = false;
            case D:
                strafeRight = false;
            default:
                return;
        }
    }

    public function update(deltaTime:Float):Void  
    {
        if (isMouseDown) {
            dx += mouseSpeed * mouseDeltaX * -1;
            dy += mouseSpeed * mouseDeltaY * -1;
            //horizontalAngle
            //verticalAngle += mouseSpeed * mouseDeltaY * -1;
        }
        
        horizontalAngle = lerpFloat(horizontalAngle, dx, 0.15);
        verticalAngle = lerpFloat(verticalAngle, dy, 0.15);

        // Direction : Spherical coordinates to Cartesian coordinates conversion
        direction = new FastVector3(
            Math.cos(verticalAngle) * Math.sin(horizontalAngle),
            Math.sin(verticalAngle),
            Math.cos(verticalAngle) * Math.cos(horizontalAngle)
        );
        
        // Right vector
        var right:FastVector3 = new FastVector3(
            Math.sin(horizontalAngle - 3.14 / 2.0), 
            0,
            Math.cos(horizontalAngle - 3.14 / 2.0)
        );
        
        // Up vector
        var up:FastVector3 = right.cross(direction);
        
        // Movement
        var lerp:Float = 0.12;
        if (moveForward) {
            var v:FastVector3 = direction.mult(deltaTime * speed);
            position = position.add(v);
        }
        if (moveBackward) {
            var v:FastVector3 = direction.mult(deltaTime * speed * -1);
            position = position.add(v);
        }
        if (strafeRight) {
            var v:FastVector3 = right.mult(deltaTime * speed);
            position = position.add(v);
        }
        if (strafeLeft) {
            var v:FastVector3 = right.mult(deltaTime * speed * -1);
            position = position.add(v);
        }
                    
        // Look vector
        look = position.add(direction);
        // Camera matrix
        viewMatrix = FastMatrix4.lookAt(position, // Camera is here
                  look, // and looks here : at the same position, plus "direction"
                  up // Head is up (set to (0, -1, 0) to look upside-down)
        );
        
        mouseDeltaX = 0;
        mouseDeltaY = 0;
    }
    
    private inline function lerpFloat(value1:Float, value2:Float, time:Float):Float
    {
        return (1 - time) * value1 + time * value2;
    }
}