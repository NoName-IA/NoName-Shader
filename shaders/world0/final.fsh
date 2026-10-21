#version 120

//#define BLUR_ENABLED //Is blur enabled at all? NoName: off by default, every blur option was at 0 and it costs an extra full-screen pass
//#define MOTION_BLUR //NoName: blurs the screen when you turn the camera or move fast
#define MOTION_BLUR_STRENGTH 100 //NoName: how strong the motion blur is [25 50 75 100 150 200]
#define BLUR_QUALITY 10 //Maximum number of sample points to use for blurring. Higher limit = higher performance impact! [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25]

uniform float pixelSizeY;
#ifdef BLUR_ENABLED
	uniform sampler2D composite; //output from previous stage
#else
	uniform sampler2D gaux3; //NoName: composite2 is skipped without blur, read composite1 output directly
	#define composite gaux3
#endif

#ifdef MOTION_BLUR
	uniform sampler2D depthtex0;
	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 gbufferPreviousModelView;
	uniform mat4 gbufferPreviousProjection;
	uniform vec3 cameraPosition;
	uniform vec3 previousCameraPosition;
	uniform float frameTime;
#endif

varying vec2 texcoord;

float fogify(float x, float width) {
	//fast, vaguely bell curve-shaped function with variable width
	return width / (x * x + width);
}

void main() {
	vec4 color = texture2D(composite, texcoord);

	#ifdef BLUR_ENABLED
		float blurRadius = 1.0 - color.a;
		if (blurRadius > 0.0) {
			float invBlurRadius1 = 1.0 / blurRadius;
			blurRadius *= 256.0; //actual radius in pixels
			float invBlurRadius2 = 1.0 / blurRadius;

			vec4 average = vec4(color.rgb * color.rgb, 1.0);

			int stepCount = int(clamp(blurRadius, 1.0, float(BLUR_QUALITY)));
			float invStepCount = 1.0 / float(stepCount);
			float stepSize = blurRadius * pixelSizeY * invStepCount;
			float bottomBound = pixelSizeY * 0.5;
			float topBound = 1.0 - bottomBound;

			for (int currentStep = 1; currentStep <= stepCount; currentStep++) {
				float weight = fogify(currentStep * invStepCount, 0.35);
				float y;
				vec4 newColor;
				float newWeight;

				y = texcoord.y - float(currentStep) * stepSize;
				if (y >= bottomBound) {
					newColor = texture2D(composite, vec2(texcoord.x, y));
					newWeight = weight * (1.0 - newColor.a) * invBlurRadius1;
					average += vec4(newColor.rgb * newColor.rgb * newWeight, newWeight);
				}

				y = texcoord.y + float(currentStep) * stepSize;
				if (y <= topBound) {
					newColor = texture2D(composite, vec2(texcoord.x, y));
					newWeight = weight * (1.0 - newColor.a) * invBlurRadius1;
					average += vec4(newColor.rgb * newColor.rgb * newWeight, newWeight);
				}
			}
			color.rgb = sqrt(average.rgb / average.a);
		}
	#endif

	#ifdef MOTION_BLUR
		float depth = texture2D(depthtex0, texcoord).r;
		if (depth > 0.56) { //skip the hand
			//reproject this pixel to where it was last frame
			vec4 pos = gbufferProjectionInverse * vec4(vec3(texcoord, depth) * 2.0 - 1.0, 1.0);
			pos = gbufferModelViewInverse * (pos / pos.w);
			pos.xyz += cameraPosition - previousCameraPosition;
			pos = gbufferPreviousProjection * (gbufferPreviousModelView * pos);
			vec2 velocity = texcoord - (pos.xy / pos.w * 0.5 + 0.5);
			//same blur length at any fps (as if the game ran at 60), so low fps doesn't smear everything
			velocity *= (MOTION_BLUR_STRENGTH * 0.005) * clamp(1.0 / (frameTime * 60.0), 0.0, 1.0);
			float speed = length(velocity);
			if (speed > 0.0005) {
				velocity *= min(speed, 0.04) / speed;
				vec3 sum = color.rgb;
				for (int i = 1; i <= 6; i++) {
					vec2 coord = clamp(texcoord + velocity * (float(i) / 6.0 - 0.5), vec2(0.0), vec2(1.0));
					sum += texture2D(composite, coord).rgb;
				}
				color.rgb = sum / 7.0;
			}
		}
	#endif

	gl_FragColor = color; //screen output
}