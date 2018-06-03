#version 450

in vec3 norm;

out vec4 frag;

void main() {
	frag = vec4(vec3(1.0, 1.0, 1.0), 1.0);
}