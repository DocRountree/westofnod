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


## Resolves clump's names too.
func resolve_clump(names: Array) -> void:
	_clump_by_biome.resize(names.size() + 1)
	for i in _clump_by_biome.size():
		_clump_by_biome[i] = float(clump.get(names[i], 0.0)) if i < names.size() else 0.0


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


## The most it can be anywhere (its peak density, clumped).
func peak_clumped() -> float:
	return peak() * (CLUMP_MAX if not clump.is_empty() else 1.0)
## What can be climbed (Player, C): lines (a trunk from the foot up, its
## limbs from where they leave it) as far as they're stout enough to hold
## you; each its node count, then 4 floats a node, local (at scale 1): x, y,
## z, radius. With none but a mesh_script with build_climb(variant), that
## makes it.
@export var climb := PackedFloat32Array()
@export var view_distance := 250.0 ## Drawn up to this far (m).
@export var shadows := true
@export var shadowless_in := PackedStringArray() ## Biomes where it casts none (the oaks: the swamp).
## It strays a few hundred metres over its biomes' borders (thinning out
## into the next: scattered trees, copses), and thins out up the mountains
## to none at the top of its height_range.
@export var strays := false
