class_name MapleTree
## The sugar maple (Acer saccharum): four standing trees, a stump, three
## fallen logs, three dead standing trees and two saplings (variants 0-12,
## as the oak's), grown by SpeciesTree and dressed with
## data/population/textures/maple_*.png (tools/trees/bake_broadleaf_textures.py).
## Not yet in the game: tools/trees/preview.gd -- <out> maple draws them.
##
## What makes it read as a sugar maple: a straight, tall trunk; branching
## opposite (side branches in pairs, each pair square to the last), limbs
## that climb steeply (ascending, not spreading as an oak's); a dense,
## rounded to oval crown, taller than wide in the open, its outline smooth;
## leaves in opposite pairs on long stalks, palmate, five-lobed, with
## rounded sinuses and a few big teeth; bark grey, smooth when young, in
## long, loose, curling vertical plates when old.

const VARIANTS := [
	# open-grown: a short bole, many ascending limbs, a full oval crown
	{"trunk_h": 2.6, "leader_h": 9.0, "trunk_r": 0.42, "limbs": 10, "limb_angle": 52.0, "limb_len": 8.5, "branch_len": 3.5, "twig_len": 1.05, "lean": 0.0, "droop": 0.0, "seed": 211, "crown": [6.8, 19.5, 3.8]},
	# young: slim, a strong leader, a narrow oval
	{"trunk_h": 3.0, "leader_h": 8.5, "trunk_r": 0.22, "limbs": 9, "limb_angle": 44.0, "limb_len": 5.4, "branch_len": 2.5, "twig_len": 0.95, "lean": 0.0, "droop": 0.0, "seed": 223, "crown": [4.0, 16.0, 3.5]},
	# leaning toward the light
	{"trunk_h": 3.2, "leader_h": 8.0, "trunk_r": 0.36, "limbs": 9, "limb_angle": 50.0, "limb_len": 7.5, "branch_len": 3.2, "twig_len": 1.0, "lean": 8.0, "droop": 0.0, "seed": 241, "crown": [6.0, 17.5, 3.8]},
	# forest-grown: a tall clean bole, a high, narrow crown
	{"trunk_h": 8.0, "leader_h": 9.0, "trunk_r": 0.4, "limbs": 8, "limb_angle": 44.0, "limb_len": 6.2, "branch_len": 2.8, "twig_len": 0.95, "lean": 0.0, "droop": 0.0, "seed": 251, "crown": [4.8, 24.0, 9.5]},
	{"kind": "stump", "seed": 261, "r": 0.44, "flare": 0.4},
	{"kind": "log", "seed": 267, "r0": 0.38, "r1": 0.27},
	{"kind": "dead", "like": 0, "seed": 271, "limb_angle": 36.0, "limb_len": 6.0, "branch_len": 2.6, "crown": [5.6, 17.5, 3.6]},
	{"kind": "log", "seed": 273, "length": Vector2(8.5, 10.0), "r0": 0.3, "r1": 0.15, "bow": 0.3, "stubs": Vector2i(4, 6)},
	{"kind": "log", "seed": 279, "length": Vector2(2.6, 3.4), "r0": 0.5, "r1": 0.46, "bow": 0.05, "stubs": Vector2i(0, 1)},
	# saplings, 3-4 m: a whip with a few pairs of side shoots, and a bushier one
	{"kind": "sapling", "trunk_h": 1.0, "leader_h": 2.3, "trunk_r": 0.04, "limbs": 6, "limb_angle": 36.0, "limb_len": 1.2, "branch_len": 0.7, "twig_len": 0.45, "lean": 0.0, "droop": 0.0, "seed": 283, "crown": [1.1, 4.0, 1.0]},
	{"kind": "sapling", "trunk_h": 0.5, "leader_h": 2.0, "trunk_r": 0.045, "limbs": 6, "limb_angle": 44.0, "limb_len": 1.4, "branch_len": 0.7, "twig_len": 0.45, "lean": 3.0, "droop": 0.0, "seed": 289, "crown": [1.4, 3.4, 0.6]},
	{"kind": "dead", "like": 1, "seed": 297, "limb_angle": 30.0, "limb_len": 4.0, "branch_len": 1.9, "crown": [3.6, 14.5, 3.4]},
	{"kind": "dead", "like": 3, "seed": 303, "lean": 5.0, "limb_angle": 36.0, "limb_len": 4.6, "branch_len": 2.2, "crown": [4.2, 22.0, 9.0]},
]

const SETTINGS := {
	"seg": [0.5, 0.6, 0.42, 0.32],
	"crook": [0.035, 0.1, 0.18, 0.24], # (straighter than an oak's)
	"up": [0.0, 0.018, 0.07, 0.1], # (limbs climbing, more than an oak's)
	"child_angle": [0.0, 0.75, 0.75, 0.7],
	"opposite": true,
	"irregular": 0.15,
	"tip_r": 0.005,
	"card_size": 0.7,
	"bark_tex": "res://data/population/textures/maple_bark.png",
	"leaf_tex": "res://data/population/textures/maple_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.78, 0.76, 0.72),
	"log_tint": Color(0.8, 0.83, 0.72),
	"shadow": [6.4, 4.2, 18.5, 0.4],
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("maple", SETTINGS, VARIANTS)
	return _species


static func build(variant := 0) -> Mesh:
	return species().build(variant)


static func build_lods(variant := 0) -> Array[Mesh]:
	return species().build_lods(variant)


static func build_shadow(variant := 0) -> Mesh:
	return species().build_shadow(variant)


static func build_walk(variant := 0) -> PackedFloat32Array:
	return species().build_walk(variant)


static func build_climb(variant := 0) -> PackedFloat32Array:
	return species().build_climb(variant)


static func variant_props(variant: int) -> Dictionary:
	return species().variant_props(variant)


static func near_multimesh(_variant := 0) -> Array:
	return [] # (no sporophytes yet)
