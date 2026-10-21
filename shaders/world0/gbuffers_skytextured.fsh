#version 120

//#define CUSTOM_SKY_FIX //Disables sun fadeout near the horizon when infinite oceans are enabled. Enable this if your resource pack's custom skys turn black near the horizon.
#define INFINITE_OCEANS //Simulates water out to the horizon instead of just your render distance.
#define MOON_SIZE 1.3 //NoName: moon size. 1.0 = vanilla [1.0 1.1 1.2 1.3 1.4 1.5 1.75 2.0]
#define PRETTY_SUN_MOON //NoName: square, pixel-stepped glow around the sun and moon, warmer sun at sunset
#define ROUND_SUN //NoName: draws the sun as a round disc with a soft round glow instead of vanilla's square. the moon stays square
#define SUNRISE_ANIMATION 100 //NoName: sunrise show: glare when you look at the low sun, a flash on the horizon when it peeks out, and a red, flattened, shimmering sun that turns yellow as it climbs. 0 = off [0 25 50 75 100 150 200]
#define RAIN_SUN 50 //NoName: how much of the sun still shows through plain rain (not thunderstorms). 0 = vanilla, hidden [0 25 35 50 65 75 100]

uniform float pixelSizeX;
uniform float pixelSizeY;
uniform ivec4 blendFunc;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform float phase;
uniform float sunset;
uniform vec3 sunPosNorm;
uniform sampler2D texture;
uniform vec3 actualCameraPosition;
uniform vec3 upPosNorm;
uniform float rainSun; //NoName: see shaders.properties
uniform float sunrise; //NoName: see shaders.properties
uniform float animTime;

varying vec2 texcoord;
varying vec4 tint;

float square(float x)        { return x * x; } //potentially faster than pow(x, 2.0).

float fogify(float x, float width) {
	//fast, vaguely bell curve-shaped function with variable width
	return width / (x * x + width);
}

/*
//required for optifine's option parsing logic.
#ifdef CUSTOM_SKY_FIX
#endif
*/

void main() {
	vec4 color = texture2D(texture, texcoord) * tint;

	//check for additive blending or an old optifine version which doesn't have the blendFunc uniform.
	if (blendFunc.xy == ivec2(770, 1) || blendFunc.xy == ivec2(0, 0)) {
		//fix alphaTestRef patch on 1.17+ causing the sun/moon to disappear
		//abruptly during the transition from clear weather to rain.
		//NoName: in plain rain the sun stays a bit visible, pale behind the clouds. vanilla fades it out completely (tint.a).
		vec4 viewTmp = gbufferProjectionInverse * vec4(gl_FragCoord.xy * vec2(pixelSizeX, pixelSizeY) * 2.0 - 1.0, 1.0, 1.0); //NoName: perf: computed once, reused below
		vec3 viewDir = normalize(viewTmp.xyz);
		bool sunSide = dot(viewDir, sunPosNorm) > 0.0;
		float bodyFade = tint.a;
		if (sunSide) {
			bodyFade = max(tint.a, rainSun * (RAIN_SUN * 0.01));
			color.a = texture2D(texture, texcoord).a * bodyFade;
		}

		color.rgb *= color.a;
		color.a = 1.0;
		float horizonFade = 1.0;

		#if defined(INFINITE_OCEANS) && !defined(CUSTOM_SKY_FIX)
			float upDot = dot(viewDir, upPosNorm) * square(max(actualCameraPosition.y, 256.0) / 256.0 + 1.0) * 0.5;
			horizonFade = 1.0 - fogify(max(upDot, 0.0), 0.0625);
			color.rgb *= horizonFade;
		#endif

		#ifdef PRETTY_SUN_MOON
			//NoName: position inside the sun/moon square: 0 = center, 1 = edge of the quad.
			//measured on the sun's own plane like the square water reflection, then rounded to 1/16 steps
			//so the glow is made of square "pixels", keeping the minecraft look.
			float sunDot = dot(viewDir, sunPosNorm);
			bool isSun = sunDot > 0.0;
			vec3 bodyDir = isSun ? sunPosNorm : -sunPosNorm;
			vec3 axisX = mat3(gbufferModelView) * vec3(0.0, 0.0, 1.0); //the sun's path rotates around world Z
			axisX = normalize(axisX - bodyDir * dot(axisX, bodyDir));
			vec3 axisY = cross(bodyDir, axisX);
			vec2 plane = vec2(dot(viewDir, axisX), dot(viewDir, axisY)) / max(abs(sunDot), 0.001);
			float edge = max(abs(plane.x), abs(plane.y)) / (isSun ? 0.3 : 0.2 * MOON_SIZE); //vanilla quads: sun 30, moon 20, at distance 100
			edge = floor(edge * 16.0) / 16.0;
			float glow = square(max(1.0 - edge, 0.0)) * bodyFade; //fades out in rain like the sun itself

			if (isSun) {
				vec3 sunTint = mix(vec3(1.0), vec3(1.0, 0.62, 0.38), sunset); //orange at sunset
				#ifdef ROUND_SUN
					//NoName: round sun. same size as vanilla's bright core (half the quad), soft edge, and a smooth round glow
					//that fades out before the quad's edge so its square never shows.
					vec2 sunShape = plane;
					#if SUNRISE_ANIMATION > 0
						//NoName: sunrise: low over the horizon the sun is flattened, its edges shimmer like hot air, and it's redder.
						//all of it fades as it climbs. the glow also breathes slowly while the sun is rising.
						float lowSun = (1.0 - smoothstep(0.0, 0.2, dot(sunPosNorm, upPosNorm))) * sunrise * (SUNRISE_ANIMATION * 0.01);
						sunShape.y /= mix(1.0, 0.82, min(lowSun, 1.0));
						sunShape.x += sin(sunShape.y * 60.0 + animTime * 5.0) * 0.008 * lowSun;
						sunTint = mix(sunTint, vec3(1.0, 0.42, 0.18), min(lowSun * 0.6, 1.0));
					#endif
					float r = length(sunShape) / 0.3; //0 = center, 1 = edge of the quad
					float disc = 1.0 - smoothstep(0.42, 0.5, r);
					float roundGlow = square(max(1.0 - r, 0.0));
					#if SUNRISE_ANIMATION > 0
						roundGlow *= 1.0 + sunrise * (SUNRISE_ANIMATION * 0.01) * (0.8 + 0.4 * sin(animTime * 1.5));
					#endif
					vec3 roundSun = vec3(1.0, 0.97, 0.86) * disc * 0.8 + vec3(1.0, 0.85, 0.6) * (roundGlow * 0.12 + roundGlow * roundGlow * 0.15);
					color.rgb = roundSun * sunTint * tint.rgb * (bodyFade * horizonFade);
				#else
					color.rgb = color.rgb * sunTint * 0.8 + vec3(1.0, 0.85, 0.6) * sunTint * glow * 0.12; //NoName: toned down, it hurt the eyes
				#endif
			}
			else {
				color.rgb = color.rgb * 1.25 + vec3(0.55, 0.65, 1.0) * glow * 0.2 * (phase * 0.7 + 0.3); //brighter halo with a fuller moon. NoName: user loved it, a bit brighter
			}
		#endif
	}

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}