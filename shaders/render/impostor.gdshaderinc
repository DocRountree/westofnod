// A tree's far-off card, as both its shaders draw it (impostor.gdshader: a
// plant's own, Population's last level of it; far_trees.gdshader, with
// FAR_TREES: every standing tree's past its last level, FarTrees):
// one card, turned about the tree's own upright to face the camera, showing
// the tree as photographed from the nearest of eight ways round
// (ImpostorBaker: its level-2 mesh, unlit, side by side in one strip), the
// two nearest stippled between as the view goes round. Lit as the leaves
// are (leaves.gdshader light()), as a whole crown: the normal a dome's,
// out from the card's middle toward the camera.
//
// The atlas is premultiplied (its background black, transparent): colour /
// alpha undoes it after filtering, so the mips' edges don't darken; in its
// own sRGB, before it's made linear (made linear first, a pixel a third
// covered came out a quarter as bright: thin limbs far off dithered in as
// dark dots, white sycamores' worst).

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lod_fade.gdshaderinc"

#ifdef FAR_TREES
uniform sampler2DArray atlas : filter_linear_mipmap, repeat_disable; // (a layer a card: sRGB, premultiplied, as below)
uniform sampler2D cards : filter_nearest, repeat_disable; // a texel a layer: its card's middle's height, half its side (the tree's own units); from where it's drawn, to where (m)
uniform float far_fade = 6.0; // m either side of where it takes over (Population.LOD_FADE: the trees' last level's own hand-over)
varying flat float layer;
#else
uniform sampler2D atlas : filter_linear_mipmap, repeat_disable; // (sRGB, premultiplied: read raw, undone, then made linear: srgb())
uniform vec2 frame = vec2(8.0, 8.0); // the card's middle's height, half its side (the tree's own units)
#endif
uniform float frames = 8.0;
uniform vec2 atlas_px = vec2(1280.0, 160.0);
uniform float shadow_strength = 0.55;
uniform float translucency = 0.5;
global uniform float night; // (OakTree.set_night: a global)
const float NIGHT_DIM = 0.5; // (as the leaves)

varying vec3 world_pos;
varying flat float view_f; // which way round it's seen, in frames (0..frames)
varying vec3 n_right; // world: the card's right, up, and toward the camera (for the dome's normal)
varying vec3 n_up;
varying vec3 n_back;

vec3 srgb(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
#ifdef FAR_TREES
	layer = floor(INSTANCE_CUSTOM.x + 0.5);
	vec4 card = texelFetch(cards, ivec2(int(layer), 0), 0);
	vec2 frame = card.xy;
	// (in from the tree's own last level as that hands over, measured as it
	// measures: lod_fades(); out thinning over the last fifth of its reach,
	// not all at one line)
	float far = distance(CAMERA_POSITION_WORLD, MODEL_MATRIX[3].xyz + MODEL_MATRIX[1].xyz * lod_mid_height);
	lod_f = vec2(smoothstep(card.z - far_fade, card.z + far_fade, far), 1.0 - smoothstep(card.w * 0.8, card.w, far));
#else
	lod_f = lod_vertex(CAMERA_POSITION_WORLD, MODEL_MATRIX, PROJECTION_MATRIX);
#endif
	vec3 cam = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	vec3 c = vec3(0.0, frame.x, 0.0);
	vec3 d = cam - c;
	d.y = 0.0;
	d = length(d) > 1e-4 ? normalize(d) : vec3(0.0, 0.0, 1.0);
	vec3 right = cross(-d, vec3(0.0, 1.0, 0.0));
	vec2 q = UV * 2.0 - 1.0;
	VERTEX = c + right * q.x * frame.y - vec3(0.0, 1.0, 0.0) * q.y * frame.y;
	if (lod_gone(lod_f))
		VERTEX = vec3(0.0);
	float a = atan(d.x, d.z); // (0 from +z, toward +x: as ImpostorBaker turned them)
	view_f = mod(a / 6.2832 * frames, frames);
	n_right = normalize(mat3(MODEL_MATRIX) * right);
	n_up = normalize(mat3(MODEL_MATRIX) * vec3(0.0, 1.0, 0.0));
	n_back = normalize(mat3(MODEL_MATRIX) * d);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (lod_hidden(FRAGCOORD.xy, lod_f)) discard;
	// the nearer of the two frames round, stippled between them
	float k0 = floor(view_f);
	float k = fract(view_f) > bayer4(FRAGCOORD.xy + 1.0) ? k0 + 1.0 : k0;
	k = mod(k, frames);
	vec2 uv = vec2((k + UV.x) / frames, UV.y);
	// (the mip from the card's own UV, not uv: neighbouring pixels stippled
	// to different frames jumped a frame apart, which read as the coarsest
	// mip, the whole strip's mean, opaque and dark: squares)
	vec2 gx = dFdx(UV) / vec2(frames, 1.0), gy = dFdy(UV) / vec2(frames, 1.0);
#ifdef FAR_TREES
	vec4 t = textureGrad(atlas, vec3(uv, layer), gx, gy);
#else
	vec4 t = textureGrad(atlas, uv, gx, gy);
#endif
	vec2 dx = dFdx(UV * atlas_px / vec2(frames, 1.0)), dy = dFdy(UV * atlas_px / vec2(frames, 1.0));
	float mip = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))));
	ALPHA = t.a * (1.0 + mip * 0.25); // (thin branches kept as the mips blur them: leaves.gdshader)
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO = srgb(clamp(t.rgb / max(t.a, 0.004), 0.0, 1.0)) * 0.9 * (1.0 - NIGHT_DIM * night); // (a little darker: the leaves' own shade deep in the crown, which the photograph hasn't)
	vec2 q = UV * 2.0 - 1.0;
	q *= 0.8;
	vec3 n = normalize(n_right * q.x - n_up * q.y + n_back * sqrt(max(1.0 - dot(q, q), 0.05)));
	// bare wood (grey to white: little colour in it) not lit as a crown's
	// dome, nor shaded as deep in one: a white sycamore's limbs went grey
	// and black on its far side
	vec3 rgb = clamp(t.rgb / max(t.a, 0.004), 0.0, 1.0);
	float wood = 1.0 - smoothstep(0.08, 0.25, max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b)));
	n = normalize(mix(n, n_back + n_up * 0.6, wood * 0.7));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	AO = mix(0.7, 0.95, wood);
	AO_LIGHT_AFFECT = 0.4;
	ROUGHNESS = 0.7;
	SPECULAR = 0.15; // (one smooth dome caught more of the sky's sheen than the many cards)
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}

void light() {
	float a = mix(1.0, ATTENUATION, shadow_strength);
	float ndl = dot(NORMAL, LIGHT);
	// the light through the leaves from behind only with the sun well up: a
	// low sun's, golden and from behind, turned half of every crown yellow
	// at dusk (a tinge of it left)
	float sun_up = (INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).y;
	float through = translucency * mix(0.12, 1.0, smoothstep(0.05, 0.4, sun_up));
	DIFFUSE_LIGHT += (clamp(ndl * 0.8 + 0.2, 0.0, 1.0) + max(-ndl, 0.0) * through) * a * LIGHT_COLOR / PI;
}
