class_name Beetles
extends AntColony
## Beetles, the make they share (the species: JuneBeetles, LadyBeetles):
## drawn at twice life size as the ants and the wasp are; made and moved as
## the ants are (AntColony: one mesh, every beetle an instance, posed by the
## same shader, ant.gdshader), slower and heavier, their antennae sweeping
## less: walking (a tripod gait), and eating (feed: at a leaf, the head
## down to it, the mouthparts working, the front legs on it; now and then
## round to another place at it). wander(i, centre, radius), feed(i, leaf).
##
## The species says its shape (shape: the underside, the pronotum, the
## wing cases, the head, the eyes, the antennae's kind, the legs, in mm,
## the thorax's middle at the origin, -z forward) and adds its markings
## (_marks: patches lying on the shell, the shader's mark colours).

## The species' shape (mm): {under, pronotum, elytron (the right one),
## scutellum: [centre, size] each; neck, head, clypeus, eye ([offset from
## the neck, size]); antenna: "lamellate" (a June bug's: a fan of plates)
## or "clubbed" (a lady beetle's: short, beaded, thickening), antenna_at
## (its socket, off the neck), antenna_len; legs: [{hip, f, t, s, home}] x3
## (the right side's: hip (mm), femur, tibia, tarsus lengths, home: the
## foot at rest, x z); leg_r: the legs' thickness (mm, the femur's);
## spines: spurs on the tibiae}
var shape := {}
## the pronotum's part: 16 the shell's colour, 17 or 18 a mark's
var pronotum_part := 16


func _build_mesh() -> Array:
	var S: Dictionary = shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 20
	sphere.rings = 12
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var SA := sphere.get_mesh_arrays()
	var CA := cyl.get_mesh_arrays()
	var ball := func(at: Vector3, size: Vector3, part: int, b := Basis(), seg := 0) -> void:
		_add(st, SA, Transform3D(b * Basis.from_scale(size), at), part, seg, false)
	var stick := func(a: Vector3, b: Vector3, r: float, part: int, seg := 0) -> void:
		_add(st, CA, _seg(a, b, r), part, seg, false)
	# the underside, and over it the shell: the pronotum, and the two wing
	# cases meeting down its middle, domed; the scutellum between them
	ball.call(S.under[0], S.under[1], 0)
	ball.call(S.pronotum[0], S.pronotum[1], pronotum_part)
	var el: Vector3 = S.elytron[0]
	for side: float in [-1.0, 1.0]:
		ball.call(Vector3(el.x * side, el.y, el.z), S.elytron[1], 16)
	ball.call(S.scutellum[0], S.scutellum[1], pronotum_part)
	# the head: under the pronotum's front, the clypeus before it, the
	# eyes on its sides
	var h: Vector3 = S.neck
	ball.call(h + (S.head[0] as Vector3), S.head[1], 1)
	ball.call(h + (S.clypeus[0] as Vector3), S.clypeus[1], 1)
	var sockets := []
	var elbows := []
	var mands := []
	var head_size: Vector3 = S.head[1]
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		var eo: Vector3 = S.eye[0]
		ball.call(h + Vector3(eo.x * side, eo.y, eo.z), S.eye[1], 15)
		# the mandibles: small, under the clypeus
		var mp := h + Vector3(0.18 * head_size.x * side, -0.3 * head_size.y, (S.clypeus[0] as Vector3).z - 0.2 * head_size.z)
		mands.append(mp)
		var mb := Basis(Vector3.UP, 0.5 * side)
		ball.call(mp + mb * Vector3(0.0, 0.0, -0.12 * head_size.z), Vector3(0.14, 0.1, 0.3) * head_size.x, 2 + s, mb)
		# an antenna
		var ao: Vector3 = S.antenna_at
		var base := h + Vector3(ao.x * side, ao.y, ao.z)
		var length: float = S.antenna_len
		var elbow := base + _dir(0.7, 0.15, side) * length * 0.3
		sockets.append(base)
		elbows.append(elbow)
		stick.call(base, elbow, length * 0.045, 4 + s)
		var p: Vector3 = elbow
		if S.antenna == "lamellate":
			# a short stalk of fine beads, then the club: three long flat
			# plates, fanned a little
			for k in 4:
				var q := p + _dir(0.55, 0.05, side) * length * 0.07
				stick.call(p, q, length * 0.035, 6 + s)
				p = q
			var fwd := _dir(0.45, 0.1, side)
			for k in 3:
				var b := Basis.looking_at(_dir(0.45 + (k - 1) * 0.22, 0.1 + (k - 1) * 0.12, side), Vector3.UP)
				ball.call(p + b * Vector3(0.0, 0.0, -length * 0.17), Vector3(length * 0.11, length * 0.03, length * 0.36), 6 + s, b)
			p += fwd * length * 0.3
		else:
			# beads, thickening to a club
			var fp := 0.2
			for k in 7:
				var q := p + _dir(0.4, fp, side) * length * 0.1
				var r := length * (0.05 + (0.06 if k >= 4 else 0.0) + 0.006 * k)
				ball.call((p + q) * 0.5, Vector3(r, r, length * 0.11), 6 + s, Basis.looking_at(q - p, Vector3.UP))
				p = q
				fp -= 0.08
	_marks(ball)
	# the legs, standing: as the ant's
	var hips := []
	var knees := []
	var dirs := []
	var up := Vector3.UP
	var lr: float = S.leg_r
	for i in 6:
		var pair := i / 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var L: Dictionary = S.legs[pair]
		var hip0 := Vector3(L.hip.x * side, L.hip.y, L.hip.z)
		var hip := hip0 + Vector3(lr * side, -lr * 0.7, 0.0)
		var home: Vector2 = L.home
		var foot := Vector3(home.x * side, -body_h + lr * 0.35, home.y)
		var out := Vector3(foot.x - hip.x, 0.0, foot.z - hip.z).normalized()
		var ankle := foot + (-out * 0.9 + up * 0.42) * float(L.s)
		var aout := Vector3(ankle.x - hip.x, 0.0, ankle.z - hip.z).normalized()
		var knee := _knee(hip, ankle, L.f, L.t, up + aout * 0.6)
		stick.call(hip0, hip, lr * 1.25, 8 + i, 0)
		ball.call(hip0, Vector3.ONE * lr * 2.4, 8 + i)
		stick.call(hip, knee, lr, 8 + i, 1)
		ball.call(knee, Vector3.ONE * lr * 1.6, 8 + i, Basis(), 1)
		stick.call(knee, ankle, lr * 0.75, 8 + i, 2)
		if S.get("spines", false): # (a June bug's tibiae spurred: along them, and two at the end)
			var td := (ankle - knee)
			for k in 3:
				var sp := knee + td * (0.35 + 0.25 * k)
				stick.call(sp, sp + (out + Vector3.DOWN * 0.4).normalized() * lr * 1.1, lr * 0.16, 8 + i, 2)
			for k in 2:
				stick.call(ankle, ankle + (td.normalized() + Vector3(0.3 * side * (k * 2 - 1), -0.2, 0.0)).normalized() * lr * 2.0, lr * 0.2, 8 + i, 2)
		# the tarsus: in segments, and its claws
		var ts := 4
		var tp := ankle
		for k in ts:
			var tq := ankle.lerp(foot, float(k + 1) / ts) + Vector3.UP * sin(PI * (k + 1) / ts) * lr * 0.25
			ball.call((tp + tq) * 0.5, Vector3(lr * 0.75, lr * 0.6, tp.distance_to(tq) * 1.1), 8 + i, Basis.looking_at((tq - tp).normalized() + Vector3(0.0, 1e-4, 0.0), Vector3.UP), 3)
			_add(st, CA, _seg(tp, tq, lr * 0.32), 8 + i, 3, false)
			tp = tq
		for k in 2:
			_add(st, CA, _seg(foot, foot + (out + Vector3(0.25 * (k * 2 - 1), -0.5, 0.0)).normalized() * lr * 1.3, lr * 0.14), 8 + i, 3, false)
		hips.append(hip0 * MM)
		knees.append(knee * MM)
		dirs.append(out)
	var pivots := {
		"hips": PackedVector3Array(hips), "knees": PackedVector3Array(knees), "leg_dirs": PackedVector3Array(dirs),
		"sockets": PackedVector3Array(sockets.map(func(v): return v * MM)), "elbows": PackedVector3Array(elbows.map(func(v): return v * MM)),
		"mand_pivots": PackedVector3Array(mands.map(func(v): return v * MM)), "neck": h * MM,
		"petiole": Vector3(0.0, 0.0, 99.0), # (no gaster to pump: its abdomen's under the wing cases)
	}
	st.generate_tangents()
	return [st.commit(), pivots]


## The species' markings, laid on its shell: ball.call(at, size, part,
## basis) (parts 17 and 18 on the body, 19 and 20 on the head: the
## shader's mark_a and mark_b).
func _marks(_ball: Callable) -> void:
	pass


## A patch lying on an ellipsoid's top (centre c, size: its diameters, mm)
## over (x, z): [the point on it, its basis there (y its normal)].
static func _on_shell(c: Vector3, size: Vector3, x: float, z: float) -> Array:
	var a := size * 0.5
	var dx := (x - c.x) / a.x
	var dz := (z - c.z) / a.z
	var dy := sqrt(maxf(1.0 - dx * dx - dz * dz, 0.0))
	var p := Vector3(x, c.y + a.y * dy, z)
	var n := Vector3(dx / a.x, dy / a.y, dz / a.z).normalized()
	var t := Vector3.BACK.cross(n)
	if t.length_squared() < 1e-6:
		t = Vector3.RIGHT
	t = t.normalized()
	return [p, Basis(t, n, t.cross(n))]


## A round mark of radius r (mm) on an ellipsoid's top at (x, z): a flat
## lens just poking out of the shell there.
static func _spot(ball: Callable, c: Vector3, size: Vector3, x: float, z: float, r: Vector2, part: int, turn := 0.0) -> void:
	var on := _on_shell(c, size, x, z)
	var b: Basis = (on[1] as Basis) * Basis(Vector3.UP, turn)
	ball.call(on[0], Vector3(r.x * 2.0, 0.14, r.y * 2.0), part, b)


## A leaf, for them to eat at: a flat green oval about 8 cm (twice life
## size), its origin at its middle, lying on the ground.
static func leaf() -> Node3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 6
	mi.mesh = s
	mi.scale = Vector3(0.05, 0.002, 0.085)
	mi.position.y = 0.001
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.48, 0.16)
	m.roughness = 0.6
	mi.material_override = m
	var root := Node3D.new()
	root.add_child(mi)
	return root
