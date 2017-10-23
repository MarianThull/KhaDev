#version 450

in vec4 texCoord;

uniform samplerCube cubemap;

out vec4 color;

void main()
{
	color = texture(cubemap, texCoord.xyz);
}