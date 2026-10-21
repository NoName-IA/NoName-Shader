#version 120

//#define CROSS_PROCESS //Opposite of desaturation, makes everything more vibrant and saturated.
#define DYNAMIC_LIGHT_FLICKER 8 //How much certain dynamic lights (like torches) will flicker [0 1 2 3 4 5 6 8 12 16 24 32 48 64]
#define DYNAMIC_LIGHTS //Holding blocks that emit light will light up their surroundings
#define HEAT_REFRACTION 1.00 //How much the screen jiggles around in the nether, or when in lava [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]
#define STORM_WAVES 100 //NoName: in thunderstorms the sea gets big waves that rise out of the block and boats ride them. 0 = off [0 25 50 75 100 150 200]
#define WATER_WAVE_STRENGTH 50 //Makes overworld oceans move up and down [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]

#define HARDCORE_DARKNESS 0 //0 (Off): Normal visibility at night. 1 (On): Complete darkness at night. 2 (Moon phase) Nighttime brightness is determined by the current phase of the moon. [0 1 2]
#define SEA_LEVEL 63 //Sea level for infinite oceans. Change this if you use custom worldgen. [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256]
#define SHADE_STRENGTH 0.35 //How dark surfaces that are facing away from the sun are [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50]

attribute vec3 mc_Entity;

uniform float adjustedTime;
uniform float day;
uniform float frameTimeCounter;
uniform float animTime; //NoName: tick-based clock, see shaders.properties
#define frameTimeCounter animTime //NoName: every animation follows /tick freeze and /tick rate
uniform float night;
uniform float phase;
uniform float rainStrength;
uniform float realTime; //NoName: water uses real time, not ticks
uniform float thunderStrength;
uniform float sunset;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D noisetex;
uniform vec3 actualCameraPosition;
uniform vec3 cameraPosition; //NoName: storm waves, your boat
uniform vec3 relativeVehiclePosition; //NoName: camera MINUS the boat you ride (Iris; checked with a debug screenshot, it is not boat - camera)
uniform bool isRiding;
uniform vec3 vehicleLookVector; //NoName: which way your boat points (Iris)
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 sunPosNorm;

varying float mcentity; //ID data of block currently being rendered.
varying vec2 lmcoord;
varying vec2 texcoord;
varying vec3 normal;
varying vec3 shadowColor; //Color of shadows. Sky-colored, to simulate indirect lighting.
varying vec3 skyLightColor; //Color of sky light. Is usually white during the day, and very dark blue at night.
varying vec3 vPosPlayer;
varying vec3 vPosView;
varying vec4 tint;
varying float stormCrest; //NoName: storm wave height at this point (-1..1), for foam. -2 = not storm sea
varying vec2 portalUV; //NoName: position on the nether portal plane, in blocks
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

#if WATER_WAVE_STRENGTH != 0
//NoName: how rough the water is: original when clear, choppier in rain, wild in a thunderstorm
float waterRoughness() { return 1.0 + rainStrength * 0.5 + thunderStrength * 0.5; } //clear = original waves
	float waterWave(vec2 pos) {
		pos *= invNoiseRes;
		float offset = 0.875;
		float waves = cos(texture2D(noisetex, pos / 20.0).r * 25.0 + realTime * 2.0) * 0.5;
		waves      += cos(texture2D(noisetex, pos / 15.0).r * 12.5 + realTime * 3.0) * 0.375;
		offset = clamp(offset + waves * waterRoughness(), 0.0, 1.75); //NoName: weather-driven, kept within the block
		return offset * (float(WATER_WAVE_STRENGTH) / 100.0 / 1.75);
	}
#endif

//NoName: storm swell, also copied in gbuffers_entities.vsh (boats ride the waves). keep both the same! three wave trains moving with the wind,
//long and short, so it never looks like a regular pattern. returns height in -1..1 and its slope.
float stormSwell(vec2 p, float t, out vec2 slope) {
	p = mod(p, 4096.0);
	const vec2 d1 = vec2(0.9439, 0.3304); const float k1 = 0.4488; //wavelength 14
	const vec2 d2 = vec2(0.8, -0.6);      const float k2 = 0.6981; //9
	const vec2 d3 = vec2(0.1961, 0.9806); const float k3 = 1.0472; //6
	float s1 = dot(p, d1) * k1 - t * 1.5;
	float s2 = dot(p, d2) * k2 - t * 1.9;
	float s3 = dot(p, d3) * k3 - t * 2.4;
	slope = d1 * (0.55 * k1 * cos(s1)) + d2 * (0.3 * k2 * cos(s2)) + d3 * (0.15 * k3 * cos(s3));
	return 0.55 * sin(s1) + 0.3 * sin(s2) + 0.15 * sin(s3);
}
//NoName: how high the storm sea lifts something at this spot and moment (same formula as the water surface)
float stormLift(vec2 xz, float t) {
	float amp = thunderStrength * (STORM_WAVES * 0.01);
	amp *= 0.7 + 0.6 * texture2D(noisetex, mod(xz, 4096.0) * (invNoiseRes / 48.0)).r;
	vec2 slope;
	float h = stormSwell(xz, t, slope);
	return amp * (h * 0.7 - abs(h) * 0.2); //NoName: crests rise less than troughs sink and there is no extra lift, so the sea spills much less onto the land
}

//NoName: pose of the boat you ride, glued to the sea surface. the wave is measured right now at 5 points of the hull
//(center, bow, stern, both sides): height = the water height at the center (so it never floats above the water
//when a wave passes), pitch = bow vs stern, roll = side vs side, so the hull lies along the surface.
//same in gbuffers_water.vsh, gbuffers_entities.vsh and gbuffers_basic.vsh, keep them the same!
void boatPose(vec2 c, vec2 f, out float lift, out float pitch, out float roll) {
	vec2 s = vec2(-f.y, f.x);
	float bow   = stormLift(c + f * 0.7, realTime);
	float stern = stormLift(c - f * 0.7, realTime);
	float port  = stormLift(c + s * 0.5, realTime);
	float star  = stormLift(c - s * 0.5, realTime);
	lift  = stormLift(c, realTime);
	pitch = clamp(atan(bow - stern, 1.4), -0.4, 0.4);
	roll  = clamp(atan(port - star, 1.0), -0.4, 0.4);
}

void main() {
	vPosView   = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vPosPlayer = mat3(gbufferModelViewInverse) * vPosView;
	texcoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	tint       =  gl_Color;
	mcentity   = 0.1;
	portalUV   = vec2(0.0);
	stormCrest = -2.0;
	vec3 stormNormal = vec3(0.0);
	vec3 worldPos = vPosPlayer + actualCameraPosition;

	//Using IDs above 10000 to represent all blocks that I care about
	//if the ID is less than 10000, then I don't need to do extra logic to see if it has special effects.
	if (mc_Entity.x > 10000.0) {
		int id = int(mc_Entity.x) - 10000;
		if (id == 9) { //water
			mcentity = 1.1;
			#if WATER_WAVE_STRENGTH != 0
				if (worldPos.y <= SEA_LEVEL + 0.01 && worldPos.y >= SEA_LEVEL - 0.99) {
					worldPos.y -= waterWave(worldPos.xz + 0.5) * fract(worldPos.y - 0.01); // + 0.5 to avoid sharp edges in lava displacement when the coords are on the edge of a noisetex pixel
				}
			#endif
			#if STORM_WAVES > 0
				//NoName: storm sea. the surface (and the top edge of side faces) rises and sinks up to ~1.3 blocks, out of the block,
				//the vertices slide a bit towards the crests so they get sharper, and the normal follows the slope for reflections.
				if (thunderStrength > 0.01 && worldPos.y <= SEA_LEVEL + 0.01 && worldPos.y >= SEA_LEVEL - 0.5) {
					float amp = thunderStrength * (STORM_WAVES * 0.01);
					amp *= 0.7 + 0.6 * texture2D(noisetex, mod(worldPos.xz, 4096.0) * (invNoiseRes / 48.0)).r; //bigger and smaller sets of waves
					vec2 slope;
					float h = stormSwell(worldPos.xz, realTime, slope);
					float lift = amp * (h * 0.7 - abs(h) * 0.2); //NoName: crests rise less than troughs sink and there is no extra lift, so the sea spills much less onto the land
					//NoName: around the boat you ride the water follows the hull: the same height and tilt as the boat
					//(see boatPose), blending back into the waves 1.5-3 blocks away. no gap under the hull.
					float boatPatch = 0.0;
					if (isRiding) {
						vec2 boatXZ = cameraPosition.xz - relativeVehiclePosition.xz;
						boatPatch = 1.0 - smoothstep(1.5, 3.0, length(worldPos.xz - boatXZ));
						if (boatPatch > 0.0) {
							vec2 f = normalize(vehicleLookVector.xz + vec2(0.0001, 0.0));
							vec2 s = vec2(-f.y, f.x);
							float boatLift, pitch, roll;
							boatPose(boatXZ, f, boatLift, pitch, roll);
							vec2 rel = worldPos.xz - boatXZ;
							float hullLine = boatLift + dot(rel, f) * tan(pitch) + dot(rel, s) * tan(roll);
							lift = mix(lift, hullLine, boatPatch);
						}
					}
					worldPos.y += lift;
					//NoName: no sideways crest shift any more: it opened cracks along the water's edges
					stormCrest = h * min(amp * 1.5, 1.0);
					if (gl_Normal.y > 0.5) stormNormal = normalize(vec3(-slope.x * amp * 0.9 * (1.0 - boatPatch), 1.0, -slope.y * amp * 0.9 * (1.0 - boatPatch)));
				}
			#endif
		}
		else if (id == 50) { //NoName: nether portal
			mcentity = 6.1;
			portalUV = abs(gl_Normal.x) > 0.5 ? worldPos.zy : worldPos.xy;
		}
		else if (id == 10) mcentity = 2.1; //stained glass
		else if (id == 11) mcentity = 3.1; //ice
	}

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

	normal = gl_NormalMatrix * gl_Normal;
	float glmult = 0.0;
	if (night < 0.999) glmult += dot( sunPosNorm, normal) * (1.0 - night);
	if (night > 0.001) glmult += dot(-sunPosNorm, normal) * night;
	//glmult = glmult * 0.375 + 0.625; //0.25 - 1.0
	glmult = glmult * SHADE_STRENGTH + (1.0 - SHADE_STRENGTH);
	glmult = mix(glmult, 1.0, rainStrength * 0.5); //less shading during rain
	glmult = mix(1.0, glmult, lmcoord.y * 0.66666666 + 0.33333333); //0.5 - 1.0 in darkness
	glmult = mix(glmult, 1.0, lmcoord.x * lmcoord.x); //increase brightness when block light is high
	tint.rgb *= glmult;
	normal = (stormNormal.y > 0.0 ? stormNormal : gl_Normal) * 0.5 + 0.5; //NoName: storm waves tilt the surface

	vPosPlayer = worldPos - actualCameraPosition;
	vPosView = mat3(gbufferModelView) * vPosPlayer;
	gl_Position = gl_ProjectionMatrix * vec4(vPosView, 1.0);
}