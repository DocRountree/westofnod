class_name BlueberryBush
## A wild highbush blueberry (Vaccinium corymbosum): a clump of many stems,
## 1.2-2.5 m, grown by SpeciesTree (variants 0-3) and dressed with
## data/population/textures/blueberry_*.png
## (tools/trees/bake_fruit_plant_textures.py). In the game
## (data/population/props/blueberry.tres: in the forest's openings, in the
## swamp's edges).
##
## What makes it read as a blueberry: many stems from the ground, upright,
## spreading into a rounded, twiggy crown; the old stems grey brown,
## shredding, the twigs zigzag, warm red; the leaves small (2-5 cm),
## elliptic, smooth edged, blue green, a few turning red; its berries small
## (1 cm), dusky blue under a pale bloom, a little five-pointed crown at
## their tips, in clusters out along the twigs (Foraging: picked one by one).

const VARIANTS := [
	{"trunk_h": 0.06, "leader_h": 1.2, "trunk_r": 0.018, "limbs": 4, "forks": 6, "fork_angle": 20.0, "fork_len": 2.8, "limb_angle": 45.0, "limb_len": 0.5, "branch_len": 0.28, "twig_len": 0.15, "lean": 0.0, "droop": 0.05, "seed": 1111, "crown": [0.9, 1.9, 0.4]},
	{"trunk_h": 0.05, "leader_h": 1.5, "trunk_r": 0.02, "limbs": 4, "forks": 7, "fork_angle": 16.0, "fork_len": 3.2, "limb_angle": 42.0, "limb_len": 0.55, "branch_len": 0.3, "twig_len": 0.15, "lean": 0.0, "droop": 0.04, "seed": 1123, "crown": [1.0, 2.3, 0.5]},
	{"trunk_h": 0.05, "leader_h": 0.9, "trunk_r": 0.015, "limbs": 4, "forks": 5, "fork_angle": 24.0, "fork_len": 2.3, "limb_angle": 50.0, "limb_len": 0.45, "branch_len": 0.25, "twig_len": 0.14, "lean": 0.0, "droop": 0.06, "seed": 1137, "crown": [0.8, 1.5, 0.35]},
	{"trunk_h": 0.06, "leader_h": 1.3, "trunk_r": 0.018, "limbs": 4, "forks": 6, "fork_angle": 22.0, "fork_len": 2.8, "limb_angle": 46.0, "limb_len": 0.5, "branch_len": 0.28, "twig_len": 0.15, "lean": 6.0, "droop": 0.05, "seed": 1143, "crown": [0.9, 2.0, 0.4]},
]

const SETTINGS := {
	"far_card": false, # (a bush: no far card, its last level to OakTree.VIEW)
	"fruit": "blueberry",
	"fruit_band": Vector2(0.1, 0.92),
	"seg": [0.22, 0.2, 0.14, 0.09],
	"crook": [0.04, 0.16, 0.3, 0.35],
	"up": [0.0, 0.02, 0.04, 0.04],
	"child_angle": [0.0, 0.8, 0.85, 0.85],
	"opposite": false,
	"irregular": 0.3,
	"tip_r": 0.0025,
	"card_size": 0.4,
	"bark_tex": "res://data/population/textures/blueberry_bark.png",
	"leaf_tex": "res://data/population/textures/blueberry_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"climb_limb_r": 9.0, # (nothing on it to climb)
	"shadow": [0.9, 0.4, 1.9, 0.06],
	"props": {
		"all": {"radius": 0.0, "foot": 0.02},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("blueberry", SETTINGS, VARIANTS)
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
