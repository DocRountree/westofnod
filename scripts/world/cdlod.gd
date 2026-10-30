class_name Cdlod
extends Node3D
## CDLOD quadtree over the world's square domain. Each frame (when the camera
## has moved) it picks the patches to draw: a node is split while the camera is
## within the range of the next finer level, so detail falls off with distance
## in powers of two; every patch is one instance of the same GRID x GRID mesh.
## The terrain and the inland water draw the same patches with their own
## materials, so they always line up. Morphing in the shaders (see
## island_maps.gdshaderinc) blends each level into the next: no cracks, no pops.

const GRID := 32
const RANGE_FACTOR := 2.4 # range of a level, in patch sizes
const MORPH_START := 0.6 # fraction of a level's range where morphing begins

var data: WorldData
var materials: Array[ShaderMaterial] = []
var levels := 0
var leaf := 0.0 # world size of a level-0 patch
var ranges := PackedFloat32Array()
var _mm: MultiMesh
var _last_cam := Vector3.INF


func setup(world: WorldData, mats: Array[ShaderMaterial]) -> void:
	data = world
	materials = mats
	leaf = GRID * world.cell()
	levels = ceili(log(world.domain / leaf) / log(2.0))
	for k in levels + 2:
		ranges.append(leaf * pow(2.0, k) * RANGE_FACTOR)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = _grid_mesh()
	for m in mats:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = _mm
		mi.material_override = m
		# Vertices are placed in the shader; never cull the set.
		mi.custom_aabb = AABB(Vector3(-1e5, -1e4, -1e5), Vector3(2e5, 2e4, 2e5))
		add_child(mi)
	for m in mats:
		m.set_shader_parameter("height_tex", world.height_tex)
		m.set_shader_parameter("map_size", float(world.size))
		m.set_shader_parameter("map_domain", world.domain)
		m.set_shader_parameter("map_origin", world.origin)


## Reselects patches around the camera. Cheap; call every frame.
func update(cam: Vector3) -> void:
	for m in materials:
		m.set_shader_parameter("view_pos", cam)
	if cam.distance_to(_last_cam) < leaf * 0.25:
		return
	_last_cam = cam
	var picked: Array = []
	var top := leaf * pow(2.0, levels)
	_select(data.origin, top, levels, cam, picked)
	_mm.instance_count = picked.size()
	for i in picked.size():
		var p: Array = picked[i]
		var lod: int = p[2]
		_mm.set_instance_transform(i, Transform3D(Basis(), Vector3(p[0].x, 0.0, p[0].y)))
		_mm.set_instance_custom_data(i, Color(lod, ranges[lod] * MORPH_START, ranges[lod], p[1]))


func _dist(cam: Vector3, corner: Vector2, size: float) -> float:
	var q := Vector2(clampf(cam.x, corner.x, corner.x + size), clampf(cam.z, corner.y, corner.y + size))
	# Same metric as cdlod_xz(): horizontal distance, plus half the height above sea.
	return Vector2(q.distance_to(Vector2(cam.x, cam.z)), maxf(cam.y, 0.0) * 0.5).length()


func _select(corner: Vector2, size: float, lod: int, cam: Vector3, out: Array) -> void:
	if lod > 0 and _dist(cam, corner, size) < ranges[lod - 1]:
		var h := size * 0.5
		for c in [Vector2(0, 0), Vector2(h, 0), Vector2(0, h), Vector2(h, h)]:
			_select(corner + c, h, lod - 1, cam, out)
	else:
		out.append([corner, size, lod])


func _grid_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for j in GRID + 1:
		for i in GRID + 1:
			verts.append(Vector3(float(i) / GRID, 0.0, float(j) / GRID))
	for j in GRID:
		for i in GRID:
			var a := j * (GRID + 1) + i
			idx.append_array([a, a + 1, a + GRID + 1, a + 1, a + GRID + 2, a + GRID + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh
