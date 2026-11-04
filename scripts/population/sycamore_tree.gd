class_name SycamoreTree
## The American sycamore (Platanus occidentalis): four standing trees, a
## stump, three fallen logs, three dead standing trees and two saplings
## (variants 0-12, as the oak's), grown by SpeciesTree and dressed with
## data/population/textures/sycamore_*.png
## (tools/trees/bake_broadleaf_textures.py). In the game
## (data/population/props/); tools/trees/preview.gd -- <out> sycamore draws them.
##
## What makes it read as a sycamore: a massive trunk that often divides low
## into two or three great leaders; long, crooked limbs reaching out at
## wide angles; an open, irregular, lumpy crown, broad; the bark peeling in
## plates into a patchwork of cream, grey-green and tan, the upper trunk
## and limbs white, the old foot dark, scaly brown; big, broad leaves
## (15-20 cm), shallowly three- to five-lobed and coarsely toothed, one by
## one on long stalks, and seed balls hanging on long threads.

const VARIANTS := [
	# open-grown, by a stream: a huge trunk dividing low into leaders, limbs spreading wide
	{"trunk_h": 2.5, "leader_h": 8.5, "trunk_r": 0.66, "limbs": 8, "forks": 2, "fork_angle": 26.0, "fork_len": 1.3, "limb_angle": 54.0, "limb_len": 12.0, "branch_len": 4.6, "twig_len": 1.3, "lean": 0.0, "droop": 0.03, "seed": 311, "crown": [9.5, 22.0, 4.0]},
	# young: one straight stem, still regular
	{"trunk_h": 3.4, "leader_h": 8.0, "trunk_r": 0.27, "limbs": 8, "limb_angle": 48.0, "limb_len": 6.8, "branch_len": 3.2, "twig_len": 1.1, "lean": 0.0, "droop": 0.0, "seed": 323, "crown": [5.4, 17.0, 4.2]},
	# leaning out over the water, its crown thrown to that side
	{"trunk_h": 2.6, "leader_h": 6.5, "trunk_r": 0.55, "limbs": 7, "forks": 1, "fork_angle": 30.0, "fork_len": 1.3, "limb_angle": 56.0, "limb_len": 10.5, "branch_len": 4.2, "twig_len": 1.25, "lean": 14.0, "droop": 0.04, "seed": 341, "crown": [8.2, 19.5, 3.8]},
	# forest-grown: a tall bole, white high up, a high crown
	{"trunk_h": 8.5, "leader_h": 8.0, "trunk_r": 0.58, "limbs": 7, "forks": 2, "fork_angle": 24.0, "fork_len": 1.15, "limb_angle": 50.0, "limb_len": 8.5, "branch_len": 3.6, "twig_len": 1.2, "lean": 0.0, "droop": 0.02, "seed": 353, "crown": [6.8, 27.0, 10.0]},
	{"kind": "stump", "seed": 361, "r": 0.62, "flare": 0.55},
	{"kind": "log", "seed": 367, "r0": 0.5, "r1": 0.34},
	{"kind": "dead", "like": 0, "seed": 371, "limb_angle": 48.0, "limb_len": 8.0, "branch_len": 3.2, "crown": [8.0, 20.0, 3.8]},
	{"kind": "log", "seed": 373, "length": Vector2(9.0, 11.0), "r0": 0.36, "r1": 0.18, "bow": 0.55, "stubs": Vector2i(4, 6)},
	{"kind": "log", "seed": 379, "length": Vector2(3.0, 3.8), "r0": 0.7, "r1": 0.64, "bow": 0.08, "stubs": Vector2i(0, 1)},
	# saplings, 3-4 m: a whip with big leaves, and one forking low
	{"kind": "sapling", "trunk_h": 1.0, "leader_h": 2.2, "trunk_r": 0.045, "limbs": 4, "limb_angle": 45.0, "limb_len": 1.5, "branch_len": 0.8, "twig_len": 0.5, "lean": 0.0, "droop": 0.0, "seed": 383, "crown": [1.4, 3.9, 0.9]},
	{"kind": "sapling", "trunk_h": 0.4, "leader_h": 1.8, "trunk_r": 0.05, "limbs": 5, "forks": 1, "fork_angle": 28.0, "fork_len": 1.2, "limb_angle": 55.0, "limb_len": 1.6, "branch_len": 0.8, "twig_len": 0.5, "lean": 5.0, "droop": 0.0, "seed": 389, "crown": [1.7, 3.4, 0.5]},
	{"kind": "dead", "like": 1, "seed": 397, "limb_angle": 42.0, "limb_len": 5.0, "branch_len": 2.4, "crown": [5.0, 15.5, 4.0]},
	{"kind": "dead", "like": 3, "seed": 403, "lean": 7.0, "limb_angle": 46.0, "limb_len": 6.0, "branch_len": 2.8, "crown": [6.0, 25.0, 9.5]},
]

const SETTINGS := {
	"seg": [0.55, 0.7, 0.5, 0.38],
	"crook": [0.06, 0.24, 0.3, 0.32], # (crooked, zigzagging limbs)
	"up": [0.0, 0.0, 0.05, 0.08],
	"child_angle": [0.0, 0.95, 0.9, 0.85], # (wide)
	"opposite": false,
	"irregular": 1.0,
	"tip_r": 0.006,
	"card_size": 0.9, # (bigger leaves: the tiles cover 0.65 m)
	"bark_tex": "res://data/population/textures/sycamore_bark.png",
	"leaf_tex": "res://data/population/textures/sycamore_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"tint_low": Color(0.5, 0.44, 0.38), # (the old foot, dark and scaly)
	"tint_heights": Vector2(0.08, 0.4),
	"dead_tint": Color(0.82, 0.8, 0.76),
	"log_tint": Color(0.74, 0.74, 0.66),
	"shadow": [9.0, 4.5, 21.0, 0.6],
	"lichen": false, # (none on its peeling bark)
	"far_bark": Color(0.88, 0.87, 0.82), # (white far off, as the eye reads its limbs: the patchwork's mean is grey)
	# as a prop (data/population/props/sycamore.tres: the swamp's only, not
	# straying out of it): the living more at its edges, fewer in its
	# middle; the dead the other way about (WorldData.swamp_depth); casting
	# shadows there (the oaks' dead don't)
	"props": {
		"all": {"strays": false},
		"tree": {"swamp_depth": Vector2(1.8, 0.35), "shadowless_in": []},
		"sapling": {"swamp_depth": Vector2(1.8, 0.35), "shadowless_in": []},
		"dead": {"swamp_depth": Vector2(0.3, 3.0), "density_like": {}, "clump": {}},
		"stump": {"shadowless_in": []},
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("sycamore", SETTINGS, VARIANTS)
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
