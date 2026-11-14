class_name BlackCherryTree
## A wild black cherry (Prunus serotina): four standing trees, a stump,
## logs, dead standing trees and saplings (variants 0-11, as the oak's),
## grown by SpeciesTree and dressed with
## data/population/textures/black_cherry_*.png
## (tools/trees/bake_fruit_plant_textures.py). In the game
## (data/population/props/black_cherry.tres).
##
## What makes it read as a black cherry: a tall tree, 15-25 m, its trunk
## straight and long, clear of branches a good way up; its crown narrow,
## oval, open, the limbs rising; the leaves lance-shaped, 6-12 cm, finely
## toothed, glossy dark green; its bark near black, broken into small, thin,
## scaly plates curling up at their edges ("burnt potato chips"), red brown
## between; its cherries small (1 cm), black purple when ripe, hanging in
## long drooping clusters out on the lower crown (Foraging: picked one by
## one, up in the tree: climb it).

const VARIANTS := [
	# forest grown: a long straight trunk, a narrow oval crown high up
	{"trunk_h": 6.0, "leader_h": 8.0, "trunk_r": 0.28, "limbs": 8, "limb_angle": 42.0, "limb_len": 4.6, "branch_len": 2.0, "twig_len": 0.7, "lean": 0.0, "droop": 0.03, "seed": 911, "crown": [4.2, 18.0, 6.5]},
	# open grown: lower limbs, a broader crown
	{"trunk_h": 3.2, "leader_h": 6.0, "trunk_r": 0.3, "limbs": 9, "limb_angle": 50.0, "limb_len": 5.0, "branch_len": 2.2, "twig_len": 0.7, "lean": 0.0, "droop": 0.05, "seed": 923, "crown": [5.0, 14.0, 3.2]},
	# young: slender, upright
	{"trunk_h": 2.5, "leader_h": 4.0, "trunk_r": 0.13, "limbs": 7, "limb_angle": 40.0, "limb_len": 2.6, "branch_len": 1.2, "twig_len": 0.55, "lean": 0.0, "droop": 0.0, "seed": 937, "crown": [2.4, 9.0, 2.5]},
	# leaning, its crown to one side
	{"trunk_h": 4.5, "leader_h": 7.0, "trunk_r": 0.25, "limbs": 7, "limb_angle": 48.0, "limb_len": 4.2, "branch_len": 1.9, "twig_len": 0.65, "lean": 9.0, "droop": 0.04, "seed": 941, "crown": [4.0, 15.0, 4.5]},
	{"kind": "stump", "seed": 953, "r": 0.28, "flare": 0.3},
	{"kind": "log", "seed": 959, "length": Vector2(5.0, 7.0), "r0": 0.26, "r1": 0.16, "bow": 0.2, "stubs": Vector2i(3, 5)},
	{"kind": "dead", "like": 0, "seed": 967},
	{"kind": "log", "seed": 971, "length": Vector2(2.4, 3.4), "r0": 0.3, "r1": 0.26, "bow": 0.05, "stubs": Vector2i(1, 3)},
	{"kind": "sapling", "trunk_h": 0.8, "leader_h": 1.6, "trunk_r": 0.025, "limbs": 5, "limb_angle": 45.0, "limb_len": 0.7, "branch_len": 0.35, "twig_len": 0.22, "lean": 0.0, "droop": 0.0, "seed": 977, "crown": [0.8, 2.6, 0.7]},
	{"kind": "sapling", "trunk_h": 0.5, "leader_h": 1.3, "trunk_r": 0.022, "limbs": 4, "limb_angle": 50.0, "limb_len": 0.6, "branch_len": 0.3, "twig_len": 0.2, "lean": 4.0, "droop": 0.0, "seed": 983, "crown": [0.7, 2.0, 0.5]},
	{"kind": "dead", "like": 3, "seed": 991},
	{"kind": "dead", "like": 2, "seed": 997},
]

const SETTINGS := {
	"fruit": "black_cherry",
	"seg": [0.55, 0.55, 0.35, 0.22],
	"crook": [0.03, 0.14, 0.24, 0.3],
	"up": [0.0, 0.03, 0.06, 0.06],
	"child_angle": [0.0, 0.75, 0.85, 0.85],
	"opposite": false,
	"irregular": 0.2,
	"tip_r": 0.004,
	"card_size": 0.8,
	"bark_tex": "res://data/population/textures/black_cherry_bark.png",
	"leaf_tex": "res://data/population/textures/black_cherry_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.8, 0.76, 0.72),
	"log_tint": Color(0.8, 0.8, 0.72),
	"shadow": [4.2, 6.5, 18.0, 0.3],
	"props": {
		"all": {"not_in_swamp": true},
		"tree": {"foot": 0.3, "radius": 0.28},
		"dead": {"foot": 0.3, "radius": 0.25},
		"sapling": {"foot": 0.04, "radius": 0.0},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("black_cherry", SETTINGS, VARIANTS)
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


static func near_multimesh(variant := 0) -> Array:
	return species().near_multimesh(variant)


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
