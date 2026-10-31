class_name TerrainCollider
extends StaticBody3D
## Collision for the terrain: a height map shape over a window around a point,
## re-centred as the point moves, sampled from WorldData.height_at() (the
## ground as drawn, relief included) every STEP metres.

const WINDOW := 129 # samples per side
const STEP := 2.0 # metres between samples
const RECENTER := 48.0 # metres from the window centre before it moves

var world: WorldData
var _shape := HeightMapShape3D.new()
var _cs := CollisionShape3D.new()
var _center := Vector2i.MAX # none yet


func _ready() -> void:
	_shape.map_width = WINDOW
	_shape.map_depth = WINDOW
	_cs.shape = _shape
	add_child(_cs)


func follow(p: Vector3) -> void:
	var c := Vector2i((Vector2(p.x, p.z) / STEP).round())
	if _center != Vector2i.MAX and Vector2(c - _center).length() * STEP < RECENTER:
		return
	_center = c
	var half := WINDOW / 2
	var data := PackedFloat32Array()
	data.resize(WINDOW * WINDOW)
	for j in WINDOW:
		for i in WINDOW:
			var x := (c.x - half + i) * STEP
			var z := (c.y - half + j) * STEP
			data[j * WINDOW + i] = world.height_at(x, z) / STEP # the shape is scaled uniformly by STEP
	_shape.map_data = data
	_cs.scale = Vector3.ONE * STEP
	_cs.position = Vector3(c.x * STEP, 0.0, c.y * STEP)
