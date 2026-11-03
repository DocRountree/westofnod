class_name WalnutTree
## The black walnut (Juglans nigra): four standing trees, a stump, three
## fallen logs, three dead standing trees and two saplings (variants 0-12,
## as the oak's), grown by SpeciesTree and dressed with
## data/population/textures/walnut_*.png
## (tools/trees/bake_walnut_textures.py). In the game
## (data/population/props/walnut.tres); tools/trees/preview.gd -- <out>
## walnut draws them.
##
## What makes it read as a black walnut: a tall, straight trunk, in a stand
## a long clean bole under a small crown; a few stout limbs, alternate,
## ascending then spreading into an open, rounded, rather thin crown (light
## comes through it); stout twigs, few of them; big pinnately compound leaves,
## 30-60 cm, of 11-19 narrow, finely toothed leaflets, crowded toward the
## twigs' ends (so the foliage is in tufts, the inner crown bare); round green
## walnuts in their husks under the twigs (the item "walnut": Foraging hangs
## them on the grown trees, picked one by one as the pawpaw's); bark dark
## brown to nearly black, deeply furrowed, the narrow ridges interlacing in
## diamonds.

const VARIANTS := [
	# open-grown: a short, stout trunk, a few big limbs, a broad open dome
	{"trunk_h": 3.5, "leader_h": 10.0, "trunk_r": 0.5, "limbs": 7, "limb_angle": 52.0, "limb_len": 9.0, "branch_len": 3.8, "twig_len": 1.0, "lean": 0.0, "droop": 0.0, "seed": 811, "crown": [8.5, 21.0, 4.5]},
	# young: slim and straight, a strong leader, a narrow oval
	{"trunk_h": 3.5, "leader_h": 9.0, "trunk_r": 0.24, "limbs": 7, "limb_angle": 42.0, "limb_len": 5.0, "branch_len": 2.4, "twig_len": 0.9, "lean": 0.0, "droop": 0.0, "seed": 823, "crown": [4.5, 16.0, 4.0]},
	# leaning toward the light, the crown heavier on that side
	{"trunk_h": 4.0, "leader_h": 9.0, "trunk_r": 0.42, "limbs": 6, "limb_angle": 48.0, "limb_len": 8.0, "branch_len": 3.4, "twig_len": 1.0, "lean": 8.0, "droop": 0.02, "seed": 841, "crown": [7.5, 19.5, 5.0]},
	# forest-grown: a long clean bole, a small high crown
	{"trunk_h": 10.0, "leader_h": 9.0, "trunk_r": 0.45, "limbs": 6, "limb_angle": 40.0, "limb_len": 6.0, "branch_len": 2.8, "twig_len": 0.95, "lean": 0.0, "droop": 0.0, "seed": 853, "crown": [5.5, 26.0, 11.0]},
	{"kind": "stump", "seed": 861, "r": 0.5, "flare": 0.4},
	{"kind": "log", "seed": 867, "r0": 0.42, "r1": 0.3},
	{"kind": "dead", "like": 0, "seed": 871, "limb_angle": 44.0, "limb_len": 7.5, "branch_len": 3.0, "crown": [7.0, 19.0, 4.5]},
	{"kind": "log", "seed": 873, "length": Vector2(8.5, 10.5), "r0": 0.34, "r1": 0.16, "bow": 0.3, "stubs": Vector2i(3, 5)},
	{"kind": "log", "seed": 879, "length": Vector2(2.8, 3.6), "r0": 0.55, "r1": 0.5, "bow": 0.05, "stubs": Vector2i(0, 1)},
	# saplings, 3-4 m: a straight whip with a few side shoots, and a bushier one
	{"kind": "sapling", "trunk_h": 1.1, "leader_h": 2.4, "trunk_r": 0.045, "limbs": 4, "limb_angle": 42.0, "limb_len": 1.3, "branch_len": 0.7, "twig_len": 0.45, "lean": 0.0, "droop": 0.0, "seed": 883, "crown": [1.2, 4.0, 1.1]},
	{"kind": "sapling", "trunk_h": 0.6, "leader_h": 2.2, "trunk_r": 0.05, "limbs": 5, "limb_angle": 50.0, "limb_len": 1.5, "branch_len": 0.7, "twig_len": 0.45, "lean": 3.0, "droop": 0.0, "seed": 889, "crown": [1.5, 3.6, 0.7]},
	{"kind": "dead", "like": 1, "seed": 897, "limb_angle": 34.0, "limb_len": 4.2, "branch_len": 2.0, "crown": [4.0, 15.0, 4.0]},
	{"kind": "dead", "like": 3, "seed": 903, "lean": 5.0, "limb_angle": 40.0, "limb_len": 5.0, "branch_len": 2.4, "crown": [4.8, 24.0, 10.5]},
]

const SETTINGS := {
	"fruit": "walnut", # (Foraging: picked from the grown trees, a click with a hand empty)
	"seg": [0.55, 0.7, 0.5, 0.4], # (long, stout shoots: few nodes)
	"crook": [0.03, 0.12, 0.2, 0.24],
	"up": [0.0, 0.015, 0.05, 0.07], # (limbs ascending, then spreading)
	"child_angle": [0.0, 0.8, 0.8, 0.75],
	"opposite": false, # (alternate)
	"irregular": 0.3, # (an open, uneven crown)
	"tip_r": 0.008, # (stout twigs)
	"card_size": 1.12, # (big compound leaves: the sprig tiles are 0.8 m)
	"bark_tex": "res://data/population/textures/walnut_bark.png",
	"leaf_tex": "res://data/population/textures/walnut_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.82, 0.8, 0.77), # (weathered greyer, still dark)
	"log_tint": Color(0.82, 0.85, 0.75),
	"shadow": [7.5, 4.5, 20.0, 0.45],
	# as a prop (data/population/props/walnut.tres: the forest's, a few on
	# the prairie): straying only where it grows (none into the taiga), none
	# in the swamp nor on its mud
	"props": {
		"all": {"strict": true, "not_in_swamp": true},
		# no dead walnuts standing, and none lying fallen of themselves:
		# only the logs an axe leaves (their models kept: variants 5-8 and
		# 6, 11, 12 as the oak's, so the kinds' indices stay as they were)
		"dead": {"weight": 0.0, "density_like": {}},
		"log": {"weight": 0.0},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("walnut", SETTINGS, VARIANTS)
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


## What fruit variant v bears (Foraging): an item id, "" none (the grown
## trees: walnuts).
static func fruit_of(variant: int) -> String:
	return species().fruit_of(variant)


## Where variant v's walnuts hang (Foraging), its own space.
static func fruit_spots(variant: int) -> PackedVector3Array:
	return species().fruit_spots(variant)
