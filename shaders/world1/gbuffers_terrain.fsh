#version 120

//#define GRASS_AO //Adds ambient occlusion to tallgrass/flowers/etc... Works best with "Remove Y Offset" enabled.
//#define LAVA_PATCHES //Randomizes lava brightness, similar to grass patches

uniform float frameTimeCounter;
uniform sampler2D noisetex;
uniform sampler2D texture;

varying float ao;
varying float isLava;
varying vec2 lmcoord;
varying vec2 randCoord;
varying vec2 texcoord;
varying vec4 tint;
varying float chorus;
varying float chorusPhase;
varying vec3 chorusPos;
varying vec3 chorusNormal;
varying vec3 chorusView;
varying vec3 chorusViewNormal;

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

	color *= tint;
	vec4 aux = vec4(lmcoord, 1.0, 1.0);
	vec3 chorusLight = vec3(0.0); //NoName: light the chorus gives off, blurred in composite1 so it spills onto everything nearby

	//NoName: jungle chorus. Fibrous plum bark with vertical grooves, patches of teal moss growing on it,
	//and the pale spots become glowing magenta fruit bulbs. Flowers are tropical blooms: magenta petals with a hot orange heart.
	//fruits and flowers are emissive and light up the area
	if (chorus > 0.5) {
		float t = frameTimeCounter;
		bool flower = chorus > 1.5;
		float lum = dot(texture2D(texture, texcoord).rgb, vec3(0.3, 0.5, 0.2));
		float pulse = 0.75 + 0.25 * sin(t * 1.2 + chorusPhase);

		vec3 n = abs(chorusNormal);
		vec2 faceUV = n.y > 0.5 ? chorusPos.xz : (n.x > 0.5 ? chorusPos.zy : chorusPos.xy);
		vec2 px = floor(faceUV * 16.0) / 16.0; //minecraft pixel grid

		float light;
		if (flower) {
			vec3 bloom = mix(vec3(0.45, 0.05, 0.35), vec3(1.0, 0.2, 0.7), smoothstep(0.2, 0.55, lum));
			bloom = mix(bloom, vec3(1.0, 0.55, 0.2), smoothstep(0.65, 0.9, lum)); //orange heart
			color.rgb = bloom * (1.0 + 0.6 * pulse);
			light = smoothstep(0.2, 0.5, lum) * pulse;
		}
		else {
			//bark: dark plum with vertical fibers (stretched noise, so grooves run along the stalk)
			float fiber = texture2D(noisetex, vec2(px.x * 1.3, px.y * 0.08) + chorusPhase * 0.01).r;
			vec3 bark = mix(vec3(0.14, 0.06, 0.12), vec3(0.36, 0.18, 0.3), fiber);
			bark *= 0.7 + 0.6 * smoothstep(0.1, 0.5, lum); //keep the block's own shading
			//moss
			float moss = smoothstep(0.55, 0.7, texture2D(noisetex, px * 0.12 + 0.37).g);
			bark = mix(bark, vec3(0.1, 0.32, 0.24) * (0.8 + fiber * 0.4), moss * 0.85);
			//glowing fruit bulbs on the pale spots
			float fruit = smoothstep(0.6, 0.8, lum) * (1.0 - moss);
			color.rgb = mix(bark, vec3(1.0, 0.3, 0.75) * (1.0 + 0.5 * pulse), fruit);
			light = fruit * pulse;
		}
		if (light > 0.4) aux = vec4(1.0, lmcoord.y, 0.5, 1.0);
		chorusLight = vec3(1.0, 0.35, 0.75) * light;
	}

/* DRAWBUFFERS:048 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = aux; //gaux1
	gl_FragData[2] = vec4(chorusLight, 1.0); //NoName: chorus light
}