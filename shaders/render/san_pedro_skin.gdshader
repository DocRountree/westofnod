shader_type spatial;

// The San Pedro's skin (SanPedroCactus): its vertices' colours (frosted blue
// green, the new tips paler, the corky foot), and painted on, not built,
// the areoles along every rib's crest: a cushion of white felt in a little
// dark notch every `gap` m, with (painted_spines) a few short brown spines
// out of it, flat (the nearest level has real ones: SanPedroCactus). From
// PlantMesh.tube's uv: UV.x round in ribs (a crest at each whole number),
// UV.y m along; UV2 the radius there, the ribs. Far off, where an areole is
// under a pixel or two, they fade to their mean (no sparkle). Drawn over
// its level of detail's span (lod_fade.gdshaderinc), hazed far off.

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lod_fade.gdshaderinc"

uniform float gap = 0.03;
uniform vec3 felt_color = vec3(0.88, 0.86, 0.8);
uniform vec3 spine_color = vec3(0.45, 0.33, 0.18);
uniform float painted_spines = 1.0;
uniform float roughness_v = 0.48;
uniform float rim_v = 0.25;

varying vec3 world_pos;
varying vec2 rib_frame; // the radius (m), the ribs

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	lod_f = lod_vertex(CAMERA_POSITION_WORLD, MODEL_MATRIX, PROJECTION_MATRIX);
	if (lod_gone(lod_f))
		VERTEX = vec3(0.0);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rib_frame = UV2;
}

void fragment() {
	if (lod_hidden(FRAGCOORD.xy, lod_f)) discard;
	vec3 col = COLOR.rgb;
	float rib_w = 6.2832 * max(rib_frame.x, 0.005) / max(rib_frame.y, 1.0); // (m from crest to crest)
	float rib = floor(UV.x + 0.5);
	float cell = floor(UV.y / gap);
	vec2 p = vec2((UV.x - rib) * rib_w, (fract(UV.y / gap) - 0.5) * gap); // (m from the areole: across, along)
	float h = hash(vec2(rib, cell));
	// how much shows: none once an areole's under a couple of pixels
	float cells_px = max(fwidth(UV.y / gap), fwidth(UV.x) * rib_w / gap);
	float detail = 1.0 - smoothstep(0.2, 0.5, cells_px);
	// the felt cushion (3.5 mm across, 5 long), in its notch
	float e = length(vec2(p.x / 0.0035, p.y / 0.005));
	float felt = 1.0 - smoothstep(0.75, 1.0, e);
	float notch = (1.0 - smoothstep(1.0, 1.6, e)) * (1.0 - felt);
	// spines out of it, flat: up to three, each its own way and length
	float spine = 0.0;
	for (int j = 0; j < 3; j++) {
		float hj = hash(vec2(h * 91.7, float(j) * 3.1 + cell));
		if (hj > 0.35 + 0.2 * float(j)) {
			float a = hj * 6.2832 + float(j) * 2.1;
			vec2 d = vec2(cos(a), sin(a));
			float len = mix(0.006, 0.016, fract(hj * 7.3));
			float t = clamp(dot(p, d), 0.0, len);
			float w = mix(0.0007, 0.0002, t / len);
			spine = max(spine, 1.0 - smoothstep(w, w * 1.8, length(p - d * t)));
		}
	}
	spine *= painted_spines * (1.0 - felt);
	vec3 near = mix(col, col * 0.72, notch * 0.7);
	near = mix(near, felt_color * (0.9 + 0.1 * h), felt);
	near = mix(near, spine_color, spine * 0.9);
	vec3 far = mix(col, felt_color, 0.05); // (their mean: a little paler)
	ALBEDO = mix(far, near, detail);
	ROUGHNESS = mix(roughness_v, 0.95, felt * detail);
	RIM = rim_v * (1.0 - felt * detail);
	RIM_TINT = 0.3;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
