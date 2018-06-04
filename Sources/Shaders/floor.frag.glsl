#version 450

in vec3 posOut;

out vec4 frag;

void main() {
	float light = 0.1;
	highp int indexX = int(floor(posOut.x * 0.5));
	highp int indexZ = int(floor(posOut.z * 0.5));
	if (indexX % 2 == 0 && indexZ % 2 == 0) {
		light = 0.15;
	}
	frag = vec4(light * vec3(1.0, 1.0, 1.0), 1.0);
}