class_name CharacterMesh
extends RefCounted
## One surface of the figure being built (CharacterParts): smooth shapes
## added to it one after another, then made a mesh. Its shapes:
## - tube: a skin lofted through cross-sections along an axis (a torso up
##   its spine, a limb down its bone), each a rounded outline wider than
##   deep, its front and back their own depths; smooth between the keys;
## - blob: an ellipsoid, turned as wanted (a nose, an ear, a knuckle);
## - grid: any sheet of points, row by row (hair, a beard, a hat's brim).
## Normals are worked out from the sheet itself and turned outward; UV.x
## goes round (or across) a shape, UV.y along it in metres (tubes) or 0..1.

var verts := PackedVector3Array()
var normals := PackedVector3Array()
var uvs := PackedVector2Array()
var indices := PackedInt32Array()


## A key's value between the keys either side, smoothly (Catmull-Rom).
static func _cr(a: float, b: float, c: float, d: float, t: float) -> float:
	return 0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t)


## keys ([t, ca, cb, ra, rb_neg, rb_pos] and, optional, its squareness: 2 an
## ellipse .. 5 a rounded box) with `sub` sections worked in between each
## pair, smoothly.
static func refine(keys: Array, sub: int) -> Array:
	var out := []
	var n := keys.size()
	for i in n - 1:
		var k0: Array = keys[maxi(i - 1, 0)]
		var k1: Array = keys[i]
		var k2: Array = keys[i + 1]
		var k3: Array = keys[mini(i + 2, n - 1)]
		for s in sub:
			var t := float(s) / sub
			var k := []
			for c in 7:
				var v := [k0, k1, k2, k3].map(func(q: Array) -> float: return float(q[c]) if c < q.size() else 2.3)
				var x := _cr(v[0], v[1], v[2], v[3], t)
				if c == 0: # (along it: never back on itself)
					x = lerpf(v[1], v[2], t)
				elif c >= 3: # (a radius: none below its keys' least, an overshoot at a tip)
					x = clampf(x, minf(v[1], v[2]) * 0.98, maxf(v[1], v[2]) * 1.06)
				k.append(x)
			out.append(k)
	var last: Array = keys[n - 1].duplicate()
	while last.size() < 7:
		last.append(2.3)
	out.append(last)
	return out


## A point of a section (a refined key) at angle th round it: (a, b), a
## across, b through (negative: its front, a torso's; a limb's -y side).
static func outline(k: Array, th: float) -> Vector2:
	var ca := cos(th)
	var sa := sin(th)
	var e := 2.0 / float(k[6])
	return Vector2(float(k[1]) + float(k[3]) * signf(ca) * pow(absf(ca), e),
			float(k[2]) + (float(k[5]) if sa > 0.0 else float(k[4])) * signf(sa) * pow(absf(sa), e))


## Where a tube's skin is, t along it, th round it (its refined keys: as
## tube lays them out).
static func surface(rk: Array, t: float, th: float, axis := "y") -> Vector3:
	var i := 0
	while i < rk.size() - 2 and float(rk[i + 1][0]) < t:
		i += 1
	var a: Array = rk[i]
	var b: Array = rk[i + 1]
	var f := clampf((t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6), 0.0, 1.0)
	var p := outline(a, th).lerp(outline(b, th), f)
	return Vector3(p.x, t, p.y) if axis == "y" else Vector3(p.x, p.y, -t)


## A tube through keys (refine()'s), `segs` round. axis "y": up y, its front
## toward -z; "z": down -z (a limb's bone), its outline in x and y. at:
## where it's set. Its ends closed.
func tube(keys: Array, segs := 16, sub := 3, axis := "y", at := Transform3D()) -> void:
	var rk := refine(keys, sub)
	var rows: Array[PackedVector3Array] = []
	var vs := PackedFloat32Array()
	for k: Array in rk:
		var row := PackedVector3Array()
		for j in segs:
			var p := outline(k, TAU * j / segs)
			row.append(at * (Vector3(p.x, float(k[0]), p.y) if axis == "y" else Vector3(p.x, p.y, -float(k[0]))))
		rows.append(row)
		vs.append(float(k[0]))
	grid(rows, true, vs, true)


## An ellipsoid at c, radii r, turned by b.
func blob(c: Vector3, r: Vector3, b := Basis(), segs := 12, rings := 8) -> void:
	var rows: Array[PackedVector3Array] = []
	for i in rings + 1:
		var la := PI * (float(i) / rings - 0.5)
		var row := PackedVector3Array()
		for j in segs:
			var lo := TAU * j / segs
			row.append(c + b * (Vector3(cos(la) * cos(lo), sin(la), cos(la) * sin(lo)) * r))
		rows.append(row)
	grid(rows, true, PackedFloat32Array(), false)


## A sheet of points, row by row (each as long as the others). wrap: each
## row closed on itself; vs: UV.y by row (else 0..1); caps: the first and
## last rows closed over (a tube's ends). out: a point the sheet's back is
## toward (its normals away from it; INF: from each row's own middle).
func grid(rows: Array[PackedVector3Array], wrap: bool, vs := PackedFloat32Array(), caps := false, out := Vector3.INF) -> void:
	var nr := rows.size()
	var nc := rows[0].size()
	var base := verts.size()
	var cols := nc + (1 if wrap else 0) # (a closed row's first point again at its end: its UV's seam)
	for i in nr:
		var mid := Vector3.ZERO
		for p in rows[i]:
			mid += p
		mid /= nc
		for j in cols:
			var p := rows[i][j % nc]
			var pu := rows[i][(j + 1) % nc] if wrap or j + 1 < nc else p
			var pd := rows[i][(j - 1 + nc) % nc] if wrap or j > 0 else p
			var pn := rows[mini(i + 1, nr - 1)][j % nc]
			var pp := rows[maxi(i - 1, 0)][j % nc]
			var n := (pu - pd).cross(pn - pp)
			var from := mid if out == Vector3.INF else out
			if n.length() < 1e-9:
				n = p - from
			n = n.normalized()
			if n.dot(p - from) < 0.0:
				n = -n
			verts.append(p)
			normals.append(n)
			uvs.append(Vector2(float(j) / (cols - 1), vs[i] if i < vs.size() else float(i) / maxf(nr - 1, 1)))
	for i in nr - 1:
		for j in cols - 1:
			var a := base + i * cols + j
			_quad(a, a + 1, a + cols + 1, a + cols)
	if caps:
		for e in [0, nr - 1]:
			var mid := Vector3.ZERO
			for p in rows[e]:
				mid += p
			mid /= nc
			var other := rows[1 if e == 0 else nr - 2][0] - rows[e][0]
			var n := -other.normalized() if other.length() > 1e-9 else Vector3.UP
			var c := verts.size()
			verts.append(mid)
			normals.append(n)
			uvs.append(Vector2(0.5, vs[e] if e < vs.size() else float(e)))
			for j in cols - 1:
				_tri(c, base + e * cols + j, base + e * cols + j + 1)


func _quad(a: int, b: int, c: int, d: int) -> void:
	_tri(a, b, c)
	_tri(a, c, d)


## A triangle, wound so its face is its corners' normals' side (Godot's
## front: clockwise).
func _tri(a: int, b: int, c: int) -> void:
	var face := (verts[c] - verts[a]).cross(verts[b] - verts[a])
	if face.dot(normals[a] + normals[b] + normals[c]) < 0.0:
		indices.append_array([a, c, b])
	else:
		indices.append_array([a, b, c])


func is_empty() -> bool:
	return indices.is_empty()


func mesh() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## The mesh, as a node under parent, with its material.
func put(parent: Node3D, material: Material, name := "") -> MeshInstance3D:
	if is_empty():
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = mesh()
	mi.material_override = material
	mi.set_meta("dress", true) # (the figure's look: made again when it changes, Avatar.set_look)
	if name != "":
		mi.name = name
	parent.add_child(mi)
	return mi
