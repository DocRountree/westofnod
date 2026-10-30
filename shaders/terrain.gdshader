shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Terrain tiles. Meshes carry positions only; everything else is per pixel from
// two small textures per tile (TerrainMesher.textures(), over the vertex grid
// plus a one-vertex ring): heights, filtered by hand (32-bit float), for the
// normal and dug depth, and attributes (floodplain, gully depth, channel cut,
// water coverage),
// filtered by the hardware. So slopes, rock, soil and river beds vary smoothly
// within each triangle instead of following the 1 m mesh grid.
//
// Colour regions come from large-scale noise only; fine noise just mottles the
// brightness and fades out once its cells approach pixel size.

uniform sampler2D height_tex : filter_nearest, repeat_disable;
uniform sampler2D attr_tex : filter_linear, repeat_disable;
uniform float spacing = 1.0;
// Far LOD tiles hide themselves where the detailed near chunks take over.
uniform float near_cutoff = 0.0;
// Far tiles are too coarse to resolve channels; their cuts would show as
// blotches. They have no river meshes either: rivers are painted from their
// coverage instead (0 on near tiles, which mesh their water).
uniform float channel_tint = 1.0;
uniform float paint_water = 0.0;

varying vec3 wpos;
varying vec2 grid; // texel coordinates of this point in the tile textures

// Height (x) and dug depth (y) at texel coordinates g (texel centres at
// integers), bilinear.
vec2 height2(vec2 g) {
	ivec2 n = textureSize(height_tex, 0) - 1;
	g = clamp(g, vec2(0.0), vec2(n) - 0.001);
	vec2 fi = floor(g);
	vec2 f = g - fi;
	ivec2 c = ivec2(fi);
	vec2 a = texelFetch(height_tex, c, 0).rg;
	vec2 b = texelFetch(height_tex, min(c + ivec2(1, 0), n), 0).rg;
	vec2 d = texelFetch(height_tex, min(c + ivec2(0, 1), n), 0).rg;
	vec2 e = texelFetch(height_tex, min(c + ivec2(1, 1), n), 0).rg;
	return mix(mix(a, b, f.x), mix(d, e, f.x), f.y);
}

float height(vec2 g) {
	return height2(g).x;
}

// World normal at g, by central differences one texel wide.
vec3 normal_at(vec2 g) {
	float hx = height(g + vec2(1.0, 0.0)) - height(g - vec2(1.0, 0.0));
	float hz = height(g + vec2(0.0, 1.0)) - height(g - vec2(0.0, 1.0));
	return normalize(vec3(-hx, 2.0 * spacing, -hz));
}

// Integer hash: exact at any world coordinate (a sin-based hash loses its
// precision a few km out and turns into blocky patterns).
float hash(ivec2 c) {
	uint v = uint(c.x) * 1597334677u ^ uint(c.y) * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	return float((v >> 22u) ^ v) / 4294967295.0;
}

// Value noise with quintic interpolation (no grid creases), plus a second
// rotated, offset octave to hide the lattice.
float vnoise1(vec2 p) {
	vec2 fi = floor(p);
	ivec2 i = ivec2(fi);
	vec2 f = p - fi;
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + ivec2(1, 0)), u.x),
			mix(hash(i + ivec2(0, 1)), hash(i + ivec2(1, 1)), u.x), u.y);
}

float vnoise(vec2 p) {
	vec2 q = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p * 1.93 + vec2(31.7, 11.3);
	return clamp(0.68 * vnoise1(p) + 0.32 * vnoise1(q), 0.0, 1.0);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	grid = VERTEX.xz / spacing + 1.0;
	NORMAL = normal_at(grid);
}

void fragment() {
	if (near_cutoff > 0.0 && distance(wpos.xz, CAMERA_POSITION_WORLD.xz) < near_cutoff) {
		discard;
	}
	vec3 n = normal_at(grid);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec4 attr = texture(attr_tex, (grid + 0.5) / vec2(textureSize(attr_tex, 0)));
	float alluvium = attr.r;
	float gully = attr.g;
	float channel = attr.b;
	float dug = height2(grid).y;
	float cover = attr.a;
	float h = wpos.y;
	vec2 p = wpos.xz;

	// Large-scale variation decides; fine noise only mottles, fading by footprint.
	float fp = length(fwidth(p));
	float patches = vnoise(p / 160.0) * 0.6 + vnoise(p / 40.0) * 0.4;
	float n1 = vnoise(p / 20.0);
	float fine = mix(0.5, vnoise(p * 0.7), 1.0 - smoothstep(0.3, 0.9, fp * 0.7)) * 0.5
			+ mix(0.5, vnoise(p * 2.9), 1.0 - smoothstep(0.3, 0.9, fp * 2.9)) * 0.5;

	vec3 grass = mix(vec3(0.27, 0.43, 0.14), vec3(0.42, 0.50, 0.22), clamp(patches * 1.2 - 0.15, 0.0, 1.0));
	vec3 meadow = mix(vec3(0.24, 0.46, 0.15), vec3(0.32, 0.50, 0.17), patches);
	vec3 silt = vec3(0.43, 0.39, 0.29);
	vec3 dirt = vec3(0.42, 0.31, 0.20);
	vec3 rock = mix(vec3(0.36, 0.35, 0.33), vec3(0.55, 0.53, 0.49), n1 * 0.6 + patches * 0.4);
	vec3 sand = mix(vec3(0.80, 0.74, 0.55), vec3(0.88, 0.82, 0.63), patches);
	vec3 seabed = mix(vec3(0.58, 0.54, 0.40), vec3(0.44, 0.42, 0.34), patches);
	vec3 gravel = mix(vec3(0.47, 0.45, 0.41), vec3(0.60, 0.58, 0.53), n1);

	vec3 col = grass;
	// Floodplains: greener meadow, with broad silty patches.
	col = mix(col, meadow, smoothstep(0.1, 0.7, alluvium));
	col = mix(col, silt, smoothstep(0.55, 0.8, vnoise(p / 30.0)) * smoothstep(0.3, 0.9, alluvium) * 0.35);
	// Gully floors and moderately steep ground show soil.
	col = mix(col, dirt, clamp(smoothstep(0.93, 0.72, n.y) * 0.6 + smoothstep(2.0, 9.0, gully) * 0.5, 0.0, 1.0));
	col *= 1.0 - 0.2 * smoothstep(2.0, 12.0, gully); // shadowed gully floors
	// Steep slopes and high ground are bare rock.
	float rocky = 1.0 - smoothstep(0.6, 0.8, n.y);
	rocky = max(rocky, smoothstep(95.0, 135.0, h + (patches - 0.5) * 40.0) * smoothstep(0.98, 0.84, n.y));
	col = mix(col, rock, rocky);
	// River beds.
	col = mix(col, gravel, smoothstep(0.4, 1.0, channel) * channel_tint);
	// Beach, then sea floor.
	col = mix(col, sand, (1.0 - smoothstep(1.0, 1.6, h + (patches - 0.5) * 0.6)) * (1.0 - smoothstep(0.1, 0.4, alluvium)));
	col = mix(col, seabed, 1.0 - smoothstep(-2.0, 0.0, h));
	// Dug ground: soil, then stone deeper down.
	col = mix(col, dirt, smoothstep(0.1, 0.3, dug) * step(1.25, h));
	col = mix(col, rock, smoothstep(1.8, 2.2, dug));
	// Mottling, so no ground is one flat colour.
	col *= 0.9 + 0.2 * fine;

	// Distant rivers: dark, glossy water, as wide as their analytic coverage.
	float wet = smoothstep(0.15, 0.6, cover) * paint_water;
	col = mix(col, vec3(0.10, 0.17, 0.20), wet);

	ALBEDO = pow(col, vec3(2.2)); // palette above is authored in sRGB
	ROUGHNESS = mix(mix(0.95, 0.82, rocky), 0.08, wet);
	SPECULAR = mix(0.25, 0.5, wet);
}
