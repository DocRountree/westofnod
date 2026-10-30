// Props scattered on the GPU around the main camera. Instance i of a GRID x GRID
// multimesh owns one world cell (the field slides with the camera, the cells
// stay put), so props are anchored in the world and never shuffle. A cell gets
// a prop with the probability given by a mask channel; each prop fades in and
// out over distance bands with a screen-door dither, so nothing pops.

#include "res://shaders/render/height_map.gdshaderinc"

uniform sampler2D mask_tex : filter_linear_mipmap, repeat_disable; // rock, wet, forest, sand
uniform int grid = 64;
uniform float cell = 8.0;
uniform float fade_in_start = -1.0; // inner band (for a far layer)
uniform float fade_in_end = 0.0;
uniform float fade_out_start = 200.0;
uniform float fade_out_end = 250.0;
uniform uint salt = 1u;

varying float v_fade;
varying float v_rand;

uint phash(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	return v.x ^ v.y ^ v.z;
}

float rnd(uint h, uint k) {
	return float(phash(uvec3(h, k, salt)) & 0xFFFFFFu) / 16777216.0;
}

// Places this instance in its cell: position, a random turn, a random number r
// to test against a density, another (seed) for size and colour, and the
// distance fade. False if the cell is outside the field's bands.
bool scatter(int id, out vec3 pos, out mat3 basis, out float r, out float seed, out float fade) {
	ivec2 c0 = ivec2(floor(view_pos.xz / cell)) - ivec2(grid / 2);
	ivec2 c = c0 + ivec2(id % grid, id / grid);
	uint h = phash(uvec3(uvec2(c), 7u));
	vec2 p = (vec2(c) + vec2(rnd(h, 1u), rnd(h, 2u))) * cell;
	float d = distance(p, view_pos.xz);
	fade = smoothstep(fade_in_start, fade_in_end, d) * (1.0 - smoothstep(fade_out_start, fade_out_end, d));
	r = rnd(h, 3u);
	seed = rnd(h, 4u);
	pos = vec3(p.x, height_m(p, 0), p.y);
	float a = rnd(h, 5u) * TAU;
	basis = mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a)));
	return fade > 0.0;
}

vec4 mask_at(vec2 p) {
	return textureLod(mask_tex, map_uv(p), 0.0);
}

// Screen-door fade: true for the growing share of pixels to drop as a prop fades.
bool dithered_out(vec2 frag, float fade) {
	return fract(52.9829189 * fract(dot(frag, vec2(0.06711056, 0.00583715)))) > fade;
}
