shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

// Rivers, lakes and oxbows: the terrain's own CDLOD patches, raised to the
// water level map. Where there is water is a coverage map, mip-filtered, so a
// river thinner than a pixel at its distance fades to a fine line rather than
// breaking into blobs; the surface and the terrain share their patches, so the
// waterline never drifts. Rivers flow: their small waves run downstream and are
// carried by the current (two copies half a cycle apart, cross-faded).

#include "res://shaders/render/island_maps.gdshaderinc"
#include "res://shaders/render/water_common.gdshaderinc"

uniform sampler2D water_tex : filter_nearest_mipmap, repeat_disable;  // level
uniform sampler2D wattr_tex : filter_linear_mipmap, repeat_disable;   // coverage, flow, kind
uniform float river_speed = 1.4; // m/s at full flow
uniform vec3 silt_color = vec3(0.07, 0.09, 0.06);
uniform float murk = 0.12;

varying vec3 world_pos;

void vertex() {
	int lod;
	float morph;
	vec2 wp = cdlod_xz(VERTEX, MODEL_MATRIX, INSTANCE_CUSTOM, lod, morph);
	float h = sample_m(water_tex, wp, lod, -1e3);
	if (morph > 0.0) h = mix(h, sample_m(water_tex, wp, lod + 1, -1e3), morph);
	vec3 origin = MODEL_MATRIX[3].xyz;
	VERTEX = vec3(wp.x - origin.x, h - origin.y, wp.y - origin.z);
	world_pos = vec3(wp.x, h, wp.y);
}

void fragment() {
	vec2 p = world_pos.xz;
	vec4 wa = texture(wattr_tex, map_uv(p));
	float cover = wa.r;
	if (cover < 0.03) discard;
	vec2 flow = (wa.gb - 0.5) * 2.0;
	float fp = max(length(fwidth(p)), 0.002);
	bool river = dot(flow, flow) > 0.01;
	vec2 slope;
	if (river) {
		vec2 u = flow * river_speed;
		float ph0 = fract(TIME * 0.25);
		float ph1 = fract(TIME * 0.25 + 0.5);
		float base = atan(flow.y, flow.x);
		vec2 s0 = small_waves(p - u * ph0 * 4.0, TIME, fp, base, 0.9, 0.15, 0.08);
		vec2 s1 = small_waves(p - u * ph1 * 4.0 + vec2(13.1, 7.7), TIME, fp, base, 0.9, 0.15, 0.08);
		slope = mix(s0, s1, abs(ph0 - 0.5) * 2.0) * (0.6 + 0.8 * length(flow));
	} else {
		slope = small_waves(p, TIME, fp, 0.35, 1.4, 0.12, 0.06);
	}
	vec3 n_world = normalize(vec3(-slope.x, 1.0, -slope.y));
	if (!FRONT_FACING) n_world = -n_world;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - world_pos);
	float thickness;
	vec3 up = water_body(SCREEN_UV, VERTEX, slope, n_world, to_eye, 0.0, INV_PROJECTION_MATRIX,
			vec3(murk), silt_color, 0.25, thickness);
	float fresnel = schlick(n_world, to_eye);
	// White water over fast, shallow riffles.
	float foam = river ? smoothstep(0.7, 1.0, length(flow)) * (1.0 - smoothstep(0.1, 0.5, thickness))
			* smoothstep(0.0, 0.5, dot(slope, vec2(0.7)) + 0.3) * (1.0 - smoothstep(0.2, 0.6, fp)) : 0.0;
	ALBEDO = vec3(0.85) * foam;
	ROUGHNESS = mix(0.04, 0.6, foam);
	SPECULAR = 0.5;
	EMISSION = up * (1.0 - fresnel) * (1.0 - foam);
	ALPHA = smoothstep(0.03, 0.5, cover) * smoothstep(0.0, 0.1, thickness);
	if (!FRONT_FACING) {
		EMISSION = deep_color + scatter_color * 0.5;
		ALBEDO = vec3(0.0);
		ALPHA = 0.95;
	}
}
