class_name Mollies
extends MultiMeshInstance3D
## A school of sailfin mollies (Poecilia latipinna), life size (a female
## about 7 cm long, tail fin and all): deep-bodied, laterally flattened,
## the head flat on top, the small mouth turned up at the front; olive
## above, silvery down the sides, pale beneath, a net of scales with rows of
## dark spots down the sides; big eyes, gold-silver irises; a rounded tail
## fin. The males: the great sail of a dorsal fin, spotted dark, its edge
## orange, half folded as they swim and raised to display; their scales
## iridescent, orange-brown dots, an orange throat; the anal fin a
## gonopodium (a rod). The females' dorsal small, their anal fin a fan.
##
## Made and moved as the ants are (AntColony): one mesh, every fish an
## instance of it, posed by its shader (shaders/render/molly.gdshader: the
## body's wave down to the tail, the turns, the pectorals sculling, the
## sail raised, grazing's pecks), so a school of hundreds is a draw call;
## here each is only moved along, once a frame. setup(n, centre, spread),
## the water its school keeps to: tank_min .. tank_max (its own space;
## bottom: a Callable (x, z) -> the bottom's y there, if it isn't flat).
## Each fish:
## - schooling: keeping a little apart from its neighbours, going their
##   way, staying with them; the school wandering about the water (or
##   swim_to(point)); scatter(from): away, fast, then together again
## - grazing (graze(i, at), or now and then of its own accord): down to the
##   bottom, nose down, pecking at it a few seconds; then back up
## - displaying (a male's: display(i), or now and then): beside a female,
##   matching her, his sail raised, quivering
## - steered, each on its own (member(i): every creature's calls, go,
##   go_to, face, stop, act (graze {at, seconds}, display {seconds}),
##   behaviours, is_busy, action_finished: pilot.gd)

const ColonyScript := preload("res://scripts/creatures/ant_colony.gd") # (its Member: the same handle every colony's members have)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.001 ## m per model mm (life size)
const NEAR := 0.1 ## m: the neighbours each keeps with
const APART := 0.028 ## m: and keeps this far from
# what each is doing
const SCHOOL := 0
const GRAZE := 1
const DISPLAY := 2
const PILOT := 3
const HOLD := 4
const TAKEN := 5 # (caught: out of the school)

var tank_min := Vector3(-0.5, 0.02, -0.5) ## the water (its own space): the bottom's corner
var tank_max := Vector3(0.5, 0.45, 0.5) ## and the surface's
var bottom: Callable ## (x, z) -> the bottom's y there (none: tank_min.y)
var cruise := 0.07 ## m/s, schooling
var top_speed := 0.35 ## m/s, scattering
var males_share := 0.4
var shader: Shader = preload("res://shaders/render/molly.gdshader")
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var seed := PackedFloat32Array()
var male := PackedByteArray()
var size := PackedFloat32Array() # (a share of a grown female: a male a little bigger)
var task := PackedInt32Array()
var task_t := PackedFloat32Array() # s left at it
var aim := PackedVector3Array() # (grazing: the spot; piloted: where it's sent)
var partner := PackedInt32Array() # (a male displaying: to her)
var pace := PackedFloat32Array()
var graze_k := PackedFloat32Array()
var display_k := PackedFloat32Array()
var heading := PackedVector3Array()
var turn := PackedFloat32Array()
var goal := Vector3.ZERO ## where the school's making for
var rng := RandomNumberGenerator.new()
var _goal_t := 0.0
var _scare := 0.0
var _scare_from := Vector3.ZERO
var _pilots := {}
var _members := {}
var _t := 0.0

static var _built: Array = [] # [mesh, pec pivots]


func setup(n: int, centre: Vector3, spread := 0.1) -> void:
	rng.randomize()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	if _built.is_empty():
		_built = build_mesh()
	multimesh.mesh = _built[0]
	multimesh.instance_count = n
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("pec_pivots", _built[1])
	m.set_shader_parameter("z_head", -28.5 * MM)
	m.set_shader_parameter("z_tail", 41.0 * MM)
	material_override = m
	# (each its own: they're values, not shared)
	pos.resize(n)
	vel.resize(n)
	aim.resize(n)
	heading.resize(n)
	seed.resize(n)
	size.resize(n)
	task_t.resize(n)
	pace.resize(n)
	graze_k.resize(n)
	display_k.resize(n)
	turn.resize(n)
	male.resize(n)
	task.resize(n)
	partner.resize(n)
	for i in n:
		pos[i] = centre + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.5), rng.randf_range(-1, 1)) * spread
		var a := rng.randf() * TAU
		heading[i] = Vector3(cos(a), 0.0, sin(a))
		vel[i] = heading[i] * cruise
		seed[i] = rng.randf()
		male[i] = 1 if rng.randf() < males_share else 0
		size[i] = rng.randf_range(0.8, 1.05) * (1.1 if male[i] == 1 else 1.0)
		task[i] = SCHOOL
		task_t[i] = rng.randf_range(5.0, 20.0)
		partner[i] = -1
		pace[i] = -1.0
	goal = centre
	custom_aabb = AABB(tank_min - Vector3.ONE * 0.1, tank_max - tank_min + Vector3.ONE * 0.2)


## The school to `point` (its own space), schooling there.
func swim_to(point: Vector3) -> void:
	goal = point
	_goal_t = 20.0


## Every fish away from `from`, fast, for a moment; then together again.
func scatter(from: Vector3) -> void:
	_scare = 1.5
	_scare_from = from


## Fish i out of the school (caught: a fishing spider's): a fish of its
## own in its place (its parent's space), still, the instance gone.
func take(i: int) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = "molly" # (a fish: it bleeds, eaten: Meal)
	mi.mesh = multimesh.mesh
	var m := (material_override as ShaderMaterial).duplicate() as ShaderMaterial
	mi.material_override = m
	var parent := get_parent() as Node3D
	parent.add_child(mi)
	mi.global_transform = global_transform * multimesh.get_instance_transform(i)
	task[i] = TAKEN
	multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 1e-4), pos[i]))
	pos[i] = tank_min - Vector3.ONE * 50.0 # (out of the others' way)
	return mi


## The fish nearest p (its parent's space; not taken), or -1.
func nearest(p: Vector3) -> int:
	var best := -1
	var bd := INF
	var lp := to_local(get_parent().to_global(p)) if is_inside_tree() else p
	for i in pos.size():
		if task[i] == TAKEN:
			continue
		var d := pos[i].distance_to(lp)
		if d < bd:
			bd = d
			best = i
	return best


## Fish i back with the school (whatever it was doing).
func rejoin(i: int) -> void:
	task[i] = SCHOOL
	partner[i] = -1
	task_t[i] = rng.randf_range(8.0, 25.0)


## Fish i down to the bottom at `at` (or under it), grazing there.
func graze(i: int, at := Vector3.INF) -> void:
	task[i] = GRAZE
	var p := at if at != Vector3.INF else pos[i] + Vector3(rng.randf_range(-0.05, 0.05), 0.0, rng.randf_range(-0.05, 0.05))
	aim[i] = Vector3(p.x, _floor(p.x, p.z) + 0.006, p.z)
	task_t[i] = rng.randf_range(4.0, 8.0)


## (A male) beside the nearest female, his sail raised.
func display(i: int) -> void:
	if male[i] == 0:
		return
	var best := -1
	var bd := INF
	for j in pos.size():
		if male[j] == 0 and pos[j].distance_to(pos[i]) < bd:
			bd = pos[j].distance_to(pos[i])
			best = j
	if best < 0:
		return
	task[i] = DISPLAY
	partner[i] = best
	task_t[i] = rng.randf_range(3.0, 6.0)


var _vs := PackedVector3Array() # (each one's velocity, smoothed: its heading and pitch follow this)


func _floor(x: float, z: float) -> float:
	return maxf(float(bottom.call(x, z)) if bottom.is_valid() else tank_min.y, tank_min.y)


func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	_t += dt
	_scare = maxf(_scare - dt, 0.0)
	for i in _pilots:
		(_pilots[i] as PilotScript).tick(dt)
	# the school's own wandering
	_goal_t -= dt
	if _goal_t <= 0.0:
		_goal_t = rng.randf_range(6.0, 14.0)
		var lo := tank_min + Vector3(0.08, 0.05, 0.08)
		var hi := tank_max - Vector3(0.08, 0.05, 0.08)
		goal = Vector3(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y), rng.randf_range(lo.z, hi.z))
	var n := pos.size()
	# who's near whom: a grid NEAR across
	var grid := {}
	for i in n:
		var k := Vector3i(floori(pos[i].x / NEAR), floori(pos[i].y / NEAR), floori(pos[i].z / NEAR))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(i)
	for i in n:
		if task[i] != TAKEN:
			_steer(i, dt, grid)
	for i in n:
		if task[i] != TAKEN:
			_place(i, dt)


## Fish i's steering: its neighbours (apart, along with them, with them),
## the school's goal, the water's walls, the bottom and the surface; its
## own doing (grazing, displaying, piloted).
func _steer(i: int, dt: float, grid: Dictionary) -> void:
	var p := pos[i]
	var v := vel[i]
	task_t[i] -= dt
	var sep := Vector3.ZERO
	var align := Vector3.ZERO
	var coh := Vector3.ZERO
	var m := 0
	var wsum := 0.0
	var c := Vector3i(floori(p.x / NEAR), floori(p.y / NEAR), floori(p.z / NEAR))
	for dz in range(-1, 2):
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for j: int in grid.get(c + Vector3i(dx, dy, dz), []):
					if j == i:
						continue
					var off := p - pos[j]
					var d := off.length()
					if d > NEAR or d < 1e-6:
						continue
					if d < APART * size[i]:
						sep += off / d * (APART * size[i] - d) / (APART * size[i])
					# (each counted less the further off: none suddenly in, or out)
					var w := (1.0 - d / NEAR) * (1.0 - d / NEAR)
					align += vel[j] * w
					coh += pos[j] * w
					wsum += w
					m += 1
	var acc := sep * 2.2
	if wsum > 1e-4:
		acc += (align / wsum - v) * 1.0 * minf(wsum, 1.0)
		acc += (coh / wsum - p) * 1.0 * minf(wsum, 1.0)
	var want := cruise * (0.8 + 0.4 * seed[i])
	var t := task[i]
	match t:
		SCHOOL:
			acc += (goal - p).normalized() * 0.04 if p.distance_to(goal) > 0.05 else Vector3.ZERO
			# (now and then: down to graze; a male to display)
			if task_t[i] <= 0.0:
				task_t[i] = rng.randf_range(8.0, 25.0)
				var r := rng.randf()
				if r < 0.35:
					graze(i)
				elif r < 0.55 and male[i] == 1:
					display(i)
		GRAZE:
			var to := aim[i] - p
			if to.length() > 0.012:
				acc = acc * 0.2 + (to.normalized() * cruise * 0.6 - v) * 2.5
				graze_k[i] = move_toward(graze_k[i], 0.0, dt * 2.0)
			else: # (there: hanging nose down over it, pecking)
				acc = (to * 4.0 - v) * 4.0
				want = 0.0
				graze_k[i] = move_toward(graze_k[i], 1.0, dt * 2.0)
			if task_t[i] <= 0.0:
				task[i] = SCHOOL
				task_t[i] = rng.randf_range(8.0, 25.0)
		DISPLAY:
			var j := partner[i]
			if j < 0 or task_t[i] <= 0.0:
				task[i] = SCHOOL
				partner[i] = -1
				task_t[i] = rng.randf_range(8.0, 25.0)
			else:
				# (beside her, a little ahead, matching her, side on)
				var hh := heading[j]
				var right := hh.cross(Vector3.UP).normalized()
				var spot := pos[j] + right * 0.025 + hh * 0.008
				acc = (spot - p) * 6.0 + (vel[j] - v) * 3.0
				want = vel[j].length()
		PILOT:
			var to := aim[i] - p
			var sp := pace[i] if pace[i] > 0.0 else cruise
			acc = acc * 0.3 + (to.normalized() * minf(sp, to.length() * 3.0) - v) * 3.0
			want = sp
		HOLD:
			acc = acc * 0.3 + (aim[i] - p) * 4.0 - v * 3.0
			want = 0.0
	display_k[i] = move_toward(display_k[i], 1.0 if t == DISPLAY else 0.0, dt * 1.5)
	if t != GRAZE:
		graze_k[i] = move_toward(graze_k[i], 0.0, dt * 2.0)
	# scattered: away from it, fast
	var fast := false
	if _scare > 0.0:
		var away := p - _scare_from
		if away.length() < 0.5:
			acc += away.normalized() * 2.5 * _scare
			fast = true
			if t == GRAZE or t == DISPLAY:
				task[i] = SCHOOL
	# the walls, the bottom, the surface
	var lo := tank_min + Vector3(0.04, 0.0, 0.04)
	var hi := tank_max - Vector3(0.04, 0.025, 0.04)
	var fl := _floor(p.x, p.z) + 0.02
	var wall := Vector3.ZERO
	wall.x = maxf(lo.x - p.x, 0.0) - maxf(p.x - hi.x, 0.0)
	wall.z = maxf(lo.z - p.z, 0.0) - maxf(p.z - hi.z, 0.0)
	wall.y = maxf(fl - p.y, 0.0) * (0.2 if t == GRAZE else 1.0) - maxf(p.y - hi.y, 0.0)
	acc += wall * 40.0
	# level, mostly: fish don't climb or dive steeply schooling
	if t == SCHOOL:
		acc.y -= v.y * 1.5
	v += acc * dt
	var spd := v.length()
	var top := top_speed if fast else maxf(want * 1.6, 0.02)
	var least := 0.0 if t in [GRAZE, HOLD, DISPLAY] else want * 0.5
	if spd > top:
		v *= top / spd
	elif spd < least and spd > 1e-5: # (eased up to it, not snapped)
		v *= lerpf(1.0, least / spd, 1.0 - exp(-2.0 * dt))
	vel[i] = v
	var np := p + v * dt
	np.x = clampf(np.x, tank_min.x, tank_max.x)
	np.z = clampf(np.z, tank_min.z, tank_max.z)
	np.y = clampf(np.y, _floor(np.x, np.z) + 0.004, tank_max.y - 0.006)
	pos[i] = np


## Fish i drawn where it is: facing its way (level, swimming slowly, or
## nose down grazing), banked into its turn.
func _place(i: int, dt: float) -> void:
	# (its way: its velocity smoothed, not each frame's nudges from its
	# neighbours; its heading turning after that, its bank by how fast it
	# turns)
	if _vs.size() != vel.size():
		_vs = vel.duplicate()
	var v := _vs[i].lerp(vel[i], 1.0 - exp(-3.0 * dt))
	_vs[i] = v
	var h := heading[i]
	var spd := v.length()
	if spd > 0.01:
		var flat := Vector3(v.x, 0.0, v.z)
		var want := h
		if flat.length() > 1e-4:
			want = flat.normalized()
		var nh := h.slerp(want, 1.0 - exp(-4.0 * dt)).normalized()
		var rate := h.signed_angle_to(nh, Vector3.UP) / maxf(dt, 1e-4) # (rad/s)
		h = nh
		turn[i] = lerpf(turn[i], clampf(rate / 2.0, -1.0, 1.0), 1.0 - exp(-3.0 * dt))
	else:
		turn[i] = lerpf(turn[i], 0.0, 1.0 - exp(-3.0 * dt))
	heading[i] = h
	var pitch := clampf(atan2(v.y, maxf(Vector2(v.x, v.z).length(), 0.01)), -0.5, 0.5) * 0.7
	pitch = lerpf(pitch, -0.75, graze_k[i]) # (nose down to the bottom)
	var b := Basis.looking_at(h, Vector3.UP) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, turn[i] * 0.35)
	multimesh.set_instance_transform(i, Transform3D(b * Basis.from_scale(Vector3.ONE * size[i]), pos[i]))
	var swim := clampf(spd / (cruise * 2.5), 0.0, 1.0)
	var x := -graze_k[i] if graze_k[i] > 0.05 else swim
	var w := (1.0 + display_k[i] * 0.99) if male[i] == 1 else 0.0
	multimesh.set_instance_custom_data(i, Color(x, turn[i], seed[i], w))


# --- the mesh ----------------------------------------------------------------------

## The body's keys: [z, y, half width, half height] (mm).
const BODY := [[-28.5, 1.0, 0.8, 0.8], [-27.0, 0.9, 2.2, 2.4], [-23.0, 0.8, 3.6, 5.0], [-17.0, 0.6, 4.6, 7.4], [-9.0, 0.2, 5.4, 9.2],
		[0.0, 0.0, 5.3, 9.0], [9.0, -0.3, 4.3, 7.4], [17.0, -0.2, 3.0, 5.4], [23.0, 0.0, 1.9, 4.3], [26.5, 0.0, 1.3, 4.0]]


## The body's [y, half width, half height] at z (mm), between its keys.
static func _key(z: float) -> Vector3:
	for k in BODY.size() - 1:
		var a: Array = BODY[k]
		var b: Array = BODY[k + 1]
		if z <= float(b[0]):
			var f := clampf((z - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			return Vector3(lerpf(a[1], b[1], f), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f))
	var l: Array = BODY[BODY.size() - 1]
	return Vector3(l[1], l[2], l[3])


static func _top(z: float) -> float:
	var k := _key(z)
	return k.x + k.z


static func _under(z: float) -> float:
	var k := _key(z)
	return k.x - k.z


## The mesh: the body, eyes, lips, every fin (both sexes'), each vertex
## tagged with its part (molly.gdshader's), in metres; and the pectorals'
## pivots.
static func build_mesh() -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	# the body: rings down it, each a tall oval, flat sided
	const RING := 18
	const STEPS := 40
	var z0 := -28.5
	var z1 := 26.5
	var rings := []
	for s in STEPS + 1:
		var z := lerpf(z0, z1, float(s) / STEPS)
		var k := _key(z)
		var ring := []
		for r in RING:
			var a := TAU * r / RING
			var cx := sin(a)
			var cy := cos(a)
			# (flatter on its sides, fuller in its belly)
			var x := signf(cx) * pow(absf(cx), 0.85) * k.y
			var y := k.x + cy * k.z * (1.0 if cy > 0.0 else 1.05)
			ring.append(Vector3(x, y, z))
		rings.append(ring)
	for s in STEPS:
		for r in RING:
			var q := [rings[s][r], rings[s + 1][r], rings[s + 1][(r + 1) % RING], rings[s][(r + 1) % RING]]
			var mid := Vector3(0.0, _key(((q[0] as Vector3).z + (q[1] as Vector3).z) * 0.5).x, ((q[0] as Vector3).z + (q[1] as Vector3).z) * 0.5)
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var A: Vector3 = q[tri[0]]
				var B: Vector3 = q[tri[1]]
				var C: Vector3 = q[tri[2]]
				_face(st, A, B, C, mid, 0)
	# the eyes, their pupils; the lips
	var SA := SphereMesh.new()
	SA.radius = 0.5
	SA.height = 1.0
	SA.radial_segments = 12
	SA.rings = 6
	var sa := SA.get_mesh_arrays()
	for side: float in [-1.0, 1.0]:
		_prim(st, sa, Transform3D(Basis.from_scale(Vector3(3.2, 4.0, 4.0)), Vector3(3.9 * side, 2.2, -20.5)), 1, 0.0)
		_prim(st, sa, Transform3D(Basis.from_scale(Vector3(1.0, 2.0, 2.0)), Vector3(5.35 * side, 2.2, -20.6)), 2, 0.0)
	_prim(st, sa, Transform3D(Basis.from_scale(Vector3(2.4, 1.1, 1.8)), Vector3(0.0, 1.3, -28.0)), 12, 0.0)
	# the fins: each a membrane from its base out to its edge
	var base := []
	var edge := []
	# a female's dorsal: small, a little behind the middle
	for k in 8:
		var u := float(k) / 7.0
		var z := lerpf(-6.0, 8.0, u)
		var b := Vector3(0.0, _top(z) - 0.3, z)
		base.append(b)
		edge.append(b + Vector3(0.0, 5.5 * sin(PI * (0.12 + 0.8 * u)) + 0.5, 2.0 + 2.5 * u))
	_fin(st, base, edge, 3)
	# a male's sail: from behind his head nearly to his tail, high, highest behind
	base = []
	edge = []
	for k in 12:
		var u := float(k) / 11.0
		var z := lerpf(-16.0, 15.0, u)
		var b := Vector3(0.0, _top(z) - 0.3, z)
		base.append(b)
		var hgt := (6.0 + 9.0 * u) * (1.0 - 0.75 * smoothstep(0.82, 1.0, u)) + 0.6
		edge.append(b + Vector3(0.0, hgt, 3.0 + 1.5 * u))
	_fin(st, base, edge, 4)
	# the tail fin: a rounded fan
	base = []
	edge = []
	for k in 11:
		var u := float(k) / 10.0
		var a := lerpf(-1.05, 1.05, u)
		base.append(Vector3(0.0, lerpf(-3.7, 3.7, u), 26.0))
		edge.append(Vector3(0.0, 9.0 * sin(a), 26.0 + 15.0 * cos(a * 0.55)))
	_fin(st, base, edge, 5)
	# the pectorals, the pelvics
	var pivots := PackedVector3Array()
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		base = []
		edge = []
		for k in 5:
			var u := float(k) / 4.0
			var b := Vector3(5.0 * side, lerpf(-0.8, -4.0, u), -13.0 + 0.6 * u)
			base.append(b)
			edge.append(b + Vector3(1.8 * side, -0.6 * u, 7.5 + 1.2 * sin(PI * u)))
		_fin(st, base, edge, 6 + s)
		pivots.append(Vector3(5.0 * side, -2.4, -13.0) * MM)
		base = []
		edge = []
		for k in 3:
			var u := float(k) / 2.0
			var z := lerpf(-3.0, -0.5, u)
			var b := Vector3(1.8 * side, _under(z) + 0.4, z)
			base.append(b)
			edge.append(b + Vector3(0.8 * side, -2.0, 5.0 - 1.5 * u))
		_fin(st, base, edge, 8 + s)
	# a female's anal fin: a fan; a male's gonopodium: a rod laid back
	base = []
	edge = []
	for k in 6:
		var u := float(k) / 5.0
		var z := lerpf(5.0, 11.0, u)
		var b := Vector3(0.0, _under(z) + 0.3, z)
		base.append(b)
		edge.append(b + Vector3(0.0, -4.2 * sin(PI * (0.15 + 0.75 * u)) - 0.4, 2.5 + 1.5 * u))
	_fin(st, base, edge, 10)
	var CA := CylinderMesh.new()
	CA.top_radius = 0.5
	CA.bottom_radius = 0.5
	CA.height = 1.0
	CA.radial_segments = 6
	CA.rings = 1
	var g0 := Vector3(0.0, _under(5.0) - 0.2, 5.0)
	var g1 := Vector3(0.0, _under(5.0) - 2.0, 15.0)
	_prim(st, CA.get_mesh_arrays(), _seg(g0, g1, 0.45), 11, g0.y)
	st.generate_tangents()
	return [st.commit(), pivots]


## A face of the body (mm), its normal out from `mid`.
static func _face(st: SurfaceTool, A: Vector3, B: Vector3, C: Vector3, mid: Vector3, part: int) -> void:
	var nrm := (B - A).cross(C - A).normalized()
	var out := ((A + B + C) / 3.0 - mid).normalized()
	var flip := nrm.dot(out) < 0.0
	var vs := [A, C, B] if not flip else [A, B, C] # (the front face clockwise, seen from outside)
	for p: Vector3 in vs:
		var k := _key(p.z)
		var n := Vector3(p.x / maxf(k.y * k.y, 0.01), (p.y - k.x) / maxf(k.z * k.z, 0.01), 0.0).normalized()
		st.set_normal(n)
		st.set_uv(Vector2((p.z + 28.5) / 55.0, 0.0))
		st.set_custom(0, Color(part, 0.0, 0.0, 0.0))
		st.add_vertex(p * MM)


## A fin (mm): rows out from its base to its edge (base[k] to edge[k]),
## tagged: CUSTOM0 (part, the way out 0..1, along its base 0..1, its
## base's height).
static func _fin(st: SurfaceTool, base: Array, edge: Array, part: int) -> void:
	const ROWS := 4
	var n := base.size()
	for k in n - 1:
		for r in ROWS:
			var corners := []
			for c in [[k, r], [k + 1, r], [k + 1, r + 1], [k, r + 1]]:
				var kk: int = c[0]
				var t := float(c[1]) / ROWS
				var b: Vector3 = base[kk]
				var e: Vector3 = edge[kk]
				var p := b.lerp(e, t)
				corners.append([p, t, float(kk) / (n - 1), b.y])
			var a: Vector3 = (corners[1][0] as Vector3) - (corners[0][0] as Vector3)
			var o: Vector3 = (corners[3][0] as Vector3) - (corners[0][0] as Vector3)
			var nrm := a.cross(o)
			nrm = nrm.normalized() if nrm.length() > 1e-6 else Vector3.RIGHT
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for q: int in tri:
					var cn: Array = corners[q]
					st.set_normal(nrm)
					st.set_uv(Vector2(cn[2], cn[1]))
					st.set_custom(0, Color(part, cn[1], cn[2], float(cn[3]) * MM))
					st.add_vertex((cn[0] as Vector3) * MM)


## A primitive's arrays (a unit sphere, a cylinder) placed by xf (mm),
## tagged part (its base's height base_y, m).
static func _prim(st: SurfaceTool, arrays: Array, xf: Transform3D, part: int, base_y: float) -> void:
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	for k in idx:
		st.set_normal((nb * ns[k]).normalized())
		st.set_uv(Vector2.ZERO)
		st.set_custom(0, Color(part, 0.0, 0.0, base_y * MM))
		st.add_vertex((xf * vs[k]) * MM)


static func _seg(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * 2.0 * r, d, z * 2.0 * r), (a + b) * 0.5)


# --- steering: a state machine's, each one on its own (pilot.gd) -------------------

## Fish i, to steer: its calls (go, go_to, face, stop, act, behaviours,
## is_busy, action_finished) as every creature's.
func member(i: int) -> RefCounted:
	if not _members.has(i):
		var m := ColonyScript.Member.new()
		m.colony = self
		m.i = i
		_members[i] = m
		var p := PilotScript.new(self, i)
		p.finished = m.action_finished.emit
		_pilots[i] = p
	return _members[i]


func _p_here(i: int) -> Vector3:
	return pos[i]


func _p_heading(i: int) -> Vector3:
	return heading[i]


func _p_steer(i: int, point: Vector3, speed: float) -> void:
	task[i] = PILOT
	aim[i] = point
	pace[i] = speed


func _p_hold(i: int) -> void:
	task[i] = HOLD
	aim[i] = pos[i]
	pace[i] = -1.0


func _p_mobile(_i: int) -> bool:
	return true


func _p_speed(_i: int) -> float:
	return cruise


func _p_reach(_i: int) -> float:
	return 0.02


## graze {at, seconds}; a male's display {seconds}.
func _p_behaviours(i: int) -> PackedStringArray:
	return PackedStringArray(["graze", "display"]) if male[i] == 1 else PackedStringArray(["graze"])


func _p_act(i: int, name: String, args: Dictionary) -> bool:
	match name:
		"graze":
			graze(i, args.get("at", Vector3.INF))
		"display":
			if male[i] == 0:
				return false
			display(i)
		_:
			return false
	return true


func _p_act_done(i: int, name: String) -> bool:
	match name:
		"graze":
			return task[i] != GRAZE
		"display":
			return task[i] != DISPLAY
	return false


func _p_act_secs(_i: int, _name: String) -> float:
	return 8.0
