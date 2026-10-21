#version 120

//NoName: shadow pass, see shadow.vsh. cut-out textures (leaves, grass, glass panes...) only cast shadow where they are solid.
//the color goes to shadowcolor0: composite.fsh uses it to tint the light that passes through stained glass.

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 tint;
varying float noShadow;

void main() {
	if (noShadow > 0.5) discard;
	vec4 color = texture2D(texture, texcoord) * tint;
	if (color.a < 0.1) discard;
/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //shadowcolor0
}
