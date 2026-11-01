class_name PropKind
extends SpawnRule
## A kind of static prop: a tree, a rock, a tuft of grass. Population places
## them chunk by chunk (density: per hectare), the same everywhere every time,
## and draws each kind in a chunk as one MultiMesh. Save one as a .tres in
## data/population/props/ and it is picked up (or Population.register_prop()).

@export var id: StringName
@export var mesh: Mesh
## With no mesh: a script whose static build() returns one (made at load, e.g.
## FractalTree from its recipe); and if it has a static build_lods(), that
## fills lods when they're empty.
@export var mesh_script: Script
## Simpler meshes for further off: lods[i] is drawn from lod_distances[i] (m)
## to the next one's (the last to view_distance); mesh, up to lod_distances[0].
@export var lods: Array[Mesh] = []
@export var lod_distances := PackedFloat32Array()
@export var lod_material: Material ## For the lods (default: material).
## Only what is drawn nearer than this casts shadows (whole levels of detail).
@export var shadow_distance := 250.0
@export var material: Material ## Optional: overrides the mesh's own.
@export var scale_range := Vector2(0.8, 1.2) ## Uniform scale, picked at random in this range.
## 0: stands upright (trees); 1: tilts with the ground (rocks, grass).
@export_range(0.0, 1.0) var align_to_ground := 0.0
@export var sink := 0.0 ## Metres into the ground (at scale 1), so it sits in it on slopes.
## Radius (m, at scale 1) the player and actors can't walk into; 0 walks through.
@export var radius := 0.0
@export var view_distance := 250.0 ## Drawn up to this far (m).
@export var shadows := true
