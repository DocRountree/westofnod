class_name TerrainMesher
extends RefCounted
## Builds heightfield mesh arrays from generator output.
## data: out_n*out_n vertices of 8 floats (height, floodplain 0..1, gully depth,
## channel cut, water level, water kind (1 river, 2 lake/oxbow), flow x, flow z)
## covering the (n+1)^2 vertex grid plus a one-vertex ring for seamless normals.
## Meshes carry positions only; shading data goes to the GPU as textures().
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


## Returns {verts, heights (vertex heights, row-major, for collision)}. Normals
## and materials are per pixel in terrain.gdshader, from textures().
static func build(data: PackedFloat32Array, delta, n: int, s: float) -> Dictionary:
	var w := n + 1
	var verts := PackedVector3Array()
	var heights := PackedFloat32Array()
	verts.resize(w * w)
	heights.resize(w * w)
	var arrays := {"verts": verts, "heights": heights}
	update_rect(arrays, data, delta, n, s, 0, 0, n, n)
	return arrays


## Recomputes vertices i0..i1, j0..j1 (inclusive, vertex indices) in place.
static func update_rect(arrays: Dictionary, data: PackedFloat32Array, delta, n: int, s: float,
		i0: int, j0: int, i1: int, j1: int) -> void:
	var w := n + 1
	var on := n + 3
	var verts: PackedVector3Array = arrays.verts
	var heights: PackedFloat32Array = arrays.heights
	for j in range(maxi(j0, 0), mini(j1, n) + 1):
		for i in range(maxi(i0, 0), mini(i1, n) + 1):
			var h := height_at(data, delta, on, i + 1, j + 1)
			verts[j * w + i] = Vector3(i * s, h, j * s)
			heights[j * w + i] = h
	arrays.verts = verts
	arrays.heights = heights


## Per-pixel shading data for a tile, over the vertex grid plus its ring
## (texel (i + 1, j + 1) is vertex (i, j)): [heights (RF, edited), attributes
## (RGBAH: floodplain 0..1, gully depth m, channel cut m, dug depth m)].
static func textures(data: PackedFloat32Array, delta, n: int) -> Array:
	var on := n + 3
	var hb := PackedFloat32Array()
	var ab := PackedFloat32Array()
	hb.resize(on * on)
	ab.resize(on * on * 4)
	for r in on * on:
		var d: float = 0.0 if delta == null else delta[r]
		hb[r] = data[r * 8] + d
		ab[r * 4] = data[r * 8 + 1]
		ab[r * 4 + 1] = data[r * 8 + 2]
		ab[r * 4 + 2] = data[r * 8 + 3]
		ab[r * 4 + 3] = -d
	var himg := Image.create_from_data(on, on, false, Image.FORMAT_RF, hb.to_byte_array())
	var aimg := Image.create_from_data(on, on, false, Image.FORMAT_RGBAF, ab.to_byte_array())
	aimg.convert(Image.FORMAT_RGBAH)
	return [himg, aimg]


static func make_mesh(arrays: Dictionary, n: int) -> ArrayMesh:
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = arrays.verts
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
	# Dry vertices on the edge of the water take their wet neighbours' level, so
	# the sheet stays flat out to where it meets the bank instead of dropping
	# away (which left a saw-toothed waterline).
	var edge := PackedVector3Array(verts)
	var ring := PackedByteArray()
	ring.resize(w * w)
	for j in w:
		for i in w:
			var a := j * w + i
			if wet[a] == 1:
				continue
			var lvl := -INF
			for dj in range(-1, 2):
				for di in range(-1, 2):
					var ni := i + di
					var nj := j + dj
					if ni >= 0 and nj >= 0 and ni < w and nj < w and wet[nj * w + ni] == 1:
						if verts[nj * w + ni].y > lvl:
							lvl = verts[nj * w + ni].y
							flow[a] = flow[nj * w + ni]
			if lvl > -INF:
				edge[a].y = lvl
				ring[a] = 1
	verts = edge
	var idx := PackedInt32Array()
	for j in n:
		for i in n:
			var a := j * w + i
			# Also keep the ring of quads around the water (their corners were
			# levelled above), so the sheet runs into the bank and the waterline
			# is where it meets the ground, not a stair-step on the grid.
			if wet[a] + wet[a + 1] + wet[a + w] + wet[a + w + 1] == 0 \
					and not (ring[a] or ring[a + 1] or ring[a + w] or ring[a + w + 1]):
				continue
			idx.append_array([a, a + 1, a + w, a + 1, a + w + 1, a + w])
	var normals := PackedVector3Array()
	normals.resize(w * w)
	normals.fill(Vector3.UP)
	return {"verts": verts, "normals": normals, "indices": idx, "flow": flow}
