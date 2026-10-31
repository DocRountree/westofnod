shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The terrain: CDLOD patches over one height map (no tiles, no near/far
// switch). Normals and materials are per pixel, from the finest mip the pixel
// can show, so detail fades smoothly with distance instead of popping.
//
// Materials come from the baked masks (lava, humid, trees (unused for now),
// sand): ground in broad patches, damp ground in hollows, rock on steep
// ground and crests, beaches, the sea floor.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"

uniform sampler2D mask_tex : filter_linear_mipmap, repeat_disable; // rock, wet, forest, sand
uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);

varying vec3 world_pos;

void vertex() {
	int lod;
	float morph;
	vec2 wp = cdlod_xz(VERTEX, MODEL_MATRIX, INSTANCE_CUSTOM, lod, morph);
	float h = terrain_height(wp, max(lod - SUB, 0));
	if (morph > 0.0) h = mix(h, terrain_height(wp, max(lod + 1 - SUB, 0)), morph);
	vec3 origin = MODEL_MATRIX[3].xyz;
	VERTEX = vec3(wp.x - origin.x, h - origin.y, wp.y - origin.z); // instances are only translated
	NORMAL = terrain_normal(wp, max(lod - SUB, 0), map_cell() * exp2(float(max(lod - SUB, 0))) * 0.5);
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
	int pm = pixel_mip(fp);
	vec3 n = terrain_normal(p, pm, max(fp, 0.5) * 1.5 + map_cell() * exp2(float(pm)) * 0.25);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float h = world_pos.y;
	vec4 m = texture(mask_tex, map_uv(p));

	float patches = vnoise(p / 240.0) * 0.6 + vnoise(p / 60.0) * 0.4;
	float fine3 = mix(0.5, vnoise(p / 3.0), 1.0 - smoothstep(0.5, 1.5, fp / 3.0));
	// The Galapagos: dusty arid scrub on the lowlands, green humid highlands,
	// black and rust-brown lava, pale coral sand, a turquoise shallow sea floor.
	vec3 arid = mix(vec3(0.50, 0.45, 0.33), vec3(0.42, 0.42, 0.30), clamp(patches * 1.3 - 0.2, 0.0, 1.0));
	vec3 humid = mix(vec3(0.13, 0.27, 0.09), vec3(0.20, 0.34, 0.12), patches); // dark green highland cover
	vec3 lava = mix(vec3(0.10, 0.09, 0.09), vec3(0.24, 0.15, 0.11), smoothstep(0.55, 0.85, vnoise(p / 35.0)));
	lava *= 0.85 + 0.3 * fine3;
	vec3 rock = mix(vec3(0.20, 0.19, 0.18), vec3(0.34, 0.31, 0.28), vnoise(p / 9.0) * 0.6 + vnoise(p / 50.0) * 0.4);
	rock = mix(rock, vec3(0.14, 0.20, 0.11), m.g * 0.7); // mossy where it's wet
	vec3 soil = vec3(0.36, 0.27, 0.19);
	vec3 sand = mix(vec3(0.84, 0.80, 0.68), vec3(0.90, 0.86, 0.74), patches);
	vec3 seabed = mix(vec3(0.70, 0.68, 0.56), vec3(0.42, 0.44, 0.40), smoothstep(-2.0, -25.0, h));

	vec3 col = mix(arid, humid, smoothstep(0.1, 0.8, m.g));
	col *= 0.9 + 0.2 * fine3;
	col = mix(col, soil, smoothstep(0.75, 0.55, n.y) * 0.5);
	col = mix(col, lava, m.r);
	float rocky = smoothstep(0.5, 0.32, n.y); // only near-cliffs go bare
	col = mix(col, rock, rocky);

	col = mix(col, sand, m.a * (1.0 - rocky * 0.7));
	col = mix(col, seabed, 1.0 - smoothstep(-1.0, 0.2, h));
	col *= mix(1.0, 0.78, (1.0 - smoothstep(0.0, 0.6, h)) * step(-0.3, h)); // damp line
	float fine = mix(0.5, vnoise(p * 0.7), 1.0 - smoothstep(0.4, 1.2, fp * 0.7));
	col *= 0.92 + 0.16 * fine;

	ALBEDO = pow(col, vec3(2.2));
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
	ROUGHNESS = mix(0.95, 0.82, rocky);
	SPECULAR = 0.25;
}
