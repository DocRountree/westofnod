class_name BlockWorld
extends Node3D
## Grid-aligned 1 m blocks placed on top of (and into) the continuous terrain.
## Stored sparsely per 16x16 column; each column gets one mesh + trimesh collider.

enum { AIR, DIRT, GRASS, STONE, SAND, GRAVEL, LOG, PLANKS, LEAVES, GLASS }

const NAMES := ["Air", "Dirt", "Grass", "Stone", "Sand", "Gravel", "Log", "Planks", "Leaves", "Glass"]
## Swatch colours for the HUD (the in-world look comes from block.gdshader).
const COLORS := [Color(0, 0, 0, 0), Color(0.45, 0.32, 0.2), Color(0.35, 0.58, 0.2),
		Color(0.5, 0.5, 0.5), Color(0.86, 0.8, 0.57), Color(0.55, 0.52, 0.5),
		Color(0.42, 0.3, 0.17), Color(0.72, 0.56, 0.33), Color(0.2, 0.45, 0.15),
		Color(0.75, 0.9, 0.95)]
const COL := 16

const FACES := [
	[Vector3i(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
	[Vector3i(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[Vector3i(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
	[Vector3i(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
	[Vector3i(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[Vector3i(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)],
]

var material: ShaderMaterial
var _columns := {} # Vector2i -> Dictionary(Vector3i -> int)
var _nodes := {} # Vector2i -> StaticBody3D (with mesh + shape children)
var _dirty := {}


func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = load("res://shaders/block.gdshader")


func _process(_delta: float) -> void:
	var n := 0
	for key in _dirty.keys():
		_rebuild(key)
		_dirty.erase(key)
		n += 1
		if n >= 8:
			break


static func column_of(c: Vector3i) -> Vector2i:
	return Vector2i(floori(c.x / float(COL)), floori(c.z / float(COL)))


func get_block(c: Vector3i) -> int:
	var col = _columns.get(column_of(c))
	if col == null:
		return AIR
	return col.get(c, AIR)


func set_block(c: Vector3i, t: int) -> void:
	var key := column_of(c)
	if not _columns.has(key):
		_columns[key] = {}
	if t == AIR:
		_columns[key].erase(c)
	else:
		_columns[key][c] = t
	_dirty[key] = true
	# Faces of neighbours across the column border may need to appear/disappear.
	for d in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		var nk := column_of(c + d)
		if nk != key and _columns.has(nk):
			_dirty[nk] = true


func add_tree(base: Vector3i, rng: RandomNumberGenerator) -> void:
	var trunk := rng.randi_range(4, 6)
	var top := base.y + trunk
	for dy in range(-2, 2):
		var r := 2 if dy < 0 else 1
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) == r and absi(dz) == r and (dy >= 0 or rng.randf() < 0.5):
					continue
				var c := Vector3i(base.x + dx, top + dy, base.z + dz)
				if get_block(c) == AIR:
					set_block(c, LEAVES)
	for y in range(base.y, top):
		set_block(Vector3i(base.x, y, base.z), LOG)


func _opaque(t: int) -> bool:
	return t != AIR and t != GLASS


func _rebuild(key: Vector2i) -> void:
	var blocks: Dictionary = _columns.get(key, {})
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()
	var faces := PackedVector3Array()
	for c in blocks:
		var t: int = blocks[c]
		var center := Vector3(c) + Vector3(0.5, 0.5, 0.5)
		for f in FACES:
			var nb := get_block(c + f[0])
			if _opaque(nb) or (nb == t and t == GLASS):
				continue
			var nrm := Vector3(f[0])
			var u: Vector3 = f[1] * 0.5
			var v: Vector3 = f[2] * 0.5
			var fc := center + nrm * 0.5
			var base := verts.size()
			var q := [fc - u - v, fc + u - v, fc + u + v, fc - u + v]
			for p in q:
				verts.append(p)
				normals.append(nrm)
				colors.append(Color(t / 255.0, 0, 0, 1))
			# clockwise seen from outside (Godot front faces)
			idx.append_array([base, base + 2, base + 1, base, base + 3, base + 2])
			faces.append_array([q[0], q[2], q[1], q[0], q[3], q[2]])

	if _nodes.has(key):
		_nodes[key].queue_free()
		_nodes.erase(key)
	if verts.is_empty():
		return
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var body := StaticBody3D.new()
	body.set_meta("kind", "blocks")
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.visibility_range_end = 300.0
	body.add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_nodes[key] = body
