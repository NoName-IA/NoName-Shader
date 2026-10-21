#version 120

#define STORM_WAVES 100 //NoName: in thunderstorms the sea gets big waves that rise out of the block and boats ride them. 0 = off [0 25 50 75 100 150 200]
#define SEA_LEVEL 63 //Sea level for infinite oceans. Change this if you use custom worldgen. [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256]

uniform float realTime; //NoName: storm waves, same clock as the water
uniform float thunderStrength;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D noisetex;
uniform vec3 actualCameraPosition;
uniform vec3 cameraPosition;
uniform vec3 relativeVehiclePosition; //NoName: camera MINUS the boat you ride (Iris; checked with a debug screenshot, it is not boat - camera)
uniform bool isRiding;
uniform vec3 vehicleLookVector; //NoName: which way your boat points (Iris)

const float invNoiseRes = 1.0 / 256.0;

varying vec2 lmcoord;
varying vec3 tint;

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
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	vec3 vPosView = (gl_ModelViewMatrix * gl_Vertex).xyz;
	//NoName: Iris draws the boat's water mask (the invisible shape that hides water inside the hull) with this program.
	//it has to ride the storm waves exactly like the boat (same rigid transform as gbuffers_entities.vsh),
	//or it stays at the old height and cuts holes in the raised water around the boat.
	#if STORM_WAVES > 0
		if (thunderStrength > 0.01 && isRiding) {
			vec3 worldPos = mat3(gbufferModelViewInverse) * vPosView + actualCameraPosition;
			vec3 boatPos = cameraPosition - relativeVehiclePosition;
			vec3 rel = worldPos - boatPos;
			if (length(rel.xz) < 1.6 && rel.y > -0.8 && rel.y < 2.6 && abs(boatPos.y - SEA_LEVEL) < 3.0) {
				vec2 f = normalize(vehicleLookVector.xz + vec2(0.0001, 0.0));
				vec2 s = vec2(-f.y, f.x);
				float lift, pitch, roll;
				boatPose(boatPos.xz, f, lift, pitch, roll);
				float along = dot(rel.xz, f), across = dot(rel.xz, s), up = rel.y;
				float cp = cos(pitch), sp = sin(pitch);
				float up1 = up * cp + along * sp;
				along = along * cp - up * sp;
				float cr = cos(roll), sr = sin(roll);
				float up2 = up1 * cr + across * sr;
				across = across * cr - up1 * sr;
				worldPos = boatPos + vec3(f.x * along + s.x * across, up2 + lift, f.y * along + s.y * across);
				vPosView = mat3(gbufferModelView) * (worldPos - actualCameraPosition);
			}
		}
	#endif
	gl_Position = gl_ProjectionMatrix * vec4(vPosView, 1.0);
	tint = gl_Color.rgb;
}
