#version 450

in vec3 pos;

out vec3 posOut;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main() {
	gl_Position = projection * view * model * vec4(pos, 1.0);
	posOut = pos;
}