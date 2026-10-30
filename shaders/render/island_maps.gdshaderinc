// The island's full-resolution maps (IslandData), shared by terrain and water.
// Heights are 32-bit floats, fetched texel by texel and filtered here (exact at
// any mip). Mip m's texel j is the mean of 2^m base samples, so its centre sits
// (2^m - 1) / 2 samples in from sample j * 2^m.

uniform sampler2D height_tex : filter_nearest_mipmap, repeat_disable;
uniform float map_size = 2048.0;     // samples per side
uniform float map_domain = 8192.0;   // metres per side
uniform vec2 map_origin = vec2(-4096.0); // world xz of sample (0, 0)
uniform vec3 view_pos;               // main camera (also during the shadow pass)

const float OCEAN_FLOOR = -95.0;

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

// The finest mip a pixel with this footprint (m per pixel) can show.
int pixel_mip(float footprint) {
	return clamp(int(floor(log2(max(footprint, 1e-3) / map_cell()))), 0, 10);
}

vec2 map_uv(vec2 p) {
	return (map_grid(p) + 0.5) / map_size;
}

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
	d = length(vec2(d, max(view_pos.y - 0.0, 0.0) * 0.5));
	morph = clamp((d - cd.y) / max(cd.z - cd.y, 1e-3), 0.0, 1.0);
	gp -= fract(gp * GRID * 0.5) * 2.0 / GRID * morph;
	return origin.xz + gp * cd.w;
}
