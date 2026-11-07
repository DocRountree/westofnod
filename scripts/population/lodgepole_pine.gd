class_name LodgepolePine
## The lodgepole pine (Pinus contorta var. latifolia): four standing trees,
## a stump, three fallen logs, three dead standing trees (grey snags, as
## the beetles leave them) and two saplings (variants 0-12, as the oak's),
## grown by SpeciesTree as a conifer and dressed with
## data/population/textures/lodgepole_*.png
## (tools/trees/bake_conifer_textures.py). In the game
## (data/population/props/); tools/trees/preview.gd -- <out> lodgepole draws them.
##
## What makes it read as a lodgepole: a very straight, slender, barely
## tapering trunk; in a stand, bare for most of its height (it sheds its
## lower branches, leaving snapped stubs), a short, narrow crown at the
## top; in the open, a narrow cone down to the ground; short branches,
## level or drooping a little, in whorls; yellow-green needles in pairs,
## 4-7 cm, crowded in bottlebrush tufts toward the shoots' ends, small
## lopsided cones clustered on the branches; thin bark in small,
## orange-brown to grey scales.

const VARIANTS := [
	# open-grown: a narrow cone, branches nearly to the ground
	{"trunk_h": 1.5, "leader_h": 15.5, "trunk_r": 0.26, "whorls": 20, "per_whorl": 5, "profile": "cone", "limb_angle": 88.0, "droop_low": 12.0, "limb_len": 3.4, "branch_len": 1.1, "twig_len": 0.45, "lean": 0.0, "droop": 0.0, "seed": 411, "crown": [3.4, 17.5, 1.5], "stubs": 0},
	# young: a small, dense cone
	{"trunk_h": 0.8, "leader_h": 8.5, "trunk_r": 0.14, "whorls": 14, "per_whorl": 5, "profile": "cone", "limb_angle": 82.0, "droop_low": 10.0, "limb_len": 2.2, "branch_len": 0.8, "twig_len": 0.4, "lean": 0.0, "droop": 0.0, "seed": 423, "crown": [2.2, 9.6, 0.8], "stubs": 0},
	# grown in a stand: a tall bare pole, a short narrow crown at the top
	{"trunk_h": 13.0, "leader_h": 10.0, "trunk_r": 0.24, "whorls": 12, "per_whorl": 4, "profile": "narrow", "limb_angle": 84.0, "droop_low": 14.0, "limb_len": 2.1, "branch_len": 0.8, "twig_len": 0.4, "lean": 0.0, "droop": 0.0, "seed": 441, "crown": [2.0, 23.5, 15.0], "stubs": 16},
	# the same, leaning a little, its crown thinner
	{"trunk_h": 11.0, "leader_h": 9.5, "trunk_r": 0.21, "whorls": 10, "per_whorl": 4, "profile": "narrow", "limb_angle": 86.0, "droop_low": 16.0, "limb_len": 1.9, "branch_len": 0.7, "twig_len": 0.4, "lean": 4.0, "droop": 0.0, "seed": 453, "crown": [1.8, 21.0, 13.5], "stubs": 12},
	{"kind": "stump", "seed": 461, "r": 0.26, "flare": 0.3},
	{"kind": "log", "seed": 467, "length": Vector2(9.0, 12.0), "r0": 0.22, "r1": 0.14, "bow": 0.1, "stubs": Vector2i(5, 9)},
	{"kind": "dead", "like": 2, "seed": 471},
	{"kind": "log", "seed": 473, "length": Vector2(12.0, 15.0), "r0": 0.18, "r1": 0.09, "bow": 0.18, "stubs": Vector2i(8, 12)},
	{"kind": "log", "seed": 479, "length": Vector2(3.0, 4.0), "r0": 0.26, "r1": 0.24, "bow": 0.02, "stubs": Vector2i(1, 2)},
	# saplings, 2-3 m: little cones
	{"kind": "sapling", "trunk_h": 0.3, "leader_h": 2.4, "trunk_r": 0.035, "whorls": 7, "per_whorl": 5, "profile": "cone", "limb_angle": 75.0, "droop_low": 5.0, "limb_len": 0.9, "branch_len": 0.35, "twig_len": 0.25, "lean": 0.0, "droop": 0.0, "seed": 483, "crown": [0.9, 2.7, 0.3]},
	{"kind": "sapling", "trunk_h": 0.2, "leader_h": 1.8, "trunk_r": 0.03, "whorls": 6, "per_whorl": 4, "profile": "cone", "limb_angle": 72.0, "droop_low": 5.0, "limb_len": 0.8, "branch_len": 0.3, "twig_len": 0.22, "lean": 3.0, "droop": 0.0, "seed": 489, "crown": [0.8, 2.0, 0.2]},
	{"kind": "dead", "like": 0, "seed": 497},
	{"kind": "dead", "like": 3, "seed": 503, "lean": 7.0},
]

const SETTINGS := {
	"climb_limb_r": 0.1, # (only its stoutest limbs climbable: its many little whorled branches got in the way)
	"seg": [0.5, 0.3, 0.22, 0.16],
	"crook": [0.012, 0.12, 0.2, 0.25], # (a ramrod trunk)
	"up": [0.0, 0.0, 0.035, 0.06],
	"child_angle": [0.0, 0.75, 0.8, 0.8],
	"opposite": false,
	"irregular": 0.0,
	"tip_r": 0.004,
	"twig_bark": false, # (its twigs, inside the sprays, not drawn: SpeciesTree.twig_bark)
	"card_size": 0.6,
	"bark_tex": "res://data/population/textures/lodgepole_bark.png",
	"leaf_tex": "res://data/population/textures/lodgepole_needles.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.86, 0.84, 0.8), # (a snag, silver-grey)
	"log_tint": Color(0.8, 0.8, 0.72),
	"shadow": [2.6, 9.0, 21.0, 0.24],
	# as a prop (data/population/props/lodgepole.tres: the taiga's, with the
	# bald cypresses as thick as the oaks in the forest, thinning out up the
	# mountains to none past 1350 m; a few in the forest): straying only
	# where it grows (never onto the prairie, nor into the swamp)
	"props": {
		"all": {"strict": true, "not_in_swamp": true},
		"tree": {"foot": 0.35},
		"dead": {"foot": 0.35},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("lodgepole", SETTINGS, VARIANTS)
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
