extends RefCounted
## Personal space for every creature with a body of its own (not those drawn
## and moved by a shader: the ant colonies, the beetles, the fish schools):
## not collision, but each a capsule on the ground, from its rump to its
## head, as wide as its body; two that overlap, whatever their kinds, are
## eased apart, each its half. Off for one meant to touch another (mating,
## nursing, suckling, playing, hunting and eating, sparring, carrying,
## nesting; the young; one in the air; the dead).
##
## A creature joins (join, in its _enter_tree) and leaves (leave), and calls
## keep_apart(self) each frame once it's moved. Its capsule: its own
## _space_spine() -> [rump, head] (world xz) and _space_r() (m) if it has
## them, else from its _pos and _yaw (or its basis) and its body's drawn
## size (its meshes' bounds, worked out once); pushed by _space_push(xz) if
## it has one, else its _pos moved. Whether it may touch: its own
## _touch_ok() if it has one, else its young / dead / in the air / mating
## role / mode (TOUCHING).

static var all: Array = []
const TOUCHING := ["nurse", "suckle", "play", "hunt", "eat", "spar", "follow", "newborn", "birth", "carry", "piloted",
		"mate", "courted", "amplexus", "lay", "nest", "feed", "strike", "tadpole", "mount", "mounted", "groom_other"]


static func join(n: Node) -> void:
	if not all.has(n):
		all.append(n)


static func leave(n: Node) -> void:
	all.erase(n)


## Whether n's not to be kept off others now.
static func touching(n: Object) -> bool:
	if n.has_method("_touch_ok"):
		return bool(n.call("_touch_ok"))
	for f in ["young", "dead", "airborne", "_airborne", "flying"]:
		var v = n.get(f)
		if v is bool and v:
			return true
	for f in ["_mate_role", "_role"]:
		var v = n.get(f)
		if v is String and v != "":
			return true
	var m = n.get("_mode")
	return m is String and m in TOUCHING


## Its body's drawn length and half width (m), from its meshes' bounds in its
## own space (worked out once; legs and antennae make it a little long).
static func _dims(n: Node3D) -> Vector2:
	if n.has_meta("space_dims"):
		return n.get_meta("space_dims")
	var box := _aabb(n, Transform3D())
	var s := n.global_basis.get_scale() if n.is_inside_tree() else Vector3.ONE
	var d := Vector2(box.size.z * absf(s.z) * 0.8, box.size.x * absf(s.x) * 0.3)
	if d.x > 0.0005:
		n.set_meta("space_dims", d)
	return d


static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for c in n.get_children():
		if not (c is Node3D) or not (c as Node3D).visible:
			continue
		var t := xf * (c as Node3D).transform
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var b := t * (c as MeshInstance3D).mesh.get_aabb()
			out = b if first else out.merge(b)
			first = false
		var cb := _aabb(c, t)
		if cb.size != Vector3.ZERO:
			out = cb if first else out.merge(cb)
			first = false
	return out


static func spine(n: Node3D) -> Array:
	if n.has_method("_space_spine"):
		return n.call("_space_spine")
	var p = n.get("_pos")
	var at: Vector3 = p if p is Vector3 else n.global_position
	var y = n.get("_yaw")
	var f := Vector2(-sin(float(y)), -cos(float(y))) if y is float else Vector2(-n.global_basis.z.x, -n.global_basis.z.z).normalized()
	var d := _dims(n)
	var half := maxf(d.x * 0.5 - d.y, 0.0)
	var c := Vector2(at.x, at.z)
	return [c - f * half, c + f * half]


static func _y(n: Node3D) -> float:
	var p = n.get("_pos")
	return (p as Vector3).y if p is Vector3 else n.global_position.y


static func radius(n: Node3D) -> float:
	if n.has_method("_space_r"):
		return float(n.call("_space_r"))
	return _dims(n).y


static func _push(n: Node3D, v: Vector2) -> void:
	if n.has_method("_space_push"):
		n.call("_space_push", v)
		return
	var p = n.get("_pos")
	if p is Vector3:
		n.set("_pos", (p as Vector3) + Vector3(v.x, 0.0, v.y))


static func _seg_pt(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	return a + ab * clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-8), 0.0, 1.0)


## n eased off every other it overlaps (its half of the overlap).
static func keep_apart(n: Node3D) -> void:
	if touching(n):
		return
	var me := spine(n)
	var a0: Vector2 = me[0]
	var a1: Vector2 = me[1]
	var r := radius(n)
	if r <= 0.0:
		return
	for o: Node in all:
		if o == n or not is_instance_valid(o) or not o.is_inside_tree() or touching(o):
			continue
		var dy := _y(n) - _y(o as Node3D)
		if absf(dy) > (r + radius(o as Node3D)) * 2.0 + 0.05:
			continue # (one above the other: in a web, on a stem, up a log)
		var them := spine(o as Node3D)
		var b0: Vector2 = them[0]
		var b1: Vector2 = them[1]
		var want := r + radius(o as Node3D)
		if minf(a0.distance_to(b0), a1.distance_to(b1)) > want + a0.distance_to(a1) + b0.distance_to(b1):
			continue # (nowhere near)
		var best := INF
		var pa := a0
		var pb := b0
		for q: Array in [[a0, _seg_pt(a0, b0, b1)], [a1, _seg_pt(a1, b0, b1)], [_seg_pt(b0, a0, a1), b0], [_seg_pt(b1, a0, a1), b1]]:
			var dd := (q[0] as Vector2).distance_to(q[1])
			if dd < best:
				best = dd
				pa = q[0]
				pb = q[1]
		if best >= want:
			continue
		var nrm := pa - pb
		if nrm.length() < 1e-4: # (crossing: apart from each other's middle)
			nrm = (a0 + a1) * 0.5 - (b0 + b1) * 0.5
			if nrm.length() < 1e-4:
				nrm = Vector2(1.0, 0.0).rotated(float(n.get_instance_id() % 628) * 0.01)
		_push(n, nrm.normalized() * (want - best) * 0.5)
