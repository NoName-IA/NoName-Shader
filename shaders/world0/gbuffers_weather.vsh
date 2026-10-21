#version 120

#define CLOUDS //3D clouds (partially volumetric too). Mild performance impact!

#define WAVING_RAIN //Makes rain not directly vertical by applying "wind" to it.

uniform float frameTimeCounter;
uniform float animTime; //NoName: tick-based clock, see shaders.properties
#define frameTimeCounter animTime //NoName: every animation follows /tick freeze and /tick rate
uniform float rainStrength;
uniform float thunderStrength;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D noisetex;
uniform vec3 actualCameraPosition;

#ifdef CLOUDS
	varying float worldHeight;
#endif
varying vec2 texcoord;
varying vec4 tint;

const int noiseTextureResolution = 256;
const float invNoiseRes = 1.0 / float(noiseTextureResolution);

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vec3 vPosView = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vec3 vPosPlayer = mat3(gbufferModelViewInverse) * vPosView;
	vec3 worldPos = vPosPlayer + actualCameraPosition;
	vec4 pos = gl_Vertex;

	#ifdef WAVING_RAIN
		//NoName: realistic slant. rain leans with the wind: the higher above you a drop is, the further upwind
		//it is, so the streaks tilt. gusts vary the angle; storms blow it much more sideways.
		vec2 windDir = vec2(0.85, 0.35);
		//gusts from a few sine waves with unrelated speeds: smooth and never repeats (a texture lookup looped every 20 s)
		float gust = 1.0 + sin(frameTimeCounter * 0.37) * 0.15 + sin(frameTimeCounter * 0.61 + 1.3) * 0.1 + sin(frameTimeCounter * 1.13 + 4.1) * 0.05;
		float slant = (0.12 + rainStrength * 0.08 + thunderStrength * 0.35) * gust;
		vec2 offset = windDir * slant * vPosPlayer.y;
		offset += vec2(sin(worldPos.x * 0.7 + frameTimeCounter * 2.3), sin(worldPos.z * 0.9 + frameTimeCounter * 1.7)) * 0.05; //a little jitter, never repeats

		worldPos.xz += offset;
		vPosPlayer = worldPos - actualCameraPosition;
		vPosView = mat3(gbufferModelView) * vPosPlayer;
	#endif

	#ifdef CLOUDS
		worldHeight = worldPos.y;
	#endif

	gl_Position = gl_ProjectionMatrix * vec4(vPosView, 1.0);
	tint = gl_Color;
}