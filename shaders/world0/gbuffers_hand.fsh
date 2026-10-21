#version 120

#define HELD_GLOW 100 //NoName: light-emitting items in your hands glow (torch flame, glowstone...). 0 = off [0 50 100 150 200]

uniform sampler2D texture;

varying float handGlow;
varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 tint;

void main() {
	vec4 color = texture2D(texture, texcoord) * tint;
	vec2 lm = lmcoord;

	//NoName: held light sources glow. only their bright pixels (the flame, not the torch stick),
	//which get full block light (so they're not darkened at night) and a brightness boost.
	#if HELD_GLOW > 0
		if (handGlow > 0.0) {
			float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
			float glow = handGlow * smoothstep(0.45, 0.7, luma);
			lm.x = mix(lm.x, 1.0, glow);
			color.rgb = min(color.rgb * (1.0 + glow * (HELD_GLOW * 0.006)), 1.0);
		}
	#endif

/* DRAWBUFFERS:04 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lm, 1.0, color.a); //gaux1
}