#version 450

in vec3 vertexPosition;
in vec3 vertexColor;
in vec2 texPosition;

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec2 texCoord;
out vec3 color;

void main()
{
    vec4 worldPos = modelMatrix * vec4(vertexPosition, 1.0);
    gl_Position = projectionMatrix * viewMatrix * worldPos;

    texCoord = texPosition;
    color = vertexColor;
}
