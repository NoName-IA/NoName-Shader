#version 120

#define BRIGHT_WATER //Overrides light levels under water to be higher
//#define CROSS_PROCESS //Opposite of desaturation, makes everything more vibrant and saturated.
#define DYNAMIC_LIGHT_VIGNETTE 50 //Reduces the brightness of dynamic light around edges the of your screen [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define DYNAMIC_LIGHTS //Holding blocks that emit light will light up their surroundings
#define HEAT_REFRACTION 1.00 //How much the screen jiggles around in the nether, or when in lava [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]
#define UNDERWATER_FOG //Applies fog to water
//#define VANILLA_LIGHTMAP //Uses vanilla light colors instead of custom ones. Requires optifine 1.12.2 HD_U_D1 or later!

#define DESATURATE_NIGHT 0.50 //Amount to desaturate the world at night [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define DESATURATE_RAIN 0.50 //Amount to desaturate the world when raining [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define FOG_DENSITY_MULTIPLIER_OVERWORLD 1.00 //How much overall fog there is in the overworld. [0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00 1.20 1.40 1.60 1.80 2.00 2.50 3.00 3.50 4.00 4.50 5.00 6.00 7.00 8.00 9.00 10.00]
#define FOG_ENABLED_OVERWORLD //Enables fog in the overworld. It is recommended to have this enabled if you also have infinite oceans enabled!
#define FOG_HEIGHT_MULTIPLIER_OVERWORLD 32.0 //Controls how much denser fog is at lower altitudes [16.0 24.0 32.0 48.0 64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0]
#define INFINITE_OCEANS //Simulates water out to the horizon instead of just your render distance.
#define OVERWORLD_FOG_SATURATION_BOOST 1.25 //Makes the horizon blue-er [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50]
#define OVERWORLD_HORIZON_HEIGHT 0.2 //How far above the horizon the fog color will be applied [0.001 0.002 0.003 0.004 0.005 0.0075 0.01 0.02 0.03 0.04 0.05 0.075 0.1 0.2 0.3 0.4 0.5 0.75 1.0]
#define SKY_DRAMA 1.0 //NoName: how dramatic sunrise/sunset/dusk colors are. 0 = original [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define OVERWORLD_SKY_SATURATION_BOOST 1.50 //Makes the sky blue-er [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50]
//NoName: rainbows removed completely (the user did not want them); the #ifdef RAINBOWS code below is never compiled
#define SEA_LEVEL 63 //Sea level for infinite oceans. Change this if you use custom worldgen. [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256]

uniform float adjustedTime;
uniform float blindness;
uniform float darknessLightFactor;
uniform float day;
uniform float far;
uniform float fogEnd;
uniform float fov;
uniform float night;
uniform float nightVision;
uniform float pixelSizeX;
uniform float pixelSizeY;
uniform float rainStrength;
uniform float thunderStrength; //NoName: storm sea gaps
uniform float realTime;
uniform sampler2D noisetex;
uniform float screenBrightness;
uniform float sunset;
uniform float wetness;
uniform int isEyeInWater;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform mat4 gbufferModelViewInverse;
//NoName: real shadows (Máximo profile). off = the shadow pass does not even run.
//#define SHADOWS //NoName: blocks, trees, mobs and players cast soft shadows from the sun. Heavy: draws the world a second time
const int shadowMapResolution = 2048; //NoName: shadow sharpness [1024 2048 3072 4096]
const float shadowDistance = 96.0; //NoName: how far shadows reach, in blocks [48.0 64.0 96.0 128.0 160.0]
const bool shadowHardwareFiltering = true;
#ifdef SHADOWS
	uniform sampler2DShadow shadowtex0; //everything that casts shadow
	uniform sampler2DShadow shadowtex1; //only opaque things (no stained glass)
	uniform sampler2D shadowcolor0; //color of what cast the shadow, for stained glass
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;
	uniform vec3 shadowLightPosition;
	const float shadowDistortion = 0.85; //keep the same as shadow.vsh
#endif
uniform mat4 gbufferProjectionInverse;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4; //lightmap
uniform sampler2D colortex8; //NoName: water mask from gbuffers_water
const vec4 colortex8ClearColor = vec4(0.0, 0.0, 0.0, 0.0); //Iris needs all 4 components here
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform vec3 actualCameraPosition;
uniform vec3 cameraPosition; //NoName: for held light distance
#ifdef IS_IRIS
	uniform vec3 eyePosition;
#else
	vec3 eyePosition = actualCameraPosition;
#endif
uniform vec3 fogColor;
uniform vec3 biomeFogTint; //NoName: biome ambience, see shaders.properties
uniform vec3 skyColor;
uniform vec3 sunPosNorm;
uniform vec3 upPosNorm;

varying vec2 texcoord;
varying vec3 shadowColor; //Color of shadows. Sky-colored, to simulate indirect lighting.
varying vec3 skyLightColor; //Color of sky light. Is usually white during the day, and very dark blue at night.
varying vec4 heldLightColor; //Color of held light source. Alpha = brightness.

#define STORM_WAVES 100 //NoName: in thunderstorms the sea gets big waves that rise out of the block and boats ride them. 0 = off [0 25 50 75 100 150 200]

//NoName: storm swell, same as gbuffers_water.vsh (used here to know how high the storm water is). keep them the same! three wave trains moving with the wind,
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

//NoName: height of the storm sea above sea level at this spot (same formula as gbuffers_water.vsh)
float stormLift(vec2 xz) {
	float amp = thunderStrength * (STORM_WAVES * 0.01);
	amp *= 0.7 + 0.6 * texture2D(noisetex, mod(xz, 4096.0) * (1.0 / (256.0 * 48.0))).r;
	vec2 slope;
	float h = stormSwell(xz, realTime, slope);
	return amp * (h * 0.7 - abs(h) * 0.2); //NoName: crests rise less than troughs sink and there is no extra lift, so the sea spills much less onto the land
}

struct Position {
	bool isSky;
	vec3 view;
	vec3 viewNorm;
	vec3 player;
	vec3 world;
	float blockDist; //distance measured in blocks
	float viewDist; //blockDist / far
};

/*
because this has to be defined in the .fsh stage in order for optifine to recognize it:
uniform float centerDepthSmooth;

const float eyeBrightnessHalflife = 20.0;
const float wetnessHalflife = 250.0;
const float drynessHalflife = 60.0;
const float centerDepthHalflife   =  1.0; //Smaller number makes DOF update faster [0.0625 0.09375 0.125 0.1875 0.25 0.375 0.5 0.75 1.0 1.5 2.0 3.0 4.0 6.0 8.0 12.0 16.0]

const int gcolorFormat = RGBA16;
const int compositeFormat = RGBA8; //NoName: was RGBA16, half the memory bandwidth
const int gaux3Format = RGBA8; //NoName: was RGBA16
const int gnormalFormat = RGB16;
*/

const float actualSeaLevel = SEA_LEVEL - 0.1111111111111111; //water source blocks are 8/9'ths of a block tall, so SEA_LEVEL - 1/9.

const vec3 blockLightColorNear   = vec3(1.0,   0.85,  0.7); //color of block lights when the player is near a light source.
const vec3 blockLightColorFar    = vec3(1.0,   0.5,   0.15); //color of block lights when the player is far away from a light source.
const vec3 nightVisionLightColor = vec3(0.375, 0.375, 0.5);

const vec3 blocklightVibrantColorFar  = vec3(1.4, 1.0, 0.8); //Vibrant color for block lights when standing far away from a light source.
const vec3 blocklightVibrantColorNear = vec3(1.2, 1.1, 1.0); //Vibrant color for block lights when standing near a light source.
const float vibrantSaturation         = 0.1; //Higher numbers mean more saturation when vibrant colors are enabled.

const float lavaOverlayResolution                     = 24.0;

#ifdef CROSS_PROCESS
	const vec3 nightSkyColor = vec3(0.02,  0.025, 0.05); //Added to sky color at night to avoid it being completely black
#else
	const vec3 nightSkyColor = vec3(0.025, 0.025, 0.05); //Added to sky color at night to avoid it being completely black
#endif

const vec3 sunsetColorForSky = vec3(7.2, 6.7, 6.2); //Subtract 6.0 from this to get the color of the horizon at sunset.

const float rainbowPosition =   0.25; //1.0 will be on top of the sun, 0.0 will be on top of the moon.
const float rainbowThinness = -24.0; //Positive numbers will make red be on the inside and blue on the outside.

//Absorb colors are a bit odd in that higher numbers mean
//that the color gets *darker* more quickly with distance.
const vec3 waterAbsorbColorWhenSunny   = vec3(0.12,  0.03,   0.06); //NoName: was (0.2, 0.05, 0.1). clearer water
const vec3 waterAbsorbColorWhenRaining = vec3(0.075, 0.0375, 0.15); //NoName: was (0.125, 0.0625, 0.25)

const vec3 waterScatterColorWhenSunny   = vec3(0.05,    0.4, 0.5);
const vec3 waterScatterColorWhenRaining = vec3(0.09375, 0.1, 0.15);

const vec3 skylightVibrantColorDuringTheDay = vec3(1.4, 1.2, 1.1);
const vec3 skylightVibrantColorAtNight      = vec3(1.0, 1.1, 1.4);
const vec3 skylightVibrantColorWhenRaining  = vec3(1.0, 1.0, 1.0); //Overrides both day and night.

float square(float x)        { return x * x; } //potentially faster than pow(x, 2.0).

float interpolateSmooth1(float x) { return x * x * (3.0 - 2.0 * x); }
vec3  interpolateSmooth3(vec3  v) { return v * v * (3.0 - 2.0 * v); }

float fogify(float x, float width) {
	//fast, vaguely bell curve-shaped function with variable width
	return width / (x * x + width);
}

float sunShadow = 1.0; //NoName: 0 = this pixel is in shadow, 1 = in the sun (set in main when SHADOWS is on)
vec3 sunTint = vec3(1.0); //NoName: color of the sunlight here: tinted where it came through stained glass

#ifdef SHADOWS
	//NoName: shadows. the point is moved a little along its surface normal (no acne), put into the squeezed
	//shadow map, and compared at 12 spots on a small disk (hardware filtered, so each one is already a 2x2 blend),
	//rotated per pixel so the edges are clean instead of banded.
	//colored shadows: where only stained glass is between this point and the sun (blocked in shadowtex0 but not in
	//shadowtex1), the light keeps coming through, tinted with the glass color from shadowcolor0 (sunTint).
	float calcSunShadow(vec3 playerPos, vec3 playerNormal, bool hasNormal) {
		vec3 lightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
		sunTint = vec3(1.0);
		if (hasNormal && dot(playerNormal, lightDir) <= 0.02) return 1.0; //faces away from the sun are already darkened by the vertex shading
		float dist = length(playerPos);
		vec3 offsetPos = playerPos + (hasNormal ? playerNormal * (0.04 + dist * 0.004) : lightDir * (0.05 + dist * 0.004));
		vec4 sp = shadowProjection * (shadowModelView * vec4(offsetPos, 1.0));
		float squeeze = length(sp.xy) * shadowDistortion + (1.0 - shadowDistortion);
		sp.xy /= squeeze;
		vec3 coord = sp.xyz * 0.5 + 0.5;
		if (any(lessThan(coord, vec3(0.0))) || any(greaterThan(coord, vec3(1.0)))) return 1.0;
		coord.z -= 0.0002;
		float radius = 0.9 * squeeze / float(shadowMapResolution); //same blur in blocks everywhere. NoName: crisp edges, like the example picture
		float angle = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831853;
		mat2 spin = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
		const vec2 disk[12] = vec2[12](vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457), vec2(-0.203, 0.621),
		                               vec2(0.962, -0.195), vec2(0.473, -0.480), vec2(0.519, 0.767), vec2(0.185, -0.893),
		                               vec2(0.507, 0.064), vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598));
		float lit = 0.0, litOpaque = 0.0;
		for (int i = 0; i < 12; i++) {
			vec3 tap = vec3(coord.xy + spin * disk[i] * radius, coord.z);
			lit += shadow2D(shadowtex0, tap).r;
			litOpaque += shadow2D(shadowtex1, tap).r;
		}
		lit /= 12.0;
		litOpaque /= 12.0;
		float throughGlass = max(litOpaque - lit, 0.0); //blocked only by stained glass
		if (throughGlass > 0.01) {
			//NoName: read the glass at the same 12 spots so its frame stays sharp. the frame of the texture is much more
			//opaque than the middle (alpha): it casts a real dark shadow, so every tinted window shows its outline.
			vec3 glassSum = vec3(0.0);
			float frameSum = 0.0;
			for (int i = 0; i < 12; i++) {
				vec4 glass = texture2D(shadowcolor0, coord.xy + spin * disk[i] * radius);
				glassSum += glass.rgb / max(max(glass.r, max(glass.g, glass.b)), 0.001); //pure hue, full brightness
				frameSum += smoothstep(0.55, 0.75, glass.a);
			}
			vec3 glassColor = mix(vec3(1.0), glassSum / 12.0, 0.85);
			float frame = frameSum / 12.0;
			float glassShare = throughGlass / max(litOpaque, 0.001); //how much of the light here comes through glass
			sunTint = mix(vec3(1.0), glassColor, glassShare);
			lit = litOpaque * (1.0 - glassShare * (0.15 + 0.8 * frame)); //the middle lets most light through, the frame almost none
		}
		float fadeOut = smoothstep(0.8, 1.0, dist / shadowDistance); //blend into no-shadow at the far edge
		sunTint = mix(sunTint, vec3(1.0), fadeOut);
		return mix(lit, 1.0, fadeOut);
	}
#endif

vec3 calcMainLightColor(inout float blocklight, inout float skylight, inout float heldlight, inout Position pos) {
	#ifdef VANILLA_LIGHTMAP
		vec3 lightclr = texture2D(gaux4, vec2(blocklight, skylight)).rgb;
	#endif

	skylight *= skylight * (1.0 - rainStrength * 0.5);
	blocklight = square(max(blocklight - skylight * day * 0.5, 0.0));

	#ifndef VANILLA_LIGHTMAP
		vec3 lightclr = vec3(0.0);
		lightclr += mix(blockLightColorFar, blockLightColorNear, eyeBrightnessSmooth.x / 240.0) * blocklight; //blocklight
		lightclr += mix(shadowColor, skyLightColor * sunTint, skylight * sunShadow) * skylight * mix(0.6, 1.0, sunShadow); //skylight. NoName: in shadow only the sky's blue light is left; sunlight through stained glass takes its color
		lightclr += clamp(nightVision, 0.0, 1.0) * nightVisionLightColor;
		lightclr += clamp(screenBrightness, 0.0, 1.0) * 0.1;
	#endif

	#ifdef DYNAMIC_LIGHTS
		if (heldLightColor.a > 0.0) {
			//NoName: works like a placed torch: light level drops by 1 per block and goes through the same block light curve.
			//like vanilla, lights don't add up, the brightest one wins.
			//NoName: measured relative to the camera, so it doesn't depend on huge world coordinates (you're at z = 444000+).
			vec3 eyeRelative = eyePosition - cameraPosition; //~0 in first person, a few blocks in third person
			if (dot(eyeRelative, eyeRelative) > 64.0) eyeRelative = vec3(0.0); //eyePosition missing or wrong: use the camera
			float heldLevel = max(heldLightColor.a - distance(pos.world - actualCameraPosition, eyeRelative), 0.0) / 15.0;
			heldlight = square(max(heldLevel - skylight * day * 0.5, 0.0));
			vec3 heldTint = mix(vec3(1.0), heldLightColor.rgb / max(heldLightColor.r, max(heldLightColor.g, heldLightColor.b)), 0.5);
			lightclr += mix(blockLightColorFar, blockLightColorNear, eyeBrightnessSmooth.x / 240.0) * heldTint * max(heldlight - blocklight, 0.0);
		}
	#endif

	return max(lightclr - square(darknessLightFactor), vec3(0.0));
}

float calcFogAmount(inout Position pos, in float fogDistance) {
	float fogDensity = exp2(
		(
			//equivalen to: (pos.world.y - SEA_LEVEL) * (-1.0 / FOG_HEIGHT_MULTIPLIER_OVERWORLD)
			pos.world.y
			* (-1.0 / FOG_HEIGHT_MULTIPLIER_OVERWORLD)
			+ (SEA_LEVEL / FOG_HEIGHT_MULTIPLIER_OVERWORLD)
		)
		* (1.0 - rainStrength)
		+ (rainStrength * 2.0)
	)
	* FOG_DENSITY_MULTIPLIER_OVERWORLD;
	return fogify(fogDistance * fogDensity, 1.0);
}

vec3 calcFogColor(vec3 viewPosNorm) {
	float upDot = dot(viewPosNorm, upPosNorm) * 2.0;
	float sunDot = dot(viewPosNorm, sunPosNorm) * 0.5 + 0.5;
	float rainCoefficient = max(rainStrength, wetness);
	vec3 color;
	vec3 skyclr = skyColor;
	skyclr.rg = mix(skyclr.bb, skyclr.rg, OVERWORLD_SKY_SATURATION_BOOST);
	skyclr = mix(skyclr, fogColor * 0.65, rainCoefficient);
	vec3 fogclr = fogColor;
	fogclr.rg = mix(fogclr.bb, fogclr.rg, OVERWORLD_FOG_SATURATION_BOOST);
	fogclr *= (1.0 - rainCoefficient * 0.25) * (1.0 - nightVision * night * 0.75); fogclr *= biomeFogTint; //NoName: greenish swamps, warm desert haze, cold blue taiga/snow

	if (upDot > 0.0) color = skyclr + nightSkyColor * (1.0 - day) * (1.0 - rainStrength); //avoid pitch black sky at night
	else color = fogclr;

	if (sunset > 0.001 && rainCoefficient < 0.999) {
		vec3 sunsetColor = interpolateSmooth3(clamp(sunsetColorForSky - adjustedTime + upDot + sunDot * 0.2 * (1.0 - night), 0.0, 1.0)); //main sunset gradient
		//NoName: dramatic sky: richer sunset colors, a taller glowing horizon band and a pink-purple glow overhead.
		sunsetColor = max(mix(vec3(dot(sunsetColor, vec3(0.299, 0.587, 0.114))), sunsetColor, 1.0 + 0.6 * SKY_DRAMA), 0.0);
		sunsetColor = mix(fogclr, sunsetColor, (sunDot * 0.5 + 0.5) * sunset * (1.0 - rainCoefficient)); //fade in at sunset and out when not looking at the sun
		color = mix(color, sunsetColor, fogify(upDot, OVERWORLD_HORIZON_HEIGHT * (1.0 + SKY_DRAMA * sunset))); //mix with final color based on how close we are to the horizon
		color += vec3(0.22, 0.04, 0.26) * (SKY_DRAMA * sunset * (1.0 - rainCoefficient) * clamp(upDot, 0.0, 1.0) * (sunDot * 0.6 + 0.4)); //NoName: twilight glow overhead
	}
	else if (upDot > 0.0) color = mix(color, fogclr, fogify(upDot, OVERWORLD_HORIZON_HEIGHT));

	#ifdef RAINBOWS
		float rainbowStrength = (wetness - rainStrength) * day * 0.25;
		float rainbowHue = (sunDot - rainbowPosition) * rainbowThinness;
		if (rainbowStrength > 0.01 && rainbowHue > 0.0 && rainbowHue < 1.0) {
			rainbowHue *= 6.0;
			color += clamp(vec3(1.5, 2.0, 1.5) - abs(rainbowHue - vec3(1.5, 3.0, 4.5)), 0.0, 1.0) * rainbowStrength;
			//color.r += clamp(1.5 - abs(rainbowHue - 1.5), 0.0, 1.0) * rainbowStrength;
			//color.g += clamp(2.0 - abs(rainbowHue - 3.0), 0.0, 1.0) * rainbowStrength;
			//color.b += clamp(1.5 - abs(rainbowHue - 4.5), 0.0, 1.0) * rainbowStrength;
		}
	#endif

	return color;
}

vec3 calcUnderwaterFogColor(vec3 color, float blockDist, float brightness) {
	float rainCoefficient = max(rainStrength, wetness);
	vec3 absorb = exp2(-blockDist * mix(waterAbsorbColorWhenSunny, waterAbsorbColorWhenRaining, rainCoefficient));
	vec3 scatter = mix(waterScatterColorWhenSunny, waterScatterColorWhenRaining, rainCoefficient) * (1.0 - absorb) * (brightness * day);
	return color * absorb + scatter;
}

//simpler algorithm for the special case where distance = infinity (for infinite oceans)
vec3 calcUnderwaterFogColorInfinity(float brightness) {
	return mix(waterScatterColorWhenSunny, waterScatterColorWhenRaining, max(rainStrength, wetness)) * (brightness * day);
}

Position posFromDepthtex(sampler2D depthtex) {
	Position pos;
	float depth = texture2D(depthtex, texcoord).r;
	pos.isSky = depth == 1.0;
	vec3 screen = vec3(texcoord, depth);
	vec4 tmp = gbufferProjectionInverse * vec4(screen * 2.0 - 1.0, 1.0);
	pos.view = tmp.xyz / tmp.w;
	pos.player = mat3(gbufferModelViewInverse) * pos.view;
	pos.world = pos.player + actualCameraPosition;
	pos.blockDist = length(pos.view);
	pos.viewDist = pos.blockDist / far;
	pos.viewNorm = pos.view / pos.blockDist;
	return pos;
}

void main() {
	vec2 tc = texcoord;

	Position nearPos = posFromDepthtex(depthtex0);
	Position farPos = posFromDepthtex(depthtex1);

	vec3 color = texture2D(gcolor, tc).rgb;
	vec4 aux = texture2D(gaux1, tc);
	if (farPos.isSky && !nearPos.isSky && aux.b > 0.5) farPos = nearPos; //NoName: translucent entities (the player skin in 26.1) are not in depthtex1, so they were treated as sky

	vec4 aux2 = texture2D(gaux2, tc);
	//NoName: solid entities drawn after water/glass (translucent pass in 26.1) are not in depthtex1 either, so they were lit and
	//fogged as if they were the terrain behind them (faded, ghostly). nothing transparent here (ID 0, no transparency) = use the nearest depth.
	if (!nearPos.isSky && aux.b > 0.5 && int(aux2.b * 10.0 + 0.1) == 0 && texture2D(gaux3, tc).r < 0.01) farPos = nearPos;
	vec4 normal = texture2D(gnormal, tc);
	normal.xyz = normal.xyz * 2.0 - 1.0;
	bool water = int(aux2.b * 10.0 + 0.1) == 1; //only ID I'm actually checking for in this stage.
	water = water || texture2D(colortex8, tc).a > 0.5; //NoName: water behind stained glass
	bool inWater = isEyeInWater == 1; //quicker to type.
	bool stormFill = false; //NoName: storm sea gap filled with water (below)

	//NoName: storm sea gaps. when the waves rise, holes can open where no water is drawn: under the edge of a raised wave,
	//next to blocks (the water has no side faces there) and under boats. there you saw the bare sea floor.
	//a sea floor pixel (below sea level, some sky light) with no water in front of it is filled with water:
	//the surface is put where the storm wave is (same formula as the water), so it gets the normal water look.
	//the shore too, like real surf running up a beach: ground just above sea level that the wave reaches
	//is covered with shallow water, but only if there is sea right next to it on screen (inland sand stays dry).
	#if STORM_WAVES > 0
		if (!water && !inWater && thunderStrength > 0.01 && !farPos.isSky && aux.g > 0.25 && farPos.world.y < actualSeaLevel + 1.6) {
			vec3 dir = farPos.player / farPos.blockDist;
			float waterTop = actualSeaLevel + stormLift(farPos.world.xz);
			bool underWave = farPos.world.y < actualSeaLevel - 0.02;
			if (!underWave && farPos.world.y < waterTop) {
				//shore: look for sea around this pixel (two rings of 4 samples, ~3% and ~7% of the screen). NoName: perf, was 16
				for (int k = 0; k < 8; k++) {
					float a = float(k) * 1.5708 + (k < 4 ? 0.0 : 0.7854);
					vec2 o = vec2(cos(a), sin(a) * pixelSizeY / pixelSizeX) * (k < 4 ? 0.03 : 0.07);
					vec2 sampleUV = clamp(texcoord + o, 0.0, 1.0);
					if (int(texture2D(gaux2, sampleUV).b * 10.0 + 0.1) == 1) { underWave = true; break; }
				}
			}
			if (underWave && actualCameraPosition.y > waterTop && dir.y < -0.001) {
				float seaT = (waterTop - actualCameraPosition.y) / dir.y; //where the view ray enters the water
				if (seaT < farPos.blockDist) {
					water = true;
					stormFill = true;
					nearPos.blockDist = seaT;
					aux2 = vec4(aux.r, max(aux.g, 0.9), 0.1, 1.0); //water ID, sky light of the surface
					normal = vec4(0.0, 1.0, 0.0, 1.0);
				}
			}
		}
	#endif

	float underwaterEyeBrightness = eyeBrightnessSmooth.y / 240.0;
	#ifdef BRIGHT_WATER
		underwaterEyeBrightness = underwaterEyeBrightness * 0.5 + 0.5;
	#endif

	bool emissive = aux.b > 0.6 && aux.b < 0.9; //NoName: beacon / JourneyMap waypoint beams glow on their own: no lighting, no fog
	if (!farPos.isSky && !emissive) {
		float skylight = aux.g;
		float blocklight = aux.r;
		float heldlight = 0.0;

		#ifdef BRIGHT_WATER
			if      ( water && !inWater) skylight = mix(skylight, skylight * 0.5 + 0.5, aux2.g); //max(skylight, aux2.g * 0.5);
			else if (!water &&  inWater) skylight = skylight * 0.5 + 0.5;
		#endif

		#ifdef SHADOWS
			//NoName: sun shadows on opaque things (not the hand). softer in rain, gone when the sun is at the horizon
			if (texture2D(depthtex1, tc).r > 0.56 && skylight > 0.05) {
				vec3 n = normal.xyz;
				bool hasNormal = abs(length(n) - 1.0) < 0.2;
				float sunHeight = abs(dot(normalize(shadowLightPosition), upPosNorm));
				sunShadow = calcSunShadow(farPos.player + gbufferModelViewInverse[3].xyz, normalize(n), hasNormal);
				sunShadow = mix(1.0, sunShadow, smoothstep(0.03, 0.15, sunHeight) * (1.0 - rainStrength * 0.8));
			}
		#endif
		color *= calcMainLightColor(blocklight, skylight, heldlight, farPos);

		vec2 lmcoord = aux.rg;

		#ifdef CROSS_PROCESS
			vec3 skyCrossColor    = mix(mix(skylightVibrantColorDuringTheDay, skylightVibrantColorAtNight, night), skylightVibrantColorWhenRaining, wetness); //cross processing color from the sun
			vec3 blockCrossColor  = mix(blocklightVibrantColorFar, blocklightVibrantColorNear, eyeBrightnessSmooth.x / 240.0); //cross processing color from block lights
			vec3 finalCrossColor  = mix(mix(vec3(1.0), skyCrossColor, lmcoord.y), blockCrossColor, lmcoord.x); //final cross-processing color (blockCrossColor takes priority over skyCrossColor)
			color.rgb = clamp(color.rgb * finalCrossColor - (color.grr + color.bbg) * vibrantSaturation, 0.0, 1.0);
		#endif

		float desaturationAmount = mix(night * DESATURATE_NIGHT, 1.0, rainStrength * DESATURATE_RAIN);
		if (desaturationAmount > 0.001) {
			desaturationAmount *= 1.0 - max(blocklight, heldlight);
			float average = dot(color.rgb, vec3(0.25, 0.5, 0.25));
			color.rgb = mix(color.rgb, vec3(average), desaturationAmount);
		}

		//!water && !inWater = white fog in stage 1
		//!water &&  inWater = blue fog
		// water && !inWater = blue fog in stage 1 then white fog in stage 2
		// water &&  inWater = white fog in stage 1 then blue fog in stage 2

		//if water xor  inwater then blue fog
		//if water ==   inwater then white fog (stage 1)
		//if water and  inwater then blue fog
		//if water and !inwater then white fog (stage 2)

		#ifdef UNDERWATER_FOG
			if      (water && !inWater) color = calcUnderwaterFogColor(color, farPos.blockDist - nearPos.blockDist, aux2.g * aux2.g);
			else if (!water && inWater) color = calcUnderwaterFogColor(color, farPos.blockDist, underwaterEyeBrightness);
		#endif

		#if STORM_WAVES > 0
			if (stormFill) { //NoName: the same murky storm tint the real water surface gets in gbuffers_water.fsh
				float sl = aux2.g, bl = aux.r, hl = 0.0;
				color = mix(color, vec3(0.16, 0.22, 0.23) * calcMainLightColor(bl, sl, hl, farPos), min(thunderStrength * (STORM_WAVES * 0.01), 1.0) * 0.35);
			}
		#endif

		#ifdef FOG_ENABLED_OVERWORLD
			if (water == inWater) {
				float fogDistance = (water ? farPos.blockDist - nearPos.blockDist : farPos.blockDist) / fogEnd;
				float actualEyeBrightness = eyeBrightness.y / 240.0;
				#ifdef BRIGHT_WATER
					if (inWater) actualEyeBrightness = actualEyeBrightness * 0.5 + 0.5;
				#endif
				float fogKeep = calcFogAmount(farPos, fogDistance); //NoName: perf: the fog color is almost a whole sky calculation; skip it where there is no fog (most nearby pixels)
				if (fogKeep < 0.996) {
					float fogLight = min(max(aux.g, actualEyeBrightness) * 2.0, 1.0); //NoName: perf in caves: without sky light the fog color is multiplied by 0, so don't compute it (fog just darkens)
					color = mix(fogLight > 0.004 ? calcFogColor(farPos.viewNorm) * fogLight : vec3(0.0), color, fogKeep);
				}
			}
		#endif

		if (blindness > 0.0) color.rgb *= interpolateSmooth1(max(1.0 - farPos.blockDist * 0.2, 0.0)) * 0.5 * blindness + (1.0 - blindness);
	}
	else {
		if (nearPos.isSky) {
			#ifdef INFINITE_OCEANS
				if (actualCameraPosition.y > actualSeaLevel) {
					if (nearPos.player.y < 0.0) {
						aux2.g = 0.96875;
						aux2.b = 0.1; //water ID
						normal = vec4(0.0, 1.0, 0.0, 1.0);
						water = true;
					}
				}
				else if (inWater) {
					if (nearPos.player.y > 0.0) {
						aux2.g = 0.96875;
						aux2.b = 0.1; //water ID
						normal = vec4(0.0, -1.0, 0.0, 1.0);
						water = true;
					}
					#ifdef UNDERWATER_FOG
						else {
							color = calcUnderwaterFogColorInfinity(underwaterEyeBrightness);
						}
					#endif
				}
			#else
				#ifdef UNDERWATER_FOG
					if (inWater) {
						color = calcUnderwaterFogColorInfinity(underwaterEyeBrightness);
					}
				#endif
			#endif
		}
		if (water && !inWater) {
			color = calcUnderwaterFogColorInfinity(0.9384765625);
		}
		color *= 1.0 - blindness;
	}

/* DRAWBUFFERS:025 */
	gl_FragData[0] = vec4(color, texture2D(gaux3, texcoord).r); //gcolor, storing transparency data in alpha channel
	gl_FragData[1] = normal * 0.5 + 0.5; //gnormal
	gl_FragData[2] = aux2; //gaux2
}