class_name MeshCut
## Cuts a mesh across the plane y = h (its own space) and keeps what's above
## it: a felled tree's trunk from the cut up (Felling), the rest left in the
## stump. Done on the meshes themselves, once, so what's kept is above the
## cut by construction, whatever draws it:
##
## - Each triangle is clipped to the half-space y >= h. That's convex, so
##   what's left of a triangle in it lies in it; the new corners are put on
##   the plane exactly (y = h), each made once for the edge it's on and
##   shared by both triangles that meet there (no cracks). Triangles wholly
##   below are dropped. So every corner of every triangle kept has y >= h.
## - Where the wood crosses the plane the clipping leaves the outline of the
##   cut, as loops of those shared corners; cap() closes each loop with a
##   fan of triangles on the plane, through exactly those corners: the cut
##   face meets the bark with no gap.
## - Nothing the shaders do moves a corner below the plane: the bark's and
##   leaves' sway with the wind is switched off (their weights zeroed: a
##   felled tree is dead wood), a level of detail not shown collapses to a
##   point (no pixels); a leaf card can grow as its neighbours thin out
##   (leaves.gdshader: up to 1 / sqrt(min_keep) round its middle) and
##   flutter (along its normal, `flutter`), so any card that could reach
##   below the plane even so is dropped whole, not clipped.

const LEAF_GROWTH := 1.83 ## the most a leaf card grows round its middle (1 / sqrt(leaves.gdshader's min_keep, 0.3))
const LEAF_FLUTTER := 0.05 ## its own units: the most a leaf flutters (leaves.gdshader: flutter 0.045)


## The part of src above y = h: {"mesh": ArrayMesh, "loops": the outlines
## where its bark crosses the plane (Array of PackedVector3Array, each a
## closed loop of corners on it)}.
static func above(src: Mesh, h: float) -> Dictionary:
	var out := ArrayMesh.new()
	var loops: Array = []
	for si in src.get_surface_count():
		var arrays := src.surface_get_arrays(si)
		var mat := src.surface_get_material(si)
		var shader_path := ""
		if mat is ShaderMaterial and (mat as ShaderMaterial).shader:
			shader_path = (mat as ShaderMaterial).shader.resource_path
		var leaves := shader_path == "res://shaders/render/leaves.gdshader"
		var r: Array = _leaves_above(arrays, h) if leaves else _clip(arrays, h)
		var new_arrays: Array = r[0]
		var kept: PackedInt32Array = new_arrays[Mesh.ARRAY_INDEX]
		if kept.is_empty():
			continue
		if not leaves:
			loops.append_array(_loops(r[1], new_arrays[Mesh.ARRAY_VERTEX]))
		var fmt: int = src.surface_get_format(si)
		var custom: int = fmt & ((Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
				| (Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) | (Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT))
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays, [], {}, custom)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	return {"mesh": out, "loops": loops}


## How many numbers a vertex has in array slot `slot` (a packed float array: TANGENT, CUSTOMn).
static func _comps(arrays: Array, slot: int, n: int) -> int:
	var a = arrays[slot]
	if a is PackedFloat32Array and n > 0:
		var f: PackedFloat32Array = a
		return f.size() / n
	return 0


## A surface's triangles clipped to y >= h: [its arrays (the corners made
## added at the end; those below left in, used by no triangle), the cut's
## segments: pairs of corner indices on the plane]. Its sway switched off
## (UV2.y: TreeBuilder's sway weight, the bark's).
static func _clip(arrays: Array, h: float) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n := verts.size()
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		idx.resize(n)
		for i in n:
			idx[i] = i
	var made := {} # edge (a * n + b, a < b) -> the corner made on it
	var extra: Array = [] # the corners made: [a, b, t]
	var segs: Array = [] # [corner, corner]
	var out := PackedInt32Array()
	for f in range(0, idx.size() - 2, 3):
		var tri := [idx[f], idx[f + 1], idx[f + 2]]
		var d := [verts[tri[0]].y - h, verts[tri[1]].y - h, verts[tri[2]].y - h]
		var up := 0
		for k in 3:
			if d[k] >= 0.0:
				up += 1
		if up == 3:
			out.append_array(PackedInt32Array(tri))
			continue
		if up == 0:
			continue
		# turned round (its order kept) so that, one above: it's first; two
		# above: the one below is last
		var r := 0
		if up == 1:
			while d[r] < 0.0:
				r += 1
		else:
			while d[(r + 2) % 3] >= 0.0:
				r += 1
		var a: int = tri[r]
		var b: int = tri[(r + 1) % 3]
		var c: int = tri[(r + 2) % 3]
		if up == 1:
			var p := _corner(a, b, verts, h, n, made, extra)
			var q := _corner(a, c, verts, h, n, made, extra)
			out.append_array(PackedInt32Array([a, p, q]))
			segs.append([p, q])
		else:
			var p := _corner(b, c, verts, h, n, made, extra)
			var q := _corner(a, c, verts, h, n, made, extra)
			out.append_array(PackedInt32Array([a, b, p, a, p, q]))
			segs.append([p, q])
	var res := _with_corners(arrays, n, extra, h)
	res[Mesh.ARRAY_INDEX] = out
	# no sway: the corners stay where they are
	var uv2 = res[Mesh.ARRAY_TEX_UV2]
	if uv2 is PackedVector2Array:
		var u: PackedVector2Array = uv2
		for i in u.size():
			u[i] = Vector2(u[i].x, 0.0)
		res[Mesh.ARRAY_TEX_UV2] = u
	return [res, segs]


## The corner on edge (a, b) at the plane: made once an edge (its index:
## n + its place in extra).
static func _corner(a: int, b: int, verts: PackedVector3Array, h: float, n: int, made: Dictionary, extra: Array) -> int:
	var key := mini(a, b) * n + maxi(a, b)
	if made.has(key):
		return made[key]
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var t := (h - verts[lo].y) / (verts[hi].y - verts[lo].y) # (from lo to hi, the same whichever triangle asks)
	var i := n + extra.size()
	extra.append([lo, hi, t])
	made[key] = i
	return i


## The arrays with the corners made added at their ends, every attribute
## interpolated along its edge, the position on the plane exactly.
static func _with_corners(arrays: Array, n: int, extra: Array, h: float) -> Array:
	var res := arrays.duplicate()
	if extra.is_empty():
		return res
	for slot in Mesh.ARRAY_MAX:
		var a = arrays[slot]
		if a == null or slot == Mesh.ARRAY_INDEX:
			continue
		if a is PackedVector3Array:
			var v: PackedVector3Array = a
			for e: Array in extra:
				var p: Vector3 = v[e[0]].lerp(v[e[1]], e[2])
				if slot == Mesh.ARRAY_VERTEX:
					p.y = h
				elif slot == Mesh.ARRAY_NORMAL:
					p = p.normalized() if p.length_squared() > 1e-12 else v[e[0]]
				v.append(p)
			res[slot] = v
		elif a is PackedVector2Array:
			var v: PackedVector2Array = a
			for e: Array in extra:
				v.append(v[e[0]].lerp(v[e[1]], e[2]))
			res[slot] = v
		elif a is PackedColorArray:
			var v: PackedColorArray = a
			for e: Array in extra:
				v.append(v[e[0]].lerp(v[e[1]], e[2]))
			res[slot] = v
		elif a is PackedFloat32Array:
			var v: PackedFloat32Array = a
			var c := _comps(arrays, slot, n)
			if c <= 0:
				continue
			for e: Array in extra:
				for k in c:
					v.append(lerpf(v[int(e[0]) * c + k], v[int(e[1]) * c + k], e[2]))
			res[slot] = v
	return res


## A leaf surface's cards above y = h: none clipped, any that could reach
## below it (grown round its middle as far as it can, and fluttering) left
## out, whole; their sway switched off (CUSTOM1.r, the sway weight).
static func _leaves_above(arrays: Array, h: float) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n := verts.size()
	var c0: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM0] if arrays[Mesh.ARRAY_CUSTOM0] is PackedFloat32Array else PackedFloat32Array()
	var cc := c0.size() / maxi(n, 1)
	var ok := PackedByteArray()
	ok.resize(n)
	for i in n:
		var off := Vector3(c0[i * cc], c0[i * cc + 1], c0[i * cc + 2]) if cc >= 3 else Vector3.ZERO
		var mid := verts[i] - off
		var low := mid.y - absf(off.y) * LEAF_GROWTH - LEAF_FLUTTER
		ok[i] = 1 if low >= h else 0
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var out := PackedInt32Array()
	for f in range(0, idx.size() - 2, 3):
		if ok[idx[f]] and ok[idx[f + 1]] and ok[idx[f + 2]]:
			out.append_array(PackedInt32Array([idx[f], idx[f + 1], idx[f + 2]]))
	var res := arrays.duplicate()
	res[Mesh.ARRAY_INDEX] = out
	var c1 = arrays[Mesh.ARRAY_CUSTOM1]
	if c1 is PackedFloat32Array:
		var w: PackedFloat32Array = c1
		w = w.duplicate()
		w.fill(0.0)
		res[Mesh.ARRAY_CUSTOM1] = w
	return [res, []]


## The cut's segments chained into loops of positions: by position, not
## by index (a tube's seam repeats its first corner for the texture's sake:
## two corners at one place, which by index left the loop open there).
static func _loops(segs: Array, verts: PackedVector3Array) -> Array:
	var pos := {} # place (Vector3i, to 0.01 mm) -> the position
	var adj := {} # place -> the places it's joined to
	for s: Array in segs:
		var kp := _place(verts[s[0]])
		var kq := _place(verts[s[1]])
		pos[kp] = verts[s[0]]
		pos[kq] = verts[s[1]]
		if kp == kq:
			continue
		for pair in [[kp, kq], [kq, kp]]:
			if not adj.has(pair[0]):
				adj[pair[0]] = []
			if not (adj[pair[0]] as Array).has(pair[1]):
				(adj[pair[0]] as Array).append(pair[1])
	var seen := {}
	var loops: Array = []
	for start in adj:
		if seen.has(start):
			continue
		var loop := PackedVector3Array()
		var prev := NONE
		var at: Vector3i = start
		while at != NONE and not seen.has(at):
			seen[at] = true
			loop.append(pos[at])
			var next := NONE
			for o: Vector3i in adj[at]:
				if o != prev and not seen.has(o):
					next = o
					break
			prev = at
			at = next
		if loop.size() >= 3:
			loops.append(loop)
	return loops


const NONE := Vector3i(-2147483647, -2147483647, -2147483647) ## (no place: the chain's end)


static func _place(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 1e5), roundi(p.y * 1e5), roundi(p.z * 1e5))


## The cut faces closing the loops (each a fan from its middle, on the plane
## y = h, through exactly the loop's corners), as end grain (UV2.x 1: the
## bark shader's cut ends; UV across the loop, -1..1), facing both ways (the
## wrong way culled): built in a frame turned by `turn` (its x along the
## axe's strokes, bark.gdshader's fresh_end), its node to be turned back.
static func cap(loops: Array, h: float, turn: Basis, material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inv := turn.inverse()
	for loop: PackedVector3Array in loops:
		var mid := Vector3.ZERO
		for p in loop:
			mid += p
		mid /= loop.size()
		mid.y = h
		var reach := 0.0
		for p in loop:
			reach = maxf(reach, Vector2(p.x - mid.x, p.z - mid.z).length())
		reach = maxf(reach, 1e-4)
		for i in loop.size():
			var a := loop[i]
			var b := loop[(i + 1) % loop.size()]
			var g := (a - mid).cross(b - mid) # (whichever way the loop runs)
			for facing in [-1.0, 1.0]:
				# a front face is clockwise seen from outside (as
				# TreeBuilder's caps): (mid, a, b) faces the way -g points
				var tri := [mid, a, b] if g.y * facing < 0.0 else [mid, b, a]
				for p: Vector3 in tri:
					st.set_normal(inv * Vector3(0.0, facing, 0.0))
					st.set_uv(Vector2(p.x - mid.x, p.z - mid.z) / reach)
					st.set_uv2(Vector2(1.0, 0.0))
					st.set_color(Color(1, 1, 1))
					st.add_vertex(inv * p)
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, material)
	return mesh
