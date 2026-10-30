shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The terrain: CDLOD patches over one height map (no tiles, no near/far
// switch). Normals and materials are per pixel, from the finest mip the pixel
// can show, so detail fades smoothly with distance instead of popping.
//
// Materials come from the baked masks (rock, wetness, forest, sand): grass in
// broad patches, dark forest floor under the canopy (and, beyond where trees
// are drawn, the canopy's own colour, so forests don't end at a line), damp
// ground in hollows, rock on steep ground and crests, beaches, the sea floor.

#include "res://shaders/render/height_map.gdshaderinc"

uniform sampler2D mask_tex : filter_linear_mipmap, repeat_disable; // rock, wet, forest, sand
uniform float trees_end = 1800.0; // where the drawn trees have faded out

varying vec3 world_pos;

void vertex() {
	int lod;
	float morph;
	vec2 wp = cdlod_xz(VERTEX, MODEL_MATRIX, INSTANCE_CUSTOM, lod, morph);
	float h = height_m(wp, lod);
	if (morph > 0.0) h = mix(h, height_m(wp, lod + 1), morph);
	vec3 origin = MODEL_MATRIX[3].xyz;
	VERTEX = vec3(wp.x - origin.x, h - origin.y, wp.y - origin.z); // instances are only translated
	NORMAL = normal_m(wp, lod);
	world_pos = vec3(wp.x, h, wp.y);
}

// Integer hash and value noise (exact at any world coordinate).
float hash(ivec2 c) {
	uint v = uint(c.x) * 1597334677u ^ uint(c.y) * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	return float((v >> 22u) ^ v) / 4294967295.0;
}

float vnoise(vec2 p) {
	vec2 fi = floor(p);
	ivec2 i = ivec2(fi);
	vec2 f = p - fi;
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + ivec2(1, 0)), u.x), mix(hash(i + ivec2(0, 1)), hash(i + ivec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 p = world_pos.xz;
	float fp = max(length(fwidth(p)), 0.01);
	vec3 n = normal_m(p, pixel_mip(fp));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float h = world_pos.y;
	vec4 m = texture(mask_tex, map_uv(p));
	float dist = distance(world_pos, CAMERA_POSITION_WORLD);

	float patches = vnoise(p / 240.0) * 0.6 + vnoise(p / 60.0) * 0.4;
	vec3 grass = mix(vec3(0.26, 0.38, 0.13), vec3(0.40, 0.44, 0.20), clamp(patches * 1.2 - 0.2, 0.0, 1.0));
	vec3 forest_floor = vec3(0.17, 0.20, 0.10);
	vec3 canopy = mix(vec3(0.11, 0.22, 0.08), vec3(0.16, 0.27, 0.09), patches);
	vec3 rock = mix(vec3(0.30, 0.28, 0.25), vec3(0.46, 0.42, 0.37), vnoise(p / 9.0) * 0.6 + vnoise(p / 50.0) * 0.4);
	vec3 soil = vec3(0.32, 0.24, 0.16);
	vec3 sand = mix(vec3(0.74, 0.68, 0.52), vec3(0.82, 0.76, 0.58), patches);
	vec3 seabed = mix(vec3(0.64, 0.60, 0.46), vec3(0.40, 0.42, 0.36), smoothstep(-2.0, -20.0, h));

	vec3 col = grass;
	// Under the trees: forest floor near by; far away, where trees are no longer
	// drawn, the canopy colour takes over so a forest stays a forest.
	float far = smoothstep(trees_end * 0.75, trees_end, dist);
	col = mix(col, mix(forest_floor, canopy, far), smoothstep(0.2, 0.8, m.b));
	col = mix(col, mix(col, vec3(0.20, 0.30, 0.12), 0.6), m.g); // damp ground
	col = mix(col, soil, smoothstep(0.75, 0.55, n.y) * 0.6);
	float rocky = max(m.r, smoothstep(0.62, 0.45, n.y));
	col = mix(col, rock, rocky);
	col = mix(col, sand, m.a * (1.0 - rocky * 0.7));
	col = mix(col, seabed, 1.0 - smoothstep(-1.0, 0.2, h));
	col *= mix(1.0, 0.78, (1.0 - smoothstep(0.0, 0.6, h)) * step(-0.3, h)); // damp line
	float fine = mix(0.5, vnoise(p * 0.7), 1.0 - smoothstep(0.4, 1.2, fp * 0.7)) * 0.5
			+ mix(0.5, vnoise(p * 3.1), 1.0 - smoothstep(0.4, 1.2, fp * 3.1)) * 0.5;
	col *= 0.88 + 0.24 * fine;

	ALBEDO = pow(col, vec3(2.2));
	ROUGHNESS = mix(0.95, 0.82, rocky);
	SPECULAR = 0.25;
}
