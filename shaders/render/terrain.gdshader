shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The terrain: CDLOD patches over one height map (no tiles, no near/far
// switch). Normals and materials are per pixel, from the finest mip the pixel
// can show, so detail fades smoothly with distance instead of popping.
//
// Materials by biome (biome_ground(): forest, mesa, prairie, swamp, tundra,
// taiga, plateau, volcano, mountains, island, coast), blended across their
// borders; within each, ground in broad patches and small clumps, bare rock
// on near-cliffs (banded red sandstone on the mesas and plateaus), snow high
// up in the north; then beaches, the damp line and the sea floor.

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

// Biomes (tools/map/bake_biomes.py): index into
// forest, mesa, prairie, swamp, tundra, taiga, plateau, volcano, mountains,
// island, coast; 255 none.
uniform sampler2D biome_tex : filter_nearest, repeat_disable;

struct Shared {
	vec2 p;
	float h;
	vec3 n;
	vec4 m;
	float fp;
	float patches;
	float fine3;
	float n9;
	float n35;
	float clumps;
	float clump_blur;
	float strata;
};

// Clumps of something (scrub, pinyon, puddles) covering `cover` of the ground.
float clump(Shared s, float cover) {
	return mix(cover, smoothstep(1.0 - cover - 0.04, 1.0 - cover + 0.04, s.clumps), s.clump_blur);
}

// Banded sandstone, as in canyon walls: reds, orange and pale bands with height.
vec3 sandstone(Shared s) {
	vec3 a = mix(vec3(0.56, 0.24, 0.13), vec3(0.72, 0.38, 0.21), s.strata);
	vec3 pale = vec3(0.82, 0.66, 0.50);
	a = mix(a, pale, smoothstep(0.88, 0.96, s.strata) * 0.8);
	return a * (0.85 + 0.3 * s.n9);
}

// A biome's ground colour, roughness and how bare (rock) it is here.
vec3 biome_ground(int b, Shared s, out float rough, out float rocky) {
	float steep = smoothstep(0.5, 0.32, s.n.y);       // near-cliffs go bare
	vec3 ground;
	vec3 rock = mix(vec3(0.24, 0.23, 0.22), vec3(0.38, 0.36, 0.33), s.n9);
	rough = 0.95;
	if (b == 0) {            // forest: dark leaf litter and undergrowth
		ground = mix(vec3(0.09, 0.18, 0.06), vec3(0.16, 0.26, 0.09), s.patches);
		ground = mix(ground, vec3(0.20, 0.17, 0.09), clump(s, 0.15)); // clearings of litter
		rock = mix(rock, vec3(0.16, 0.21, 0.13), 0.6);                // mossy
	} else if (b == 1) {     // mesa: red sand, scattered dark scrub
		ground = mix(vec3(0.55, 0.27, 0.12), vec3(0.66, 0.37, 0.18), s.patches);
		ground = mix(ground, vec3(0.20, 0.25, 0.12), clump(s, 0.18));
		rock = sandstone(s);
		steep = smoothstep(0.62, 0.42, s.n.y);
	} else if (b == 2) {     // prairie: golden-green grass in broad patches
		ground = mix(vec3(0.44, 0.45, 0.20), vec3(0.58, 0.52, 0.26), s.patches);
		ground = mix(ground, vec3(0.30, 0.40, 0.15), s.m.g * 0.6);   // greener where it's wetter
		ground = mix(ground, vec3(0.62, 0.55, 0.30), clump(s, 0.12) * 0.6);
	} else if (b == 3) {     // swamp: dark mud and moss, standing water
		ground = mix(vec3(0.15, 0.16, 0.09), vec3(0.22, 0.25, 0.12), s.patches);
		float pools = clump(s, 0.3);
		ground = mix(ground, vec3(0.05, 0.08, 0.07), pools);
		rough = mix(0.9, 0.15, pools);
	} else if (b == 4) {     // tundra: grey-green moss and lichen, snow higher up
		ground = mix(vec3(0.40, 0.42, 0.33), vec3(0.52, 0.50, 0.40), s.patches);
		ground = mix(ground, vec3(0.55, 0.42, 0.30), clump(s, 0.1) * 0.5);  // rust lichen
		float snow = smoothstep(80.0, 260.0, s.h + (s.patches - 0.5) * 120.0) * smoothstep(0.55, 0.8, s.n.y);
		ground = mix(ground, vec3(0.92, 0.94, 0.97), snow);
		rock = vec3(0.36, 0.36, 0.37) * (0.85 + 0.3 * s.n9);
		rough = mix(0.95, 0.6, snow);
	} else if (b == 5) {     // taiga: dark conifer floor, grey rock
		ground = mix(vec3(0.07, 0.13, 0.09), vec3(0.12, 0.19, 0.12), s.patches);
		ground = mix(ground, vec3(0.30, 0.29, 0.24), clump(s, 0.12));  // rocky openings
		rock = vec3(0.32, 0.32, 0.31) * (0.85 + 0.3 * s.n9);
		float snow = smoothstep(1100.0, 1500.0, s.h + (s.patches - 0.5) * 200.0) * smoothstep(0.5, 0.75, s.n.y);
		ground = mix(ground, vec3(0.9, 0.92, 0.95), snow);
	} else if (b == 6) {     // plateau: scrubby tan caprock, red banded walls, red talus
		ground = mix(vec3(0.60, 0.50, 0.34), vec3(0.68, 0.56, 0.38), s.patches);
		ground = mix(ground, vec3(0.15, 0.21, 0.11), clump(s, 0.35));  // pinyon and juniper
		float talus = smoothstep(0.93, 0.8, s.n.y);
		ground = mix(ground, vec3(0.58, 0.32, 0.19) * (0.85 + 0.3 * s.fine3), talus);
		rock = sandstone(s);
		steep = smoothstep(0.7, 0.45, s.n.y);
	} else if (b == 7) {     // volcano: black basalt and ash, rust oxides
		ground = mix(vec3(0.07, 0.07, 0.07), vec3(0.20, 0.19, 0.18), s.patches);
		ground = mix(ground, vec3(0.38, 0.15, 0.08), smoothstep(0.6, 0.8, s.n35) * 0.7);
		rock = mix(vec3(0.06, 0.06, 0.06), vec3(0.16, 0.14, 0.13), s.n9);
		float snow = smoothstep(250.0, 500.0, s.h) * smoothstep(0.6, 0.85, s.n.y);
		ground = mix(ground, vec3(0.9, 0.92, 0.95), snow);
		rough = 0.85;
	} else if (b == 8) {     // mountains: grey
		ground = mix(vec3(0.36, 0.35, 0.30), vec3(0.44, 0.42, 0.36), s.patches);
	} else if (b == 9) {     // island: bright tropical green
		ground = mix(vec3(0.24, 0.42, 0.13), vec3(0.34, 0.52, 0.18), s.patches);
		ground = mix(ground, vec3(0.16, 0.30, 0.09), clump(s, 0.25));
	} else if (b == 10) {    // coast: beach sand above the tide, dune grass behind
		vec3 sandc = mix(vec3(0.84, 0.78, 0.63), vec3(0.90, 0.85, 0.72), s.patches);
		vec3 dune = mix(vec3(0.58, 0.57, 0.38), vec3(0.66, 0.62, 0.42), s.patches);
		ground = mix(sandc, dune, smoothstep(3.0, 14.0, s.h + (s.n35 - 0.5) * 8.0));
		ground = mix(ground, vec3(0.42, 0.46, 0.25), clump(s, 0.2) * smoothstep(3.0, 14.0, s.h));
	} else {                 // none: the old dry lowlands, green highlands, lava
		vec3 arid = mix(vec3(0.50, 0.45, 0.33), vec3(0.42, 0.42, 0.30), clamp(s.patches * 1.3 - 0.2, 0.0, 1.0));
		vec3 humid = mix(vec3(0.13, 0.27, 0.09), vec3(0.20, 0.34, 0.12), s.patches);
		ground = mix(arid, humid, smoothstep(0.1, 0.8, s.m.g));
		vec3 lava = mix(vec3(0.10, 0.09, 0.09), vec3(0.24, 0.15, 0.11), smoothstep(0.55, 0.85, s.n35));
		ground = mix(ground, lava, s.m.r);
		rock = mix(rock, vec3(0.14, 0.20, 0.11), s.m.g * 0.7);
	}
	ground *= 0.9 + 0.2 * s.fine3;
	ground = mix(ground, vec3(0.36, 0.27, 0.19), smoothstep(0.75, 0.55, s.n.y) * 0.35); // soil on banks
	rocky = steep;
	rough = mix(rough, 0.82, steep);
	return mix(ground, rock, steep);
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
	Shared sh;
	sh.p = p;
	sh.h = h;
	sh.n = n;
	sh.m = m;
	sh.fp = fp;
	sh.patches = patches;
	sh.fine3 = fine3;
	sh.n9 = vnoise(p / 9.0) * 0.6 + vnoise(p / 50.0) * 0.4;
	sh.n35 = vnoise(p / 35.0);
	// small clumps (scrub, pinyon, puddles): a few metres across, averaged to
	// their cover once smaller than the pixel
	float clump_detail = 1.0 - smoothstep(1.5, 5.0, fp);
	sh.clumps = mix(0.5, vnoise(p / 4.0) * 0.7 + vnoise(p / 1.7) * 0.3, clump_detail);
	sh.clump_blur = clump_detail;
	sh.strata = 0.5 + 0.5 * sin(h * 0.42 + (vnoise(p / 300.0) - 0.5) * 6.0) * (0.6 + 0.4 * vnoise(vec2(h * 0.3, p.x / 400.0)));

	// The biome here: the four nearest texels of the biome map blended by
	// distance, the point jittered so borders wander instead of running straight.
	vec2 jit = (vec2(vnoise(p / 70.0), vnoise(p / 70.0 + 31.7)) - 0.5) * 140.0
			+ (vec2(vnoise(p / 19.0 + 5.1), vnoise(p / 19.0 - 8.3)) - 0.5) * 40.0;
	vec2 bsz = vec2(textureSize(biome_tex, 0));
	vec2 bg = (p + jit - map_origin) / (map_domain + map_cell()) * bsz - 0.5;
	ivec2 b0 = ivec2(floor(bg));
	vec2 bf = bg - floor(bg);
	vec3 col = vec3(0.0);
	float rough = 0.0;
	float rocky = 0.0;
	for (int k = 0; k < 4; k++) {
		ivec2 o = ivec2(k & 1, k >> 1);
		float w = (o.x == 1 ? bf.x : 1.0 - bf.x) * (o.y == 1 ? bf.y : 1.0 - bf.y);
		if (w <= 0.0)
			continue;
		int b = int(texelFetch(biome_tex, clamp(b0 + o, ivec2(0), ivec2(bsz) - 1), 0).r * 255.0 + 0.5);
		float r_, k_;
		col += biome_ground(b, sh, r_, k_) * w;
		rough += r_ * w;
		rocky += k_ * w;
	}

	vec3 sand = mix(vec3(0.84, 0.80, 0.68), vec3(0.90, 0.86, 0.74), patches);
	vec3 seabed = mix(vec3(0.70, 0.68, 0.56), vec3(0.42, 0.44, 0.40), smoothstep(-2.0, -25.0, h));
	col = mix(col, sand, m.a * (1.0 - rocky * 0.7));
	col = mix(col, seabed, 1.0 - smoothstep(-1.0, 0.2, h));
	col *= mix(1.0, 0.78, (1.0 - smoothstep(0.0, 0.6, h)) * step(-0.3, h)); // damp line
	float fine = mix(0.5, vnoise(p * 0.7), 1.0 - smoothstep(0.4, 1.2, fp * 0.7));
	col *= 0.92 + 0.16 * fine;

	ALBEDO = pow(col, vec3(2.2));
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
	ROUGHNESS = rough;
	SPECULAR = 0.25;
}
