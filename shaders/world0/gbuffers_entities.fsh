#version 120

uniform int entityId;
uniform sampler2D texture;
uniform vec4 entityColor;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 tint;

void main() {
	vec4 color;
	float lightAlpha;
	if (entityId == 10000) {
		color = tint;
		lightAlpha = 1.0;
	}
	else {
		color = texture2D(texture, texcoord) * tint;
		if (color.a < 0.01) discard; //fix phantoms, and maybe other entities too.
		color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
		lightAlpha = step(0.75, color.a);
	}

	//NoName: in 26.1 many entities are drawn in the translucent pass, AFTER water. they did not clear the water data
	//behind them (ID in gaux2, water color in composite, water mask in colortex8), so composite1 drew water over them
	//(dark, distorted bodies in front of lakes and the sea). solid pixels now erase it; see the blend modes in shaders.properties.
/* DRAWBUFFERS:045386 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord, 1.0, lightAlpha); //gaux1
	gl_FragData[2] = vec4(lmcoord, 0.0, lightAlpha); //gaux2: ID 0 = nothing special
	gl_FragData[3] = vec4(0.0, 0.0, 0.0, lightAlpha); //composite: no transparent layer here
	gl_FragData[4] = vec4(0.0, 0.0, 0.0, lightAlpha); //colortex8: no water mask / portal glow here
	gl_FragData[5] = vec4(0.0, 0.0, 0.0, lightAlpha); //gaux3: red = how transparent the water/glass in front is. 0 = nothing in front
}