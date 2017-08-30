#version 450

in vec2 texCoord;
in vec3 color;

layout(location = 0) out vec4 color_space;
layout(location = 1) out vec4 red_space;

void main() 
{
    color_space = vec4(color, 1.0);
    red_space = vec4(1.0, 0.0, 0.0, 1.0);
}
