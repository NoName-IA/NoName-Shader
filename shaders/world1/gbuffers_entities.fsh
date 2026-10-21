#version 120

uniform float frameTimeCounter;
uniform int entityId;
uniform sampler2D texture;
uniform vec4 entityColor;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 tint;

void main() {
	vec4 color;
	float lightAlpha;
	if (entityId == 10000) {
		color = tint;
		lightAlpha = 1.0;
	}
	else {
		color = texture2D(texture, texcoord) * tint;
		if (color.a < 0.01) discard; //fix phantoms, and maybe other entities too.
		color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
		lightAlpha = step(0.75, color.a);
	}

	//NoName: ender dragon death rays. They're drawn white in the middle fading to magenta at the edges,
	//while the dragon's body is always white, so any color with less green is a ray.
	//make them blinding, shimmering beams of white, hot pink and violet, and emissive
	float auxB = 1.0;
	if (entityId == 10001 && tint.g < 0.995 && tint.r > 0.9) {
		float shimmer = 0.8 + 0.2 * sin(frameTimeCounter * 30.0 + tint.g * 25.0);
		vec3 beam = mix(vec3(0.5, 0.0, 1.0), vec3(1.0, 0.25, 0.85), smoothstep(0.0, 0.5, tint.g));
		beam = mix(beam, vec3(1.0, 0.95, 1.0), smoothstep(0.6, 1.0, tint.g));
		color = vec4(beam * 2.2 * shimmer, min(tint.a * 1.6, 1.0));
		lightAlpha = 1.0;
		auxB = 0.5;
	}

/* DRAWBUFFERS:04 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(auxB < 0.9 ? 1.0 : lmcoord.x, lmcoord.y, auxB, lightAlpha); //gaux1. NoName: b = 0.5 marks emissive
}