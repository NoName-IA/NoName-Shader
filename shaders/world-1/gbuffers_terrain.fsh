#version 120

//#define GRASS_AO //Adds ambient occlusion to tallgrass/flowers/etc... Works best with "Remove Y Offset" enabled.
//#define LAVA_PATCHES //Randomizes lava brightness, similar to grass patches

#define SOUL_LAVA_AMOUNT 100 //NoName: how strong the red-orange soul valley lava recolor is [5 10 15 20 30 40 50 55 60 70 80 90 100]
#define SOUL_LAVA //NoName: soul valley lava is orange with red details (no blue). When enabled, lava and magma blocks will be blue tinted in soul sand valleys

uniform float frameTimeCounter;
uniform float inSoulSandValley;
uniform sampler2D noisetex;
uniform sampler2D texture;

varying float ao;
varying float isLava;
varying vec2 lmcoord;
varying vec2 randCoord;
varying vec2 texcoord;
varying vec4 tint;
varying float isMagma;
varying vec3 magmaPos;

const int noiseTextureResolution = 256;
const float invNoiseRes = 1.0 / float(noiseTextureResolution);

#ifdef LAVA_PATCHES
	float noiseMap(vec2 coord) {
		coord *= invNoiseRes;
		float noise = 0.0;
		noise += texture2D(noisetex, coord * 0.03125).r;
		noise += texture2D(noisetex, coord * 0.0625 ).r * 0.4;
		noise += texture2D(noisetex, coord * 0.125  ).r * 0.16;
		return noise;
	}
#endif

//NoName: nicer magma blocks. The dark crust gets darker, the cracks glow hot (orange to yellow at their brightest),
//heat slowly flows through them, and each block breathes at its own pace. Glowing cracks raise the block light so they shine in the dark
vec3 magmaLook(vec3 c, float t, float phase, vec3 worldPos, inout float blocklight) {
	float heat = smoothstep(0.35, 0.8, c.r) * smoothstep(0.0, 0.25, c.r - c.b);
	float flow = texture2D(noisetex, worldPos.xz * 0.04 + worldPos.y * 0.02 + vec2(t * 0.006, t * 0.004)).r;
	float pulse = 0.8 + 0.2 * sin(t * 1.3 + phase);
	vec3 crust = c * 0.75;
	vec3 crack = mix(vec3(1.0, 0.38, 0.06), vec3(1.0, 0.82, 0.35), smoothstep(0.7, 0.95, c.r) * flow);
	crack *= (0.85 + 0.5 * flow) * pulse;
	blocklight = max(blocklight, heat * 0.9);
	return mix(crust, crack, heat);
}

void main() {
	vec4 color = texture2D(texture, texcoord);
	#ifdef GRASS_AO
		if (ao < 0.999) color.rgb *= sqrt(ao) * 0.5 + 0.5;
	#endif

	if (isLava > 0.9) {
		#ifdef LAVA_PATCHES
			if (color.r > 0.625) { //ignore non-lava part of magma blocks
				color.rgb += cos(
					noiseMap(randCoord) * 12.5
					+ frameTimeCounter * 0.5
				)
				* 0.125;
			}
		#endif
		#ifdef SOUL_LAVA
			//NoName: soul valley lava. Remaps the lava's own pattern: deep red cracks, orange flow, yellow-orange hot spots. Magma is left alone
			if (isLava > 0.99) {
				float lavaLum = dot(color.rgb, vec3(0.3, 0.5, 0.2));
				vec3 lavaColor = mix(vec3(0.55, 0.04, 0.01), vec3(1.0, 0.42, 0.06), smoothstep(0.3, 0.7, lavaLum));
				lavaColor = mix(lavaColor, vec3(1.0, 0.78, 0.30), smoothstep(0.8, 1.0, lavaLum));
				color.rgb = mix(color.rgb, lavaColor, inSoulSandValley * (SOUL_LAVA_AMOUNT * 0.01));
			}
		#endif
	}
	color *= tint;
	vec2 lm = lmcoord;
	//NoName: magma look removed, the user prefers the vanilla texture
	//if (isMagma > 0.5) color.rgb = magmaLook(color.rgb, frameTimeCounter, dot(floor(magmaPos), vec3(1.7, 2.9, 2.3)), magmaPos, lm.x);

/* DRAWBUFFERS:04 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lm, 1.0, 1.0); //gaux1
}