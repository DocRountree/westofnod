shader_type spatial;
render_mode cull_disabled;

// Leaf cards: an alpha-cut atlas of sprigs and clumps
// (tools/trees/bake_oak_textures.py), lit as part of a whole crown (the
// normals TreeBuilder gives them point out from the crown's middle, the
// same on both sides of a card), light coming through from behind
// (light(): wrapped, plus translucency), darker deep inside (vertex
// alpha). The top of each card flutters a little in the wind (UV2.y: 0 at
// the twig, 1 at the top).
//
// Level of detail, on top of the mesh's (sprig cards near, fewer clump
// cards further off): every card has a random rank (UV2.x), and past the
// distance its mesh starts thinning from (CUSTOM0.w) only a share
// (thin_from / distance)^thin_power of them is drawn, at least min_keep; the
// others collapse to a point (no pixels), the ones kept grow by
// 1/sqrt(share) about their middle (CUSTOM0.xyz: this corner's offset from
// it), so the crown keeps its cover while the overdraw falls off. A card
// on its way out dissolves (stippled) over the last 8% of rank, so none
// pops; and whole levels hand over stippled too (lod_fade.gdshaderinc).
//
// Alpha-cut leaves thin out with distance as the texture's mips blur their
// edges; the cut is lowered with the mip level to keep the coverage (Ben
// Golus, "Anti-aliased Alpha Test").

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lod_fade.gdshaderinc"
#include "res://shaders/render/wind.gdshaderinc"

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float flutter = 0.045; // m
uniform float brightness = 1.4; // (the atlas is painted dark)
uniform float shadow_strength = 0.55;
uniform float translucency = 0.5; // light through the leaves from behind
uniform vec2 atlas_size = vec2(2048.0, 1024.0);
uniform float thin_power = 1.3;
uniform float min_keep = 0.3;

varying vec3 world_pos;
varying float card_fade; // 1 drawn, 0 gone: a card being dropped dissolves (stippled) first

void vertex() {
	vec3 mid = VERTEX - CUSTOM0.xyz;
	float d = distance(CAMERA_POSITION_WORLD, (MODEL_MATRIX * vec4(mid, 1.0)).xyz);
	float keep = clamp(pow(CUSTOM0.w / max(d, 0.01), thin_power), min_keep, 1.0);
	card_fade = clamp((keep - UV2.x) / 0.08 + 1.0, 0.0, 1.0); // over the 8% of rank above the cut
	VERTEX = card_fade <= 0.0 ? mid : mid + CUSTOM0.xyz * inversesqrt(keep);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float ph = dot(world_pos, vec3(0.37, 0.21, 0.29));
	VERTEX += NORMAL * sin(TIME * 2.3 + ph) * flutter * UV2.y; // the leaves flutter...
	VERTEX += wind_local(MODEL_MATRIX, mid, 1.0, TIME);        // ...and sway with their twig
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (lod_hidden(FRAGCOORD.xy, CAMERA_POSITION_WORLD, PROJECTION_MATRIX) || card_fade < bayer4(FRAGCOORD.xy + 2.0)) discard;
	vec4 t = texture(leaf_tex, UV);
	vec2 dx = dFdx(UV * atlas_size), dy = dFdy(UV * atlas_size);
	float mip = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))));
	ALPHA = t.a * (1.0 + mip * 0.25);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	if (!FRONT_FACING) NORMAL = -NORMAL; // (undo the flip: one normal for both sides)
	ALBEDO = t.rgb * COLOR.rgb * brightness;
	AO = COLOR.a;
	AO_LIGHT_AFFECT = 0.4;
	ROUGHNESS = 0.6;
	SPECULAR = 0.35;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}

// Lit by hand so a shadow only dims it part way (shadow_strength): trees
// take their shadows from one stand-in (a dome on a stalk) that wraps their
// own crown, which would otherwise black out the whole tree. The ground
// under it still gets the full shadow.
void light() {
	float a = mix(1.0, ATTENUATION, shadow_strength);
	float ndl = dot(NORMAL, LIGHT);
	DIFFUSE_LIGHT += (clamp(ndl * 0.8 + 0.2, 0.0, 1.0) + max(-ndl, 0.0) * translucency) * a * LIGHT_COLOR / PI;
	vec3 h = normalize(VIEW + LIGHT);
	SPECULAR_LIGHT += pow(max(dot(NORMAL, h), 0.0), 24.0) * 0.04 * a * LIGHT_COLOR * clamp(ndl, 0.0, 1.0);
}
