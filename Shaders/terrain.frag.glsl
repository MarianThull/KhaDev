#version 450

in vec2 texCoord;
in vec3 color;

void main() 
{
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(1.0, 0.0, 0.0, 1.0);
}
