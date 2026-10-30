shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx, depth_draw_never;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 shallow_color : source_color = vec3(0.16, 0.55, 0.58);
uniform vec3 deep_color : source_color = vec3(0.02, 0.11, 0.24);

varying vec3 wpos;

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

float waves(vec2 p, float t) {
	return vnoise(p * 0.35 + vec2(t * 0.25, t * 0.1)) * 0.6
			+ vnoise(p * 0.9 - vec2(t * 0.2, -t * 0.3)) * 0.3
			+ vnoise(p * 2.3 + vec2(-t * 0.5, t * 0.4)) * 0.1;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	float thickness = max(VERTEX.z - v.z, 0.0);

	float e = 0.15;
	float hx = waves(wpos.xz + vec2(e, 0.0), TIME) - waves(wpos.xz - vec2(e, 0.0), TIME);
	float hz = waves(wpos.xz + vec2(0.0, e), TIME) - waves(wpos.xz - vec2(0.0, e), TIME);
	float fade = clamp(1.0 - length(VERTEX) / 400.0, 0.15, 1.0);
	vec3 nw = normalize(vec3(-hx * 1.2 * fade, 1.0, -hz * 1.2 * fade));
	NORMAL = (VIEW_MATRIX * vec4(nw, 0.0)).xyz;

	float depth_mix = clamp(thickness / 18.0, 0.0, 1.0);
	vec3 col = mix(shallow_color, deep_color, sqrt(depth_mix));
	float foam = (1.0 - smoothstep(0.0, 0.5, thickness)) * step(0.45, vnoise(wpos.xz * 1.5 + TIME * 0.3));
	col = mix(col, vec3(0.9, 0.95, 0.95), foam * 0.7);
	ALBEDO = col;
	ALPHA = clamp(0.35 + thickness * 0.25, 0.35, 0.93);
	ROUGHNESS = 0.05;
	SPECULAR = 0.6;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
		ALPHA = 0.7;
	}
}
