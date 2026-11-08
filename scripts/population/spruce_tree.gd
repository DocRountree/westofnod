class_name SpruceTree
## The spruce (Picea engelmannii, the Engelmann spruce, with something of
## the subalpine fir that grows among it): five standing trees, a stump,
## three fallen logs, three dead standing trees and three saplings
## (variants 0-14, as the oak's), grown by SpeciesTree as a conifer and
## dressed with data/population/textures/spruce_*.png
## (tools/trees/bake_conifer_textures.py --spruce). In the game
## (data/population/props/spruce.tres: the taiga's, up toward the treeline
## but not to it); tools/trees/preview.gd -- <out> spruce draws them.
##
## What makes it read as a spruce: a narrow, steep spire, crowned to the
## ground or nearly, its point sharp; dense, many short branches in close
## whorls, the lower ones sweeping down and turning up again at their
## tips, the top ones lifted; dark blue-green needles, short and stiff, all
## round the shoots, the new growth at the tips fresher; thin grey-brown
## bark in small scales.

const VARIANTS := [
	# a tall spire, crowned to the ground
	{"trunk_h": 0.6, "leader_h": 21.0, "trunk_r": 0.3, "whorls": 34, "per_whorl": 6, "profile": "spire", "limb_angle": 100.0, "droop_low": 14.0, "lift_top": 40.0, "limb_len": 2.6, "branch_len": 0.9, "twig_len": 0.35, "lean": 0.0, "droop": 0.18, "seed": 1101, "crown": [2.6, 21.6, 0.5], "stubs": 0},
	# middling
	{"trunk_h": 0.5, "leader_h": 15.5, "trunk_r": 0.22, "whorls": 28, "per_whorl": 6, "profile": "spire", "limb_angle": 98.0, "droop_low": 12.0, "lift_top": 40.0, "limb_len": 2.1, "branch_len": 0.8, "twig_len": 0.32, "lean": 0.0, "droop": 0.16, "seed": 1123, "crown": [2.1, 16.0, 0.4], "stubs": 0},
	# young: a small, dense spire
	{"trunk_h": 0.3, "leader_h": 8.5, "trunk_r": 0.12, "whorls": 20, "per_whorl": 5, "profile": "spire", "limb_angle": 92.0, "droop_low": 10.0, "lift_top": 35.0, "limb_len": 1.5, "branch_len": 0.6, "twig_len": 0.3, "lean": 0.0, "droop": 0.12, "seed": 1131, "crown": [1.5, 8.8, 0.2], "stubs": 0},
	# grown in a stand: the lower trunk bare, a few dead stubs
	{"trunk_h": 5.0, "leader_h": 18.0, "trunk_r": 0.28, "whorls": 28, "per_whorl": 5, "profile": "spire", "limb_angle": 102.0, "droop_low": 16.0, "lift_top": 40.0, "limb_len": 2.2, "branch_len": 0.8, "twig_len": 0.33, "lean": 2.0, "droop": 0.2, "seed": 1147, "crown": [2.2, 23.0, 5.0], "stubs": 10},
	# old, a little broader at the foot, its top leaning
	{"trunk_h": 0.8, "leader_h": 24.0, "trunk_r": 0.38, "whorls": 36, "per_whorl": 6, "profile": "spire", "limb_angle": 104.0, "droop_low": 18.0, "lift_top": 40.0, "limb_len": 3.1, "branch_len": 1.0, "twig_len": 0.36, "lean": 3.0, "droop": 0.22, "seed": 1153, "crown": [3.1, 24.8, 0.7], "stubs": 3},
	{"kind": "stump", "seed": 1161, "r": 0.3, "flare": 0.35},
	{"kind": "log", "seed": 1163, "length": Vector2(10.0, 14.0), "r0": 0.26, "r1": 0.12, "bow": 0.08, "stubs": Vector2i(10, 16)},
	{"kind": "dead", "like": 0, "seed": 1171},
	{"kind": "log", "seed": 1181, "length": Vector2(6.0, 8.0), "r0": 0.2, "r1": 0.13, "bow": 0.12, "stubs": Vector2i(8, 12)},
	{"kind": "log", "seed": 1187, "length": Vector2(3.0, 4.0), "r0": 0.3, "r1": 0.27, "bow": 0.02, "stubs": Vector2i(2, 4)},
	# saplings, 1-3 m: little spires, dense, branched to the ground
	{"kind": "sapling", "trunk_h": 0.1, "leader_h": 2.6, "trunk_r": 0.035, "whorls": 9, "per_whorl": 5, "profile": "spire", "limb_angle": 85.0, "droop_low": 6.0, "lift_top": 30.0, "limb_len": 0.75, "branch_len": 0.3, "twig_len": 0.2, "lean": 0.0, "droop": 0.05, "seed": 1193, "crown": [0.75, 2.7, 0.1]},
	{"kind": "sapling", "trunk_h": 0.1, "leader_h": 1.6, "trunk_r": 0.025, "whorls": 7, "per_whorl": 4, "profile": "spire", "limb_angle": 82.0, "droop_low": 5.0, "lift_top": 30.0, "limb_len": 0.55, "branch_len": 0.25, "twig_len": 0.18, "lean": 2.0, "droop": 0.04, "seed": 1201, "crown": [0.55, 1.7, 0.1]},
	{"kind": "dead", "like": 3, "seed": 1213},
	{"kind": "dead", "like": 1, "seed": 1217, "lean": 6.0},
	{"kind": "sapling", "trunk_h": 0.05, "leader_h": 0.9, "trunk_r": 0.018, "whorls": 5, "per_whorl": 4, "profile": "spire", "limb_angle": 80.0, "droop_low": 4.0, "lift_top": 25.0, "limb_len": 0.35, "branch_len": 0.18, "twig_len": 0.14, "lean": 0.0, "droop": 0.0, "seed": 1223, "crown": [0.35, 0.95, 0.05]},
]

const SETTINGS := {
	"climb_limb_r": 0.1,
	"seg": [0.5, 0.28, 0.2, 0.15],
	"crook": [0.01, 0.1, 0.18, 0.22], # (a ramrod trunk)
	"up": [0.0, 0.07, 0.05, 0.06], # (the limbs, drooping from the trunk, turn up toward their tips)
	"child_angle": [0.0, 0.8, 0.85, 0.8],
	"opposite": false,
	"irregular": 0.0,
	"tip_r": 0.004,
	"twig_bark": false,
	"card_size": 0.42,
	"bark_tex": "res://data/population/textures/spruce_bark.png",
	"leaf_tex": "res://data/population/textures/spruce_needles.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.82, 0.8, 0.77),
	"log_tint": Color(0.78, 0.77, 0.7),
	"shadow": [2.2, 1.0, 22.0, 0.28],
	# as a prop (data/population/props/spruce.tres): the taiga's, from the
	# valleys up to just below the treeline (and none of the topmost
	# stands: the lodgepoles and the turf have those)
	"props": {
		"all": {"strict": true, "not_in_swamp": true},
		"tree": {"foot": 0.4},
		"dead": {"foot": 0.4},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("spruce", SETTINGS, VARIANTS)
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
