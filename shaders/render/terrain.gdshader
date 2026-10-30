shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The island's terrain: CDLOD patches over one height map (no tiles, no
// near/far switch). Normals and materials are per pixel, from the finest mip
// the pixel can show, so detail fades smoothly with distance instead of
// popping, and nothing follows the mesh grid.
//
// Colours are natural and untextured for now: grass in broad patches, drier up
// high; floodplain meadow; damp swales and silted oxbows; gravel river beds;
// sandy fans and deltas; rock on steep ground; beaches and the sea floor.
// Distant rivers are painted from their mip-filtered coverage, so a river too
// thin for its distance thins into a line instead of breaking into blobs.

#include "res://shaders/render/island_maps.gdshaderinc"

uniform sampler2D material_tex : filter_linear_mipmap, repeat_disable; // floodplain, wet, bed, deposit
uniform sampler2D wattr_tex : filter_linear_mipmap, repeat_disable;    // water coverage, flow, kind

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
	vec4 mat = texture(material_tex, map_uv(p));
	vec4 wa = texture(wattr_tex, map_uv(p));

	float patches = vnoise(p / 220.0) * 0.6 + vnoise(p / 55.0) * 0.4;
	vec3 grass = mix(vec3(0.30, 0.40, 0.16), vec3(0.47, 0.47, 0.26), clamp(patches * 1.1 - 0.2 + smoothstep(80.0, 260.0, h) * 0.6, 0.0, 1.0));
	vec3 meadow = mix(vec3(0.27, 0.42, 0.15), vec3(0.34, 0.45, 0.18), patches);
	vec3 marsh = vec3(0.27, 0.35, 0.17);
	vec3 gravel = mix(vec3(0.45, 0.43, 0.39), vec3(0.55, 0.53, 0.48), vnoise(p / 7.0));
	vec3 fan = mix(vec3(0.55, 0.50, 0.38), vec3(0.62, 0.57, 0.44), patches);
	vec3 rock = mix(vec3(0.30, 0.29, 0.27), vec3(0.47, 0.45, 0.42), vnoise(p / 11.0) * 0.6 + vnoise(p / 70.0) * 0.4);
	vec3 sand = mix(vec3(0.70, 0.64, 0.49), vec3(0.78, 0.72, 0.56), patches);
	vec3 seabed = mix(vec3(0.62, 0.58, 0.45), vec3(0.45, 0.43, 0.36), smoothstep(-2.0, -25.0, h));

	vec3 col = grass;
	col = mix(col, meadow, smoothstep(0.2, 0.8, mat.r));
	col = mix(col, fan, smoothstep(0.3, 0.9, mat.a) * 0.35 * (1.0 - mat.r) * smoothstep(0.85, 0.97, n.y));
	col = mix(col, marsh, smoothstep(0.25, 0.8, mat.g) * 0.7);
	float rocky = smoothstep(0.78, 0.6, n.y);
	col = mix(col, rock, rocky);
	col = mix(col, gravel, smoothstep(0.3, 0.8, mat.b));
	// Beaches above the waterline (not on floodplains reaching the sea), sea floor below.
	float beach = (1.0 - smoothstep(0.8, 1.6, h + (patches - 0.5) * 0.6)) * (1.0 - smoothstep(0.2, 0.6, mat.r));
	col = mix(col, sand, beach * (1.0 - rocky * 0.7));
	col = mix(col, seabed, 1.0 - smoothstep(-1.5, 0.0, h));
	// Damp just above the waterline.
	col *= mix(1.0, 0.75, (1.0 - smoothstep(0.0, 0.5, h)) * step(-0.3, h));
	// Mottling, fading out where its cells shrink below a pixel.
	float fine = mix(0.5, vnoise(p * 0.6), 1.0 - smoothstep(0.4, 1.2, fp * 0.6)) * 0.5
			+ mix(0.5, vnoise(p * 2.7), 1.0 - smoothstep(0.4, 1.2, fp * 2.7)) * 0.5;
	col *= 0.9 + 0.2 * fine;
	// Distant rivers and lakes: their coverage, mip-averaged, painted as water.
	float dist = distance(world_pos, CAMERA_POSITION_WORLD);
	float far_water = wa.r * smoothstep(250.0, 700.0, dist);
	col = mix(col, vec3(0.13, 0.20, 0.24), far_water);
	// Aerial perspective: far land turns blue-grey.
	float haze = 1.0 - exp(-dist / 5000.0);
	col = mix(col, vec3(dot(col, vec3(0.3, 0.59, 0.11))) * vec3(0.65, 0.8, 1.15), haze * 0.6);

	ALBEDO = pow(col, vec3(2.2));
	ROUGHNESS = mix(mix(0.95, 0.85, rocky), 0.1, far_water);
	SPECULAR = mix(0.25, 0.5, far_water);
}
