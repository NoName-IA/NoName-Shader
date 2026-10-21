#version 120

#define MOON_SIZE 1.3 //NoName: moon size. 1.0 = vanilla [1.0 1.1 1.2 1.3 1.4 1.5 1.75 2.0]

uniform vec3 sunPosNorm;

varying vec2 texcoord;
varying vec4 tint;

void main() {
	vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	//NoName: the moon is the quad on the opposite side of the sky from the sun. grow it around its own center.
	vec3 moonDir = -sunPosNorm;
	if (dot(normalize(viewPos), moonDir) > 0.0) {
		vec3 center = moonDir * dot(viewPos, moonDir);
		viewPos = center + (viewPos - center) * MOON_SIZE;
	}
	gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
	tint = gl_Color;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}