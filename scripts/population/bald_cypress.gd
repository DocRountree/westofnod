class_name BaldCypress
## The bald cypress (Taxodium distichum): four standing trees, a stump,
## three fallen logs, three dead standing trees and two saplings (variants
## 0-12, as the oak's), grown by SpeciesTree as a conifer and dressed with
## data/population/textures/cypress_*.png
## (tools/trees/bake_conifer_textures.py). Not yet in the game:
## tools/trees/preview.gd -- <out> cypress draws them.
##
## What makes it read as a bald cypress: a swamp tree; its foot swollen and
## fluted into buttresses, knees (knobs of root) standing up out of the
## water and mud round it; young, a neat narrow cone; old, a broad, flat,
## ragged top on a tall trunk, its big limbs reaching out level near the
## top; soft, feathery foliage, flat sprays of short, flat, light green
## needles in two rows (it's deciduous: "bald" in winter); bark reddish
## brown to grey, fibrous, in long, narrow, stringy strips.

const VARIANTS := [
	# old, in the swamp: a flaring, buttressed foot, knees all round, a broad flat top
	{"trunk_h": 6.0, "leader_h": 15.0, "trunk_r": 0.62, "flare": 1.25, "knees": 12, "whorls": 13, "per_whorl": 3, "profile": "flat", "lift_top": 6.0, "limb_angle": 84.0, "droop_low": 8.0, "limb_len": 8.5, "branch_len": 2.8, "twig_len": 0.9, "lean": 0.0, "droop": 0.0, "seed": 511, "crown": [8.5, 20.5, 9.0]},
	# young: a neat cone
	{"trunk_h": 1.5, "leader_h": 12.5, "trunk_r": 0.28, "flare": 0.9, "knees": 3, "whorls": 16, "per_whorl": 4, "profile": "cone", "limb_angle": 76.0, "droop_low": 8.0, "limb_len": 3.8, "branch_len": 1.6, "twig_len": 0.7, "lean": 0.0, "droop": 0.0, "seed": 523, "crown": [3.8, 14.5, 1.8]},
	# middle-aged, leaning, its cone going flat on top
	{"trunk_h": 4.0, "leader_h": 13.0, "trunk_r": 0.45, "flare": 1.1, "knees": 8, "whorls": 14, "per_whorl": 3, "profile": "flat", "lift_top": 10.0, "limb_angle": 82.0, "droop_low": 10.0, "limb_len": 6.0, "branch_len": 2.0, "twig_len": 0.8, "lean": 6.0, "droop": 0.0, "seed": 541, "crown": [5.2, 18.0, 5.5]},
	# a giant: a tall, massive trunk, a high, ragged, flat crown
	{"trunk_h": 11.0, "leader_h": 17.0, "trunk_r": 0.85, "flare": 1.35, "knees": 16, "whorls": 11, "per_whorl": 3, "profile": "flat", "lift_top": 4.0, "limb_angle": 84.0, "droop_low": 6.0, "limb_len": 10.0, "branch_len": 3.2, "twig_len": 1.0, "lean": 0.0, "droop": 0.0, "seed": 553, "crown": [10.0, 26.5, 15.0]},
	{"kind": "stump", "seed": 561, "r": 0.7, "flare": 1.1},
	{"kind": "log", "seed": 567, "r0": 0.5, "r1": 0.36},
	{"kind": "dead", "like": 0, "seed": 571},
	{"kind": "log", "seed": 573, "length": Vector2(9.0, 11.0), "r0": 0.34, "r1": 0.18, "bow": 0.25, "stubs": Vector2i(4, 7)},
	{"kind": "log", "seed": 579, "length": Vector2(2.6, 3.4), "r0": 0.72, "r1": 0.66, "bow": 0.04, "stubs": Vector2i(0, 1)},
	# saplings, 2-3 m: slim cones
	{"kind": "sapling", "trunk_h": 0.3, "leader_h": 2.3, "trunk_r": 0.04, "whorls": 7, "per_whorl": 4, "profile": "cone", "limb_angle": 72.0, "droop_low": 5.0, "limb_len": 0.9, "branch_len": 0.4, "twig_len": 0.3, "lean": 0.0, "droop": 0.0, "seed": 583, "crown": [0.9, 2.6, 0.3]},
	{"kind": "sapling", "trunk_h": 0.2, "leader_h": 1.9, "trunk_r": 0.035, "whorls": 6, "per_whorl": 4, "profile": "cone", "limb_angle": 70.0, "droop_low": 5.0, "limb_len": 0.8, "branch_len": 0.35, "twig_len": 0.28, "lean": 4.0, "droop": 0.0, "seed": 589, "crown": [0.8, 2.1, 0.2]},
	{"kind": "dead", "like": 1, "seed": 597},
	{"kind": "dead", "like": 3, "seed": 603, "lean": 4.0},
]

const SETTINGS := {
	"seg": [0.6, 0.45, 0.3, 0.2],
	"crook": [0.02, 0.15, 0.22, 0.25],
	"up": [0.0, 0.0, 0.03, 0.05],
	"child_angle": [0.0, 0.8, 0.85, 0.8],
	"opposite": false,
	"irregular": 0.0,
	"tip_r": 0.004,
	"card_size": 0.7,
	"bark_tex": "res://data/population/textures/cypress_bark.png",
	"leaf_tex": "res://data/population/textures/cypress_needles.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.8, 0.78, 0.74),
	"log_tint": Color(0.76, 0.78, 0.68),
	"shadow": [6.0, 8.0, 22.0, 0.6],
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("cypress", SETTINGS, VARIANTS)
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


static func choppable(variant: int) -> bool:
	return species().choppable(variant)


static func trunk_radius(variant: int) -> float:
	return species().trunk_radius(variant)


static func trunk_radius_at(variant: int, h: float) -> float:
	return species().section_at(variant, h)[0]


static func trunk_outline_at(variant: int, h: float) -> PackedVector2Array:
	return species().section_at(variant, h)[1]


static func cut_meshes(variant := 0) -> Array:
	return species().cut_meshes(variant)


## What fruit variant v bears (Foraging): an item id, "" none.
static func fruit_of(variant: int) -> String:
	return species().fruit_of(variant)
