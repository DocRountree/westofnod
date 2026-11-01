class_name Cdlod
extends Node3D
## CDLOD quadtree over the world's square domain. Each frame (when the camera
## has moved) it picks the patches to draw: a node is split while the camera is
## within the range of the next finer level, so detail falls off with distance
## in powers of two; every patch is one instance of the same GRID x GRID mesh
## (each material given to setup() draws the same patches, so they line up).
## Morphing in the shader (cdlod_xz in height_map.gdshaderinc) blends each
## level into the next: no cracks, no pops.

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
var zoom := 1.0 ## Magnification: detail as if everything were this many times nearer.
var _dir := Vector2(0, -1) # horizontal view direction, and the wedge seen (when magnified)
var _tan := 1.0


func setup(world: WorldData, mats: Array[ShaderMaterial]) -> void:
	data = world
	materials = mats
	leaf = GRID * world.cell() / 8.0 # three levels finer than the data (SUB in the shader)
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
	if cam.distance_to(_last_cam) < leaf * 0.25 / zoom:
		return
	_last_cam = cam
	var picked: Array = []
	var top := leaf * pow(2.0, levels)
	_select(data.origin, top, levels, cam, picked)
	# one upload: per instance a translation (3x4, row-major) then the custom data
	var buf := PackedFloat32Array()
	buf.resize(picked.size() * 16)
	for i in picked.size():
		var p: Array = picked[i]
		var lod: int = p[2]
		var corner: Vector2 = p[0]
		var o := i * 16
		buf[o] = 1.0
		buf[o + 3] = corner.x
		buf[o + 5] = 1.0
		buf[o + 10] = 1.0
		buf[o + 11] = corner.y
		buf[o + 12] = lod
		# Morphing ends a little short of the level's range: the shader
		# measures from the camera now, the selection from where it was last
		# made (up to leaf / 4 away), and a finer patch must be fully morphed
		# where it meets a coarser one, or the seam cracks.
		buf[o + 13] = ranges[lod] * MORPH_START
		buf[o + 14] = ranges[lod] - leaf * 0.3
		buf[o + 15] = p[1]
	_mm.instance_count = picked.size()
	_mm.buffer = buf


## Magnified view: detail by distance / zoom, and only the patches in the
## wedge seen along dir (horizontal unit vector; tan_half its half-angle).
func magnify(dir: Vector2, z: float, tan_half: float) -> void:
	if z == zoom and (z <= 1.01 or (dir.dot(_dir) > 0.9995 and tan_half == _tan)):
		return
	zoom = z
	_dir = dir
	_tan = tan_half
	_last_cam = Vector3.INF # reselect
	for m in materials:
		m.set_shader_parameter("lod_zoom", zoom)


func _in_wedge(cam: Vector3, corner: Vector2, size: float) -> bool:
	if zoom <= 1.01:
		return true
	var c := Vector2(cam.x, cam.z)
	var perp := Vector2(-_dir.y, _dir.x)
	var pad := size * 0.75 + 50.0
	# outside if every corner is past the same edge of the wedge
	var left := 0
	var right := 0
	var back := 0
	for q: Vector2 in [corner, corner + Vector2(size, 0), corner + Vector2(0, size), corner + Vector2(size, size)]:
		var r := q - c
		var along := r.dot(_dir)
		var across := r.dot(perp)
		if across > along * _tan + pad:
			left += 1
		elif -across > along * _tan + pad:
			right += 1
		if along < -pad:
			back += 1
	return left < 4 and right < 4 and back < 4


func _dist(cam: Vector3, corner: Vector2, size: float) -> float:
	var q := Vector2(clampf(cam.x, corner.x, corner.x + size), clampf(cam.z, corner.y, corner.y + size))
	# Same metric as cdlod_xz(): horizontal distance, plus half the height above sea.
	return Vector2(q.distance_to(Vector2(cam.x, cam.z)), maxf(cam.y, 0.0) * 0.5).length() / zoom


func _select(corner: Vector2, size: float, lod: int, cam: Vector3, out: Array) -> void:
	if not _in_wedge(cam, corner, size):
		return
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
