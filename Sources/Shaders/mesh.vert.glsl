#version 450

in vec3 pos;
in vec3 normal;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

out vec3 norm;

void main() {
	norm = normalize((model * vec4(normal, 0.0)).xyz);
	gl_Position = projection * view * model * vec4(pos, 1.0);
}
