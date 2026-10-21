#version 120

//#define GRASS_AO //Adds ambient occlusion to tallgrass/flowers/etc... Works best with "Remove Y Offset" enabled.
//#define LAVA_PATCHES //Randomizes lava brightness, similar to grass patches

#define PUDDLES //NoName: puddles form on the ground when it rains, reflecting the sky, sun and moon, with raindrop ripples
#define SNOW_COVER 100 //NoName: snow piles up on the top of blocks and leaves while it snows, and melts when it stops. 0 = off [0 25 50 75 100]
#define QUARTZ_SHINE 100 //NoName: polished quartz reflects the sky softly and shows a small highlight of the sun, the moon and torches. 0 = off [0 25 50 75 100 150 200]
#define ORE_SHINE 100 //NoName: shiny reflections on ores and mineral blocks. 0 = off [0 25 50 75 100 150 200]

#define WET_DIRT //Hydrated hummus. Soggy soil. Drenched dirt. I can't think of a good name for this config option, but it makes dirt darker during rain to simulate being wet.

uniform float day;
uniform float night;
uniform float phase; //NoName: 1 = full moon, 0 = new moon
uniform float frameTimeCounter;
uniform float animTime; //NoName: tick-based clock, see shaders.properties
#define frameTimeCounter animTime //NoName: every animation follows /tick freeze and /tick rate
uniform vec3 sunPosNorm;
uniform vec3 upPosNorm;
uniform float rainStrength;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse; //NoName: normal for shadows
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float wetness;
uniform float snowCover; //NoName: see shaders.properties
uniform float snowing;
uniform sampler2D noisetex;
uniform sampler2D texture;

varying float ao;
varying float isDirt;
varying float isLava;
varying vec2 lmcoord;
varying vec2 randCoord;
varying vec2 texcoord;
varying vec4 tint;
varying float isMagma;
varying vec3 magmaPos;
varying float isOre;
varying float oreMaterial;
varying vec3 vNormalView;
varying vec3 vViewPos;
varying vec3 vWorldPos;
varying float puddleSurface;
varying float isFoliage; //NoName: grass, plants, leaves, vines

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

#ifdef WET_DIRT
	bool testDirt(vec3 color) {
		float hueIsh = (color.g - color.b) / (color.r - color.b);
		float saturationIsh = color.b / color.r;
		return hueIsh < saturationIsh || saturationIsh >= 0.99;
	}
#endif

#if ORE_SHINE > 0
	//NoName: how each mineral reflects light, based on the real material.
	//metals (gold, iron, copper, netherite) reflect in their own color; gems and stones reflect white.
	//sharpness = how polished it is (bigger = smaller, crisper highlight). strength = how much light it reflects.
	void getOreMaterial(int m, out vec3 reflectColor, out float sharpness, out float strength) {
		if      (m == 0) { reflectColor = vec3(1.0);               sharpness = 96.0; strength = 1.0;  } //diamond: very polished, strong white sparkle
		else if (m == 1) { reflectColor = vec3(1.0);               sharpness = 64.0; strength = 0.6;  } //emerald: glassy
		else if (m == 2) { reflectColor = vec3(1.0, 0.78, 0.34);   sharpness = 48.0; strength = 1.0;  } //gold: bright golden metal
		else if (m == 3) { reflectColor = vec3(0.56, 0.57, 0.58);  sharpness = 24.0; strength = 0.75; } //iron: grey metal, a bit rough
		else if (m == 4) { reflectColor = vec3(0.95, 0.64, 0.54);  sharpness = 32.0; strength = 0.8;  } //copper: orange metal
		else if (m == 5) { reflectColor = vec3(1.0);               sharpness = 6.0;  strength = 0.15; } //lapis: rough stone, barely shines
		else if (m == 6) { reflectColor = vec3(1.0);               sharpness = 8.0;  strength = 0.2;  } //redstone: dusty, matte
		else if (m == 7) { reflectColor = vec3(0.45, 0.42, 0.42);  sharpness = 20.0; strength = 0.55; } //netherite: dark metal
		else             { reflectColor = vec3(0.95, 0.9, 1.0);    sharpness = 48.0; strength = 0.5;  } //amethyst: crystal
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

	#ifdef LAVA_PATCHES
		if (isLava > 0.9 && color.r > 0.625) { //ignore non-lava part of magma blocks
			color.rgb += cos(
				noiseMap(randCoord) * 12.5
				+ frameTimeCounter * 0.5
			)
			* 0.125;
		}
	#endif

	#ifdef WET_DIRT
		if (wetness > 0.001 && isDirt > 0.5 && testDirt(color.rgb)) {
			float amt = min(wetness * lmcoord.y * lmcoord.y * 1.5, 1.0);
			float average = color.r + color.g + color.g;
			color.rgb = mix(color.rgb, color.rgb * 0.875 - average * 0.125, amt);
			//color.rgb = vec3(1.0, 0.0, 0.0);
		}
	#endif

	color *= tint;

	#ifdef WET_DIRT
		//NoName: wet ground = a thin film of clear water, like sea water: the ground stays visible underneath
		//(just a touch darker and blue-green), and on top it reflects the sky, the sun/moon and nearby lights.
		//the reflections follow the light around: bright under the sky by day, dim at night, warm near torches.
		float wet = wetness * lmcoord.y * lmcoord.y * (1.0 - snowing); //NoName: snow doesn't make the ground look wet
		if (wet > 0.001) {
			vec3 wetNormal = normalize(vNormalView);
			vec3 wetView = normalize(vViewPos);
			vec3 wetReflect = reflect(wetView, wetNormal);
			float upFacing = clamp(dot(wetNormal, upPosNorm), 0.0, 1.0);
			float film = wet * (0.35 + 0.65 * upFacing); //water settles on top faces, walls just get damp

			color.rgb *= mix(vec3(1.0), vec3(0.82, 0.92, 0.96), film); //seen through the water

			float wetFresnel = mix(0.06, 1.0, pow(1.0 - max(dot(-wetView, wetNormal), 0.0), 5.0));
			vec3 skyReflection = mix(fogColor, skyColor * 1.2, sqrt(clamp(dot(wetReflect, upPosNorm), 0.0, 1.0)));
			float shine = 1.0 - isFoliage * 0.9; //NoName: wet grass/leaves barely reflect (the sun glinting on grass was annoying)
			color.rgb = mix(color.rgb, skyReflection, wetFresnel * film * 0.85 * shine);

			vec3 wetGlints = vec3(1.0, 0.9, 0.75) * pow(max(dot(wetReflect, sunPosNorm), 0.0), 120.0) * day * 2.5;
			wetGlints += vec3(0.75, 0.85, 1.0) * pow(max(dot(wetReflect, -sunPosNorm), 0.0), 120.0) * night * phase * 1.5;
			float torchSheen = lmcoord.x * lmcoord.x * lmcoord.x * (0.25 + wetFresnel * 0.75);
			float handHighlight = pow(max(dot(wetReflect, -wetView), 0.0), 32.0) * lmcoord.x * lmcoord.x;
			wetGlints += vec3(1.0, 0.75, 0.45) * (torchSheen * 0.4 + handHighlight * 0.6);
			color.rgb = min(color.rgb + wetGlints * film * shine, 1.0);
		}
	#endif

	#ifdef PUDDLES
		//NoName: puddles. only on flat tops of solid blocks under the open sky, and only while it rains
		//(they come and go with the rain, no slow drying). crystal clear like river/sea water:
		//you see the ground through them from above, and they reflect the sky at shallow angles.
		if (puddleSurface > 0.5 && puddleSurface < 1.5 && rainStrength > 0.01 && snowing < 0.99) { //NoName: no puddles while it snows
			vec3 n = normalize(vNormalView);
			float openSky = smoothstep(0.85, 0.97, lmcoord.y);
			if (dot(n, upPosNorm) > 0.95 && openSky > 0.0) {
				vec2 p = vWorldPos.xz;
				float shape = texture2D(noisetex, p * (0.0625 * invNoiseRes)).r * 0.65 + texture2D(noisetex, p * (0.1875 * invNoiseRes)).r * 0.35;
				float puddle = smoothstep(0.43, 0.47, shape) * rainStrength * openSky * (1.0 - snowing); //a bit more puddle area than before
				if (puddle > 0.001) {
					//raindrop ripples: two overlapping layers of drops landing at random spots and moments.
					//each drop sends out a small train of rings that spreads and fades; heavier rain = more drops.
					if (rainStrength > 0.01) {
						vec2 ripple = vec2(0.0);
						for (int layer = 0; layer < 2; layer++) {
							vec2 q = p * (layer == 0 ? 2.0 : 3.3) + float(layer) * 17.3;
							vec2 cell = floor(q);
							float random = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
							vec2 toDrop = fract(q) - 0.5 - (vec2(fract(random * 7.0), fract(random * 13.0)) - 0.5) * 0.6;
							float age = fract(frameTimeCounter * (0.7 + random * 0.6) + random);
							float front = length(toDrop) - age * 0.5;
							float wave = sin(front * 70.0) * exp(-front * front * 150.0) * (1.0 - age) * (1.0 - age);
							wave *= step(random, rainStrength * 0.8 + 0.2); //fewer drops in light rain
							ripple += normalize(toDrop + 0.0001) * wave;
						}
						n = normalize(n + mat3(gbufferModelView) * vec3(ripple.x, 0.0, ripple.y) * (0.6 * rainStrength));
					}
					vec3 viewDir = normalize(vViewPos);
					vec3 refl = reflect(viewDir, n);
					float fresnel = mix(0.12, 1.0, pow(1.0 - max(dot(-viewDir, n), 0.0), 4.0));
					vec3 skyReflection = mix(fogColor, skyColor * 1.2, sqrt(clamp(dot(refl, upPosNorm), 0.0, 1.0)));
					vec3 glints = vec3(1.0, 0.9, 0.75) * pow(max(dot(refl, sunPosNorm), 0.0), 200.0) * day * (1.0 - rainStrength) * 4.0 * (1.0 - isFoliage * 0.9); //NoName: puddles on grass: no sun sparkle
					glints += vec3(0.75, 0.85, 1.0) * pow(max(dot(refl, -sunPosNorm), 0.0), 200.0) * night * phase * 2.0;
					vec3 underwater = color.rgb * vec3(0.8, 0.92, 0.95); //ground seen through clear water, slightly blue-green
					vec3 puddleColor = mix(underwater, skyReflection * 1.1, fresnel) + glints;
					//NoName: lights reflect in puddles: warm glow near torches, and your hand light as a bright spot
					puddleColor += vec3(1.0, 0.75, 0.45) * (lmcoord.x * lmcoord.x * lmcoord.x * fresnel * 0.5 + pow(max(dot(refl, -viewDir), 0.0), 48.0) * lmcoord.x * lmcoord.x * 1.2);
					color.rgb = min(mix(color.rgb, puddleColor, puddle), 1.0);
				}
			}
		}
	#endif
	//NoName: snow cover. while it snows, the tops of blocks and leaves under the open sky turn white,
	//first in patches and then completely. the patches follow the 16x16 texture pixels so it still looks like minecraft,
	//and the texture shows through a little so blocks don't become flat white. melts slowly when the snow stops.
	#if SNOW_COVER > 0
		if (puddleSurface > 0.5 && snowCover > 0.01 && isLava < 0.5 && isMagma < 0.5) {
			vec3 n = normalize(vNormalView);
			float up = smoothstep(0.55, 0.9, dot(n, upPosNorm));
			float openSky = smoothstep(0.85, 0.97, lmcoord.y);
			if (up * openSky > 0.0) {
				vec2 px = floor(vWorldPos.xz * 16.0) / 16.0 + 0.5 / 16.0; //snap to texture pixels
				float patches = texture2D(noisetex, px * (0.25 * invNoiseRes)).r * 0.6 + texture2D(noisetex, px * (1.0 * invNoiseRes)).r * 0.4;
				float amount = snowCover * (SNOW_COVER * 0.01);
				float cover = smoothstep(1.0 - amount * 1.3, 1.1 - amount * 1.3, patches) * up * openSky;
				float detail = dot(color.rgb, vec3(0.3, 0.59, 0.11));
				vec3 snow = vec3(0.93, 0.96, 1.0) * (0.82 + detail * 0.25);
				color.rgb = mix(color.rgb, snow, cover * 0.95);
			}
		}
	#endif

	vec2 lm = lmcoord; //NoName: ore effects can raise this so they show up in the dark
	//NoName: magma look removed, the user prefers the vanilla texture (magmaLook() kept below main's helpers in case it comes back)
	//if (isMagma > 0.5) color.rgb = magmaLook(color.rgb, frameTimeCounter, dot(floor(magmaPos), vec3(1.7, 2.9, 2.3)), magmaPos, lm.x);

	//NoName: empty end portal frames glow very faintly and flicker, only on their greenish-teal parts
	if (isOre > 2.5 && isOre < 3.5) {
		float teal = smoothstep(0.0, 0.08, color.g - color.r);
		float seed = dot(floor(vWorldPos), vec3(1.7, 3.1, 2.3)); //each frame block flickers on its own
		float flicker = 0.6 + 0.25 * sin(frameTimeCounter * 2.3 + seed) + 0.15 * sin(frameTimeCounter * 7.1 + seed * 1.9);
		color.rgb = min(color.rgb + vec3(0.02, 0.08, 0.07) * teal * flicker, 1.0);
		lm.x = max(lm.x, 0.12 * teal * flicker);
	}

	//NoName: ore reflections. the surface is gently wavy (smooth, not per pixel), so highlights slide across the gems as you move.
	//lit by the sun (outdoors) and by torches/held light, approximated as coming from the camera.
	#if ORE_SHINE > 0
		if (isOre > 0.5 && isOre < 2.5) {
			bool mineralBlock = isOre > 1.5;
			float maxC = max(color.r, max(color.g, color.b));
			float minC = min(color.r, min(color.g, color.b));
			float gem = mineralBlock ? 1.0 : smoothstep(0.15, 0.3, (maxC - minC) / max(maxC, 0.001)); //ores: only the colorful pixels, not the stone around them
			if (gem > 0.01) {
				vec3 facet = sin(vWorldPos.zxy * 9.0 + vWorldPos * 5.0) * 0.5;
				vec3 n = normalize(normalize(vNormalView) + facet * (mineralBlock ? 0.2 : 0.7));
				vec3 viewDir = normalize(vViewPos);
				vec3 refl = reflect(viewDir, n);
				vec3 reflectColor;
				float sharpness, strength;
				getOreMaterial(int(oreMaterial + 0.5), reflectColor, sharpness, strength);
				float energy = (sharpness + 8.0) / 24.0; //sharper highlights are smaller but brighter, like in real life
				float spec = pow(max(dot(refl, -viewDir), 0.0), sharpness * 0.5) * lmcoord.x * lmcoord.x; //torch light
				spec += pow(max(dot(refl, sunPosNorm), 0.0), sharpness) * lmcoord.y * lmcoord.y * day * 2.0; //sun
				spec *= energy * strength * gem * (ORE_SHINE * 0.01);
				//NoName: moonlight. the moon is opposite the sun; cold bluish light, brighter with a fuller moon.
				float moonSpec = pow(max(dot(refl, -sunPosNorm), 0.0), sharpness) * lmcoord.y * lmcoord.y * night * (phase * 0.8 + 0.2);
				moonSpec *= energy * strength * gem * (ORE_SHINE * 0.01);
				color.rgb = min(color.rgb + reflectColor * (color.rgb * 0.8 + 0.4) * spec + reflectColor * vec3(0.75, 0.85, 1.0) * (color.rgb * 0.5 + 0.3) * moonSpec, 1.0);

				int material = int(oreMaterial + 0.5);
				//NoName: redstone slowly pulses with a red glow, like energy.
				if (material == 6) { //very subtle: barely noticeable, but there
					float pulse = (sin(frameTimeCounter * 1.5) * 0.5 + 0.5) * gem * (ORE_SHINE * 0.01);
					color.rgb = min(color.rgb + vec3(0.08, 0.005, 0.0) * pulse, 1.0);
					lm.x = max(lm.x, pulse * 0.15);
				}
			}
		}
	#endif

	//NoName: polished quartz, like marble. it reflects the sky softly (more at grazing angles, fresnel), only where
	//the sky reaches, and shows a small crisp highlight of the sun (the moon at night) plus a warm sheen near torches.
	#if QUARTZ_SHINE > 0
		if (isOre > 3.5) {
			vec3 qn = normalize(vNormalView);
			vec3 qv = normalize(vViewPos);
			vec3 qr = reflect(qv, qn);
			float qFresnel = mix(0.04, 1.0, pow(1.0 - max(dot(-qv, qn), 0.0), 5.0));
			float qSky = lmcoord.y * lmcoord.y;
			vec3 qSkyColor = mix(fogColor, skyColor * 1.2, sqrt(clamp(dot(qr, upPosNorm), 0.0, 1.0)));
			color.rgb = mix(color.rgb, qSkyColor, qFresnel * qSky * 0.35 * (QUARTZ_SHINE * 0.01));
			float qSpec = pow(max(dot(qr, sunPosNorm), 0.0), 90.0) * day * (1.0 - rainStrength) * qSky * 1.2;
			qSpec += pow(max(dot(qr, -sunPosNorm), 0.0), 90.0) * night * (phase * 0.7 + 0.3) * qSky * 0.5;
			qSpec += pow(max(dot(qr, -qv), 0.0), 24.0) * lmcoord.x * lmcoord.x * 0.35; //torches and your hand light, seen from the camera
			color.rgb = min(color.rgb + vec3(1.0, 0.96, 0.9) * qSpec * (QUARTZ_SHINE * 0.01), 1.0);
		}
	#endif

/* DRAWBUFFERS:042 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lm, 1.0, color.a); //gaux1
	gl_FragData[2] = vec4(normalize(mat3(gbufferModelViewInverse) * vNormalView) * 0.5 + 0.5, 1.0); //gnormal. NoName: so shadows can be offset along the surface
}