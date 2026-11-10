class_name PropKind
extends SpawnRule
## A kind of static prop: a tree, a rock, a tuft of grass. Population places
## them chunk by chunk (density: per hectare), the same everywhere every time,
## and draws each kind in a chunk as one MultiMesh. Save one as a .tres in
## data/population/props/ and it is picked up (or Population.register_prop()).

@export var id: StringName
@export var mesh: Mesh
## With no mesh: a script whose static build(variant) returns one (made at
## load, e.g. OakTree); and if it has a static build_lods(variant), that
## fills lods when they're empty. Its meshes may carry their own materials
## (per surface: leave material empty).
@export var mesh_script: Script
## How many different models (variants 0..n-1 of mesh_script): Population
## makes a kind of each, sharing the density.
@export var variants := 1
## Simpler meshes for further off: lods[i] is drawn from lod_distances[i] (m)
## to the next one's (the last to view_distance); mesh, up to lod_distances[0].
@export var lods: Array[Mesh] = []
@export var lod_distances := PackedFloat32Array()
@export var lod_material: Material ## For the lods (default: material).
## Only what is drawn nearer than this casts shadows (whole levels of detail).
@export var shadow_distance := 250.0
## If set, this casts the shadow (to shadow_distance) in place of the meshes,
## which cast none: a cheap stand-in (a tree: a lumpy dome on a stalk). With
## no shadow mesh but a mesh_script with build_shadow(), that makes it.
@export var shadow_mesh: Mesh
@export var material: Material ## Optional: overrides the mesh's own.
@export var scale_range := Vector2(0.8, 1.2) ## Uniform scale, picked at random in this range.
## 0: stands upright (trees); 1: tilts with the ground (rocks, grass).
@export_range(0.0, 1.0) var align_to_ground := 0.0
@export var sink := 0.0 ## Metres into the ground (at scale 1), so it sits in it on slopes.
## Metres (at scale 1) from its middle to the edge of its foot (a trunk's
## flared base): on a slope it sinks as much more as the ground falls away
## over that, so its downhill side doesn't stand on air.
@export var foot := 0.0
## Where it grows: "" on the ground; "wood" on fallen logs and stumps (any
## tree's) and the lower trunks of living oaks, its back to the wood (+z out
## from it), where a biome it grows in (density > 0 there) has them
## (Population: the fungi's chicken of the woods).
@export var grows_on := ""
## (grows_on "wood") The chance it's on each one (a log, by its length).
@export var per_site := 0.0
## Only this near (m) a standing tree's foot (0: anywhere it fits).
@export var near_trees := 0.0
## Picked (Foraging: Population.pickable_at) as this item ("": not picked),
## so many of it; the view passing within pick_r (m) of pick_at (its own
## point, at scale 1).
@export var item := ""
@export var pick_count := 1
@export var pick_at := Vector3.ZERO
@export var pick_r := 0.1
## Radius (m, at scale 1) the player and actors can't walk into; 0 walks through.
@export var radius := 0.0
## What can be stood on (a fallen log's trunk, a stump): round segments, 8
## floats each, local (at scale 1): ax, ay, az, bx, by, bz, radius at a, at
## b. One steeper than 45° is a post with a flat top (a stump). A negative
## radius at a marks one high in the air (a tree's limb).
## Bodies step up onto one no higher than Population.STEP_UP above their
## feet; one higher is a wall (jump onto it). With none but a mesh_script
## with build_walk(variant), that makes them.
@export var walk := PackedFloat32Array()
## Clumping: biome name -> how strongly (0..1) it gathers there in clumps
## (irregular, of clump_size m), thinning out between them, as many in all.
@export var clump := {}
@export var clump_size := 30.0
## None closer than this (m) to another of its kind (in the same chunk).
@export var min_spacing := 0.0

const CLUMP_MAX := 13.0 ## The most a clump packs them in (x the density).
var _clump_by_biome := PackedFloat32Array()


## Biomes it never stands in, not even at their blended edges: none where
## the ground has any share of one (WorldData.biome_bits_at: the bald
## cypress, none on the prairie).
@export var never_in := []
var never_bits := 0 ## (never_in as biome bits)


## Resolves clump's names too (and never_in's).
func resolve_clump(names: Array) -> void:
	_clump_by_biome.resize(names.size() + 1)
	for i in _clump_by_biome.size():
		_clump_by_biome[i] = float(clump.get(names[i], 0.0)) if i < names.size() else 0.0
	never_bits = 0
	for b in never_in:
		var i := names.find(b)
		if i >= 0 and i < 31:
			never_bits |= 1 << i


## How much more (or less) common it is at (x, z) in biome b than its
## density there: clumps, irregular (two scales of noise), denser in the
## middle; between them few.
func clump_at(b: int, x: float, z: float) -> float:
	if clump.is_empty():
		return 1.0
	var k := _clump_by_biome[b if b >= 0 else _clump_by_biome.size() - 1]
	if k <= 0.0:
		return 1.0
	var n := WorldData.vnoise(x / clump_size + 17.3, z / clump_size - 4.1) * 0.65 + WorldData.vnoise(x / (clump_size * 0.37) - 8.2, z / (clump_size * 0.37) + 3.7) * 0.35
	return lerpf(1.0, CLUMP_MAX * smoothstep(0.56, 0.78, n), k)


## The most it can be anywhere (its peak density, clumped, and times the
## most swamp_depth makes it).
func peak_clumped() -> float:
	var k := maxf(maxf(swamp_depth.x, swamp_depth.y), 1.0) if swamp_depth != Vector2.ZERO else 1.0
	return peak() * (CLUMP_MAX if not clump.is_empty() else 1.0) * k
## What can be climbed (Player, C): lines (a trunk from the foot up, its
## limbs from where they leave it) as far as they're stout enough to hold
## you; each its node count, then 4 floats a node, local (at scale 1): x, y,
## z, radius. With none but a mesh_script with build_climb(variant), that
## makes it.
@export var climb := PackedFloat32Array()
@export var view_distance := 250.0 ## Drawn up to this far (m).
## Past view_distance, drawn as a far card (FarTrees) out to this (m, at the
## standard tree render distance: Settings), if it has one (far_card).
@export var far_distance := 0.0
var far_card := -1 ## Its far card (FarTrees' layer), -1 none: its last level's mesh says (its "far_card").
@export var shadows := true
@export var shadowless_in := PackedStringArray() ## Biomes where it casts none (the oaks: the swamp).
## It strays a few hundred metres over its biomes' borders (thinning out
## into the next: scattered trees, copses), and thins out up the mountains
## to none at the top of its height_range.
@export var strays := false
## None in the swamp (where it is drawn swamp, or its mud reaches), however
## it strays or blends there (the oaks' logs).
@export var not_in_swamp := false
## Straying (strays), only into biomes it grows in: none where the ground's
## own biome has no density for it (the pines: from the taiga into the
## forest, but never onto the prairie).
@export var strict := false
## In the swamp, its density times x at the swamp's edge, y in its middle,
## by how far in (WorldData.swamp_depth); (0, 0) none of this (the
## sycamores: the living more at the edges, the dead in the middle).
@export var swamp_depth := Vector2.ZERO
