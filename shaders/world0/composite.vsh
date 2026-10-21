#version 120

//#define CROSS_PROCESS //Opposite of desaturation, makes everything more vibrant and saturated.
#define DYNAMIC_LIGHT_FLICKER 8 //How much certain dynamic lights (like torches) will flicker [0 1 2 3 4 5 6 8 12 16 24 32 48 64]
#define DYNAMIC_LIGHTS //Holding blocks that emit light will light up their surroundings
#define HEAT_REFRACTION 1.00 //How much the screen jiggles around in the nether, or when in lava [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]

#define HARDCORE_DARKNESS 0 //0 (Off): Normal visibility at night. 1 (On): Complete darkness at night. 2 (Moon phase) Nighttime brightness is determined by the current phase of the moon. [0 1 2]

uniform float adjustedTime;
uniform float day;
uniform float frameTimeCounter;
uniform float animTime; //NoName: tick-based clock, see shaders.properties
#define frameTimeCounter animTime //NoName: every animation follows /tick freeze and /tick rate
uniform float phase;
uniform float rainStrength;
uniform float sunset;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;
uniform sampler2D noisetex;
uniform vec3 fogColor;
uniform vec3 skyColor;

varying vec2 texcoord;
varying vec3 shadowColor; //Color of shadows. Sky-colored, to simulate indirect lighting.
varying vec3 skyLightColor; //Color of sky light. Is usually white during the day, and very dark blue at night.
#ifdef DYNAMIC_LIGHTS
	varying vec4 heldLightColor; //Color of held light source. Alpha = brightness.
#endif

const int noiseTextureResolution = 256;
const float invNoiseRes = 1.0 / float(noiseTextureResolution);

const float lavaOverlayResolution                     = 24.0;

#ifdef CROSS_PROCESS
#else
#endif

const vec3 sunsetColorForSky = vec3(7.2, 6.7, 6.2); //Subtract 6.0 from this to get the color of the horizon at sunset.
//Roughly corresponds to the color a bit above the horizon at sunset,
//or the horizon itself a bit before sunset.
//usages include:
//	color of skylight at sunset
//	color of light applied to my fancy clouds
const vec3 sunsetColorForOtherThings = sunsetColorForSky + vec3(0.2, 0.2, 0.2);

const vec3 skylightColorDuringTheDay = vec3(1.0,  1.0, 1.0);
const vec3 skylightColorAtNight      = vec3(0.05, 0.1, 0.15); //If hardcore darkness is enabled, this will be 0 instead.

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

#ifdef DYNAMIC_LIGHTS
	float flicker() {
		/*
		#ifdef DYNAMIC_LIGHT_FLICKER
		#endif
		*/
		#if DYNAMIC_LIGHT_FLICKER != 0
			float n = texture2D(noisetex, frameTimeCounter * vec2(16.7825, 15.4192) * invNoiseRes).r - 0.5;
			return n * n * n * DYNAMIC_LIGHT_FLICKER;
		#else
			return 0.0;
		#endif
	}

	vec4 calcHeldLightColor() { //rgb = color, a = brightness
		int mainLight = heldBlockLightValue > 0 ? heldBlockLightValue : itemLightLevel(heldItemId); //NoName
		int offLight = heldBlockLightValue2 > 0 ? heldBlockLightValue2 : itemLightLevel(heldItemId2);
		if (mainLight == 0) { //NoName: check the off hand too
			if (offLight == 0) return vec4(0.0); //not holding a light source
			return vec4(0.8, 0.65, 0.5, float(offLight) + flicker());
		}
		else if (heldItemId == 50   ) return vec4(1.0,  0.6,  0.3, float(mainLight) + flicker()); //regular torches/lanterns/campfires
		else if (heldItemId == 89   ) return vec4(1.0,  0.6,  0.1, float(mainLight)            ); //glowstone
		else if (heldItemId == 10005) return vec4(1.0,  0.45, 0.1, float(mainLight) + flicker()); //NoName: lava bucket
		else if (heldItemId == 10006) return vec4(1.0,  0.55, 0.15, float(mainLight) + flicker()); //NoName: blaze rod
		else if (heldItemId == 10007) return vec4(1.0,  0.5,  0.1, float(mainLight) + flicker()); //NoName: blaze powder
		else if (heldItemId == 10008) return vec4(1.0,  0.8,  0.3, float(mainLight)            ); //NoName: glow berries
		else if (heldItemId == 10009) return vec4(0.9,  0.9,  1.0, float(mainLight)            ); //NoName: nether star
		else if (heldItemId == 10010) return vec4(1.0,  0.65, 0.35, float(mainLight) + flicker()); //NoName: candles
		else if (heldItemId == 10011) return vec4(1.0,  0.6,  0.3, float(mainLight) + flicker()); //NoName: furnaces
		else if (heldItemId == 10012) return vec4(1.0,  0.7,  0.4, float(mainLight)            ); //NoName: redstone lamp
		else if (heldItemId == 10013) return vec4(0.6,  0.3,  1.0, float(mainLight)            ); //NoName: respawn anchor
		else if (heldItemId == 169  ) return vec4(0.6,  0.8,  0.6, float(mainLight)            ); //sea lanterns
		else if (heldItemId == 198  ) return vec4(0.75, 0.55, 0.8, float(mainLight)            ); //end rods
		else if (heldItemId == 76   ) return vec4(1.0,  0.3,  0.1, float(mainLight) + flicker()); //redstone torches
		else if (heldItemId == 91   ) return vec4(1.0,  0.5,  0.1, float(mainLight) + flicker()); //jack-o-lanterns
		else if (heldItemId == 138  ) return vec4(0.4,  0.6,  0.8, float(mainLight)            ); //beacons
		#if MC_VERSION >= 11600
		else if (heldItemId == 10001) return vec4(0.3,  0.6,  1.0, float(mainLight) + flicker()); //soul torches/lanterns/campfires.
		else if (heldItemId == 10002) return vec4(1.0,  0.5,  0.1, float(mainLight)            ); //shroomlight
		else if (heldItemId == 10004) return vec4(0.625 + sin(frameTimeCounter) * 0.125, 0.25, 1.0, float(mainLight)); //crying obsidian
		#endif
		#if MC_VERSION >= 11300
		else if (heldItemId == 10003) return vec4(0.9,  1.0,  0.5, float(mainLight)            ); //sea pickles
		#endif
		else                          return vec4(0.8,  0.65, 0.5, float(mainLight)            ); //everything else
	}
#endif

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	#ifdef DYNAMIC_LIGHTS
		heldLightColor = calcHeldLightColor();
	#endif

	skyLightColor = skylightColorDuringTheDay * day;
	shadowColor = mix(skyColor, fogColor, rainStrength);

	if (sunset > 0.01) {
		vec3 sunsetColor = clamp(sunsetColorForOtherThings - adjustedTime, 0.0, 1.0); //color of sunset gradient at the horizon, and mix level
		if (rainStrength > 0.001) sunsetColor = mix(sunsetColor, fogColor * (1.0 - rainStrength * 0.5), rainStrength * 0.625); //reduce redness intensity when raining
		sunsetColor   *= sunset;
		skyLightColor += sunsetColor;
		shadowColor   += sunsetColor;
	}

	#if HARDCORE_DARKNESS == 0
		skyLightColor += skylightColorAtNight * (1.0 - day);
	#elif HARDCORE_DARKNESS == 1
		//skyLightColor += vec3(0.0);
	#elif HARDCORE_DARKNESS == 2
		skyLightColor += skylightColorAtNight * ((1.0 - day) * phase);
	#else
		#error HARDCORE_DARKNESS should be set to 0, 1, or 2.
	#endif
}