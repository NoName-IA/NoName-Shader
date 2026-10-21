#version 120

uniform float frameTimeCounter;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 tint;

void main() {
	vec4 color = texture2D(texture, texcoord) * tint;
	vec4 aux = vec4(lmcoord, 1.0, 1.0);

	//NoName: dragon's breath. Its particles are the only ones tinted magenta with zero green,
	//so they're easy to spot. Make them a glowing, flickering, dangerous-looking acid fire:
	//white-hot pink cores, burning magenta, deep violet edges. Marked emissive so the end's lighting doesn't dim them
	if (tint.g < 0.05 && tint.r > 0.6 && tint.b > 0.75) {
		float heat = dot(texture2D(texture, texcoord).rgb, vec3(0.33333));
		float t = frameTimeCounter;
		//violent flicker: fast, uneven, never steady
		float flicker = 0.7 + 0.3 * sin(t * 23.0 + gl_FragCoord.x * 0.21 + gl_FragCoord.y * 0.17) * sin(t * 37.0 - gl_FragCoord.y * 0.13);
		flicker *= 0.85 + 0.15 * sin(t * 9.0); //the whole cloud throbs
		//crackling sparks: random white-hot flecks that pop in and out
		vec2 cell = floor(gl_FragCoord.xy * 0.25);
		float spark = fract(sin(dot(cell, vec2(12.9898, 78.233)) + floor(t * 18.0) * 1.618) * 43758.5453);
		spark = smoothstep(0.93, 1.0, spark);
		//black-violet smoky edges, burning magenta body, white-hot pink core
		vec3 fire = mix(vec3(0.12, 0.0, 0.2), vec3(1.0, 0.05, 0.75), smoothstep(0.15, 0.55, heat));
		fire = mix(fire, vec3(1.0, 0.75, 1.0), smoothstep(0.65, 1.0, heat));
		color.rgb = fire * 2.6 * flicker + vec3(1.0, 0.85, 1.0) * spark * 3.0 * heat;
		color.a = min(color.a * 1.9, 1.0);
		aux = vec4(1.0, lmcoord.y, 0.5, 1.0);
	}

/* DRAWBUFFERS:04 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = aux; //gaux1
}