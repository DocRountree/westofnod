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
var _pending := Vector2i.ZERO
var _data := PackedFloat32Array()
var _task := -1
var _first := true


func _ready() -> void:
	_shape.map_width = WINDOW
	_shape.map_depth = WINDOW
	_cs.shape = _shape
	add_child(_cs)


func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)


func follow(p: Vector3) -> void:
	# sampling the window costs ~16k height_at() calls: do it on a worker
	# thread so flying fast doesn't hitch, and swap the shape in when done
	if _task != -1:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_shape.map_data = _data
		_cs.scale = Vector3.ONE * STEP
		_cs.position = Vector3(_pending.x * STEP, 0.0, _pending.y * STEP)
	var c := Vector2i((Vector2(p.x, p.z) / STEP).round())
	if _center != Vector2i.MAX and Vector2(c - _center).length() * STEP < RECENTER:
		return
	_center = c
	_pending = c
	if _first:
		_first = false
		_build(c) # the very first window is needed at once, before falling
		_shape.map_data = _data
		_cs.scale = Vector3.ONE * STEP
		_cs.position = Vector3(c.x * STEP, 0.0, c.y * STEP)
		return
	_task = WorkerThreadPool.add_task(_build.bind(c))


func _build(c: Vector2i) -> void:
	var half := WINDOW / 2
	var data := PackedFloat32Array()
	data.resize(WINDOW * WINDOW)
	for j in WINDOW:
		for i in WINDOW:
			var x := (c.x - half + i) * STEP
			var z := (c.y - half + j) * STEP
			data[j * WINDOW + i] = world.height_at(x, z) / STEP # the shape is scaled uniformly by STEP
	_data = data
