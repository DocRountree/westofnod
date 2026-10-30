class_name TerrainCollider
extends StaticBody3D
## Collision for the terrain: a height map shape over a window of the island's
## full-resolution heights around a point, re-centred as the point moves. Same
## samples as the finest rendered level, so feet meet the visible ground.

const WINDOW := 129 # samples per side
const RECENTER := 96.0 # metres from the window centre before it moves

var island: IslandData
var _shape := HeightMapShape3D.new()
var _cs := CollisionShape3D.new()
var _center := Vector2i.MAX # none yet


func _ready() -> void:
	_shape.map_width = WINDOW
	_shape.map_depth = WINDOW
	_cs.shape = _shape
	add_child(_cs)


func follow(p: Vector3) -> void:
	var cell := island.cell()
	var g := ((Vector2(p.x, p.z) - island.origin) / cell).round()
	var c := Vector2i(g)
	if _center != Vector2i.MAX and Vector2(c - _center).length() * cell < RECENTER:
		return
	_center = c
	var half := WINDOW / 2
	var data := PackedFloat32Array()
	data.resize(WINDOW * WINDOW)
	for j in WINDOW:
		for i in WINDOW:
			var gi := c.x - half + i
			var gj := c.y - half + j
			var h := IslandGenerator.OCEAN_FLOOR
			if gi >= 0 and gj >= 0 and gi < island.size and gj < island.size:
				h = island.heights[gj * island.size + gi]
			data[j * WINDOW + i] = h / cell # the shape is scaled uniformly by the cell size
	_shape.map_data = data
	_cs.scale = Vector3.ONE * cell
	var centre := island.origin + Vector2(c) * cell
	_cs.position = Vector3(centre.x, 0.0, centre.y)
