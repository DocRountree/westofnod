shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

// Open sea. Six Gerstner waves displace a camera-centred grid (UV.x carries the
// grid spacing; waves too short for it fade out, so nothing aliases). Waves
// feel the real sea floor from the world's height map: they shrink as the
// water shoals, and are gone at the shore, so swell never climbs onto land.
// Per pixel: analytic wave normal plus small waves, refraction and depth
// absorption, crest scattering, foam where the waves pinch and at the swash.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/water_common.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"

uniform float amplitude = 0.6;
uniform float wind_angle = 0.35;

const int NW = 6;
// direction offset from the wind (rad), wavelength (m), steepness, phase
const vec4 WAVE[NW] = vec4[](
	vec4(0.0, 61.0, 0.16, 0.0),
	vec4(-0.75, 37.0, 0.14, 1.7),
	vec4(0.5, 23.0, 0.12, 4.1),
	vec4(-1.35, 14.0, 0.10, 2.3),
	vec4(-0.2, 8.5, 0.08, 5.6),
	vec4(1.6, 5.3, 0.06, 0.9)
);

varying vec2 x0;
varying float spacing;
varying float crest;
varying float pinch;
varying float sea_depth;

float shoal(float lambda, float depth) {
	return smoothstep(0.0, 0.35 * lambda, depth);
}

vec3 waves(vec2 p, float t, float sp, float depth, out vec2 slope, out float jac) {
	vec3 disp = vec3(0.0);
	slope = vec2(0.0);
	float nz = 1.0;
	float jxx = 1.0, jzz = 1.0, jxz = 0.0;
	for (int i = 0; i < NW; i++) {
		float ang = wind_angle + WAVE[i].x;
		vec2 d = vec2(cos(ang), sin(ang));
		float lambda = WAVE[i].y;
		float k = TAU / lambda;
		float st = WAVE[i].z * amplitude * clamp((lambda - 3.0 * sp) / (3.0 * sp), 0.0, 1.0) * shoal(lambda, depth);
		float a = st / k;
		float th = k * dot(d, p) - sqrt(G * k) * t + WAVE[i].w;
		float c = cos(th);
		float s = sin(th);
		disp.xz += d * a * c;
		disp.y += a * s;
		slope += d * st * c;
		nz -= st * s;
		jxx -= d.x * d.x * st * s;
		jzz -= d.y * d.y * st * s;
		jxz -= d.x * d.y * st * s;
	}
	slope /= max(nz, 0.2);
	jac = jxx * jzz - jxz * jxz;
	return disp;
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	x0 = world.xz;
	spacing = UV.x;
	// Sea floor from a mip matched to the grid spacing.
	sea_depth = -height_m(x0, clamp(int(log2(max(spacing, 1.0) / map_cell())), 0, 8));
	vec2 sl;
	float jac;
	vec3 disp = waves(x0, TIME, spacing, sea_depth, sl, jac);
	crest = disp.y;
	pinch = clamp(1.0 - jac, 0.0, 1.0);
	VERTEX += disp;
}

void fragment() {
	float fp = max(length(fwidth(x0)), 0.002);
	vec2 slope;
	float jac;
	waves(x0, TIME, spacing, sea_depth, slope, jac);
	vec2 ds = small_waves(x0, TIME, fp, wind_angle, 1.4, 1.0, 0.075) * smoothstep(0.0, 0.5, sea_depth);
	slope += ds;
	vec3 n_world = normalize(vec3(-slope.x, 1.0, -slope.y));
	if (!FRONT_FACING) n_world = -n_world;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - world_pos);
	float thickness;
	vec3 up = water_body(SCREEN_UV, VERTEX, slope, n_world, to_eye, crest, INV_PROJECTION_MATRIX,
			vec3(0.0), vec3(0.0), 0.0, thickness);
	// Foam: breaking crests, and the swash line (only while a pixel is finer
	// than the swash), broken up by the small waves themselves.
	float breakup = clamp(0.5 + 2.5 * dot(ds, vec2(0.7)), 0.0, 1.0);
	float foam = smoothstep(0.25, 0.6, 1.0 - jac) * breakup;
	foam = max(foam, (1.0 - smoothstep(0.0, 0.35, thickness)) * smoothstep(0.3, 0.7, breakup) * 0.8
			* (1.0 - smoothstep(0.15, 0.6, fp)));
	float fresnel = schlick(n_world, to_eye);
	ALBEDO = vec3(0.85) * foam;
	ROUGHNESS = mix(0.03, 0.6, foam);
	SPECULAR = 0.5;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
	EMISSION = up * (1.0 - fresnel) * (1.0 - foam);
	ALPHA = smoothstep(0.0, 0.12, thickness);
	if (!FRONT_FACING) {
		EMISSION = mix(deep_color + scatter_color * 0.5, textureLod(screen_tex, SCREEN_UV, 0.0).rgb,
				smoothstep(0.65, 0.8, abs(dot(n_world, to_eye))));
		ALBEDO = vec3(0.0);
		ALPHA = 1.0;
	}
}
