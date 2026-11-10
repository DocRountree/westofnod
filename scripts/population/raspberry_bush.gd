class_name RaspberryBush
## A wild raspberry (Rubus idaeus, the American red raspberry): a clump of
## arching canes, 1-1.8 m, grown by SpeciesTree (its "trees" stools of canes:
## variants 0-3) and dressed with data/population/textures/raspberry_*.png
## (tools/trees/bake_fruit_plant_textures.py). In the game
## (data/population/props/raspberry.tres: at the forest's edges and in its
## clearings, out on the prairie a little).
##
## What makes it read as a raspberry: many canes from the ground, rising and
## arching over, purplish red brown under a whitish bloom, finely prickly;
## the leaves compound, three leaflets (five on the first-year canes),
## ovate, coarsely double-toothed, wrinkled; its berries red, a cap of
## little drupelets, hanging under the leaves all over the clump (Foraging:
## picked one by one).

const VARIANTS := [
	{"trunk_h": 0.05, "leader_h": 1.0, "trunk_r": 0.012, "limbs": 3, "forks": 7, "fork_angle": 34.0, "fork_len": 2.0, "limb_angle": 60.0, "limb_len": 0.55, "branch_len": 0.3, "twig_len": 0.18, "lean": 0.0, "droop": 0.25, "seed": 1011, "crown": [0.9, 1.6, 0.25]},
	{"trunk_h": 0.04, "leader_h": 0.9, "trunk_r": 0.011, "limbs": 3, "forks": 6, "fork_angle": 40.0, "fork_len": 1.8, "limb_angle": 62.0, "limb_len": 0.5, "branch_len": 0.28, "twig_len": 0.16, "lean": 0.0, "droop": 0.3, "seed": 1023, "crown": [1.0, 1.4, 0.2]},
	{"trunk_h": 0.05, "leader_h": 1.2, "trunk_r": 0.013, "limbs": 3, "forks": 8, "fork_angle": 30.0, "fork_len": 2.4, "limb_angle": 58.0, "limb_len": 0.6, "branch_len": 0.3, "twig_len": 0.18, "lean": 5.0, "droop": 0.28, "seed": 1037, "crown": [1.1, 1.8, 0.3]},
	{"trunk_h": 0.04, "leader_h": 0.7, "trunk_r": 0.01, "limbs": 2, "forks": 5, "fork_angle": 36.0, "fork_len": 1.6, "limb_angle": 60.0, "limb_len": 0.4, "branch_len": 0.22, "twig_len": 0.14, "lean": 0.0, "droop": 0.2, "seed": 1043, "crown": [0.7, 1.1, 0.2]},
]

const SETTINGS := {
	"far_card": false, # (a bush: no far card, its last level to OakTree.VIEW)
	"fruit": "raspberry",
	"fruit_band": Vector2(0.1, 0.9),
	"seg": [0.2, 0.2, 0.14, 0.1],
	"crook": [0.05, 0.1, 0.2, 0.25],
	"up": [0.0, -0.02, 0.0, 0.02],
	"child_angle": [0.0, 0.9, 0.9, 0.8],
	"opposite": false,
	"irregular": 0.4,
	"tip_r": 0.003,
	"card_size": 0.5,
	"bark_tex": "res://data/population/textures/raspberry_bark.png",
	"leaf_tex": "res://data/population/textures/raspberry_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"lichen": false,
	"climb_limb_r": 9.0, # (nothing on it to climb)
	"shadow": [0.9, 0.2, 1.6, 0.05],
	"props": {
		"all": {"not_in_swamp": true, "radius": 0.0, "foot": 0.02},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("raspberry", SETTINGS, VARIANTS)
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
