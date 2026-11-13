class_name FishSchool
extends MultiMeshInstance3D
## A school of fish of one kind, life size, made and moved as the mollies
## are (Mollies; the ants: AntColony): one mesh, every fish an instance of
## it, posed by shaders/render/fish.gdshader (the body's wave, the turns,
## the pectorals, the jaw), so a school of hundreds is a draw call; here
## each fish is only moved along, once a frame. FishSchool.new(kind,
## variant), then setup(n, centre, spread); the water it keeps to tank_min
## .. tank_max (its own space; bottom: a Callable (x, z) -> the bottom's
## y); current: the water's flow (m/s), if it's a stream.
## The kinds:
## - "chinook": a Chinook (king) salmon (Oncorhynchus tshawytscha), about
##   90 cm: at sea ("ocean") dark blue green above, silver, white beneath,
##   black spots over its back and both lobes of its tail; spawning
##   ("spawning") dark olive and maroon, humped, the male's jaws hooked
##   (the kype: the spawning variant is the male's)
## - "rainbow": a rainbow trout (Oncorhynchus mykiss), about 45 cm: olive
##   above, spotted black over its back, its fins and its tail, a pink red
##   band down its side, silver white beneath, its fins edged white; a
##   steelhead ("steelhead": the sea-run) silver, the band faint
## - "bluefin": an Atlantic bluefin tuna (Thunnus thynnus), about 2 m: a
##   torpedo, deep metallic navy above, silver white below, faint pale bars
##   down its lower sides; its first dorsal grey yellow, its second and its
##   anal fin tall and sickle shaped, reddish brown; the yellow finlets
##   behind them, edged black; keels each side of its narrow tail stalk; the
##   tail a crescent; its whole beat in its tail
## Each fish:
## - schooling: apart from its neighbours, going their way, staying with
##   them; the school wandering (swim_to(point)); scatter(from)
## - holding (hold(i), a trout's in a stream: of its own accord when
##   there's a current): in its place by the bottom, facing upstream into
##   the current, its tail just working, now and then darting aside
## - rising (rise(i)): up to the surface, its mouth open, a sip (a ring
##   spreading on the water), and back down
## - feeding (feed(at)): the school dashing through the bait at `at`, mouths
##   open, scattering through it (a tuna's)
## - steered (member(i): go, go_to, face, stop, act rise / hold / feed:
##   pilot.gd)

const ColonyScript := preload("res://scripts/creatures/ant_colony.gd")
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.001
const SCHOOL := 0
const HOLD := 1
const RISE := 2
const FEED := 3
const PILOT := 4
const STILL := 5
const TAKEN := 6 ## (caught: out of the school, take())

## each kind's: its species (the shader's), its speeds (m/s), the distances
## it keeps (m), how stiff its body (a tuna's beat all in its tail), its
## spots' spacing, its half height (m)
const KINDS := {
	"chinook": {"species": 0, "cruise": 0.55, "top": 4.0, "near": 1.4, "apart": 0.5, "stiff": 0.0, "spot": 0.022, "half_h": 0.11, "scale": 1.0},
	"rainbow": {"species": 1, "cruise": 0.3, "top": 2.5, "near": 0.7, "apart": 0.22, "stiff": 0.0, "spot": 0.009, "half_h": 0.055, "scale": 0.5},
	"bluefin": {"species": 2, "cruise": 1.4, "top": 8.0, "near": 6.0, "apart": 2.6, "stiff": 1.0, "spot": 0.05, "half_h": 0.37, "scale": 1.0},
}
const VARIANTS := {"ocean": 0, "spawning": 1, "steelhead": 1}

var kind := "chinook"
var variant := 0
var K: Dictionary
var tank_min := Vector3(-5.0, 0.0, -5.0) ## the water (its own space): the bottom's corner
var tank_max := Vector3(5.0, 3.0, 5.0) ## and the surface's
var bottom: Callable ## (x, z) -> the bottom's y (none: tank_min.y)
var current := Vector3.ZERO ## the water's flow (m/s): a stream's
var rings: Array[Node3D] = [] ## (the rises' rings, spreading on the surface)
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var seed := PackedFloat32Array()
var size := PackedFloat32Array()
var task := PackedInt32Array()
var task_t := PackedFloat32Array()
var aim := PackedVector3Array()
var pace := PackedFloat32Array()
var heading := PackedVector3Array()
var turn := PackedFloat32Array()
var mouth := PackedFloat32Array()
var goal := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var _goal_t := 0.0
var _scare := 0.0
var _scare_from := Vector3.ZERO
var _bait := Vector3.INF
var _bait_t := 0.0
var _pilots := {}
var _members := {}
var _t := 0.0

static var _built := {} # kind:variant -> [mesh, pec pivots, jaw pivot, z_head, z_tail]


func _init(kind_ := "chinook", variant_ := "ocean") -> void:
	kind = kind_ if KINDS.has(kind_) else "chinook"
	K = KINDS[kind]
	variant = int(VARIANTS.get(variant_, 0))


func setup(n: int, centre: Vector3, spread := 1.0) -> void:
	rng.randomize()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	var key := "%s:%d" % [kind, variant]
	if not _built.has(key):
		_built[key] = build_mesh(kind, variant)
	var B: Array = _built[key]
	multimesh.mesh = B[0]
	multimesh.instance_count = n
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/fish.gdshader")
	m.set_shader_parameter("species", int(K.species))
	m.set_shader_parameter("variant", variant)
	m.set_shader_parameter("pec_pivots", B[1])
	m.set_shader_parameter("jaw_pivot", B[2])
	m.set_shader_parameter("z_head", B[3])
	m.set_shader_parameter("z_tail", B[4])
	m.set_shader_parameter("stiff", float(K.stiff))
	m.set_shader_parameter("spot_cell", float(K.spot))
	m.set_shader_parameter("half_h", float(K.half_h))
	material_override = m
	pos.resize(n)
	vel.resize(n)
	aim.resize(n)
	heading.resize(n)
	seed.resize(n)
	size.resize(n)
	task.resize(n)
	task_t.resize(n)
	pace.resize(n)
	turn.resize(n)
	mouth.resize(n)
	for i in n:
		pos[i] = centre + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-1, 1)) * spread
		var a := rng.randf() * TAU
		heading[i] = Vector3(cos(a), 0.0, sin(a))
		vel[i] = heading[i] * float(K.cruise)
		seed[i] = rng.randf()
		size[i] = rng.randf_range(0.8, 1.1)
		task[i] = HOLD if current.length() > 0.01 else SCHOOL
		aim[i] = pos[i]
		task_t[i] = rng.randf_range(5.0, 20.0)
		pace[i] = -1.0
	goal = centre
	custom_aabb = AABB(tank_min - Vector3.ONE, tank_max - tank_min + Vector3.ONE * 2.0)


func swim_to(point: Vector3) -> void:
	goal = point
	_goal_t = 25.0


func scatter(from: Vector3) -> void:
	_scare = 1.5
	_scare_from = from


## Fish i in its place by the bottom, facing upstream into the current.
func hold(i: int, at := Vector3.INF) -> void:
	task[i] = HOLD
	var p := at if at != Vector3.INF else pos[i]
	aim[i] = Vector3(p.x, _floor(p.x, p.z) + float(K.half_h) * 1.6, p.z)


## Fish i up to the surface, a sip, and back.
func rise(i: int) -> void:
	task[i] = RISE
	aim[i] = Vector3(pos[i].x, tank_max.y - float(K.half_h) * 0.6, pos[i].z) + heading[i] * float(K.half_h) * 4.0
	task_t[i] = 6.0


## The school through the bait at `at`, mouths open, a while.
func feed(at: Vector3) -> void:
	_bait = at
	_bait_t = 8.0
	for i in pos.size():
		if task[i] != PILOT:
			task[i] = FEED


func rejoin(i: int) -> void:
	task[i] = HOLD if current.length() > 0.01 else SCHOOL
	task_t[i] = rng.randf_range(8.0, 25.0)


func _floor(x: float, z: float) -> float:
	return maxf(float(bottom.call(x, z)) if bottom.is_valid() else tank_min.y, tank_min.y)


func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	_t += dt
	_scare = maxf(_scare - dt, 0.0)
	_bait_t -= dt
	if _bait_t <= 0.0 and _bait != Vector3.INF:
		_bait = Vector3.INF
		for i in pos.size():
			if task[i] == FEED:
				rejoin(i)
	for i in _pilots:
		(_pilots[i] as PilotScript).tick(dt)
	_goal_t -= dt
	if _goal_t <= 0.0:
		_goal_t = rng.randf_range(8.0, 16.0)
		var lo := tank_min + (tank_max - tank_min) * 0.15
		var hi := tank_max - (tank_max - tank_min) * 0.15
		goal = Vector3(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y), rng.randf_range(lo.z, hi.z))
	var near := float(K.near)
	var grid := {}
	for i in pos.size():
		var k := Vector3i(floori(pos[i].x / near), floori(pos[i].y / near), floori(pos[i].z / near))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(i)
	for i in pos.size():
		_steer(i, dt, grid)
	for i in pos.size():
		_place(i, dt)
	for r in rings:
		if is_instance_valid(r):
			var a := float(r.get_meta("t")) + dt
			r.set_meta("t", a)
			r.scale = Vector3.ONE * (0.05 + a * 0.35) * float(K.scale)
			var rm := (r as MeshInstance3D).material_override as StandardMaterial3D
			var col := rm.albedo_color
			col.a = maxf(0.5 - a * 0.25, 0.0)
			rm.albedo_color = col
			if a > 2.0:
				r.queue_free()
	var live: Array[Node3D] = []
	for r in rings:
		if is_instance_valid(r):
			live.append(r)
	rings = live


func _steer(i: int, dt: float, grid: Dictionary) -> void:
	if task[i] == TAKEN:
		return
	var p := pos[i]
	var v := vel[i]
	task_t[i] -= dt
	var near := float(K.near)
	var apart := float(K.apart) * size[i]
	var cruise := float(K.cruise)
	var sep := Vector3.ZERO
	var align := Vector3.ZERO
	var coh := Vector3.ZERO
	var m := 0
	var c := Vector3i(floori(p.x / near), floori(p.y / near), floori(p.z / near))
	for dz in range(-1, 2):
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for j: int in grid.get(c + Vector3i(dx, dy, dz), []):
					if j == i:
						continue
					var off := p - pos[j]
					var d := off.length()
					if d > near or d < 1e-6:
						continue
					if d < apart:
						sep += off / d * (apart - d) / apart
					align += vel[j]
					coh += pos[j]
					m += 1
	var acc := sep * 2.0 * cruise
	var want := cruise * (0.85 + 0.3 * seed[i])
	var t := task[i]
	if m > 0 and t in [SCHOOL, FEED]:
		acc += (align / m - v) * 1.1
		acc += (coh / m - p) * 0.8 * cruise / near
	mouth[i] = move_toward(mouth[i], 0.0, dt * 2.0)
	match t:
		SCHOOL:
			if p.distance_to(goal) > near:
				acc += (goal - p).normalized() * 0.08 * cruise
			if task_t[i] <= 0.0:
				task_t[i] = rng.randf_range(10.0, 30.0)
				if kind != "bluefin" and rng.randf() < 0.3:
					rise(i)
		HOLD: # (in its place, facing upstream, its tail just working)
			var to := aim[i] - p
			acc = (to * 3.0 - v) * 2.0
			want = 0.0
			if task_t[i] <= 0.0: # (a dart aside, or a rise)
				task_t[i] = rng.randf_range(6.0, 18.0)
				if rng.randf() < 0.5:
					rise(i)
				else:
					var to2 := aim[i] + Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)) * float(K.half_h) * 4.0
					to2.y = _floor(to2.x, to2.z) + float(K.half_h) * 1.6
					aim[i] = to2
		RISE:
			var to := aim[i] - p
			if to.length() > float(K.half_h) * 0.8:
				acc = acc * 0.3 + (to.normalized() * cruise * 1.4 - v) * 3.0
				mouth[i] = move_toward(mouth[i], 1.0 if to.length() < float(K.half_h) * 3.0 else 0.0, dt * 4.0)
			else: # (the sip: a ring on the water; back down)
				mouth[i] = 1.0
				_ring(Vector3(p.x, tank_max.y, p.z))
				if current.length() > 0.01:
					hold(i, p)
				else:
					task[i] = SCHOOL
				task_t[i] = rng.randf_range(10.0, 30.0)
		FEED: # (through the bait, mouths open)
			if _bait != Vector3.INF:
				var to := _bait - p
				acc += to.normalized() * cruise * 2.5
				want = cruise * 3.0
				mouth[i] = move_toward(mouth[i], 1.0 if to.length() < near * 0.6 else 0.3, dt * 3.0)
		PILOT:
			var to := aim[i] - p
			var sp := pace[i] if pace[i] > 0.0 else cruise
			acc = acc * 0.3 + (to.normalized() * minf(sp, to.length() * 2.0) - v) * 2.5
			want = sp
		STILL:
			acc = acc * 0.3 + (aim[i] - p) * 3.0 - v * 2.5
			want = 0.0
	var fast := false
	if _scare > 0.0:
		var away := p - _scare_from
		if away.length() < near * 4.0:
			acc += away.normalized() * cruise * 4.0 * _scare
			fast = true
	# the walls, the bottom, the surface
	var margin := float(K.half_h) * 4.0
	var lo := tank_min + Vector3(margin, 0.0, margin)
	var hi := tank_max - Vector3(margin, float(K.half_h) * (0.3 if t == RISE else 2.5), margin)
	var fl := _floor(p.x, p.z) + float(K.half_h) * 1.3
	var wall := Vector3(maxf(lo.x - p.x, 0.0) - maxf(p.x - hi.x, 0.0), maxf(fl - p.y, 0.0) - maxf(p.y - hi.y, 0.0), maxf(lo.z - p.z, 0.0) - maxf(p.z - hi.z, 0.0))
	acc += wall * 20.0 * cruise / margin
	if t == SCHOOL:
		acc.y -= v.y * 1.2
	v += acc * dt
	var spd := v.length()
	var top := float(K.top) if fast else maxf(want * 1.7, 0.03)
	var least := 0.0 if t in [HOLD, STILL] else want * 0.5
	if spd > top:
		v *= top / spd
	elif spd < least and spd > 1e-5:
		v *= least / spd
	vel[i] = v
	# (a stream's current carries it; holding, it swims against it)
	var drift := current if t != HOLD else Vector3.ZERO
	var np := p + (v + drift) * dt
	np.x = clampf(np.x, tank_min.x, tank_max.x)
	np.z = clampf(np.z, tank_min.z, tank_max.z)
	np.y = clampf(np.y, _floor(np.x, np.z) + float(K.half_h) * 0.8, tank_max.y - float(K.half_h) * 0.4)
	pos[i] = np


func _place(i: int, dt: float) -> void:
	if task[i] == TAKEN:
		return
	var v := vel[i]
	var h := heading[i]
	var want := h
	var flat := Vector3(v.x, 0.0, v.z)
	if task[i] == HOLD and current.length() > 0.01:
		want = (-current).normalized() # (facing upstream)
	elif flat.length() > 0.02:
		want = flat.normalized()
	var yaw_rate := h.signed_angle_to(want, Vector3.UP)
	# (turned toward it about the vertical: its heading level, as it always is;
	# not slerp, whose axis, from two near parallel headings, comes out a hair
	# off unit length and errors)
	h = h.rotated(Vector3.UP, yaw_rate * (1.0 - exp(-4.0 * dt)))
	h = Vector3(h.x, 0.0, h.z).normalized() if Vector2(h.x, h.z).length() > 1e-5 else Vector3.FORWARD
	turn[i] = lerpf(turn[i], clampf(yaw_rate / maxf(dt, 1e-4) / 3.0, -1.0, 1.0), 1.0 - exp(-5.0 * dt))
	heading[i] = h
	var pitch := clampf(atan2(v.y, maxf(Vector2(v.x, v.z).length(), 0.02)), -0.6, 0.6) * 0.8
	var b := Basis.looking_at(h, Vector3.UP) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, turn[i] * (0.15 if kind == "bluefin" else 0.3))
	multimesh.set_instance_transform(i, Transform3D(b * Basis.from_scale(Vector3.ONE * size[i]), pos[i]))
	var swim := clampf(v.length() / (float(K.cruise) * 2.5), 0.0, 1.0)
	if task[i] == HOLD:
		swim = maxf(swim, clampf(current.length() / (float(K.cruise) * 2.5), 0.15, 0.6)) # (its tail working against the current)
	multimesh.set_instance_custom_data(i, Color(swim, turn[i], seed[i], mouth[i]))


func _ring(at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 24
	tm.ring_segments = 4
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.95, 1.0, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.position = at + Vector3.UP * 0.003
	mi.set_meta("t", 0.0)
	add_child(mi)
	mi.scale = Vector3.ONE * 0.05
	rings.append(mi)


# --- the meshes --------------------------------------------------------------------

## The salmon's body, [z, y, half width, half height] (mm); the trout's the
## same, half the size; the tuna's.
const CHINOOK := [[-450.0, 8.0, 6.0, 8.0], [-430.0, 10.0, 26.0, 34.0], [-380.0, 14.0, 46.0, 66.0], [-300.0, 18.0, 64.0, 96.0], [-180.0, 16.0, 72.0, 110.0],
		[-40.0, 10.0, 70.0, 104.0], [100.0, 4.0, 58.0, 86.0], [210.0, 0.0, 40.0, 62.0], [290.0, 0.0, 24.0, 44.0], [330.0, 0.0, 18.0, 40.0]]
const BLUEFIN := [[-1000.0, 0.0, 10.0, 12.0], [-960.0, 8.0, 70.0, 90.0], [-850.0, 20.0, 180.0, 240.0], [-650.0, 25.0, 280.0, 340.0], [-400.0, 25.0, 320.0, 370.0],
		[-100.0, 20.0, 310.0, 350.0], [200.0, 10.0, 240.0, 265.0], [480.0, 0.0, 140.0, 150.0], [680.0, 0.0, 65.0, 60.0], [800.0, 0.0, 38.0, 32.0], [840.0, 0.0, 30.0, 28.0]]


static func _key(keys: Array, z: float) -> Vector3:
	for k in keys.size() - 1:
		var a: Array = keys[k]
		var b: Array = keys[k + 1]
		if z <= float(b[0]):
			var f := clampf((z - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			return Vector3(lerpf(a[1], b[1], f), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f))
	var l: Array = keys[keys.size() - 1]
	return Vector3(l[1], l[2], l[3])


## The mesh of a kind (and its variant: a spawner's hump and hooked jaws):
## [mesh, the pectorals' pivots, the jaw's pivot, z_head, z_tail] (m).
static func build_mesh(kind_: String, variant_ := 0) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var tuna := kind_ == "bluefin"
	var sc := 0.5 if kind_ == "rainbow" else 1.0
	var keys: Array = []
	for k: Array in (BLUEFIN if tuna else CHINOOK):
		var kk := [float(k[0]) * sc, float(k[1]) * sc, float(k[2]) * sc, float(k[3]) * sc]
		if kind_ == "chinook" and variant_ == 1: # (a spawner's hump, its snout longer)
			var z: float = k[0]
			kk[3] = float(kk[3]) * (1.0 + 0.18 * exp(-pow((z + 220.0) / 120.0, 2.0)))
			kk[1] = float(kk[1]) + 14.0 * exp(-pow((z + 220.0) / 120.0, 2.0))
			if z < -420.0:
				kk[0] = z - 25.0
		keys.append(kk)
	var z0: float = (keys[0] as Array)[0]
	var z1: float = (keys[keys.size() - 1] as Array)[0]
	# the body
	const RING := 16
	const STEPS := 36
	var rings_ := []
	for s in STEPS + 1:
		var z := lerpf(z0, z1, float(s) / STEPS)
		var k := _key(keys, z)
		var ring := []
		for r in RING:
			var a := TAU * r / RING
			var x := sin(a) * k.y * (0.92 if not tuna else 1.0)
			var y := k.x + cos(a) * k.z
			ring.append(Vector3(x, y, z))
		rings_.append(ring)
	for s in STEPS:
		for r in RING:
			var q := [rings_[s][r], rings_[s + 1][r], rings_[s + 1][(r + 1) % RING], rings_[s][(r + 1) % RING]]
			var zm := ((q[0] as Vector3).z + (q[1] as Vector3).z) * 0.5
			var mid := Vector3(0.0, _key(keys, zm).x, zm)
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				_face(st, keys, q[tri[0]], q[tri[1]], q[tri[2]], mid)
	var top := func(z: float) -> float:
		var k := _key(keys, z)
		return k.x + k.z
	var under := func(z: float) -> float:
		var k := _key(keys, z)
		return k.x - k.z
	var hw := func(z: float) -> float:
		return _key(keys, z).y
	# the lower jaw, its pivot
	var jaw_keys: Array
	var jaw_at: Vector3
	if tuna:
		jaw_keys = [[-850.0, -70.0, 95.0, 30.0], [-930.0, -55.0, 55.0, 18.0], [-985.0, -30.0, 20.0, 8.0]]
		jaw_at = Vector3(0.0, -60.0, -850.0)
	else:
		jaw_keys = [[-330.0 * sc, -35.0 * sc, 28.0 * sc, 11.0 * sc], [-400.0 * sc, -30.0 * sc, 18.0 * sc, 8.0 * sc], [-448.0 * sc, -20.0 * sc, 7.0 * sc, 4.0 * sc]]
		jaw_at = Vector3(0.0, -30.0 * sc, -330.0 * sc)
	var CA := CylinderMesh.new()
	CA.top_radius = 0.5
	CA.bottom_radius = 0.5
	CA.height = 1.0
	CA.radial_segments = 6
	var SA := SphereMesh.new()
	SA.radius = 0.5
	SA.height = 1.0
	SA.radial_segments = 12
	SA.rings = 6
	var sa := SA.get_mesh_arrays()
	for j in jaw_keys.size() - 1:
		var a: Array = jaw_keys[j]
		var b: Array = jaw_keys[j + 1]
		var mid_ := Vector3(0.0, (float(a[1]) + float(b[1])) * 0.5, (float(a[0]) + float(b[0])) * 0.5)
		_prim(st, sa, Transform3D(Basis.from_scale(Vector3((float(a[2]) + float(b[2])), (float(a[3]) + float(b[3])), absf(float(b[0]) - float(a[0])) * 1.3)), mid_), 12)
	if kind_ == "chinook" and variant_ == 1: # (the kype: the lower jaw's tip hooked up)
		var tip := Vector3(0.0, -20.0, -470.0)
		_prim(st, CA.get_mesh_arrays(), _seg(tip, tip + Vector3(0.0, 40.0, 8.0), 6.0), 12)
	# the eyes
	var eye_at := Vector3(75.0, 45.0, -880.0) if tuna else Vector3(26.0, 16.0, -385.0) * sc
	var eye_r := 50.0 if tuna else 16.0 * sc
	for side: float in [-1.0, 1.0]:
		var e := Vector3(maxf(eye_at.x, float(hw.call(eye_at.z)) * 0.85) * side, eye_at.y, eye_at.z)
		_prim(st, sa, Transform3D(Basis.from_scale(Vector3(eye_r * 0.5, eye_r, eye_r)), e), 1)
		_prim(st, sa, Transform3D(Basis.from_scale(Vector3(eye_r * 0.2, eye_r * 0.5, eye_r * 0.5)), e + Vector3(eye_r * 0.22 * side, 0.0, 0.0)), 2)
	# the fins
	var tail_z := 0.0
	if tuna:
		# the first dorsal (spiny), the second (tall, sickle), the anal
		_fin_along(st, -480.0, -250.0, 6, top, 3, true, func(u: float) -> Vector3: return Vector3(0.0, 140.0 * sin(PI * (0.1 + 0.8 * u)) * (1.0 - 0.5 * u), 60.0))
		_fin_along(st, -150.0, -20.0, 6, top, 4, true, func(u: float) -> Vector3: return Vector3(0.0, 280.0 * (1.0 - u * 0.85), 160.0 + 40.0 * u))
		_fin_along(st, -90.0, 20.0, 6, under, 10, false, func(u: float) -> Vector3: return Vector3(0.0, -250.0 * (1.0 - u * 0.85), 150.0 + 40.0 * u))
		# the finlets, above and below
		for k in 8:
			var z := lerpf(140.0, 660.0, float(k) / 7.0)
			_fin_along(st, z, z + 30.0, 2, top, 11, true, func(u: float) -> Vector3: return Vector3(0.0, 45.0 * (1.0 - u), 25.0))
			_fin_along(st, z, z + 30.0, 2, under, 11, false, func(u: float) -> Vector3: return Vector3(0.0, -45.0 * (1.0 - u), 25.0))
		# the keels each side of its tail stalk
		for side: float in [-1.0, 1.0]:
			var base := []
			var edge := []
			for k in 5:
				var z := lerpf(650.0, 820.0, float(k) / 4.0)
				var b := Vector3(float(hw.call(z)) * side * 0.95, 0.0, z)
				base.append(b)
				edge.append(b + Vector3(35.0 * side * sin(PI * float(k) / 4.0) + 2.0 * side, 0.0, 0.0))
			_fin(st, base, edge, 13)
		# the tail: a crescent
		var base := []
		var edge := []
		tail_z = 836.0
		for k in 13:
			var a := lerpf(-1.0, 1.0, float(k) / 12.0)
			base.append(Vector3(0.0, a * 25.0, tail_z))
			edge.append(Vector3(0.0, 620.0 * a, tail_z + 40.0 + 260.0 * pow(absf(a), 1.6)))
		_fin(st, base, edge, 5)
		tail_z += 300.0
	else:
		_fin_along(st, -90.0 * sc, 40.0 * sc, 6, top, 3, true, func(u: float) -> Vector3: return Vector3(0.0, 75.0 * sc * sin(PI * (0.08 + 0.75 * u)) + 4.0 * sc, 30.0 * sc + 10.0 * sc * u))
		_fin_along(st, 225.0 * sc, 265.0 * sc, 3, top, 4, true, func(u: float) -> Vector3: return Vector3(0.0, 20.0 * sc * sin(PI * u) + 4.0 * sc, 6.0 * sc)) # (the adipose)
		_fin_along(st, 175.0 * sc, 235.0 * sc, 5, under, 10, false, func(u: float) -> Vector3: return Vector3(0.0, -55.0 * sc * sin(PI * (0.1 + 0.7 * u)) - 3.0 * sc, 22.0 * sc))
		var base := []
		var edge := []
		tail_z = 326.0 * sc
		var notch := (50.0 if kind_ == "chinook" else 18.0) * sc # (the trout's less forked)
		for k in 11:
			var a := lerpf(-1.0, 1.0, float(k) / 10.0)
			base.append(Vector3(0.0, a * 36.0 * sc, tail_z))
			edge.append(Vector3(0.0, a * 100.0 * sc, tail_z + 125.0 * sc - notch * (1.0 - pow(absf(a), 0.8))))
		_fin(st, base, edge, 5)
		tail_z += 125.0 * sc
	# the pectorals, the pelvics
	var pivots := PackedVector3Array()
	var pec_z := -640.0 if tuna else -290.0 * sc
	var pec_l := 300.0 if tuna else 90.0 * sc
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		var px := float(hw.call(pec_z)) * 0.95
		var py := (-40.0 if tuna else -55.0 * sc)
		var base := []
		var edge := []
		for k in 4:
			var u := float(k) / 3.0
			var b := Vector3(px * side, py - u * (40.0 if tuna else 20.0 * sc), pec_z + u * 10.0)
			base.append(b)
			edge.append(b + Vector3(side * pec_l * 0.25, -pec_l * 0.25 * u, pec_l * (0.95 - 0.35 * u)))
		_fin(st, base, edge, 6 + s)
		pivots.append(Vector3(px * side, py, pec_z) * MM)
		var pz := -600.0 if tuna else -30.0 * sc
		base = []
		edge = []
		for k in 3:
			var u := float(k) / 2.0
			var z := pz + u * (40.0 if tuna else 20.0 * sc)
			var b := Vector3((60.0 if tuna else 22.0 * sc) * side, float(under.call(z)) + 3.0, z)
			base.append(b)
			edge.append(b + Vector3(side * 8.0, -(60.0 if tuna else 18.0 * sc), (120.0 if tuna else 55.0 * sc) * (1.0 - 0.3 * u)))
		_fin(st, base, edge, 8 + s)
	st.generate_tangents()
	return [st.commit(), pivots, jaw_at * MM, z0 * MM, tail_z * MM]


static func _face(st: SurfaceTool, keys: Array, A: Vector3, B: Vector3, C: Vector3, mid: Vector3) -> void:
	var nrm := (B - A).cross(C - A).normalized()
	var out := ((A + B + C) / 3.0 - mid).normalized()
	var vs := [A, C, B] if nrm.dot(out) >= 0.0 else [A, B, C]
	for p: Vector3 in vs:
		var k := _key(keys, p.z)
		var n := Vector3(p.x / maxf(k.y * k.y, 0.01), (p.y - k.x) / maxf(k.z * k.z, 0.01), 0.0).normalized()
		st.set_normal(n)
		st.set_uv(Vector2.ZERO)
		st.set_custom(0, Color(0, 0.0, 0.0, 0.0))
		st.add_vertex(p * MM)


## A fin along the back (or the belly) from z0 to z1 (mm), n rays: each
## from its base on the body (on: the body's top or under at z) out by
## out(u) (u 0..1 along its base).
static func _fin_along(st: SurfaceTool, z0_: float, z1_: float, n: int, on: Callable, part: int, _up: bool, out: Callable) -> void:
	var base := []
	var edge := []
	for k in n:
		var u := float(k) / maxf(n - 1, 1)
		var z := lerpf(z0_, z1_, u)
		var b := Vector3(0.0, float(on.call(z)) - (1.0 if _up else -1.0), z)
		base.append(b)
		edge.append(b + (out.call(u) as Vector3))
	_fin(st, base, edge, part)


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
				corners.append([b.lerp(e, t), t, float(kk) / (n - 1)])
			var a: Vector3 = (corners[1][0] as Vector3) - (corners[0][0] as Vector3)
			var o: Vector3 = (corners[3][0] as Vector3) - (corners[0][0] as Vector3)
			var nrm := a.cross(o)
			nrm = nrm.normalized() if nrm.length() > 1e-6 else Vector3.RIGHT
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for q: int in tri:
					var cn: Array = corners[q]
					st.set_normal(nrm)
					st.set_uv(Vector2(cn[2], cn[1]))
					st.set_custom(0, Color(part, cn[1], cn[2], 0.0))
					st.add_vertex((cn[0] as Vector3) * MM)


static func _prim(st: SurfaceTool, arrays: Array, xf: Transform3D, part: int) -> void:
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	for k in idx:
		st.set_normal((nb * ns[k]).normalized())
		st.set_uv(Vector2.ZERO)
		st.set_custom(0, Color(part, 0.0, 0.0, 0.0))
		st.add_vertex((xf * vs[k]) * MM)


static func _seg(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	return Transform3D(Basis(x * 2.0 * r, d, x.cross(y) * 2.0 * r), (a + b) * 0.5)


## Fish i taken out of the school (caught: a bear's): a fish of its own,
## in the school's parent, where it was (its mesh, its colours); gone from
## the school. (A fish: it bleeds, eaten: Meal, by its name.)
func take(i: int) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = "fish"
	mi.mesh = multimesh.mesh
	mi.material_override = material_override
	var parent := get_parent() as Node3D
	parent.add_child(mi)
	mi.global_transform = global_transform * multimesh.get_instance_transform(i)
	task[i] = TAKEN
	multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 1e-4), pos[i]))
	pos[i] = tank_min - Vector3.ONE * 500.0 # (out of the others' way)
	vel[i] = Vector3.ZERO
	return mi


## The fish nearest p (its parent's space; not taken), or -1.
func nearest(p: Vector3) -> int:
	var lp := to_local(get_parent().to_global(p)) if is_inside_tree() else p
	var best := -1
	var bd := INF
	for i in pos.size():
		if task[i] == TAKEN:
			continue
		var d := pos[i].distance_to(lp)
		if d < bd:
			bd = d
			best = i
	return best


# --- steering (pilot.gd) ----------------------------------------------------------

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
	task[i] = STILL
	aim[i] = pos[i]
	pace[i] = -1.0


func _p_mobile(_i: int) -> bool:
	return true


func _p_speed(_i: int) -> float:
	return float(K.cruise)


func _p_reach(_i: int) -> float:
	return float(K.half_h) * 3.0


## rise, hold {at}, feed {at} (the whole school's).
func _p_behaviours(_i: int) -> PackedStringArray:
	return PackedStringArray(["rise", "hold", "feed"])


func _p_act(i: int, name: String, args: Dictionary) -> bool:
	match name:
		"rise":
			rise(i)
		"hold":
			hold(i, args.get("at", Vector3.INF))
		"feed":
			feed(args.get("at", pos[i] + heading[i] * float(K.near)))
		_:
			return false
	return true


func _p_act_done(i: int, name: String) -> bool:
	match name:
		"rise":
			return task[i] != RISE
		"feed":
			return _bait == Vector3.INF
	return false


func _p_act_secs(_i: int, name: String) -> float:
	return 10.0 if name == "hold" else -1.0
