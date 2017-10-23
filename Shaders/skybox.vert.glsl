#version 450

in vec3 vertexPosition;

uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec4 texCoord;


void main()
{
	mat4 vm = viewMatrix;
	vm[3][0] = 0.0;
	vm[3][1] = 0.0;
	vm[3][2] = 0.0;

	texCoord = inverse(vm) * inverse(projectionMatrix) * vec4(vertexPosition, 1.0);
	// gl_Position = vec4(vertexPosition, 1.0);
}