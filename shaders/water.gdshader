shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx, depth_draw_never;

// Gerstner waves: a sum of trochoidal waves, each moving vertices in circles
// (horizontally toward crests, vertically up/down), with analytic normals.
// The ocean uses full-size swell; rivers and lakes reuse the same set scaled
// down to short, low ripples.

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 shallow_color : source_color = vec3(0.16, 0.55, 0.58);
uniform vec3 deep_color : source_color = vec3(0.02, 0.11, 0.24);
uniform float amplitude = 1.0;      // multiplies wave steepness
uniform float length_scale = 1.0;   // multiplies wavelengths
uniform float near_cutoff = 0.0;    // far LOD water hides near the camera
uniform float fade_start = 250.0;   // waves flatten with distance (coarse mesh)
uniform float fade_end = 1600.0;

const int WAVES = 6;
// direction angle (rad), wavelength (m), steepness (sum < 1 avoids loops)
const vec3 WAVE[WAVES] = vec3[](
	vec3(0.35, 61.0, 0.17),
	vec3(-0.45, 37.0, 0.15),
	vec3(0.9, 23.0, 0.13),
	vec3(-1.2, 14.0, 0.11),
	vec3(0.1, 8.5, 0.09),
	vec3(2.1, 5.3, 0.07)
);

varying vec3 wpos;
varying float crest;

vec3 gerstner(vec2 xz, float t, float fade, inout vec3 tangent, inout vec3 binormal) {
	vec3 offset = vec3(0.0);
	for (int i = 0; i < WAVES; i++) {
		vec2 d = vec2(cos(WAVE[i].x), sin(WAVE[i].x));
		float lambda = WAVE[i].y * length_scale;
		float steep = WAVE[i].z * amplitude * fade;
		float k = 6.28318530718 / lambda;
		float c = sqrt(9.81 / k);
		float f = k * (dot(d, xz) - c * t);
		float a = steep / k;
		float sf = sin(f);
		float cf = cos(f);
		offset += vec3(d.x * a * cf, a * sf, d.y * a * cf);
		tangent += vec3(-d.x * d.x * steep * sf, d.x * steep * cf, -d.x * d.y * steep * sf);
		binormal += vec3(-d.x * d.y * steep * sf, d.y * steep * cf, -d.y * d.y * steep * sf);
	}
	return offset;
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = distance(world.xz, CAMERA_POSITION_WORLD.xz);
	float fade = 1.0 - smoothstep(fade_start, fade_end, dist);
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 off = gerstner(world.xz, TIME, fade, tangent, binormal);
	VERTEX += off;
	NORMAL = normalize(cross(binormal, tangent));
	wpos = world + off;
	// Pinched crests (horizontal convergence) are where foam forms.
	crest = clamp(1.0 - tangent.x * binormal.z + tangent.z * binormal.x, 0.0, 1.0);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	if (near_cutoff > 0.0 && distance(wpos.xz, CAMERA_POSITION_WORLD.xz) < near_cutoff) {
		discard;
	}
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	float thickness = max(VERTEX.z - v.z, 0.0);

	// Fine ripples on top of the geometric waves.
	vec2 uv = wpos.xz * 1.3 / length_scale;
	float e = 0.08;
	float n0 = vnoise(uv + TIME * vec2(0.4, 0.25));
	float nx = vnoise(uv + vec2(e, 0.0) + TIME * vec2(0.4, 0.25)) - n0;
	float nz = vnoise(uv + vec2(0.0, e) + TIME * vec2(0.4, 0.25)) - n0;
	vec3 ripple = normalize(vec3(-nx * 2.0, 1.0, -nz * 2.0));
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz + (ripple - vec3(0.0, 1.0, 0.0)) * 0.35);
	NORMAL = (VIEW_MATRIX * vec4(nw, 0.0)).xyz;

	float depth_mix = clamp(thickness / 18.0, 0.0, 1.0);
	vec3 col = mix(shallow_color, deep_color, sqrt(depth_mix));
	float shore = (1.0 - smoothstep(0.0, 0.6, thickness)) * step(0.4, vnoise(wpos.xz * 1.5 + TIME * 0.3));
	float whitecap = smoothstep(0.35, 0.7, crest) * step(0.45, vnoise(wpos.xz * 0.8 - TIME * 0.2));
	col = mix(col, vec3(0.92, 0.96, 0.97), clamp(shore * 0.75 + whitecap * 0.6, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp(0.35 + thickness * 0.25 + whitecap * 0.4, 0.35, 0.94);
	ROUGHNESS = 0.05;
	SPECULAR = 0.6;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
		ALPHA = 0.7;
	}
}
