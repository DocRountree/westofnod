// The ground's colour, shared by the terrain (terrain.gdshader) and what
// grows on it (ground_cover.gdshader: grass, ferns), so a tuft is the colour
// of the ground it stands on and fades into it unseen. Needs
// height_map.gdshaderinc (biome_tex, map_*) first.

uniform sampler2D mask_tex : filter_linear_mipmap, repeat_disable; // rock, wet, forest, sand

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
// (biome_tex: declared in height_map.gdshaderinc)

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

// Mud, in the forest (and the prairie's lowlands): bare, damp patches a metre or a few across, breaking
// up the litter and the grass (more where the ground is wetter); darker,
// wetter in the middle of the bigger ones. 0..1 (puddle: 0..1 within it). Nothing grows on it
// (ground_cover_bake.gdshader asks here too). Past a few metres a pixel
// its patches average out to their share of the ground.
//
// The prairie's lowlands too: the flat bottoms of its hollows (the ground a
// metre or more below the land round it, over a few hundred metres: the
// height map's coarser mip), muddier the deeper.
float biome_mud(int b, Shared s, out float puddle) {
	puddle = 0.0;
	float from;
	float far_share = 0.08; // (what a pixel too big for the patches gets)
	if (b == 0) {
		from = 0.71 - 0.05 * s.m.g;
	} else if (b == 2) {
		float low = smoothstep(1.0, 4.5, terrain_height(s.p, 3) - s.h) * smoothstep(0.9, 0.97, s.n.y);
		if (low <= 0.0)
			return 0.0;
		from = 1.02 - 0.3 * low;
		far_share = 0.05 * low;
	} else {
		return 0.0;
	}
	float n = vnoise(s.p / 5.0 + 41.0) * 0.6 + vnoise(s.p / 1.7 - 17.0) * 0.3 + vnoise(s.p / 0.6) * 0.1;
	float detail = 1.0 - smoothstep(1.0, 4.0, s.fp);
	float mud = mix(far_share, smoothstep(from, from + 0.02, n), detail);
	puddle = smoothstep(from + 0.09, from + 0.11, n) * detail;
	return mud;
}

// The taiga's floor: how much of it is fallen needles (the rest moss), in
// mottles of a few to tens of metres; most of it.
float taiga_needles(Shared s) {
	float mottle = s.n9 * 0.55 + s.fine3 * 0.45;
	return smoothstep(0.24, 0.44, mottle);
}

// A biome's ground colour, roughness, how bare (rock) it is here, and how
// much of it is leaf litter (the forest's brown patches: terrain.gdshader
// lays the fallen leaves' texture over them).
vec3 biome_ground(int b, Shared s, out float rough, out float rocky, out float litter) {
	litter = 0.0;
	float steep = smoothstep(0.5, 0.32, s.n.y);       // near-cliffs go bare
	vec3 ground;
	vec3 rock = mix(vec3(0.24, 0.23, 0.22), vec3(0.38, 0.36, 0.33), s.n9);
	rough = 0.95;
	if (b == 0) {            // forest: olive undergrowth mottled with leaf litter and humus
		// greens toward olive (red close to green), darker in the broad patches
		vec3 olive = mix(vec3(0.13, 0.15, 0.07), vec3(0.22, 0.23, 0.11), s.patches);
		olive = mix(olive, vec3(0.17, 0.21, 0.09), smoothstep(0.55, 0.8, s.n35) * 0.6); // greener drifts
		// litter in mottles of a few to tens of metres: tan, red-brown, dark humus
		float mottle = s.n9 * 0.55 + s.fine3 * 0.45;
		vec3 litter_c = mix(vec3(0.2, 0.17, 0.1), vec3(0.22, 0.15, 0.09), s.n35);   // dry oak leaves, dun to russet
		litter_c = mix(litter_c, vec3(0.12, 0.1, 0.06), smoothstep(0.55, 0.85, s.fine3) * 0.7); // humus
		litter = smoothstep(0.48, 0.72, mottle);
		ground = mix(olive, litter_c, litter * 0.7);
		float pud;
		float mud = biome_mud(b, s, pud);
		ground = mix(ground, mix(vec3(0.11, 0.085, 0.06), vec3(0.06, 0.05, 0.035), pud) * (0.9 + 0.2 * s.fine3), mud);
		rough = mix(rough, 0.85, mud); // (matte: damp, not shiny)
		litter *= 1.0 - mud;
		ground = mix(ground, vec3(0.2, 0.24, 0.1), clump(s, 0.1) * 0.7);          // moss and seedlings
		ground = mix(ground, vec3(0.11, 0.09, 0.06), clump(s, 0.06) * 0.35);       // damp hollows
		ground *= 0.9 + 0.2 * s.fine3;
		rock = mix(rock, vec3(0.18, 0.2, 0.12), 0.6);                             // mossy
	} else if (b == 1) {     // mesa: red sand, scattered dark scrub
		ground = mix(vec3(0.55, 0.27, 0.12), vec3(0.66, 0.37, 0.18), s.patches);
		ground = mix(ground, vec3(0.20, 0.25, 0.12), clump(s, 0.18));
		rock = sandstone(s);
		steep = smoothstep(0.62, 0.42, s.n.y);
	} else if (b == 2) {     // prairie: golden-green grass in broad patches
		ground = mix(vec3(0.44, 0.45, 0.20), vec3(0.58, 0.52, 0.26), s.patches);
		ground = mix(ground, vec3(0.30, 0.40, 0.15), s.m.g * 0.6);   // greener where it's wetter
		ground = mix(ground, vec3(0.62, 0.55, 0.30), clump(s, 0.12) * 0.6);
		// mud in its lowlands (biome_mud), greyer than the forest's, puddles darker
		float pud;
		float mud = biome_mud(b, s, pud);
		ground = mix(ground, mix(vec3(0.21, 0.17, 0.12), vec3(0.1, 0.085, 0.065), pud) * (0.9 + 0.2 * s.fine3), mud);
		rough = mix(rough, 0.85, mud);
	} else if (b == 3) {     // swamp: dark mud and moss, standing water
		ground = mix(vec3(0.15, 0.16, 0.09), vec3(0.22, 0.25, 0.12), s.patches);
		float pools = clump(s, 0.6);                                    // mostly water
		ground = mix(ground, vec3(0.04, 0.07, 0.07), pools);
		rough = mix(0.9, 0.08, pools);
	} else if (b == 4) {     // tundra: grey-green moss and lichen, snow higher up
		ground = mix(vec3(0.40, 0.42, 0.33), vec3(0.52, 0.50, 0.40), s.patches);
		ground = mix(ground, vec3(0.55, 0.42, 0.30), clump(s, 0.1) * 0.5);  // rust lichen
		float snow = smoothstep(80.0, 260.0, s.h + (s.patches - 0.5) * 120.0) * smoothstep(0.55, 0.8, s.n.y);
		ground = mix(ground, vec3(0.92, 0.94, 0.97), snow);
		rock = vec3(0.36, 0.36, 0.37) * (0.85 + 0.3 * s.n9);
		rough = mix(0.95, 0.6, snow);
	} else if (b == 5) {     // taiga: needle duff and moss, grey rock
		// rusty brown fallen needles in mottles (terrain.gdshader lays the
		// needles' texture over them: litter, as the forest's leaves),
		// feather moss, dark green, between
		vec3 moss = mix(vec3(0.12, 0.17, 0.08), vec3(0.17, 0.23, 0.1), s.patches);
		vec3 duff = mix(vec3(0.22, 0.17, 0.115), vec3(0.28, 0.215, 0.15), s.n35); // (grey-brown, a little rusty)
		duff = mix(duff, vec3(0.13, 0.095, 0.06), smoothstep(0.6, 0.85, s.fine3) * 0.5); // damp, darker
		litter = taiga_needles(s);
		ground = mix(moss, duff, litter);
		ground = mix(ground, vec3(0.30, 0.29, 0.24), clump(s, 0.12));  // rocky openings
		litter *= 1.0 - clump(s, 0.12);
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


// The noise fields biome_ground() reads, at p (fp: metres per pixel, for
// fading out what's finer than that).
Shared ground_shared(vec2 p, float h, vec3 n, vec4 m, float fp) {
	Shared sh;
	sh.p = p;
	sh.h = h;
	sh.n = n;
	sh.m = m;
	sh.fp = fp;
	sh.patches = vnoise(p / 240.0) * 0.6 + vnoise(p / 60.0) * 0.4;
	sh.fine3 = mix(0.5, vnoise(p / 3.0), 1.0 - smoothstep(0.5, 1.5, fp / 3.0));
	sh.n9 = vnoise(p / 9.0) * 0.6 + vnoise(p / 50.0) * 0.4;
	sh.n35 = vnoise(p / 35.0);
	// small clumps (scrub, pinyon, puddles): a few metres across, averaged to
	// their cover once smaller than the pixel
	float clump_detail = 1.0 - smoothstep(1.5, 5.0, fp);
	sh.clumps = mix(0.5, vnoise(p / 4.0) * 0.7 + vnoise(p / 1.7) * 0.3, clump_detail);
	sh.clump_blur = clump_detail;
	sh.strata = 0.5 + 0.5 * sin(h * 0.42 + (vnoise(p / 300.0) - 0.5) * 6.0) * (0.6 + 0.4 * vnoise(vec2(h * 0.3, p.x / 400.0)));
	return sh;
}

// Where the biome map is read for p: jittered, so borders wander instead of
// running straight along its texels, and reach out into each other in
// tongues and islands. Then the sixteen nearest texels blend
// (biome_texel()).
vec2 biome_grid(vec2 p) {
	// (three scales: kilometre tongues and islands, then the smaller wander;
	// WorldData.biome_blend_at the same)
	vec2 jit = (vec2(vnoise(p / 1400.0 + 3.3), vnoise(p / 1400.0 - 12.9)) - 0.5) * 1100.0
			+ (vec2(vnoise(p / 90.0), vnoise(p / 90.0 + 31.7)) - 0.5) * 180.0
			+ (vec2(vnoise(p / 23.0 + 5.1), vnoise(p / 23.0 - 8.3)) - 0.5) * 50.0;
	vec2 bsz = vec2(textureSize(biome_tex, 0));
	return (p + jit - map_origin) / (map_domain + map_cell()) * bsz - 0.5;
}

// Cubic B-spline weights for the four texels round a fraction f.
vec4 bspline4(float f) {
	float f2 = f * f, f3 = f2 * f;
	return vec4((1.0 - f) * (1.0 - f) * (1.0 - f), 3.0 * f3 - 6.0 * f2 + 4.0, -3.0 * f3 + 3.0 * f2 + 3.0 * f + 1.0, f3) / 6.0;
}

const int BIOME_TAPS = 16;

// Biome texel k (0-15) of the four by four round g, and its weight (a cubic
// B-spline: a border takes about three texels, 200 m, to go over from one
// biome to the next, smoothly, where the four nearest made it 68 m).
int biome_texel(vec2 g, int k, out float w) {
	vec2 bsz = vec2(textureSize(biome_tex, 0));
	ivec2 b0 = ivec2(floor(g)) - 1;
	vec2 bf = g - floor(g);
	ivec2 o = ivec2(k & 3, k >> 2);
	vec4 wx = bspline4(bf.x), wy = bspline4(bf.y);
	w = wx[o.x] * wy[o.y];
	return int(texelFetch(biome_tex, clamp(b0 + o, ivec2(0), ivec2(bsz) - 1), 0).r * 255.0 + 0.5);
}

// The two biomes with most of the sixteen texels' weight round g (biome_grid),
// and their shares (summing to 1), so the ground works out at most two
// biomes a pixel (terrain.gdshader, ground_cover_bake.gdshader). Where a
// third reaches in (three borders meeting) the two give up its share
// between them smoothly: each less the third's weight, so none jumps in
// or out as they trade places. (Gathered in plain variables, not an array
// indexed by biome: that put every pixel's array in slow memory.)
void biome_top(vec2 g, out int b1, out float w1, out int b2, out float w2) {
	int s0 = -1, s1 = -1, s2 = -1, s3 = -1;
	float a0 = 0.0, a1 = 0.0, a2 = 0.0, a3 = 0.0;
	ivec2 hi = textureSize(biome_tex, 0) - 1;
	ivec2 c0 = ivec2(floor(g)) - 1;
	vec4 wx = bspline4(g.x - floor(g.x)), wy = bspline4(g.y - floor(g.y));
	for (int k = 0; k < BIOME_TAPS; k++) {
		ivec2 o = ivec2(k & 3, k >> 2);
		float w = wx[o.x] * wy[o.y];
		int b = int(texelFetch(biome_tex, clamp(c0 + o, ivec2(0), hi), 0).r * 255.0 + 0.5);
		if (s0 < 0 || b == s0) {
			s0 = b;
			a0 += w;
		} else if (s1 < 0 || b == s1) {
			s1 = b;
			a1 += w;
		} else if (s2 < 0 || b == s2) {
			s2 = b;
			a2 += w;
		} else { // (a fifth: as good as never)
			s3 = b;
			a3 += w;
		}
	}
	// the most first (a few swaps)
	if (a1 > a0) { float t = a0; a0 = a1; a1 = t; int u = s0; s0 = s1; s1 = u; }
	if (a2 > a1) { float t = a1; a1 = a2; a2 = t; int u = s1; s1 = s2; s2 = u; }
	if (a1 > a0) { float t = a0; a0 = a1; a1 = t; int u = s0; s0 = s1; s1 = u; }
	float third = max(a2, a3);
	w1 = a0 - third;
	w2 = max(a1 - third, 0.0);
	float sum = max(w1 + w2, 1e-6);
	w1 /= sum;
	w2 /= sum;
	b1 = s0;
	b2 = s1 < 0 ? s0 : s1;
}

