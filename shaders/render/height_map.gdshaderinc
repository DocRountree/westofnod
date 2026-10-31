// The world height map (WorldData), shared by terrain, water and scattered props.
// terrain_height() is the ground as drawn, the same function as
// WorldData.height_at(): a cubic B-spline through the samples plus procedural
// relief below their resolution. height_m() is the plain bilinear map (the sea
// uses it for depth).
// Heights are 32-bit floats, fetched texel by texel and filtered here (exact at
// any mip). Mip m's texel j is the mean of 2^m base samples, so its centre sits
// (2^m - 1) / 2 samples in from sample j * 2^m.

uniform sampler2D height_tex : filter_nearest_mipmap, repeat_disable;
uniform float map_size = 2048.0;     // samples per side
uniform float map_domain = 8192.0;   // metres per side
uniform vec2 map_origin = vec2(-4096.0); // world xz of sample (0, 0)
uniform vec3 view_pos;               // main camera (also during the shadow pass)
// Magnification (the telescope): detail is chosen as if everything were this
// many times nearer, so it holds up when magnified.
uniform float lod_zoom = 1.0;

const float OCEAN_FLOOR = -300.0;
// Below the data: three octaves of value noise (wavelength m, amplitude m), as
// WorldData.DETAIL; each fades out with distance once too fine to matter.
const vec2 DETAIL[3] = vec2[](vec2(40.0, 3.0), vec2(15.0, 1.1), vec2(6.0, 0.4));

float map_cell() {
	return map_domain / (map_size - 1.0);
}

// Grid coordinates (in base samples) of world xz.
vec2 map_grid(vec2 p) {
	return (p - map_origin) / map_cell();
}

float fetch_m(sampler2D tex, ivec2 c, int m) {
	int n = int(map_size) >> m;
	c = clamp(c, ivec2(0), ivec2(n - 1));
	return texelFetch(tex, c, m).r;
}

// Bilinear value of a float map at world xz from mip m. Outside the domain:
// the sea floor (heights) / far below it (water).
float sample_m(sampler2D tex, vec2 p, int m, float outside) {
	vec2 g = map_grid(p);
	if (g.x < 0.0 || g.y < 0.0 || g.x > map_size - 1.0 || g.y > map_size - 1.0) return outside;
	float scale = exp2(float(m));
	g = (g - (scale - 1.0) * 0.5) / scale;
	vec2 i = floor(g);
	vec2 f = g - i;
	ivec2 c = ivec2(i);
	float a = fetch_m(tex, c, m);
	float b = fetch_m(tex, c + ivec2(1, 0), m);
	float d = fetch_m(tex, c + ivec2(0, 1), m);
	float e = fetch_m(tex, c + ivec2(1, 1), m);
	return mix(mix(a, b, f.x), mix(d, e, f.x), f.y);
}

float height_m(vec2 p, int m) {
	return sample_m(height_tex, p, m, OCEAN_FLOOR);
}

vec3 normal_m(vec2 p, int m) {
	float s = map_cell() * exp2(float(m));
	float hx = height_m(p + vec2(s, 0.0), m) - height_m(p - vec2(s, 0.0), m);
	float hz = height_m(p + vec2(0.0, s), m) - height_m(p - vec2(0.0, s), m);
	return normalize(vec3(-hx, 2.0 * s, -hz));
}

float hm_hash(ivec2 c) {
	uint v = uint(c.x) * 1597334677u ^ uint(c.y) * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	return float((v >> 22u) ^ v) / 4294967295.0;
}

float hm_vnoise(vec2 p) {
	vec2 fi = floor(p);
	ivec2 i = ivec2(fi);
	vec2 f = p - fi;
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hm_hash(i), hm_hash(i + ivec2(1, 0)), u.x), mix(hm_hash(i + ivec2(0, 1)), hm_hash(i + ivec2(1, 1)), u.x), u.y);
}

vec4 bspline(float t) {
	float t2 = t * t;
	float t3 = t2 * t;
	float s = 1.0 - t;
	return vec4(s * s * s, 3.0 * t3 - 6.0 * t2 + 4.0, -3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0, t3) / 6.0;
}

// The data's smooth surface from mip m: a uniform cubic B-spline.
float base_height(vec2 p, int m) {
	vec2 g = map_grid(p);
	if (g.x < -2.0 || g.y < -2.0 || g.x > map_size + 1.0 || g.y > map_size + 1.0) return OCEAN_FLOOR;
	float scale = exp2(float(m));
	g = (g - (scale - 1.0) * 0.5) / scale;
	vec2 fi = floor(g);
	ivec2 c = ivec2(fi);
	vec4 wx = bspline(g.x - fi.x);
	vec4 wz = bspline(g.y - fi.y);
	float h = 0.0;
	for (int b = 0; b < 4; b++) {
		float row = 0.0;
		for (int a = 0; a < 4; a++) {
			row += fetch_m(height_tex, c + ivec2(a - 1, b - 1), m) * wx[a];
		}
		h += row * wz[b];
	}
	return h;
}

// Relief below the data, each octave faded out with distance from the main
// camera (not with the LOD level, so neighbouring levels agree).
float terrain_detail(vec2 p) {
	float dist = distance(p, view_pos.xz) / lod_zoom;
	float d = 0.0;
	for (int k = 0; k < 3; k++) {
		float fade = 1.0 - smoothstep(DETAIL[k].x * 25.0, DETAIL[k].x * 40.0, dist);
		if (fade <= 0.0) continue;
		d += (hm_vnoise(p / DETAIL[k].x + vec2(17.0 * float(k), -9.0 * float(k))) - 0.5) * 2.0 * DETAIL[k].y * fade;
	}
	return d;
}

// The ground as drawn: the data's surface from mip m, plus the relief (on land).
float terrain_height(vec2 p, int m) {
	float b = base_height(p, m);
	return b + terrain_detail(p) * clamp((b - 0.5) / 3.0, 0.0, 1.0);
}

vec3 terrain_normal(vec2 p, int m, float e) {
	float hx = terrain_height(p + vec2(e, 0.0), m) - terrain_height(p - vec2(e, 0.0), m);
	float hz = terrain_height(p + vec2(0.0, e), m) - terrain_height(p - vec2(0.0, e), m);
	return normalize(vec3(-hx, 2.0 * e, -hz));
}

// The finest mip a pixel with this footprint (m per pixel) can show.
int pixel_mip(float footprint) {
	return clamp(int(floor(log2(max(footprint, 1e-3) / map_cell()))), 0, 10);
}

vec2 map_uv(vec2 p) {
	return (map_grid(p) + 0.5) / map_size;
}

// The CDLOD levels finer than the data: level `lod` reads mip max(lod - SUB, 0).
const int SUB = 3;

// ---- CDLOD patches: every patch is the same grid of GRID x GRID quads over
// [0, 1]^2, placed and scaled per instance. INSTANCE_CUSTOM = (lod, morph start,
// morph end, patch size). Near the far end of its range a vertex slides onto
// the next coarser grid and blends to the next mip, so neighbouring levels meet
// without cracks or pops (Strugar, "Continuous Distance-Dependent Level of
// Detail").
const float GRID = 32.0;

// Returns world xz of the (morphed) vertex; lod and morph out.
vec2 cdlod_xz(vec3 vertex, mat4 model, vec4 cd, out int lod, out float morph) {
	vec3 origin = model[3].xyz;
	vec2 gp = vertex.xz;
	vec2 wp = origin.xz + gp * cd.w;
	lod = int(cd.x + 0.5);
	float d = distance(vec3(wp.x, 0.0, wp.y), vec3(view_pos.x, 0.0, view_pos.z));
	d = length(vec2(d, max(view_pos.y - 0.0, 0.0) * 0.5)) / lod_zoom;
	morph = clamp((d - cd.y) / max(cd.z - cd.y, 1e-3), 0.0, 1.0);
	gp -= fract(gp * GRID * 0.5) * 2.0 / GRID * morph;
	return origin.xz + gp * cd.w;
}
