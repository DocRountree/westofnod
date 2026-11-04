class_name MammalSkin
extends RefCounted
## One smooth skin for a mammal: its body, neck and head, its legs and its
## tail as tubes swept through rings, every vertex weighted to the bones the
## animal's own motor moves (its torso, neck, head, jaw, tail joints, each
## leg's segments), skinned on the GPU. The rings are laid out in a rest
## pose the caller knows each bone's transform in; each frame the caller
## gives the bones where its motor has them (pose), and the skin follows,
## bending smoothly at every joint: no parts stacked, no seams to see.
##
## Each vertex carries, for the coat's shader (carnivore.gdshader):
## CUSTOM0 (its part: 0 the body, 2 a foreleg, 3 a hind leg, 6 the tail;
## its place along it, 0..1; its share of the face's colours; 1: it is the
## skin's), CUSTOM1 (where it was at rest, the body's mm), CUSTOM2 (its
## normal at rest), CUSTOM3 (where it was in the head's own space).

var skel: Skeleton3D
var _rest: Array[Transform3D] = []
var _names: Array[String] = []
var _st := SurfaceTool.new()
var _count := 0


func _init() -> void:
	_st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS) # (before it begins)
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in 4:
		_st.set_custom_format(c, SurfaceTool.CUSTOM_RGBA_FLOAT)


## A bone, at rest at `rest` (the skeleton's space: the body's). Its index.
func bone(name: String, rest: Transform3D) -> int:
	_names.append(name)
	_rest.append(rest)
	return _rest.size() - 1


func rest_of(i: int) -> Transform3D:
	return _rest[i]


## A ring for a tube: its centre, its side (x) and up (y) axes (unit), its
## half widths (x; up; down), its shape (pw: 2 an ellipse, more boxier), its
## bones' weights ({bone: weight}), and its coat's data: part, along (0..1),
## face (its share of the face's colours), head (the head's rest transform,
## for where it is in the head's own space; or null).
static func ring(c: Vector3, ax: Vector3, ay: Vector3, rx: float, ry: float, ryb: float, w: Dictionary, part: int, along: float, face := 0.0, pw := 2.0) -> Dictionary:
	return {"c": c, "ax": ax, "ay": ay, "rx": rx, "ry": ry, "ryb": ryb, "w": w, "part": part, "a": along, "face": face, "pw": pw}


## The rings smoothed (Catmull-Rom through their centres and sizes), `steps`
## between each two.
static func smooth(rings: Array, steps: int) -> Array:
	var out := []
	var K := rings.size()
	if K < 2 or steps <= 1:
		return rings.duplicate()
	for j in K - 1:
		for s in steps:
			var f := float(s) / steps
			out.append(_between(rings, j, f))
	out.append(rings[K - 1])
	return out


static func _cr(p0: Variant, p1: Variant, p2: Variant, p3: Variant, f: float) -> Variant:
	return 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)


static func _between(rings: Array, j: int, f: float) -> Dictionary:
	var K := rings.size()
	var r0: Dictionary = rings[maxi(j - 1, 0)]
	var r1: Dictionary = rings[j]
	var r2: Dictionary = rings[j + 1]
	var r3: Dictionary = rings[mini(j + 2, K - 1)]
	var out := {}
	out.c = _cr(r0.c, r1.c, r2.c, r3.c, f)
	for k in ["rx", "ry", "ryb"]:
		out[k] = maxf(float(_cr(r0[k], r1[k], r2[k], r3[k], f)), 0.01)
	out.ax = (r1.ax as Vector3).lerp(r2.ax, f).normalized()
	out.ay = (r1.ay as Vector3).lerp(r2.ay, f).normalized()
	out.pw = lerpf(r1.pw, r2.pw, f)
	out.a = lerpf(r1.a, r2.a, f)
	out.face = lerpf(r1.face, r2.face, f)
	out.part = r1.part if f < 0.5 else r2.part
	var w := {}
	for b in r1.w:
		w[b] = float(r1.w[b]) * (1.0 - f)
	for b in r2.w:
		w[b] = float(w.get(b, 0.0)) + float(r2.w[b]) * f
	out.w = w
	return out


## A tube through rings (each ring, around, points), its ends closed with
## rounded caps. head: the head's bone (the CUSTOM3 space; -1 none).
func tube(rings: Array, around := 18, head := -1) -> void:
	var R := rings.size()
	if R < 2:
		return
	# (the caps: each end rounded off past its last ring)
	var all := rings.duplicate()
	for e in [0, 1]:
		var end: Dictionary = all[0] if e == 0 else all[all.size() - 1]
		var nxt: Dictionary = all[1] if e == 0 else all[all.size() - 2]
		var d := ((end.c as Vector3) - (nxt.c as Vector3)).normalized()
		var r := (float(end.rx) + float(end.ry)) * 0.5
		var caps := []
		for k in [[0.55, 0.8], [0.85, 0.5], [0.98, 0.18]]:
			var cr := end.duplicate()
			cr.c = (end.c as Vector3) + d * r * float(k[0]) * 0.8
			for q in ["rx", "ry", "ryb"]:
				cr[q] = float(end[q]) * float(k[1])
			caps.append(cr)
		if e == 0:
			caps.reverse()
			all = caps + all
		else:
			all = all + caps
	R = all.size()
	var P := []
	for i in R:
		var rg: Dictionary = all[i]
		var row := []
		for k in around:
			var a := TAU * k / around
			var cx := cos(a)
			var cy := sin(a)
			var pw: float = rg.pw
			var ex := signf(cx) * pow(absf(cx), 2.0 / pw)
			var ey := signf(cy) * pow(absf(cy), 2.0 / pw)
			var ry: float = rg.ry if cy >= 0.0 else rg.ryb
			row.append((rg.c as Vector3) + (rg.ax as Vector3) * ex * float(rg.rx) + (rg.ay as Vector3) * ey * ry)
		P.append(row)
	# normals: across the rings and round them
	var N := []
	for i in R:
		var row := []
		for k in around:
			var t1: Vector3 = P[i][(k + 1) % around] - P[i][(k - 1 + around) % around]
			var t2: Vector3 = P[mini(i + 1, R - 1)][k] - P[maxi(i - 1, 0)][k]
			var n := t1.cross(t2)
			if n.length_squared() < 1e-10:
				n = (P[i][k] as Vector3) - (all[i].c as Vector3)
			n = n.normalized()
			if n.dot((P[i][k] as Vector3) - (all[i].c as Vector3)) < 0.0:
				n = -n
			row.append(n)
		N.append(row)
	var hinv := _rest[head].affine_inverse() if head >= 0 else Transform3D()
	var tip0 := (all[0].c as Vector3)
	var tip1 := (all[R - 1].c as Vector3)
	# (its faces out: wound by its rings' handedness along it)
	var run := (all[R - 1].c as Vector3) - (all[0].c as Vector3)
	var flip := (all[R / 2].ax as Vector3).cross(all[R / 2].ay).dot(run) < 0.0
	for i in R - 1:
		for k in around:
			var k1 := (k + 1) % around
			var quad := [[i, k], [i, k1], [i + 1, k], [i, k1], [i + 1, k1], [i + 1, k]] if flip else [[i, k], [i + 1, k], [i, k1], [i, k1], [i + 1, k], [i + 1, k1]]
			for q: Array in quad:
				_vert(P[q[0]][q[1]], N[q[0]][q[1]], all[q[0]], hinv, head >= 0)
	# (the very tips: fans to a point)
	for e in [0, 1]:
		var i := 0 if e == 0 else R - 1
		var tip := tip0 if e == 0 else tip1
		var d := (tip - (all[1 if e == 0 else R - 2].c as Vector3)).normalized()
		for k in around:
			var k1 := (k + 1) % around
			var tri := [[P[i][k], N[i][k]], [tip, d], [P[i][k1], N[i][k1]]] if (e == 0) != flip else [[P[i][k], N[i][k]], [P[i][k1], N[i][k1]], [tip, d]]
			for v: Array in tri:
				_vert(v[0], v[1], all[i], hinv, head >= 0)


func _vert(p: Vector3, n: Vector3, rg: Dictionary, hinv: Transform3D, has_head: bool) -> void:
	# its four strongest bones, their weights summing to 1
	var pairs := []
	for b in rg.w:
		if float(rg.w[b]) > 1e-4:
			pairs.append([int(b), float(rg.w[b])])
	pairs.sort_custom(func(x: Array, y: Array) -> bool: return x[1] > y[1])
	var bones := PackedInt32Array([0, 0, 0, 0])
	var ws := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var sum := 0.0
	for k in mini(pairs.size(), 4):
		sum += float(pairs[k][1])
	for k in mini(pairs.size(), 4):
		bones[k] = pairs[k][0]
		ws[k] = float(pairs[k][1]) / maxf(sum, 1e-6)
	if pairs.is_empty():
		ws[0] = 1.0
	_st.set_bones(bones)
	_st.set_weights(ws)
	_st.set_normal(n)
	_st.set_custom(0, Color(float(rg.part), float(rg.a), float(rg.face), 1.0))
	_st.set_custom(1, Color(p.x, p.y, p.z, 0.0))
	_st.set_custom(2, Color(n.x, n.y, n.z, 0.0))
	var h := hinv * p if has_head else Vector3.ZERO
	_st.set_custom(3, Color(h.x, h.y, h.z, 0.0))
	_st.add_vertex(p)
	_count += 1


## The skeleton and the skinned mesh, under parent (the body: its space the
## skeleton's), drawn with mat.
func finish(parent: Node3D, mat: Material) -> MeshInstance3D:
	skel = Skeleton3D.new()
	parent.add_child(skel)
	for i in _rest.size():
		skel.add_bone(_names[i])
		skel.set_bone_rest(i, _rest[i])
		skel.set_bone_pose_position(i, _rest[i].origin)
		skel.set_bone_pose_rotation(i, _rest[i].basis.get_rotation_quaternion())
	_st.index()
	var mesh := _st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	skel.add_child(mi)
	var skin := Skin.new()
	for i in _rest.size():
		skin.add_bind(i, _rest[i].affine_inverse())
	mi.skin = skin
	mi.skeleton = mi.get_path_to(skel)
	var bb := mesh.get_aabb()
	mi.custom_aabb = bb.grow(bb.size.length() * 0.6) # (posed, it reaches past where it rests)
	return mi


## Bone i where the motor has it now (the body's space).
func pose(i: int, xf: Transform3D) -> void:
	skel.set_bone_pose_position(i, xf.origin)
	skel.set_bone_pose_rotation(i, xf.basis.orthonormalized().get_rotation_quaternion())


## A bone's transform along a to b: its origin at a, y along it, x as near
## `side` as it can be.
static func along(a: Vector3, b: Vector3, side := Vector3.RIGHT) -> Transform3D:
	var y := b - a
	y = y.normalized() if y.length() > 1e-5 else Vector3.DOWN
	var x := side - y * y.dot(side)
	if x.length() < 1e-4:
		x = Vector3.FORWARD - y * y.dot(Vector3.FORWARD)
	x = x.normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x, y, z), a)
