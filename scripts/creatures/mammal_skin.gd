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


# --- the small mammals' make (Hare, Mouse, FoxSquirrel, Beaver): no neck of
# its own (the head on the body), legs of three bones each --------------------

## The body (torso keys [z, y, half width, half height], the torso's bone)
## rounding up into the head (head keys in the head's space, at rest hrest)
## to its nose: one tube; its chest's front apart beneath. along: the body
## 0..0.6, the head 0.75..1.
func body_head(torso: int, body_keys: Array, head: int, hrest: Transform3D, head_keys: Array, pw := 2.2, around := 22) -> void:
	var bk: Array = body_keys.duplicate()
	bk.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var z0 := float(bk[0][0])
	var z1 := float(bk[bk.size() - 1][0])
	var h0: Array = head_keys[0]
	var hz := (hrest * Vector3(0.0, h0[1], h0[0])).z # (where the head's back is, along the body)
	var gap := float(h0[3]) * 0.6
	var rings := []
	for k: Array in bk:
		if float(k[0]) < hz + gap:
			continue
		rings.append(ring(Vector3(0.0, k[1], k[0]), Vector3.RIGHT, Vector3.UP, k[2], k[3], k[3], {torso: 1.0}, 0, 0.6 * (z0 - float(k[0])) / maxf(z0 - z1, 1.0), 0.0, pw))
	for j in head_keys.size():
		var k: Array = head_keys[j]
		var w := {torso: 0.5, head: 0.5} if j == 0 else ({torso: 0.15, head: 0.85} if j == 1 else {head: 1.0})
		rings.append(ring(hrest * Vector3(0.0, k[1], k[0]), hrest.basis.x, hrest.basis.y, k[2], k[3], k[3], w, 0, 0.75 + 0.25 * j / maxf(head_keys.size() - 1, 1), 0.3 if j == 0 else 1.0, lerpf(pw, 2.0, minf(j / 2.0, 1.0))))
	tube(smooth(rings, 4), around, head)
	var chest := []
	for k: Array in bk:
		if float(k[0]) < hz + gap + float(h0[3]) * 1.6:
			chest.append(ring(Vector3(0.0, float(k[1]) - float(k[3]) * 0.12, k[0]), Vector3.RIGHT, Vector3.UP, float(k[2]) * 0.92, float(k[3]) * 0.8, float(k[3]) * 0.95, {torso: 1.0}, 0, 0.6 * (z0 - float(k[0])) / maxf(z0 - z1, 1.0), 0.0, pw))
	if chest.size() >= 2:
		tube(smooth(chest, 3), around - 2, head)


## A jaw (keys in its own space, at rest jrest) under the head.
func jaw_tube(head: int, jaw: int, jrest: Transform3D, keys: Array) -> void:
	var rings := []
	for j in keys.size():
		var k: Array = keys[j]
		rings.append(ring(jrest * Vector3(0.0, k[1], k[0]), jrest.basis.x, jrest.basis.y, k[2], k[3], k[3], {head: 0.5, jaw: 0.5} if j == 0 else {jaw: 1.0}, 0, 0.9, 1.0))
	tube(smooth(rings, 3), 14, head)


## A tail through its joints' bones (rests: each joint's rest transform, the
## tail running along its z; seg: a joint's length), its radius at each
## (radii); from inside the body (torso). flat: its depth's share of its
## width (a beaver's paddle: thin).
func tail_chain(torso: int, bones: Array, rests: Array, radii: Array, seg: float, flat := 1.0, around := 12) -> void:
	var rings := []
	var t0: Transform3D = rests[0]
	var r0 := float(radii[0])
	rings.append(ring(t0 * Vector3(0.0, 0.0, -r0 * 1.2), t0.basis.x, t0.basis.y, r0 * 1.1, r0 * 1.1, r0 * 1.1, {torso: 1.0}, 6, 0.0))
	var n := bones.size()
	for k in n:
		var xf: Transform3D = rests[k]
		var rk := float(radii[k])
		var wj := {torso: 0.5, bones[0]: 0.5} if k == 0 else {bones[k - 1]: 0.5, bones[k]: 0.5}
		var fk := lerpf(1.0, flat, clampf(k / 2.0, 0.0, 1.0))
		rings.append(ring(xf.origin, xf.basis.x, xf.basis.y, rk, rk * fk, rk * fk, wj, 6, float(k) / n))
		var rn := float(radii[mini(k + 1, n - 1)])
		var rm := (rk + rn) * 0.5
		rings.append(ring(xf * Vector3(0.0, 0.0, seg * 0.5), xf.basis.x, xf.basis.y, rm, rm * fk, rm * fk, {bones[k]: 1.0}, 6, (k + 0.5) / n))
	var last: Transform3D = rests[n - 1]
	var rl := float(radii[n - 1]) * 0.7
	rings.append(ring(last * Vector3(0.0, 0.0, seg), last.basis.x, last.basis.y, rl, rl * flat, rl * flat, {bones[n - 1]: 1.0}, 6, 1.0))
	tube(smooth(rings, 2), around)


## A leg of three bones (b: upper, lower, foot) through its joints J (hip,
## knee, heel, toe; at rest), its radius r; hind: a haunch, round and big,
## and a long foot; foot_w: the foot's width (times r).
func leg3(torso: int, b: Array, J: Array, r: float, hind: bool, foot_w := 1.3, a := -1.0, fold := false) -> void:
	var hip: Vector3 = J[0]
	var knee: Vector3 = J[1]
	var heel: Vector3 = J[2]
	var toe: Vector3 = J[3]
	if a < 0.0:
		a = hip.distance_to(knee)
	var spec := []
	if hind:
		spec = [[hip * Vector3(0.45, 1.0, 1.0) + Vector3(0.0, a * 0.35, a * 0.15), 1.8, 2.9, 2.3, {torso: 1.0}],
			[hip * Vector3(0.72, 1.0, 1.0), 2.3, 3.2, 2.5, {torso: 0.55, b[0]: 0.45}],
			[(hip * Vector3(0.85, 1.0, 1.0)).lerp(knee, 0.45), 2.1, 2.8, 2.1, {b[0]: 0.85, torso: 0.15}],
			[knee, 1.45, 1.6, 1.35, {b[0]: 0.5, b[1]: 0.5}],
			[knee.lerp(heel, 0.3), 1.2, 1.45, 1.0, {b[1]: 1.0}],
			[knee.lerp(heel, 0.82), 0.78, 0.85, 0.72, {b[1]: 1.0}],
			[heel, 0.8, 0.95, 0.8, {b[1]: 0.5, b[2]: 0.5}, (heel - knee).normalized()],
			[heel + (toe - heel).normalized() * r * 1.1, foot_w * 0.7, 0.7, 0.62, {b[1]: 0.15, b[2]: 0.85}, (toe - heel).normalized()],
			[heel.lerp(toe, 0.4), foot_w, 0.62, 0.62, {b[2]: 1.0}],
			[heel.lerp(toe, 0.95), foot_w * 0.8, 0.42, 0.45, {b[2]: 1.0}]]
	else:
		spec = [[hip * Vector3(0.5, 1.0, 1.0) + Vector3(0.0, a * 0.5, a * 0.05), 1.35, 2.1, 2.1, {torso: 1.0}],
			[hip * Vector3(0.75, 1.0, 1.0), 1.65, 1.95, 2.1, {torso: 0.55, b[0]: 0.45}],
			[(hip * Vector3(0.88, 1.0, 1.0)).lerp(knee, 0.5), 1.5, 1.65, 1.7, {b[0]: 0.85, torso: 0.15}],
			[knee, 1.2, 1.45, 1.15, {b[0]: 0.5, b[1]: 0.5}],
			[knee.lerp(heel, 0.3), 1.05, 0.95, 1.15, {b[1]: 1.0}],
			[knee.lerp(heel, 0.85), 0.8, 0.75, 0.82, {b[1]: 1.0}],
			[heel, 0.82, 0.8, 0.8, {b[1]: 0.5, b[2]: 0.5}, (heel - knee).normalized()],
			[heel + (toe - heel).normalized() * r * 0.9, foot_w * 0.8, 0.6, 0.62, {b[1]: 0.15, b[2]: 0.85}, (toe - heel).normalized()],
			[heel.lerp(toe, 0.5), foot_w, 0.55, 0.6, {b[2]: 1.0}],
			[heel.lerp(toe, 0.95), foot_w * 0.8, 0.4, 0.45, {b[2]: 1.0}]]
	var pts := []
	for sp: Array in spec:
		pts.append(sp[0])
	var total := 0.0
	for k in range(1, pts.size()):
		total += (pts[k] as Vector3).distance_to(pts[k - 1])
	var dirs := []
	for k in spec.size():
		var sp: Array = spec[k]
		dirs.append(sp[5] if sp.size() > 5 else ((pts[mini(k + 1, pts.size() - 1)] as Vector3) - (pts[maxi(k - 1, 0)] as Vector3)).normalized())
	var fr := frames(dirs)
	var rings := []
	var run := 0.0
	for k in spec.size():
		var sp: Array = spec[k]
		var c: Vector3 = sp[0]
		if k > 0:
			run += c.distance_to(pts[k - 1])
		rings.append(ring(c, fr[k][0], fr[k][1], float(sp[1]) * r, float(sp[2]) * r, float(sp[3]) * r, sp[4], 3 if hind else 2, run / maxf(total, 1e-3), 0.0, 2.0))
	tube(smooth(rings, 1 if fold else 2), 14) # (a leg folded tight: no curve to overshoot its turns)


## Frames along a limb (its rings' directions): the first's side as near
## the body's right as it can be, its second axis behind; each after it
## turned from the one before by the least turn (no twist along the limb).
static func frames(dirs: Array) -> Array:
	var out := []
	var d0: Vector3 = dirs[0]
	var ax := (Vector3.RIGHT - d0 * d0.dot(Vector3.RIGHT)).normalized()
	var ay := d0.cross(ax).normalized()
	out.append([ax, ay])
	for k in range(1, dirs.size()):
		var a: Vector3 = dirs[k - 1]
		var b: Vector3 = dirs[k]
		if a.dot(b) < 0.9999 and a.cross(b).length() > 1e-5:
			var q := Quaternion(a, b)
			ax = (q * ax).normalized()
			ay = (q * ay).normalized()
		out.append([ax, ay])
	return out


## A leg's three bones, posed (or at rest) through its joints.
func pose_leg3(b: Array, J: Array) -> void:
	for q in 3:
		pose(b[q], along(J[q], J[q + 1]))
