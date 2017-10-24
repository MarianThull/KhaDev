#version 450

in vec3 vertexPosition;

out vec2 texCoord;

void main()
{
	texCoord = vec2((vertexPosition.x + 1.0) * 0.5, (vertexPosition.y + 1.0) * 0.5);
	gl_Position = vec4(vertexPosition, 1.0);
}