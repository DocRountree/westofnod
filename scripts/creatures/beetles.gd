class_name Beetles
extends AntColony
## Beetles, the make they share (the species: JuneBeetles, LadyBeetles):
## drawn at twice life size as the ants and the wasp are; made and moved as
## the ants are (AntColony: one mesh, every beetle an instance, posed by the
## same shader, ant.gdshader), slower and heavier, their antennae sweeping
## less: walking (a tripod gait), and eating (feed: at a leaf, the head
## down to it, the mouthparts working, the front legs on it; now and then
## round to another place at it), and flying (fly: the elytra opening,
## raised and spread, the hind wings unfolding from under them and beating,
## it lifts off, nose up, and wanders through the air round a place; told
## to walk or feed again, it comes down, lands, and folds them away).
## wander(i, centre, radius), feed(i, leaf), fly(i, centre, radius, height).
## mate(i, j): one of them a male (males[k]: every other one), the other a
## female (no difference between them to see): he comes up behind her,
## climbs onto her back, his legs on her shell, and stays there joined,
## rocking now and then; then slides off behind her, and both go back to
## what they were doing. Only the females lay.
##
## At rest its wing cases (elytra) are one unbroken shell: the two halves
## of one dome, split down the middle where they meet, edge to edge (the
## same points, the same normals there); only flying do they part.
##
## The species says its shape (shape: the underside, the pronotum, the
## wing cases, the head, the eyes, the antennae's kind, the legs, in mm,
## the thorax's middle at the origin, -z forward) and adds its markings
## (_marks: patches lying on the shell, the shader's mark colours).

## The species' shape (mm): {under, pronotum, elytra (the shell over both:
## one dome, centred on the middle line), scutellum: [centre, size] each; neck, head, clypeus, eye ([offset from
## the neck, size]); antenna: "lamellate" (a June bug's: a fan of plates)
## or "clubbed" (a lady beetle's: short, beaded, thickening) or
## "filiform" (a firefly's: long, slender, even), antenna_at
## (its socket, off the neck), antenna_len; legs: [{hip, f, t, s, home}] x3
## (the right side's: hip (mm), femur, tibia, tarsus lengths, home: the
## foot at rest, x z); leg_r: the legs' thickness (mm, the femur's);
## spines: spurs on the tibiae; hind_wing: the hind wings' length (a
## share of the elytra's)}
var shape := {}
var fly_speed := 0.5 ## m/s
var fly_pitch := 0.5 ## rad, nose up, flying

# flying (each beetle): how high over the ground (m), how far its elytra
# are open (0..1), its velocity, where it's making for in the air (x, its
# height over the ground, z) or, coming down, the spot it lands on
var alt := PackedFloat32Array()
var fly_k := PackedFloat32Array()
var vel := PackedVector3Array()
var air_at := PackedVector3Array()
var fly_h := PackedFloat32Array()
var landing := PackedByteArray()
## the pronotum's part: 16 the shell's colour, 17 or 18 a mark's
var pronotum_part := 16
var males := PackedByteArray() ## (1: a male; every other one)
var mate_secs := 25.0 ## s joined
# mating (each): its partner (-1 none), the stage (1 going to her, 2 climbing
# on, 3 joined, 4 climbing off; a female's 9: still, his), how long at it,
# the task it was at before
var partner := PackedInt32Array()
var mate_stage := PackedByteArray()
var mate_t := PackedFloat32Array()
var mate_for := PackedFloat32Array()
var _was := PackedInt32Array()
const MATING := 5


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
	var ec: Vector3 = S.elytra[0]
	var es: Vector3 = S.elytra[1]
	var halves := [_half(SA, -1.0), _half(SA, 1.0)]
	var e_piv := []
	var w_piv := []
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		# one dome, its two halves (left 21, right 22)
		_add(st, halves[s], Transform3D(Basis.from_scale(es), ec), 21 + s, 0, false)
		# its hinge: at the base, by the middle, near the top
		e_piv.append(Vector3(0.06 * es.x * side, ec.y + 0.2 * es.y, ec.z - 0.44 * es.z))
		# the hind wing, folded under it: a long thin membrane out from its
		# hinge (the shader unfolds it, flying)
		var wp := Vector3(0.12 * es.x * side, ec.y + 0.05 * es.y, ec.z - 0.36 * es.z)
		w_piv.append(wp)
		var wl: float = es.z * float(S.get("hind_wing", 1.25))
		var wb := Basis(Vector3.UP, -0.22 * side)
		ball.call(wp + wb * Vector3(wl * 0.5 * side, 0.0, 0.0), Vector3(wl, 0.03 * es.z, wl * 0.3), 25 + s, wb)
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
		elif S.antenna == "filiform":
			# a firefly's: long, slender, of eleven even segments, a little
			# flattened, curving out and forward
			var fp := 0.15
			for k in 11:
				var q := p + _dir(0.5 + 0.03 * k, fp, side) * length * 0.075
				var r := length * 0.028 * (1.0 - 0.025 * k)
				ball.call((p + q) * 0.5, Vector3(r * 1.25, r, length * 0.082), 6 + s, Basis.looking_at(q - p, Vector3.UP))
				p = q
				fp -= 0.045
		else:
			# beads, thickening to a club
			var fp := 0.2
			for k in 7:
				var q := p + _dir(0.4, fp, side) * length * 0.1
				var r := length * (0.05 + (0.06 if k >= 4 else 0.0) + 0.006 * k)
				ball.call((p + q) * 0.5, Vector3(r, r, length * 0.11), 6 + s, Basis.looking_at(q - p, Vector3.UP))
				p = q
				fp -= 0.08
	_mark_st = st
	_marks(ball)
	_mark_st = null
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
		"elytra_pivots": PackedVector3Array(e_piv.map(func(v): return v * MM)),
		"wing_pivots": PackedVector3Array(w_piv.map(func(v): return v * MM)),
	}
	st.generate_tangents()
	return [st.commit(), pivots]


## The species' markings, laid on its shell: ball.call(at, size, part,
## basis) (parts 17 and 18 on the body, 19 and 20 on the head: the
## shader's mark_a and mark_b; 23 and 24 on the left and the right elytron,
## mark_a, opening with it).
func _marks(_ball: Callable) -> void:
	pass


## A unit sphere's half (side: +1 the right, x >= 0; -1 the left): its
## other half pressed flat onto the middle plane (its inner wall, seen only
## when the halves part), the outer half untouched, so the two halves
## together are the whole sphere, unbroken.
static func _half(arrays: Array, side: float) -> Array:
	var out := arrays.duplicate()
	var vs: PackedVector3Array = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).duplicate()
	var ns: PackedVector3Array = (arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate()
	for k in vs.size():
		if vs[k].x * side < -1e-5:
			vs[k] = Vector3(0.0, vs[k].y, vs[k].z)
			ns[k] = Vector3(-side, 0.0, 0.0)
	out[Mesh.ARRAY_VERTEX] = vs
	out[Mesh.ARRAY_NORMAL] = ns
	return out


var _mark_st: SurfaceTool # (building: the mesh the marks go into)


## The elytron's mark part on a side (23 left, 24 right).
static func _el_mark(side: float) -> int:
	return 24 if side > 0.0 else 23


# --- flying ------------------------------------------------------------------

func _resize(n: int) -> void:
	var was := males.size()
	super(n)
	alt.resize(n)
	fly_k.resize(n)
	vel.resize(n)
	air_at.resize(n)
	fly_h.resize(n)
	landing.resize(n)
	males.resize(n)
	partner.resize(n)
	mate_stage.resize(n)
	mate_t.resize(n)
	mate_for.resize(n)
	_was.resize(n)
	for i in range(was, n):
		males[i] = i % 2
		partner[i] = -1


## (Steering, pilot.gd: a beetle's behaviours, flying too.)
func _p_behaviours(i: int) -> PackedStringArray:
	return PackedStringArray(["feed", "lay", "fly", "mate"]) if lays and males[i] == 0 else PackedStringArray(["feed", "fly", "mate"])


## Beetle i laying (a female: the males don't).
func lay(i: int, at: Vector3) -> void:
	if males[i] == 0:
		super(i, at)


## Beetles i and j mating (one male, one female, neither mating, both on
## the ground): false if they can't.
func mate(i: int, j: int, secs := -1.0) -> bool:
	if i == j or i < 0 or j < 0 or i >= pos.size() or j >= pos.size() or males[i] == males[j]:
		return false
	if partner[i] >= 0 or partner[j] >= 0 or alt[i] > 0.0 or alt[j] > 0.0:
		return false
	var him := i if males[i] == 1 else j
	var her := j if him == i else i
	for k: int in [him, her]:
		_was[k] = task[k] if task[k] != MATING else 0
		task[k] = MATING
		mate_t[k] = 0.0
		mate_for[k] = secs if secs > 0.0 else mate_secs
	partner[him] = her
	partner[her] = him
	mate_stage[him] = 1
	mate_stage[her] = 9
	return true


func _fly_array() -> PackedFloat32Array:
	return fly_k


func _partner_array() -> PackedInt32Array:
	return partner


func _together(i: int, j: int) -> bool:
	return partner[i] == j


func is_mating(i: int) -> bool:
	return partner[i] >= 0


func _end_mate(i: int) -> void:
	var j := partner[i]
	for k: int in ([i, j] if j >= 0 else [i]):
		partner[k] = -1
		mate_stage[k] = 0
		task[k] = _was[k] if _was[k] != MATING else 0
		target[k] = pos[k]
		wait[k] = rng.randf_range(0.5, 2.0)


func _think(i: int, dt: float) -> void:
	if task[i] != MATING:
		super(i, dt)
		return
	feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
	var j := partner[i]
	if j < 0:
		task[i] = 0
		return
	mate_t[i] += dt
	if mate_stage[i] == 9: # (her: still)
		target[i] = pos[i]
		return
	# him: to just behind her
	var back := Vector3(sin(yaw[j]), 0.0, cos(yaw[j]))
	var to := pos[j] + back * (_length() * 0.75) * MM
	target[i] = to
	if Vector2(to.x - pos[i].x, to.z - pos[i].z).length() < 0.003:
		mate_stage[i] = 2
		mate_t[i] = 0.0


## (How long a beetle is, mm: its shell's.)
func _length() -> float:
	return float((shape.elytra[1] as Vector3).z) + float((shape.pronotum[1] as Vector3).z) * 0.6


## Him on her back (climbing on, joined, climbing off): placed here, not
## walking.
func _ride(i: int, dt: float) -> void:
	var j := partner[i]
	mate_t[i] += dt
	var st := mate_stage[i]
	if st == 2 and mate_t[i] > 0.7:
		mate_stage[i] = 3
		mate_t[i] = 0.0
	elif st == 3 and mate_t[i] > mate_for[i]:
		mate_stage[i] = 4
		mate_t[i] = 0.0
	elif st == 4 and mate_t[i] > 0.7:
		var back := Vector3(sin(yaw[j]), 0.0, cos(yaw[j]))
		var off := pos[j] + back * _length() * 0.8 * MM
		pos[i] = Vector3(off.x, height.call(off.x, off.z) if height.is_valid() else pos[j].y, off.z)
		_end_mate(i)
		_place(i, pos[i], 0.0)
		return
	var k := 1.0
	if mate_stage[i] == 2:
		k = clampf(mate_t[i] / 0.7, 0.0, 1.0)
	elif mate_stage[i] == 4:
		k = 1.0 - clampf(mate_t[i] / 0.7, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var ec: Vector3 = shape.elytra[0]
	var es: Vector3 = shape.elytra[1]
	var fwd := Vector3(-sin(yaw[j]), 0.0, -cos(yaw[j]))
	var behind := pos[j] - fwd * _length() * 0.75 * MM
	var on := pos[j] - fwd * (es.z * 0.12) * MM # (his middle a little behind hers)
	var p := behind.lerp(on, k)
	var top := (ec.y + es.y * 0.5 + body_h * 0.55) * MM # (over her shell)
	var rock := sin(_t * 4.0 + seed[i] * 9.0) * maxf(sin(_t * 0.7 + seed[i] * 3.0), 0.0) if mate_stage[i] == 3 else 0.0
	yaw[i] = lerp_angle(yaw[i], yaw[j], 1.0 - exp(-8.0 * dt))
	var b := Basis(Vector3.UP, yaw[i]) * Basis(Vector3.RIGHT, (0.12 + 0.05 * rock) * k)
	multimesh.set_instance_transform(i, Transform3D(b, p + Vector3.UP * (body_h * MM * (1.0 - k) + (top + sin(PI * k) * 1.5 * MM) * k)))
	multimesh.set_instance_custom_data(i, Color(0.25 * (1.0 - k) if mate_stage[i] != 3 else 0.0, 0.0, seed[i], 0.0))
	pos[i] = Vector3(p.x, pos[j].y, p.z)
	speed[i] = 0.0


func _p_act(i: int, name: String, args: Dictionary) -> bool:
	if name == "fly":
		fly(i, args.get("centre", pos[i]), float(args.get("radius", 0.3)), float(args.get("height", 0.25)))
		return true
	return super(i, name, args)


func _p_act_secs(i: int, name: String) -> float:
	return 6.0 if name == "fly" else super(i, name)


## Beetle i up and flying round c (within r), about h (m) over the ground.
func fly(i: int, c: Vector3, r: float, h := 0.25) -> void:
	if partner[i] >= 0:
		_end_mate(i)
	task[i] = 2
	centre[i] = c
	radius[i] = r
	fly_h[i] = h
	wait[i] = 0.0
	air_at[i] = Vector3(pos[i].x, h, pos[i].z)


func _fly_of(i: int) -> float:
	return fly_k[i]


## Flying, or coming down: moved here, not walking (true); on the ground,
## its elytra closing if they're open (false: it walks).
func _air(i: int, dt: float) -> bool:
	if task[i] == MATING and mate_stage[i] in [2, 3, 4] and partner[i] >= 0:
		_ride(i, dt)
		return true
	var p := pos[i]
	if task[i] != 2 and alt[i] <= 0.0:
		fly_k[i] = move_toward(fly_k[i], 0.0, dt * 1.6) # (folding the wings away, closing the shell)
		landing[i] = 0
		return false
	var flying := task[i] == 2
	if flying:
		landing[i] = 0
		fly_k[i] = move_toward(fly_k[i], 1.0, dt * 2.0)
		speed[i] = move_toward(speed[i], 0.0, dt * 0.6)
		if alt[i] <= 0.0 and fly_k[i] < 0.97: # (opening up first, standing)
			_place(i, p, 0.0)
			return true
	var here := Vector3(p.x, alt[i], p.z)
	if flying:
		wait[i] -= dt
		if wait[i] <= 0.0 or here.distance_to(air_at[i]) < 0.05:
			var a := rng.randf() * TAU
			var c := centre[i] + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * radius[i]
			air_at[i] = Vector3(c.x, fly_h[i] * rng.randf_range(0.6, 1.4), c.z)
			wait[i] = rng.randf_range(1.5, 4.0)
	else:
		fly_k[i] = 1.0
		if landing[i] == 0:
			# the spot to come down on: its place at the food, or somewhere
			# in its round
			landing[i] = 1
			var spot: Vector3
			if task[i] == 1:
				spot = food[i] + Vector3(cos(slot[i]), 0.0, sin(slot[i])) * reach * MM
			else:
				var a := rng.randf() * TAU
				spot = centre[i] + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * radius[i]
			air_at[i] = Vector3(spot.x, 0.0, spot.z)
	var to := air_at[i] - here
	var d := to.length()
	var want := to / maxf(d, 1e-5) * minf(fly_speed, d * 2.5)
	vel[i] = vel[i].lerp(want, 1.0 - exp(-3.0 * dt))
	here += vel[i] * dt
	if not flying and (here.y <= 0.0 or d < 0.004):
		# down: on its feet, the wings to fold
		here.y = 0.0
		vel[i] = Vector3.ZERO
		target[i] = Vector3(here.x, 0.0, here.z)
		wait[i] = rng.randf_range(0.5, 1.5)
	alt[i] = maxf(here.y, 0.0)
	var hv := Vector2(vel[i].x, vel[i].z)
	if hv.length() > 0.02:
		var turn := wrapf(atan2(-hv.x, -hv.y) - yaw[i], -PI, PI)
		yaw[i] += clampf(turn, -5.0 * dt, 5.0 * dt)
	p = Vector3(here.x, height.call(here.x, here.z) if height.is_valid() else 0.0, here.z)
	pos[i] = p
	feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
	_place(i, p, alt[i])
	return true


## Beetle i drawn at p (the ground under it), a (m) over it: nose up as it
## flies, bobbing with its beat.
func _place(i: int, p: Vector3, a: float) -> void:
	var air := clampf(a / 0.02, 0.0, 1.0)
	var b := Basis(Vector3.UP, yaw[i]) * Basis(Vector3.RIGHT, fly_pitch * air)
	var bob := sin(_t * 9.0 + seed[i] * 20.0) * 0.002 * air
	multimesh.set_instance_transform(i, Transform3D(b, p + Vector3.UP * (body_h * MM + a + bob)))
	multimesh.set_instance_custom_data(i, Color(0.0, feed_k[i], seed[i], fly_k[i]))


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


## A round mark (radii r, mm: across, along) on an ellipsoid's top at (x,
## z): a patch of the shell's own surface there (out to its rim, if it's
## past it, round onto its side), lying on it a hair proud: no flat lens
## standing off the curve. turn: its long way turned (rad, about its normal).
func _spot(_ball: Callable, c: Vector3, size: Vector3, x: float, z: float, r: Vector2, part: int, turn := 0.0) -> void:
	var a := size * 0.5
	var u := Vector2((x - c.x) / a.x, (z - c.z) / a.z)
	if u.length() > 0.97:
		u = u.normalized() * 0.97
	var d := Vector3(u.x, sqrt(maxf(1.0 - u.length_squared(), 0.0)), u.y)
	_shell_patch(c, a, d, r, part, turn)


## A patch of an ellipsoid's surface (centre c, semi-axes a, mm) about the
## point d (a unit direction, in its unit-sphere space), radii r across
## and along, turned by turn about its normal; a hair proud (mm), added to
## the mesh being built as part `part`.
func _shell_patch(c: Vector3, a: Vector3, d: Vector3, r: Vector2, part: int, turn := 0.0, proud := 0.03) -> void:
	if _mark_st == null:
		return
	d = d.normalized()
	var p0 := c + a * d
	var n0 := (d / a).normalized()
	var t := Vector3.BACK.cross(n0)
	if t.length_squared() < 1e-6:
		t = Vector3.RIGHT
	t = t.normalized().rotated(n0, turn)
	var b := t.cross(n0).normalized()
	const RINGS := 4
	const SECTORS := 16
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var on := func(q: Vector3) -> Array: # (q onto the shell, and out a hair)
		var e := ((q - c) / a).normalized()
		var nn := (e / a).normalized()
		return [c + a * e + nn * proud, nn]
	var mid: Array = on.call(p0)
	vs.append(mid[0])
	ns.append(mid[1])
	uvs.append(Vector2.ZERO)
	for k in range(1, RINGS + 1):
		var f := float(k) / RINGS
		for j in SECTORS:
			var ang := TAU * j / SECTORS
			var v: Array = on.call(p0 + (t * cos(ang) * r.x + b * sin(ang) * r.y) * f)
			vs.append(v[0])
			ns.append(v[1])
			uvs.append(Vector2.ZERO)
	for j in SECTORS: # (the middle's fan)
		idx.append_array([0, 1 + j, 1 + (j + 1) % SECTORS])
	for k in range(1, RINGS):
		var r0 := 1 + (k - 1) * SECTORS
		var r1 := 1 + k * SECTORS
		for j in SECTORS:
			var j1 := (j + 1) % SECTORS
			idx.append_array([r0 + j, r1 + j, r0 + j1, r1 + j, r1 + j1, r0 + j1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vs
	arrays[Mesh.ARRAY_NORMAL] = ns
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	_add(_mark_st, arrays, Transform3D(), part, 0, false)


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
