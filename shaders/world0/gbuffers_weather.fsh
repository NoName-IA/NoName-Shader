#version 120

#define CLOUDS //3D clouds (partially volumetric too). Mild performance impact!

uniform float night;
uniform float nightVision;
uniform float pixelSizeX;
uniform float pixelSizeY;
uniform float rainStrength;
uniform float thunderStrength;
uniform float wetness;
uniform int bedrockLevel = 0;
uniform int heightLimit = 384;
uniform sampler2D depthtex0;
uniform sampler2D texture;
uniform vec3 fogColor;

#ifdef CLOUDS
	varying float worldHeight;
#endif
varying vec2 texcoord;
varying vec4 tint;

void main() {
	#ifdef CLOUDS
		if (worldHeight > bedrockLevel + heightLimit) discard; //don't draw rain above clouds.
	#endif

	vec4 color = texture2D(texture, texcoord) * tint;
	//NoName: realistic rain: cool, see-through drops instead of solid streaks. a bit denser in storms.
	//snow uses this program too; its flakes are white while rain is bluish, so only rain is changed.
	bool isRain = color.b - color.r > 0.08;
	if (isRain) color.rgb = mix(color.rgb, vec3(0.78, 0.85, 0.95) * dot(color.rgb, vec3(0.3333)), 0.6);

	if (texture2D(depthtex0, gl_FragCoord.xy * vec2(pixelSizeX, pixelSizeY)).r == 1.0) {
		color.rgb = fogColor * (1.0 - max(rainStrength, wetness) * 0.5) * (1.0 - nightVision * night * 0.75);
	}
	if (isRain) color.a *= 0.55 + thunderStrength * 0.2;
	else color.a *= 2.0 - color.a; //snow: as before

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}