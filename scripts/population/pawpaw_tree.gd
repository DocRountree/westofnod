class_name PawpawTree
## The pawpaw (Asimina triloba): four standing trees, a stump, three
## fallen logs, three dead standing trees and two saplings (variants 0-12,
## as the oak's), grown by SpeciesTree and dressed with
## data/population/textures/pawpaw_*.png
## (tools/trees/bake_small_tree_textures.py). Not yet in the game:
## tools/trees/preview.gd -- <out> pawpaw draws them.
##
## What makes it read as a pawpaw: a small understory tree, 4-9 m, often in
## clonal thickets of several stems; a slender trunk, branches spreading
## and a little drooping, a narrow, roughly pyramidal crown; huge leaves,
## 15-30 cm, obovate, smooth-edged, hanging down in ranks from the twigs
## and crowding their ends (a tropical look); now and then a cluster of
## stubby green fruit; bark thin, smooth, grey-brown, blotched lighter,
## warty with lenticels.

const VARIANTS := [
	# in a sunny gap: a pyramid of drooping branches
	{"trunk_h": 1.2, "leader_h": 4.8, "trunk_r": 0.1, "limbs": 9, "limb_angle": 72.0, "limb_len": 2.3, "branch_len": 1.2, "twig_len": 0.55, "lean": 0.0, "droop": 0.05, "seed": 611, "crown": [2.6, 7.2, 1.3]},
	# young, slender, a few branches
	{"trunk_h": 1.6, "leader_h": 3.2, "trunk_r": 0.06, "limbs": 7, "limb_angle": 68.0, "limb_len": 1.5, "branch_len": 0.8, "twig_len": 0.45, "lean": 0.0, "droop": 0.04, "seed": 623, "crown": [1.6, 5.4, 1.6]},
	# a clump from one root: three stems up from the ground
	{"trunk_h": 0.3, "leader_h": 4.5, "trunk_r": 0.13, "limbs": 8, "forks": 3, "fork_angle": 14.0, "fork_len": 2.0, "limb_angle": 70.0, "limb_len": 2.0, "branch_len": 1.0, "twig_len": 0.5, "lean": 0.0, "droop": 0.05, "seed": 641, "crown": [2.8, 6.6, 1.0]},
	# in the shade: tall, leggy, leaning to the light, a thin crown high up
	{"trunk_h": 3.2, "leader_h": 5.2, "trunk_r": 0.12, "limbs": 6, "limb_angle": 66.0, "limb_len": 2.5, "branch_len": 1.2, "twig_len": 0.55, "lean": 7.0, "droop": 0.05, "seed": 653, "crown": [2.6, 9.2, 3.6]},
	{"kind": "stump", "seed": 661, "r": 0.13, "flare": 0.25},
	{"kind": "log", "seed": 667, "length": Vector2(3.0, 4.5), "r0": 0.13, "r1": 0.08, "bow": 0.15, "stubs": Vector2i(2, 4)},
	{"kind": "dead", "like": 0, "seed": 671},
	{"kind": "log", "seed": 673, "length": Vector2(5.0, 6.5), "r0": 0.11, "r1": 0.05, "bow": 0.3, "stubs": Vector2i(3, 6)},
	{"kind": "log", "seed": 679, "length": Vector2(1.6, 2.2), "r0": 0.15, "r1": 0.14, "bow": 0.02, "stubs": Vector2i(0, 1)},
	# saplings, 1-2 m: a whip with a few big leaves (the thickets' suckers)
	{"kind": "sapling", "trunk_h": 0.4, "leader_h": 1.2, "trunk_r": 0.02, "limbs": 4, "limb_angle": 60.0, "limb_len": 0.5, "branch_len": 0.3, "twig_len": 0.25, "lean": 0.0, "droop": 0.0, "seed": 683, "crown": [0.6, 1.8, 0.4]},
	{"kind": "sapling", "trunk_h": 0.3, "leader_h": 0.9, "trunk_r": 0.018, "limbs": 3, "limb_angle": 62.0, "limb_len": 0.45, "branch_len": 0.25, "twig_len": 0.2, "lean": 4.0, "droop": 0.0, "seed": 689, "crown": [0.5, 1.3, 0.3]},
	{"kind": "dead", "like": 1, "seed": 697},
	{"kind": "dead", "like": 3, "seed": 703},
]

const SETTINGS := {
	"seg": [0.4, 0.35, 0.28, 0.22],
	"crook": [0.03, 0.12, 0.18, 0.2],
	"up": [0.0, 0.0, 0.02, 0.0], # (branches level, a little drooping)
	"child_angle": [0.0, 0.9, 0.85, 0.8],
	"opposite": false,
	"irregular": 0.25,
	"tip_r": 0.004,
	"card_size": 0.98, # (big leaves: the tiles cover 0.7 m)
	"bark_tex": "res://data/population/textures/pawpaw_bark.png",
	"leaf_tex": "res://data/population/textures/pawpaw_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.82, 0.8, 0.76),
	"log_tint": Color(0.8, 0.82, 0.72),
	"shadow": [2.6, 1.6, 7.6, 0.1],
	# as a prop (data/population/props/pawpaw.tres: in the forest's
	# understory): drawn to 300 m (small trees); the standing ones, saplings
	# and dead gathered in thickets (clonal patches, from one root); their
	# trunks slender (a small foot, a small solid trunk)
	"props": {
		"all": {"view_distance": 300.0, "radius": 0.0},
		"tree": {"foot": 0.12, "radius": 0.14, "clump": {"forest": 1.0}, "clump_size": 16.0},
		"sapling": {"foot": 0.03, "radius": 0.0, "clump": {"forest": 1.0}, "clump_size": 16.0},
		"dead": {"foot": 0.12, "radius": 0.14, "clump": {"forest": 1.0}, "clump_size": 16.0, "min_spacing": 0.0},
		"stump": {"foot": 0.12},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("pawpaw", SETTINGS, VARIANTS)
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
