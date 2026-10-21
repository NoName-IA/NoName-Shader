#version 120

#define IDLE_HANDS //Makes your hands sway back and forth in 1st person, like they do in 3rd person

#define SHADE_STRENGTH 0.35 //How dark surfaces that are facing away from the sun are [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50]

uniform float frameTimeCounter;
uniform float animTime; //NoName: tick-based clock, see shaders.properties
#define frameTimeCounter animTime //NoName: every animation follows /tick freeze and /tick rate
uniform float night;
uniform float rainStrength;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;
uniform vec3 sunPosNorm;

varying float handGlow; //NoName: 0-1, how much light the items in your hands give off
varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 tint;

//NoName: light level of an item by its item.properties ID, used when Iris doesn't fill in heldBlockLightValue (it stays 0 on 26.1)
int itemLightLevel(int id) {
	if (id == 89 || id == 169 || id == 91 || id == 138 || id == 10002 || id == 10005) return 15; //glowstone, sea lantern, jack-o-lantern, beacon, shroomlight, lava bucket
	if (id == 50 || id == 198) return 14; //torches/lanterns/campfires, end rods
	if (id == 10001 || id == 10004) return 10; //soul torches, crying obsidian
	if (id == 76) return 7; //redstone torches
	if (id == 10003) return 6; //sea pickles
	if (id == 10012 || id == 10013) return 15; //NoName: redstone lamp, respawn anchor (as if on/charged)
	if (id == 10011) return 13; //NoName: furnaces/smokers (as if lit)
	if (id == 10008 || id == 10009) return 12; //NoName: glow berries, nether star
	if (id == 10006) return 10; //NoName: blaze rod
	if (id == 10007) return 6; //NoName: blaze powder
	if (id == 10010) return 3; //NoName: candles (one lit candle)
	return 0;
}

void main() {
	//match logic from gbuffers_armor_glint.vsh
	vec3 vPosView = (gl_ModelViewMatrix * gl_Vertex).xyz;
	#ifdef IDLE_HANDS
		if (heldItemId != 359 && heldItemId2 != 359) { //no hand sway when holding a map.
			vPosView.xy += sin(frameTimeCounter * vec2(1.6, 1.2)) * (sign(gl_ModelViewMatrix[3][0] + 0.3125) * 0.015625);
		}
	#endif
	gl_Position = gl_ProjectionMatrix * vec4(vPosView, 1.0);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	int mainLight = heldBlockLightValue > 0 ? heldBlockLightValue : itemLightLevel(heldItemId); //NoName
	int offLight = heldBlockLightValue2 > 0 ? heldBlockLightValue2 : itemLightLevel(heldItemId2);
	lmcoord.x = max(lmcoord.x, float(max(mainLight, offLight)) * 0.0625 + 0.03125); //NoName: off hand lights your hands too
	handGlow = float(max(mainLight, offLight)) / 15.0; //NoName: both hands

	tint  =  gl_Color;
	//not pre-normalized for item frames with maps in them
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
	float glmult = 0.0;
	if (night < 0.999) glmult += dot( sunPosNorm, normal) * (1.0 - night);
	if (night > 0.001) glmult += dot(-sunPosNorm, normal) * night;
	//glmult = glmult * 0.375 + 0.625; //0.25 - 1.0
	glmult = glmult * SHADE_STRENGTH + (1.0 - SHADE_STRENGTH);
	glmult = mix(glmult, 1.0, rainStrength * 0.5); //less shading during rain
	glmult = mix(1.0, glmult, lmcoord.y * 0.66666666 + 0.33333333); //0.5 - 1.0 in darkness
	glmult = mix(glmult, 1.0, lmcoord.x * lmcoord.x); //increase brightness when block light is high
	tint.rgb *= glmult;
}