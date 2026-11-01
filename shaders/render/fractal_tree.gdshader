shader_type spatial;
render_mode cull_front, diffuse_burley, specular_schlick_ggx;

// A raymarched fractal tree (the recipe: scripts/population/fractal_tree.gd;
// keep the numbers in step). The mesh is only a box round the tree; each
// pixel of its far side marches a ray through the tree's distance function
// from where the ray enters the box, and writes the hit's depth, normal and
// light position, so the tree sorts, lights and casts shadows like a mesh.
// Back faces, so it still draws with the camera inside the box (under the
// canopy).
//
// Each instance differs: its seed is its position. Detail follows distance:
// far off, whole branches (and their sub-branches) become one leaf cluster,
// so the march does fewer folds and the canopy doesn't shimmer.

#include "res://shaders/render/aerial.gdshaderinc"

uniform float trunk_len = 4.2;
uniform float trunk_r = 0.34;
uniform int levels = 7;
uniform float len_ratio = 0.76;
uniform float rad_ratio = 0.64;
uniform float tilt = 0.52;
uniform float twist = 2.4;
uniform float leaf_r = 1.25;
uniform float leaf_amp = 0.32;
uniform float variation = 1.0; // 0: every tree the same (as the mesh); 1: each its own
uniform float lod_distance = 40.0; // m: a level of detail dropped each time the distance doubles past this
uniform int max_steps = 96;
uniform vec3 box_min = vec3(-8.0, 0.0, -8.0); // the mesh's box (tree space, m)
uniform vec3 box_max = vec3(8.0, 18.0, 8.0);
uniform vec3 bark_colour : source_color = vec3(0.3, 0.22, 0.15);
uniform vec3 leaf_colour : source_color = vec3(0.16, 0.3, 0.09);

varying vec3 v_obj;          // this vertex, tree space
varying vec3 v_cam;          // the eye, tree space (perspective)
varying vec3 v_look;         // the view direction, tree space (orthographic: directional shadows)
varying flat vec3 v_params;  // per instance: tilt, twist, colour shift

float hash1(vec2 p) {
	uvec2 q = floatBitsToUint(p);
	uint v = q.x * 1597334677u ^ q.y * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	return float((v >> 22u) ^ v) / 4294967295.0;
}

void vertex() {
	// the box mesh is centred; the tree stands on the origin
	VERTEX = mix(box_min, box_max, VERTEX / (box_max - box_min) + 0.5);
	v_obj = VERTEX;
	mat4 inv_mv = inverse(MODELVIEW_MATRIX);
	v_cam = (inv_mv * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_look = (inv_mv * vec4(0.0, 0.0, -1.0, 0.0)).xyz;
	vec2 at = MODEL_MATRIX[3].xz;
	float h1 = hash1(floor(at * 8.0));
	float h2 = hash1(floor(at * 8.0) + 17.0);
	float h3 = hash1(floor(at * 8.0) + 51.0);
	v_params = vec3(tilt * (1.0 + variation * (h1 - 0.5) * 0.35),
			twist + variation * (h2 - 0.5) * 0.9,
			variation * (h3 - 0.5));
}

// Lumps on the leaf clusters (FractalTree.leaf_noise(), the same): two
// octaves of sine products, the second in a rotated frame so the bumps
// don't line up with the axes. Its slope stays under ~1.3 per metre times
// leaf_amp, which the march's 0.8 step allows for.
float leaf_noise(vec3 p) {
	float a = sin(p.x * 2.1 + 1.3) * sin(p.y * 2.3 + 0.7) * sin(p.z * 1.9 + 2.1);
	vec3 q = vec3(0.8 * p.y + 0.6 * p.z, -0.8 * p.x + 0.36 * p.y - 0.48 * p.z, -0.6 * p.x - 0.48 * p.y + 0.64 * p.z) * 4.3;
	float b = sin(q.x + 0.5) * sin(q.y + 1.7) * sin(q.z + 2.9);
	return a * 0.75 + b * 0.25;
}

// Distance (m) to the tree from p (tree space, m), and whether the nearest
// thing is leaves (y = 1) or bark (0). lv: levels of branches drawn; the
// rest of each branch's subtree is one leaf cluster sized to cover it.
vec2 tree(vec3 p, int lv, vec2 tw) {
	vec3 p0 = p;
	float ct = cos(tw.x), st = sin(tw.x);
	float cw = cos(tw.y), sw = sin(tw.y);
	float sc = 1.0;  // m per local unit
	float r = trunk_r;
	float wood = 1e9;
	for (int i = 0; i < levels; i++) {
		if (i >= lv) break;
		float r_top = r * rad_ratio / len_ratio;
		float h = clamp(p.y / trunk_len, 0.0, 1.0);
		wood = min(wood, (length(p - vec3(0.0, h * trunk_len, 0.0)) - mix(r, r_top, h)) * sc);
		p.y -= trunk_len;
		p.x = abs(p.x);
		p.xy = vec2(ct * p.x - st * p.y, st * p.x + ct * p.y);
		p.xz = vec2(cw * p.x - sw * p.z, sw * p.x + cw * p.z);
		p /= len_ratio;
		sc *= len_ratio;
		r = r_top;
		// the rest of this subtree lies within a sphere round its base (its
		// branches add up to at most trunk_len / (1 - len_ratio), plus a
		// cluster): far outside it, that sphere is distance enough
		float bound = length(p) * sc - (trunk_len / (1.0 - len_ratio) * sc + leaf_r * 2.2 + leaf_amp);
		if (bound > 0.5) {
			return vec2(min(wood, bound), 0.0);
		}
	}
	int m = levels - min(lv, levels); // levels folded into the cluster
	float hm = trunk_len * (1.0 - pow(len_ratio, float(m))) / (1.0 - len_ratio);
	float rl = leaf_r / sc;
	vec3 c = vec3(0.0, 0.45 * hm + rl * 0.6, 0.0);
	float R = 0.5 * hm + rl;
	float leaf = (length(p - c) - R) * sc + leaf_amp * leaf_noise(p0);
	return leaf < wood ? vec2(leaf, 1.0) : vec2(wood, 0.0);
}

void fragment() {
	bool ortho = PROJECTION_MATRIX[3][3] > 0.5;
	vec3 rd = normalize(ortho ? v_look : v_obj - v_cam);
	vec3 ro = ortho ? v_obj - rd * 1000.0 : v_cam;
	// the ray's span in the box
	vec3 inv = 1.0 / rd;
	vec3 ta = (box_min - ro) * inv, tb = (box_max - ro) * inv;
	vec3 tlo = min(ta, tb), thi = max(ta, tb);
	float t0 = max(max(max(tlo.x, tlo.y), tlo.z), 0.0);
	float t1 = min(min(thi.x, thi.y), thi.z);
	// tree space is metres scaled by the instance; t is in tree units, and so
	// is a pixel's footprint per unit of t
	float pix = 2.0 / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	float inst_scale = length(MODEL_MATRIX[0].xyz);
	float dist_m = ortho ? lod_distance : (t0 * inst_scale);
	int lv = levels - int(clamp(floor(log2(max(dist_m, 1.0) / lod_distance)) + 1.0, 0.0, float(levels)));
	if (ortho) lv = max(levels - 3, 1); // shadows: coarser
	vec2 tw = v_params.xy;
	float t = t0;
	vec2 h = vec2(1e9, 0.0);
	bool hit = false;
	for (int i = 0; i < max_steps; i++) {
		vec3 p = ro + rd * t;
		h = tree(p, lv, tw);
		float eps = ortho ? 0.02 : max(0.002, t * pix * 0.7);
		if (h.x < eps) { hit = true; break; }
		t += h.x * 0.8;
		if (t > t1) break;
	}
	if (!hit) discard;
	vec3 p = ro + rd * t;
	// normal: tetrahedral gradient
	float e = max(0.01, t * pix);
	vec2 k = vec2(1.0, -1.0);
	vec3 n = normalize(k.xyy * tree(p + k.xyy * e, lv, tw).x + k.yyx * tree(p + k.yyx * e, lv, tw).x
			+ k.yxy * tree(p + k.yxy * e, lv, tw).x + k.xxx * tree(p + k.xxx * e, lv, tw).x);
	// two-tap ambient occlusion from the distance field (deep in the canopy is dark)
	float ao = 1.0;
	if (!ortho) {
		float a1 = tree(p + n * 0.4, lv, tw).x / 0.4;
		float a2 = tree(p + n * 1.5, lv, tw).x / 1.5;
		ao = clamp(0.35 + 0.35 * clamp(a1, 0.0, 1.0) + 0.3 * clamp(a2, 0.0, 1.0), 0.0, 1.0);
		ao *= mix(0.55, 1.0, clamp(p.y / (box_max.y * 0.7), 0.0, 1.0)); // the underside, in its own shade
	}
	mat3 mv = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	vec3 hit_view = VERTEX + mv * (p - v_obj);
	vec4 clip = PROJECTION_MATRIX * vec4(hit_view, 1.0);
	DEPTH = clip.z / clip.w;
	LIGHT_VERTEX = hit_view;
	NORMAL = normalize(mv * n);
	float leaf = h.y;
	float shade = 1.0 + 0.25 * v_params.z + 0.15 * leaf * leaf_noise(p * 0.7 + 3.0);
	ALBEDO = mix(bark_colour, leaf_colour * shade, leaf);
	ROUGHNESS = mix(0.95, 0.8, leaf);
	SPECULAR = 0.3;
	AO = ao;
	AO_LIGHT_AFFECT = 0.3;
	BACKLIGHT = leaf_colour * 0.5 * leaf;
	vec3 world = (INV_VIEW_MATRIX * vec4(hit_view, 1.0)).xyz;
	FOG = aerial_fog(world, CAMERA_POSITION_WORLD);
}
