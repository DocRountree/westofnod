extends RefCounted
## Personal space for every creature with a body of its own (not those drawn
## and moved by a shader: the ant colonies, the beetles, the fish schools):
## not collision, but each a capsule on the ground, from its rump to its
## head, as wide as its body (or, a long body, a few of them along it:
## _space_spines); two that overlap, whatever their kinds, are eased apart,
## each its half (or the other all of it, where one can't be shifted:
## _space_fixed). Off for one meant to touch another (mating, nursing,
## suckling, playing, sparring, carrying, nesting; the young; one in the
## air; the dead); and between a hunter or an eater and its own prey, meal
## or food (_prey, _meal, _food) only: a wolf after a hare still goes round
## the turtle in its way.
##
## A creature joins (join, in its _enter_tree) and leaves (leave), and calls
## keep_apart(self) each frame once it's moved. Its capsule: its own
## _space_spine() -> [rump, head] (world xz) and _space_r() (m) if it has
## them, else from its _pos and _yaw (or its basis) and its body's drawn
## size (its meshes' bounds, worked out once); or several, _space_spines()
## -> [[a, b], ...], each _space_r() round (a snake's along its whole
## length), _space_fixed(i) true for one it can't be moved by (a snake's
## body: only its head goes where it's pushed); pushed by _space_push(xz)
## if it has one, else its _pos moved. Whether it may touch: its own
## _touch_ok() if it has one, else its young / dead / in the air / mating
## role / mode (TOUCHING).

static var all: Array = []
const MAX_PUSH := 0.04 ## m a frame, at most: eased apart, never thrown
const TOUCHING := ["nurse", "suckle", "play", "spar", "follow", "newborn", "birth", "carry", "piloted",
		"mate", "courted", "amplexus", "lay", "nest", "tadpole", "mount", "mounted", "groom_other"]
## (hunting, eating, feeding, striking: not here, but only between the two:
## its _prey, _meal or _food, and it: _target_of)


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
## own space (legs and antennae make it a little long). Worked out again
## every couple of seconds: it grows, and its parts are scaled to its size
## only once it's placed (measured before, a frog read as 54 m long).
const REMEASURE := 120 ## frames
const MAX_LEN := 6.0 ## m: anything longer is a measure gone wrong (none so long)
static func _dims(n: Node3D) -> Vector2:
	var now := Engine.get_process_frames()
	if n.has_meta("space_dims") and now - int(n.get_meta("space_at", 0)) < REMEASURE and n.get_meta("space_dims") != Vector2.ZERO:
		return n.get_meta("space_dims")
	var box := _aabb(n, Transform3D())
	var s := n.global_basis.get_scale() if n.is_inside_tree() else Vector3.ONE
	var d := Vector2(box.size.z * absf(s.z) * 0.8, box.size.x * absf(s.x) * 0.3)
	if d.x > MAX_LEN or d.y > MAX_LEN * 0.25:
		d = Vector2.ZERO # (not yet scaled to its size: no capsule till it is)
	n.set_meta("space_dims", d)
	n.set_meta("space_at", now)
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


## Whether a is after b (its prey, its meal, its food; a deer mouse's seed,
## or grub), or b after a.
static func _target_of(a: Object, b: Object) -> bool:
	for f in ["_prey", "_meal", "_food", "_seed"]:
		if a.get(f) == b or b.get(f) == a:
			return true
	return false


## Its capsules' spines: [[a, b], ...] (most, one).
static func spines(n: Node3D) -> Array:
	if n.has_method("_space_spines"):
		return n.call("_space_spines")
	return [spine(n)]


static func _fixed(n: Node3D, i: int) -> bool:
	return n.has_method("_space_fixed") and bool(n.call("_space_fixed", i))


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


## A spot near at (map) for n to come down on (a frog's leap) clear of the
## others it's kept off: at itself if it's clear, else moved out of their
## capsules (n taken as round, its own radius). (A leap isn't eased off them
## on the way: it would land inside one and wait there to be pushed off,
## to land in it again with its next.)
static func clear_spot(n: Node3D, at: Vector3) -> Vector3:
	var r := radius(n)
	if r <= 0.0:
		return at
	var p := Vector2(at.x, at.z)
	for pass_ in 3:
		var moved := false
		for o: Node in all:
			if o == n or not is_instance_valid(o) or not o.is_inside_tree() or touching(o) or _target_of(n, o):
				continue
			var want := r + radius(o as Node3D) + 0.005
			for sp: Array in spines(o as Node3D):
				var q := _seg_pt(p, sp[0], sp[1])
				var d := p.distance_to(q)
				if d < want:
					var away := (p - q) if d > 1e-4 else Vector2(1.0, 0.0).rotated(float(n.get_instance_id() % 628) * 0.01)
					p = q + away.normalized() * want
					moved = true
		if not moved:
			break
	return Vector3(p.x, at.y, p.y)


## n eased off every other it overlaps (its half of the overlap; all of it
## where the other's part can't be moved), by its part that overlaps each
## most (none for a part of it that can't be moved).
static func keep_apart(n: Node3D) -> void:
	if touching(n):
		return
	var mine := spines(n)
	var r := radius(n)
	if r <= 0.0 or mine.is_empty():
		return
	var lo := Vector2.INF
	var hi := -Vector2.INF
	for sp: Array in mine:
		lo = lo.min(sp[0]).min(sp[1])
		hi = hi.max(sp[0]).max(sp[1])
	var push := Vector2.ZERO # (each other's, by the part of each that overlaps most)
	for o: Node in all:
		if o == n or not is_instance_valid(o) or not o.is_inside_tree() or touching(o) or _target_of(n, o):
			continue
		var ro := radius(o as Node3D)
		if ro <= 0.0:
			continue
		var dy := _y(n) - _y(o as Node3D)
		if absf(dy) > (r + ro) * 2.0 + 0.05:
			continue # (one above the other: in a web, on a stem, up a log)
		var want := r + ro
		var theirs := spines(o as Node3D)
		# (nowhere near: their boxes apart by more than both are wide)
		var olo := Vector2.INF
		var ohi := -Vector2.INF
		for sp: Array in theirs:
			olo = olo.min(sp[0]).min(sp[1])
			ohi = ohi.max(sp[0]).max(sp[1])
		if olo.x > hi.x + want or olo.y > hi.y + want or lo.x > ohi.x + want or lo.y > ohi.y + want:
			continue
		var worst := Vector2.ZERO
		var worst_seg := -1
		for i in mine.size():
			var a0: Vector2 = mine[i][0]
			var a1: Vector2 = mine[i][1]
			for j in theirs.size():
				var b0: Vector2 = theirs[j][0]
				var b1: Vector2 = theirs[j][1]
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
				# (its half; all of it if the other's part won't move)
				var share := 1.0 if _fixed(o as Node3D, j) else 0.5
				var v := nrm.normalized() * minf((want - best) * share, MAX_PUSH)
				if v.length() > worst.length():
					worst = v
					worst_seg = i
		if worst_seg >= 0 and not _fixed(n, worst_seg):
			push += worst
	if push != Vector2.ZERO:
		_push(n, push)
