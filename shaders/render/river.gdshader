shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

// River surfaces (RiverMeshes ribbons). COLOR.rg: downstream direction, b: speed,
// a: width / 60 m. UV.x across the ribbon, UV.y metres along the river.
// The small waves run downstream and are carried by the current: two copies of
// the pattern advected along the flow, half a cycle apart, cross-faded, so the
// water visibly moves the right way everywhere. Edges feather into the banks.

#include "res://shaders/render/water_common.gdshaderinc"

uniform float river_speed = 1.6; // m/s at full speed
uniform vec3 silt_color = vec3(0.07, 0.085, 0.05);
uniform float murk = 0.55;

varying vec3 world_pos;
varying vec2 flow;
varying float speed;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	flow = COLOR.rg * 2.0 - 1.0;
	speed = COLOR.b;
}

void fragment() {
	vec2 p = world_pos.xz;
	float fp = max(length(fwidth(p)), 0.002);
	vec2 dir = normalize(flow);
	vec2 u = dir * speed * river_speed;
	float ph0 = fract(TIME * 0.25);
	float ph1 = fract(TIME * 0.25 + 0.5);
	float base = atan(dir.y, dir.x);
	vec2 s0 = small_waves(p - u * ph0 * 4.0, TIME, fp, base, 0.9, 0.18, 0.07);
	vec2 s1 = small_waves(p - u * ph1 * 4.0 + vec2(13.1, 7.7), TIME, fp, base, 0.9, 0.18, 0.07);
	vec2 slope = mix(s0, s1, abs(ph0 - 0.5) * 2.0) * (0.6 + 0.8 * speed);
	vec3 n_world = normalize(vec3(-slope.x, 1.0, -slope.y));
	if (!FRONT_FACING) n_world = -n_world;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - world_pos);
	float thickness;
	vec3 up = water_body(SCREEN_UV, VERTEX, slope, n_world, to_eye, 0.0, INV_PROJECTION_MATRIX,
			vec3(murk), silt_color, 0.65, thickness);
	float fresnel = schlick(n_world, to_eye);
	// White water where it runs fast over shallows.
	float foam = smoothstep(0.65, 1.0, speed) * (1.0 - smoothstep(0.05, 0.5, thickness))
			* smoothstep(0.0, 0.6, dot(slope, vec2(0.7)) + 0.35) * (1.0 - smoothstep(0.2, 0.6, fp));
	ALBEDO = vec3(0.85) * foam;
	ROUGHNESS = mix(0.05, 0.6, foam);
	SPECULAR = 0.5;
	EMISSION = up * (1.0 - fresnel) * (1.0 - foam);
	ALPHA = smoothstep(0.0, 0.12, thickness);
	if (!FRONT_FACING) {
		EMISSION = deep_color + scatter_color * 0.5;
		ALBEDO = vec3(0.0);
		ALPHA = 0.95;
	}
}
