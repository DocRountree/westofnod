class_name TerrainMesher
extends RefCounted
## Builds heightfield mesh arrays from generator output.
## data: out_n*out_n vertices of 8 floats (height, floodplain 0..1, gully depth,
## channel cut, water level, water kind (1 river, 2 lake/oxbow), flow x, flow z)
## covering the (n+1)^2 vertex grid plus a one-vertex ring for seamless normals.
## delta: optional per-ring-vertex height edits (digging), same layout, or null.

static var _index_cache := {}


static func indices(n: int) -> PackedInt32Array:
	if _index_cache.has(n):
		return _index_cache[n]
	var idx := PackedInt32Array()
	idx.resize(n * n * 6)
	var w := n + 1
	var k := 0
	for j in n:
		for i in n:
			var a := j * w + i
			idx[k] = a
			idx[k + 1] = a + 1
			idx[k + 2] = a + w
			idx[k + 3] = a + 1
			idx[k + 4] = a + w + 1
			idx[k + 5] = a + w
			k += 6
	_index_cache[n] = idx
	return idx


static func height_at(data: PackedFloat32Array, delta, out_n: int, i: int, j: int) -> float:
	var r := j * out_n + i
	var h := data[r * 8]
	if delta != null:
		h += delta[r]
	return h


## Returns {verts, normals, colors, heights (vertex heights, row-major, for collision)}.
static func build(data: PackedFloat32Array, delta, n: int, s: float) -> Dictionary:
	var w := n + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var heights := PackedFloat32Array()
	verts.resize(w * w)
	normals.resize(w * w)
	colors.resize(w * w)
	heights.resize(w * w)
	var arrays := {"verts": verts, "normals": normals, "colors": colors, "heights": heights}
	update_rect(arrays, data, delta, n, s, 0, 0, n, n)
	return arrays


## Recomputes vertices i0..i1, j0..j1 (inclusive, vertex indices) in place.
static func update_rect(arrays: Dictionary, data: PackedFloat32Array, delta, n: int, s: float,
		i0: int, j0: int, i1: int, j1: int) -> void:
	var w := n + 1
	var on := n + 3
	var verts: PackedVector3Array = arrays.verts
	var normals: PackedVector3Array = arrays.normals
	var colors: PackedColorArray = arrays.colors
	var heights: PackedFloat32Array = arrays.heights
	for j in range(maxi(j0, 0), mini(j1, n) + 1):
		for i in range(maxi(i0, 0), mini(i1, n) + 1):
			var oi := i + 1
			var oj := j + 1
			var r := oj * on + oi
			var h := data[r * 8]
			var dug := 0.0
			if delta != null:
				dug = -delta[r]
				h -= dug
			var hl := height_at(data, delta, on, oi - 1, oj)
			var hr := height_at(data, delta, on, oi + 1, oj)
			var hd := height_at(data, delta, on, oi, oj - 1)
			var hu := height_at(data, delta, on, oi, oj + 1)
			var v := j * w + i
			verts[v] = Vector3(i * s, h, j * s)
			normals[v] = Vector3(hl - hr, 2.0 * s, hd - hu).normalized()
			# r: alluvium, g: gully depth/10, b: channel cut/2, a: dug depth/3
			colors[v] = Color(data[r * 8 + 1], data[r * 8 + 2] / 10.0,
					data[r * 8 + 3] / 2.0, clampf(dug / 3.0, 0.0, 1.0))
			heights[v] = h
	arrays.verts = verts
	arrays.normals = normals
	arrays.colors = colors
	arrays.heights = heights


static func make_mesh(arrays: Dictionary, n: int) -> ArrayMesh:
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = arrays.verts
	a[Mesh.ARRAY_NORMAL] = arrays.normals
	a[Mesh.ARRAY_COLOR] = arrays.colors
	a[Mesh.ARRAY_INDEX] = indices(n)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return mesh


## River and lake surfaces: a sheet at each vertex's water level, kept only where
## the grid has water (around it the sheet sits below the banks). UV carries the
## river flow (direction x speed). Empty if none.
static func build_water(data: PackedFloat32Array, n: int, s: float) -> Dictionary:
	var w := n + 1
	var on := n + 3
	var verts := PackedVector3Array()
	verts.resize(w * w)
	var flow := PackedVector2Array()
	flow.resize(w * w)
	var wet := PackedByteArray()
	wet.resize(w * w)
	var any := false
	for j in w:
		for i in w:
			var r := ((j + 1) * on + i + 1) * 8
			verts[j * w + i] = Vector3(i * s, data[r + 4], j * s)
			flow[j * w + i] = Vector2(data[r + 6], data[r + 7])
			if data[r + 5] > 0.5:
				wet[j * w + i] = 1
				any = true
	if not any:
		return {}
	var idx := PackedInt32Array()
	for j in n:
		for i in n:
			var a := j * w + i
			if wet[a] + wet[a + 1] + wet[a + w] + wet[a + w + 1] == 0:
				continue
			idx.append_array([a, a + 1, a + w, a + 1, a + w + 1, a + w])
	var normals := PackedVector3Array()
	normals.resize(w * w)
	normals.fill(Vector3.UP)
	return {"verts": verts, "normals": normals, "indices": idx, "flow": flow}
