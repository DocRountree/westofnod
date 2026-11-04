class_name CrabappleTree
## A wild crabapple (Malus, the prairie and sweet crabapples): four standing
## trees, a stump, three fallen logs, three dead standing trees and two
## saplings (variants 0-12, as the oak's), grown by SpeciesTree and dressed
## with data/population/textures/crabapple_*.png
## (tools/trees/bake_small_tree_textures.py). In the game
## (data/population/props/); tools/trees/preview.gd -- <out> crabapple draws them.
##
## What makes it read as a crabapple: a small tree, 5-8 m, on a short
## trunk, often several stems; crooked, gnarled limbs spreading low into a
## broad, rounded, dense, twiggy crown, wider than tall; small oval
## leaves, 5-8 cm, sharply toothed, clustered on short spurs; little
## crabapples, 2-3 cm, red to yellow-green, hanging on long stalks;
## grey-brown bark flaking off in small scaly plates, orange-brown beneath.

const VARIANTS := [
	# open-grown: a short trunk, gnarled limbs spreading into a broad dome
	{"trunk_h": 1.4, "leader_h": 2.4, "trunk_r": 0.2, "limbs": 7, "limb_angle": 60.0, "limb_len": 3.9, "branch_len": 1.8, "twig_len": 0.6, "lean": 0.0, "droop": 0.02, "seed": 711, "crown": [4.0, 6.6, 1.4]},
	# young: upright, a small round head
	{"trunk_h": 1.3, "leader_h": 2.6, "trunk_r": 0.09, "limbs": 6, "limb_angle": 50.0, "limb_len": 2.3, "branch_len": 1.1, "twig_len": 0.5, "lean": 0.0, "droop": 0.0, "seed": 723, "crown": [2.4, 5.0, 1.4]},
	# several stems from the ground, a wide, low crown
	{"trunk_h": 0.4, "leader_h": 2.6, "trunk_r": 0.2, "limbs": 6, "forks": 3, "fork_angle": 32.0, "fork_len": 1.1, "limb_angle": 62.0, "limb_len": 3.2, "branch_len": 1.5, "twig_len": 0.55, "lean": 0.0, "droop": 0.02, "seed": 741, "crown": [3.8, 5.8, 0.9]},
	# old and gnarled, leaning, its crown heavy to one side
	{"trunk_h": 1.2, "leader_h": 2.0, "trunk_r": 0.26, "limbs": 6, "limb_angle": 66.0, "limb_len": 4.2, "branch_len": 1.9, "twig_len": 0.6, "lean": 12.0, "droop": 0.04, "seed": 753, "crown": [4.2, 6.0, 1.2]},
	{"kind": "stump", "seed": 761, "r": 0.24, "flare": 0.35},
	{"kind": "log", "seed": 767, "length": Vector2(2.6, 3.8), "r0": 0.2, "r1": 0.13, "bow": 0.3, "stubs": Vector2i(3, 5)},
	{"kind": "dead", "like": 0, "seed": 771},
	{"kind": "log", "seed": 773, "length": Vector2(4.0, 5.0), "r0": 0.15, "r1": 0.07, "bow": 0.45, "stubs": Vector2i(4, 6)},
	{"kind": "log", "seed": 779, "length": Vector2(1.4, 2.0), "r0": 0.27, "r1": 0.24, "bow": 0.04, "stubs": Vector2i(1, 2)},
	# saplings, 1.5-2.5 m: twiggy, a little round head
	{"kind": "sapling", "trunk_h": 0.6, "leader_h": 1.4, "trunk_r": 0.025, "limbs": 5, "limb_angle": 50.0, "limb_len": 0.8, "branch_len": 0.45, "twig_len": 0.25, "lean": 0.0, "droop": 0.0, "seed": 783, "crown": [0.9, 2.3, 0.6]},
	{"kind": "sapling", "trunk_h": 0.3, "leader_h": 1.1, "trunk_r": 0.025, "limbs": 5, "limb_angle": 58.0, "limb_len": 0.8, "branch_len": 0.4, "twig_len": 0.25, "lean": 5.0, "droop": 0.0, "seed": 789, "crown": [1.0, 1.8, 0.3]},
	{"kind": "dead", "like": 2, "seed": 797},
	{"kind": "dead", "like": 3, "seed": 803},
]

const SETTINGS := {
	"fruit": "crabapple", # (Foraging: hung on the grown trees, picked one by one with a left click)
	"seg": [0.4, 0.42, 0.3, 0.2],
	"crook": [0.06, 0.26, 0.33, 0.36], # (gnarled, zigzag)
	"up": [0.0, 0.01, 0.05, 0.08],
	"child_angle": [0.0, 0.9, 0.95, 0.9],
	"opposite": false,
	"irregular": 0.35,
	"tip_r": 0.004,
	"card_size": 0.7,
	"bark_tex": "res://data/population/textures/crabapple_bark.png",
	"leaf_tex": "res://data/population/textures/crabapple_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.8, 0.78, 0.74),
	"log_tint": Color(0.78, 0.8, 0.7),
	"shadow": [3.6, 1.4, 6.6, 0.18],
	# as a prop (data/population/props/crabapple.tres: a few in the forest
	# and out on the prairie): straying only where it grows, none in the
	# swamp; small trees, drawn to 400 m, their trunks slender
	"props": {
		"all": {"strict": true, "not_in_swamp": true, "view_distance": 400.0},
		"tree": {"foot": 0.25, "radius": 0.2},
		"dead": {"foot": 0.25, "radius": 0.2},
		"sapling": {"foot": 0.04, "radius": 0.0},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("crabapple", SETTINGS, VARIANTS)
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


## The stump an axe leaves (Felling): this species' own, sawn flat.
static func fresh_stump() -> Array:
	return species().fresh_stump()


## What fruit variant v bears (Foraging): an item id, "" none.
static func fruit_of(variant: int) -> String:
	return species().fruit_of(variant)


## Where variant v's fruit hang (Foraging), its own space.
static func fruit_spots(variant: int) -> PackedVector3Array:
	return species().fruit_spots(variant)
