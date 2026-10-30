shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx, depth_draw_never;

// Gerstner water. A sum of trochoidal waves moves each vertex in a circle
// (horizontally toward the crests, vertically up and down); normals and the
// crest pinch (where foam forms) are analytic.
//  - Ocean: full-size swell from one wind direction, flattening with distance.
//  - Lakes: the same set shrunk to short, low ripples.
//  - Rivers: UV carries the flow (direction x speed). Waves are turned to run
//    downstream and travel with the current, and the surface detail is
//    advected along the flow (two-phase flow map) so the water visibly moves.

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 shallow_color : source_color = vec3(0.16, 0.55, 0.58);
uniform vec3 deep_color : source_color = vec3(0.02, 0.11, 0.24);
uniform float amplitude = 1.0;      // multiplies wave steepness
uniform float length_scale = 1.0;   // multiplies wavelengths
uniform float wind_angle = 0.35;
uniform float near_cutoff = 0.0;    // far LOD water hides near the camera
uniform float fade_start = 250.0;   // waves flatten with distance (coarse mesh)
uniform float fade_end = 1600.0;
uniform float river_speed = 1.6;    // m/s at full flow

const int WAVES = 6;
// direction offset from the wind (rad), wavelength (m), steepness (sum < 1: no loops)
const vec3 WAVE[WAVES] = vec3[](
	vec3(0.0, 61.0, 0.17),
	vec3(-0.8, 37.0, 0.15),
	vec3(0.55, 23.0, 0.13),
	vec3(-1.5, 14.0, 0.11),
	vec3(-0.25, 8.5, 0.09),
	vec3(1.75, 5.3, 0.07)
);

varying vec3 wpos;
varying float crest;
varying vec2 vflow;

vec3 gerstner(vec2 xz, float t, float fade, vec2 flow, inout vec3 tangent, inout vec3 binormal) {
	vec3 offset = vec3(0.0);
	float fs = length(flow);
	float base = fs > 0.01 ? atan(flow.y, flow.x) : wind_angle;
	for (int i = 0; i < WAVES; i++) {
		// River waves fan out less around the downstream direction.
		float ang = base + WAVE[i].x * (fs > 0.01 ? 0.4 : 1.0);
		vec2 d = vec2(cos(ang), sin(ang));
		float lambda = WAVE[i].y * length_scale;
		float steep = WAVE[i].z * amplitude * fade;
		float k = 6.28318530718 / lambda;
		// Deep-water phase speed, plus the current carrying the wave downstream.
		float c = sqrt(9.81 / k) + fs * river_speed;
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
	vflow = UV;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 off = gerstner(world.xz, TIME, fade, vflow, tangent, binormal);
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

// Ripple slope (d/dx, d/dz) of a small noise surface.
vec2 ripple(vec2 uv) {
	float e = 0.08;
	float n0 = vnoise(uv);
	return vec2(vnoise(uv + vec2(e, 0.0)) - n0, vnoise(uv + vec2(0.0, e)) - n0) / e;
}

void fragment() {
	if (near_cutoff > 0.0 && distance(wpos.xz, CAMERA_POSITION_WORLD.xz) < near_cutoff) {
		discard;
	}
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	float thickness = max(VERTEX.z - v.z, 0.0);

	// Fine ripples. On rivers they are advected by the current: two copies half
	// a cycle apart, each reset when it has drifted too far, cross-faded.
	vec2 uv = wpos.xz * 1.3 / length_scale;
	vec2 slope;
	float fs = length(vflow);
	if (fs > 0.01) {
		vec2 drift = vflow * river_speed * 1.3 / length_scale;
		float ph0 = fract(TIME * 0.5);
		float ph1 = fract(TIME * 0.5 + 0.5);
		vec2 s0 = ripple(uv - drift * ph0 * 2.0);
		vec2 s1 = ripple(uv - drift * ph1 * 2.0 + vec2(17.3, 5.1));
		slope = mix(s0, s1, abs(ph0 - 0.5) * 2.0) * 0.12;
	} else {
		slope = ripple(uv + TIME * vec2(0.4, 0.25)) * 0.12;
	}
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz + vec3(-slope.x, 0.0, -slope.y) * 1.4);
	NORMAL = (VIEW_MATRIX * vec4(nw, 0.0)).xyz;

	float depth_mix = clamp(thickness / 18.0, 0.0, 1.0);
	vec3 col = mix(shallow_color, deep_color, sqrt(depth_mix));
	float shore = (1.0 - smoothstep(0.0, 0.6, thickness)) * step(0.4, vnoise(wpos.xz * 1.5 + TIME * 0.3));
	float whitecap = smoothstep(0.35, 0.7, crest) * step(0.45, vnoise(wpos.xz * 0.8 - TIME * 0.2));
	// Fast water breaks white over shallows.
	float riffle = fs * smoothstep(0.5, 0.9, fs) * (1.0 - smoothstep(0.0, 0.5, thickness));
	col = mix(col, vec3(0.92, 0.96, 0.97), clamp(shore * 0.75 + whitecap * 0.6 + riffle * 0.5, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp(0.35 + thickness * 0.25 + whitecap * 0.4, 0.35, 0.94);
	ROUGHNESS = 0.05;
	SPECULAR = 0.6;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
		ALPHA = 0.7;
	}
}
