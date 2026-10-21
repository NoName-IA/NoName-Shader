#version 120

//NoName: shadow pass. draws the world from the sun (or moon) into the shadow map.
//the picture is squeezed towards the middle (distortion) so shadows near you get more resolution than far ones;
//composite.fsh undoes it with the same formula. only runs when SHADOWS is on (see shaders.properties).

attribute vec3 mc_Entity;

varying vec2 texcoord;
varying vec4 tint;
varying float noShadow; //water doesn't cast shadows

const float shadowDistortion = 0.85; //keep the same as composite.fsh

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	tint = gl_Color;
	noShadow = float(abs(mc_Entity.x - 10009.0) < 0.5);
	vec4 pos = ftransform();
	pos.xy /= length(pos.xy) * shadowDistortion + (1.0 - shadowDistortion);
	gl_Position = pos;
}
