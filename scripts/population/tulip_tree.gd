class_name TulipTree
## The tulip tree (Liriodendron tulipifera): four standing trees, a stump,
## three fallen logs, three dead standing trees and two saplings (variants
## 0-12, as the oak's), grown by SpeciesTree and dressed with
## data/population/textures/tulip_*.png (tools/trees/bake_tulip_textures.py).
## In the game (data/population/props/tulip.tres: the forest's, a very few
## on the prairie, nowhere else); tools/trees/preview.gd -- <out> tulip
## draws them.
##
## What makes it read as a tulip tree: the tallest of the eastern
## broadleaves, a trunk dead straight and running right up through the
## crown; in a stand a very long clean bole and a small, high crown; in the
## open a narrow, tall oval, pointed when young; limbs short for the tree's
## height, alternate, ascending then spreading; leaves on long slender
## stalks, four-lobed, the tip cut off square in a shallow notch, bright
## green, fluttering; in early summer, high up, tulip-shaped flowers,
## greenish yellow with orange, and through the winter the upright brown
## cones of seeds; bark grey, in narrow interlacing ridges, the furrows
## paler.

const VARIANTS := [
	# open-grown: a tall narrow oval, the leader straight to the top
	{"trunk_h": 4.0, "leader_h": 13.0, "trunk_r": 0.46, "limbs": 9, "limb_angle": 48.0, "limb_len": 7.0, "branch_len": 3.0, "twig_len": 0.95, "lean": 0.0, "droop": 0.0, "seed": 911, "crown": [7.0, 25.0, 4.5]},
	# young: slim, a pointed spire of a crown
	{"trunk_h": 3.0, "leader_h": 11.0, "trunk_r": 0.24, "limbs": 9, "limb_angle": 46.0, "limb_len": 4.2, "branch_len": 2.0, "twig_len": 0.85, "lean": 0.0, "droop": 0.0, "seed": 923, "crown": [3.8, 18.0, 3.5]},
	# leaning a little toward the light
	{"trunk_h": 5.0, "leader_h": 11.0, "trunk_r": 0.4, "limbs": 8, "limb_angle": 46.0, "limb_len": 6.0, "branch_len": 2.7, "twig_len": 0.95, "lean": 5.0, "droop": 0.0, "seed": 941, "crown": [6.0, 23.0, 5.5]},
	# forest-grown: a very long clean bole, a small crown high up
	{"trunk_h": 15.0, "leader_h": 10.0, "trunk_r": 0.5, "limbs": 7, "limb_angle": 42.0, "limb_len": 5.5, "branch_len": 2.5, "twig_len": 0.9, "lean": 0.0, "droop": 0.0, "seed": 953, "crown": [5.0, 33.0, 15.5]},
	{"kind": "stump", "seed": 961, "r": 0.5, "flare": 0.35},
	{"kind": "log", "seed": 967, "r0": 0.44, "r1": 0.32},
	{"kind": "dead", "like": 0, "seed": 971, "limb_angle": 40.0, "limb_len": 5.8, "branch_len": 2.4, "crown": [5.8, 23.0, 4.5]},
	{"kind": "log", "seed": 973, "length": Vector2(10.0, 12.5), "r0": 0.36, "r1": 0.16, "bow": 0.15, "stubs": Vector2i(3, 5)},
	{"kind": "log", "seed": 979, "length": Vector2(3.0, 4.0), "r0": 0.55, "r1": 0.5, "bow": 0.03, "stubs": Vector2i(0, 1)},
	# saplings, 3-4 m: a straight whip, and one with a few more side shoots
	{"kind": "sapling", "trunk_h": 1.2, "leader_h": 2.6, "trunk_r": 0.045, "limbs": 5, "limb_angle": 44.0, "limb_len": 1.1, "branch_len": 0.6, "twig_len": 0.45, "lean": 0.0, "droop": 0.0, "seed": 983, "crown": [1.0, 4.2, 1.2]},
	{"kind": "sapling", "trunk_h": 0.8, "leader_h": 2.4, "trunk_r": 0.05, "limbs": 6, "limb_angle": 50.0, "limb_len": 1.3, "branch_len": 0.65, "twig_len": 0.45, "lean": 2.0, "droop": 0.0, "seed": 989, "crown": [1.3, 3.8, 0.8]},
	{"kind": "dead", "like": 1, "seed": 997, "limb_angle": 36.0, "limb_len": 3.6, "branch_len": 1.7, "crown": [3.4, 17.0, 3.5]},
	{"kind": "dead", "like": 3, "seed": 1003, "lean": 4.0, "limb_angle": 40.0, "limb_len": 4.6, "branch_len": 2.1, "crown": [4.3, 31.0, 15.0]},
]

const SETTINGS := {
	"seg": [0.6, 0.62, 0.45, 0.34], # (a long straight trunk)
	"crook": [0.02, 0.09, 0.17, 0.22], # (straighter than most)
	"up": [0.0, 0.02, 0.06, 0.08], # (limbs ascending, then spreading)
	"child_angle": [0.0, 0.78, 0.76, 0.72],
	"opposite": false, # (alternate)
	"irregular": 0.15,
	"tip_r": 0.005,
	"card_size": 0.8,
	"bark_tex": "res://data/population/textures/tulip_bark.png",
	"leaf_tex": "res://data/population/textures/tulip_leaves.png",
	"bark_tint": Color(1, 1, 1),
	"dead_tint": Color(0.82, 0.8, 0.77),
	"log_tint": Color(0.82, 0.85, 0.75),
	"shadow": [6.0, 4.5, 23.0, 0.42],
	# as a prop (data/population/props/tulip.tres: the forest's, a very few
	# on the prairie): only there, none where the ground has any share of
	# another biome, none in the swamp nor on its mud
	"props": {
		"all": {"strict": true, "not_in_swamp": true, "never_in": ["swamp", "taiga", "mesa", "tundra", "plateau", "volcano", "mountains", "island", "coast"]}, # (nor at the edges of any other)
	},
}

static var _species: SpeciesTree


static func species() -> SpeciesTree:
	if _species == null:
		_species = SpeciesTree.new("tulip", SETTINGS, VARIANTS)
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


## What fruit variant v bears (Foraging): an item id, "" none (the tulip
## tree's: none to pick).
static func fruit_of(variant: int) -> String:
	return species().fruit_of(variant)


## Where variant v's fruit hangs (Foraging), its own space (none).
static func fruit_spots(variant: int) -> PackedVector3Array:
	return species().fruit_spots(variant)
