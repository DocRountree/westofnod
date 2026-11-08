class_name Krill
extends MultiMeshInstance3D
## A swarm of Antarctic krill (Euphausia superba), life size (about 5 cm):
## slender, see-through pink, flecked with red (their chromatophores); the
## green of the gut showing through the shell behind the head; big black
## eyes on stalks; long antennae and antennules; the thoracic legs, fringed
## with bristles, folded into a feeding basket under the head; five pairs
## of feathery swimmerets under the abdomen; the tail fan; and the
## photophores, the little lights under the body and on the eyestalks,
## glowing blue-green (brighter in the dark).
##
## Made and moved as the ants and the mollies are (AntColony, Mollies): one
## mesh, every krill an instance of it, posed by its shader
## (shaders/render/krill.gdshader: the swimmerets beating in a wave from
## back to front, the feeding basket opening, the antennae trailing, the
## tail flicked under in its escape), so a swarm of hundreds is one draw
## call; here each is only moved along, once a frame. setup(n, centre,
## spread), the water it keeps to: tank_min .. tank_max (its own space;
## bottom: a Callable (x, z) -> the bottom's y). Each krill:
## - swarming: close packed (a couple of centimetres apart), all facing
##   the same way, hanging in the water, the swarm drifting about (or
##   swim_to(point))
## - feeding (feed(i), or now and then of its own accord): stopped, tipped
##   head up, its feeding basket thrown open and swept shut, again and again
## - its escape (scatter(from): "lobstering"): the tail flicked under it
##   again and again, shooting it backward away from the threat, fast; then
##   back with the others
## - steered, each on its own (member(i): every creature's calls: pilot.gd)

const ColonyScript := preload("res://scripts/creatures/ant_colony.gd") # (its Member: the same handle every colony's members have)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.001 ## m per model mm (life size)
const APART := 0.045 ## m: each keeps this far from its neighbours (about a body length: as a real swarm's) (its only neighbour checks: as the ants', a grid this fine)
const Z_HEAD := -26.0 ## mm: the rostrum's tip
const Z_TAIL := 25.0 ## mm: the tail fan's edge
const Z_HINGE := -3.0 ## mm: where the abdomen bends from the carapace
# what each is doing
const SWARM := 0
const FEED := 1
const ESCAPE := 2
const PILOT := 3
const HOLD := 4

var tank_min := Vector3(-0.5, 0.02, -0.5) ## the water (its own space): the bottom's corner
var tank_max := Vector3(0.5, 0.45, 0.5) ## and the surface's
var bottom: Callable ## (x, z) -> the bottom's y there (none: tank_min.y)
var cruise := 0.045 ## m/s, swarming
var escape_speed := 0.55 ## m/s, lobstering
var shader: Shader = preload("res://shaders/render/krill.gdshader")
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var heading := PackedVector3Array()
var seed := PackedFloat32Array()
var size := PackedFloat32Array()
var task := PackedInt32Array()
var task_t := PackedFloat32Array()
var aim := PackedVector3Array()
var pace := PackedFloat32Array()
var feed_k := PackedFloat32Array()
var flip_t := PackedFloat32Array() # (s into its escape: its tail flicks)
var flee_from := PackedVector3Array()
var goal := Vector3.ZERO ## where the swarm's making for
var rng := RandomNumberGenerator.new()
var _goal_t := 0.0
var _pilots := {}
var _members := {}
var _vs := PackedVector3Array()
var _mid := Vector3.ZERO # (the swarm's middle, this frame)
var _way := Vector3.FORWARD # (the way it faces)

static var _built: Mesh


func setup(n: int, centre: Vector3, spread := 0.08) -> void:
	rng.randomize()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	if _built == null:
		_built = build_mesh()
	multimesh.mesh = _built
	multimesh.instance_count = n
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("z_hinge", Z_HINGE * MM)
	m.set_shader_parameter("z_tail", Z_TAIL * MM)
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF # (small, see-through)
	# (each its own: packed arrays are values, resized one by one)
	pos.resize(n)
	vel.resize(n)
	heading.resize(n)
	aim.resize(n)
	flee_from.resize(n)
	_vs.resize(n)
	seed.resize(n)
	size.resize(n)
	task_t.resize(n)
	pace.resize(n)
	feed_k.resize(n)
	flip_t.resize(n)
	task.resize(n)
	var a := rng.randf() * TAU
	var way := Vector3(cos(a), 0.0, sin(a)) # (a swarm all facing the one way)
	for i in n:
		pos[i] = centre + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6), rng.randf_range(-1, 1)) * spread
		heading[i] = way
		vel[i] = way * cruise
		_vs[i] = vel[i]
		seed[i] = rng.randf()
		size[i] = rng.randf_range(0.8, 1.1)
		task[i] = SWARM
		task_t[i] = rng.randf_range(4.0, 20.0)
		pace[i] = -1.0
	goal = centre
	custom_aabb = AABB(tank_min - Vector3.ONE * 0.1, tank_max - tank_min + Vector3.ONE * 0.2)


## The swarm to `point` (its own space), swarming there.
func swim_to(point: Vector3) -> void:
	goal = point
	_goal_t = 20.0


## Every krill near `from` off in its escape: tail flicks, shooting backward.
func scatter(from: Vector3) -> void:
	for i in pos.size():
		if pos[i].distance_to(from) < 0.6:
			task[i] = ESCAPE
			task_t[i] = rng.randf_range(0.6, 1.1) # (a few flicks: a burst of half a metre or so)
			flip_t[i] = 0.0
			flee_from[i] = from


## Krill i stops to feed, its basket working, a while.
func feed(i: int, secs := -1.0) -> void:
	task[i] = FEED
	task_t[i] = secs if secs > 0.0 else rng.randf_range(4.0, 9.0)


func rejoin(i: int) -> void:
	task[i] = SWARM
	task_t[i] = rng.randf_range(4.0, 20.0)


func _floor(x: float, z: float) -> float:
	return maxf(float(bottom.call(x, z)) if bottom.is_valid() else tank_min.y, tank_min.y)


func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	for i in _pilots:
		(_pilots[i] as PilotScript).tick(dt)
	_goal_t -= dt
	if _goal_t <= 0.0:
		_goal_t = rng.randf_range(6.0, 14.0)
		var lo := tank_min + Vector3(0.1, 0.06, 0.1)
		var hi := tank_max - Vector3(0.1, 0.06, 0.1)
		goal = Vector3(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y), rng.randf_range(lo.z, hi.z))
	var n := pos.size()
	# the swarm as a whole, once a frame (cheap: no neighbour searches for
	# it): its middle and the way it faces, from the ones swarming
	var mid := Vector3.ZERO
	var way := Vector3.ZERO
	var m := 0
	for i in n:
		if task[i] == SWARM or task[i] == FEED:
			mid += pos[i]
			way += heading[i]
			m += 1
	_mid = mid / m if m > 0 else goal
	_way = way.normalized() if way.length() > 1e-4 else Vector3.FORWARD
	var grid := {}
	for i in n:
		var k := Vector3i(floori(pos[i].x / APART), floori(pos[i].y / APART), floori(pos[i].z / APART))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(i)
	for i in n:
		_steer(i, dt, grid)
	for i in n:
		_place(i, dt)


## Krill i's steering: its neighbours (apart, the same way, together), the
## swarm's goal, the water's walls; its own doing.
func _steer(i: int, dt: float, grid: Dictionary) -> void:
	var p := pos[i]
	var v := vel[i]
	task_t[i] -= dt
	# (apart from those right by it: the few in the cells round its own)
	var sep := Vector3.ZERO
	var c := Vector3i(floori(p.x / APART), floori(p.y / APART), floori(p.z / APART))
	for dz in range(-1, 2):
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for j: int in grid.get(c + Vector3i(dx, dy, dz), []):
					if j == i:
						continue
					var off := p - pos[j]
					var d := off.length()
					var keep := APART * size[i]
					if d < keep and d > 1e-6:
						sep += off / d * (keep - d) / keep
	var acc := sep * 1.8
	# (with the swarm: facing its way, toward its middle, the more the
	# further out)
	acc += (_way * cruise - v) * 1.0
	var to_mid := _mid - p
	var stray := to_mid.length()
	acc += to_mid * 1.2 * clampf(stray / 0.2, 0.2, 1.5)
	var want := cruise * (0.7 + 0.6 * seed[i])
	if stray > 0.25 and task[i] == SWARM: # (strayed, scattered: back to the others, quickly)
		acc += to_mid.normalized() * 0.6
		want = maxf(want, minf(0.04 + stray * 0.6, 0.2))
	match task[i]:
		SWARM:
			if p.distance_to(goal) > 0.06:
				acc += (goal - p).normalized() * 0.035
			if task_t[i] <= 0.0:
				task_t[i] = rng.randf_range(6.0, 20.0)
				if rng.randf() < 0.35:
					feed(i)
		FEED: # (hanging nearly still, its basket working)
			acc = acc * 0.5 - v * 1.5
			want = 0.0
			if task_t[i] <= 0.0:
				rejoin(i)
		ESCAPE: # (shot backward by each flick of its tail, away from it)
			flip_t[i] += dt
			var away := (p - flee_from[i])
			away = away.normalized() if away.length() > 1e-4 else -heading[i]
			var kick := maxf(sin(flip_t[i] * TAU * 3.0), 0.0) # (three flicks a second)
			away.y *= 0.3 # (mostly level: shot back through the water, not up or down)
			away = away.normalized()
			acc = away * escape_speed * 9.0 * kick - v * 2.0
			want = escape_speed
			if task_t[i] <= 0.0:
				rejoin(i)
		PILOT:
			var to := aim[i] - p
			var sp := pace[i] if pace[i] > 0.0 else cruise
			acc = acc * 0.3 + (to.normalized() * minf(sp, to.length() * 3.0) - v) * 3.0
			want = sp
		HOLD:
			acc = acc * 0.3 + (aim[i] - p) * 4.0 - v * 3.0
			want = 0.0
	feed_k[i] = move_toward(feed_k[i], 1.0 if task[i] == FEED else 0.0, dt * 1.5)
	# the walls, the bottom, the surface
	var lo := tank_min + Vector3(0.03, 0.0, 0.03)
	var hi := tank_max - Vector3(0.03, 0.02, 0.03)
	var fl := _floor(p.x, p.z) + 0.03
	var wall := Vector3.ZERO
	wall.x = maxf(lo.x - p.x, 0.0) - maxf(p.x - hi.x, 0.0)
	wall.z = maxf(lo.z - p.z, 0.0) - maxf(p.z - hi.z, 0.0)
	wall.y = maxf(fl - p.y, 0.0) - maxf(p.y - hi.y, 0.0)
	acc += wall * 40.0
	if task[i] == SWARM:
		acc.y -= v.y * 1.2 # (level, mostly)
	v += acc * dt
	var spd := v.length()
	var top := escape_speed if task[i] == ESCAPE else maxf(want * 1.6, 0.015)
	if spd > top:
		v *= top / spd
	vel[i] = v
	var np := p + v * dt
	np.x = clampf(np.x, tank_min.x, tank_max.x)
	np.z = clampf(np.z, tank_min.z, tank_max.z)
	np.y = clampf(np.y, _floor(np.x, np.z) + 0.006, tank_max.y - 0.006)
	pos[i] = np


## Krill i drawn where it is: facing its way (escaping, the way it faced:
## it goes backward), tipped head up feeding; its pose's numbers.
func _place(i: int, dt: float) -> void:
	var v := _vs[i].lerp(vel[i], 1.0 - exp(-4.0 * dt))
	_vs[i] = v
	var h := heading[i]
	var escaping := task[i] == ESCAPE
	if not escaping and v.length() > 0.008:
		var flat := Vector3(v.x, 0.0, v.z)
		if flat.length() > 1e-4:
			h = h.slerp(flat.normalized(), 1.0 - exp(-3.0 * dt)).normalized()
	elif escaping: # (its back to the threat... its tail to it: going backward, away)
		var away := Vector3(pos[i].x - flee_from[i].x, 0.0, pos[i].z - flee_from[i].z)
		if away.length() > 1e-4:
			h = h.slerp(-away.normalized(), 1.0 - exp(-8.0 * dt)).normalized()
	heading[i] = h
	var pitch := 0.0 if escaping else clampf(atan2(v.y, maxf(Vector2(v.x, v.z).length(), 0.01)), -0.4, 0.4) * 0.6
	pitch += 0.6 * feed_k[i] # (head up, feeding)
	var b := Basis.looking_at(h, Vector3.UP) * Basis(Vector3.RIGHT, pitch)
	multimesh.set_instance_transform(i, Transform3D(b * Basis.from_scale(Vector3.ONE * size[i]), pos[i]))
	var swim := clampf(v.length() / (cruise * 2.0), 0.0, 1.0)
	var curl := maxf(sin(flip_t[i] * TAU * 3.0), 0.0) if escaping else 0.0
	multimesh.set_instance_custom_data(i, Color(swim, feed_k[i], seed[i], curl))


# --- the mesh ----------------------------------------------------------------------

## The body's keys: [z, y, half width, half height] (mm): the carapace,
## then the abdomen, tapering to the tail fan.
const BODY := [[-26.0, 1.4, 0.3, 0.3], [-24.0, 1.2, 0.9, 0.9], [-21.0, 1.0, 2.1, 2.5], [-14.0, 0.8, 2.9, 3.3], [-6.0, 0.4, 2.9, 3.2],
		[-3.0, 0.2, 2.7, 3.0], [3.0, 0.0, 2.5, 2.8], [9.0, -0.2, 2.1, 2.4], [14.0, -0.4, 1.6, 1.9], [18.0, -0.6, 1.1, 1.3], [19.5, -0.6, 0.8, 0.9]]


static func _key(z: float) -> Vector4:
	for k in BODY.size() - 1:
		var a: Array = BODY[k]
		var b: Array = BODY[k + 1]
		if z <= float(b[0]):
			var f := clampf((z - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			return Vector4(lerpf(a[1], b[1], f), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f), 0.0)
	var l: Array = BODY[BODY.size() - 1]
	return Vector4(l[1], l[2], l[3], 0.0)


## (A vertex: CUSTOM0 its part, its way out along its limb 0..1, its index
## (a swimmeret's, a leg's, 0..1), 0; UV its limb's base (z, y: mm), m.)
static func _v(st: SurfaceTool, p: Vector3, n: Vector3, part: int, out := 0.0, idx := 0.0, base := Vector2.ZERO) -> void:
	st.set_normal(n)
	st.set_uv(base * MM)
	st.set_custom(0, Color(part, out, idx, 0.0))
	st.add_vertex(p * MM)


## A thin tube through pts (mm), radius r tapering to r * tip, `sides` round.
static func _tube(st: SurfaceTool, pts: Array, r: float, tip: float, part: int, idx: float, sides := 4) -> void:
	var base: Vector3 = pts[0]
	var rings := []
	for k in pts.size():
		var p: Vector3 = pts[k]
		var d: Vector3 = (pts[mini(k + 1, pts.size() - 1)] as Vector3) - (pts[maxi(k - 1, 0)] as Vector3)
		d = d.normalized()
		var x := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
		var y := x.cross(d)
		var rr := r * lerpf(1.0, tip, float(k) / (pts.size() - 1))
		var ring := []
		for s in sides + 1:
			var a := TAU * s / sides
			var o := x * cos(a) + y * sin(a)
			ring.append([p + o * rr, o, float(k) / (pts.size() - 1)])
		rings.append(ring)
	for k in rings.size() - 1:
		for s in sides:
			var q := [rings[k][s], rings[k][s + 1], rings[k + 1][s + 1], rings[k + 1][s]]
			for t: Array in [[0, 2, 1], [0, 3, 2]]:
				for e: int in t:
					var c: Array = q[e]
					_v(st, c[0], c[1], part, c[2], idx, Vector2(base.z, base.y))


## An ellipsoid (mm): centre, radii, part.
static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, part: int, idx := 0.0, U := 6, V := 4) -> void:
	var pt := func(i: int, j: int) -> Array:
		var th := PI * float(j) / V
		var ph := TAU * float(i) / U
		var u := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
		return [c + u * r, (u / r).normalized()]
	for i in U:
		for j in V:
			var a: Array = pt.call(i, j)
			var b: Array = pt.call(i + 1, j)
			var e: Array = pt.call(i + 1, j + 1)
			var d: Array = pt.call(i, j + 1)
			for t: Array in [[a, e, b], [a, d, e]]:
				for q: Array in t:
					_v(st, q[0], q[1], part, 0.0, idx, Vector2(c.z, c.y))


## The mesh, life size, in metres, facing -z; each vertex's part (krill.
## gdshader's): 0 the body, 1 an eye, 2 a swimmeret, 3 a thoracic leg (the
## basket), 4 an antenna or antennule, 5 a photophore, 6 the tail fan.
static func build_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	# the body: rings down it, oval, a little flat beneath
	const RING := 8
	const STEPS := 22
	var rings := []
	for s in STEPS + 1:
		var z := lerpf(Z_HEAD, 19.5, float(s) / STEPS)
		var k := _key(z)
		var ring := []
		for r in RING + 1:
			var a := TAU * r / RING
			var cx := sin(a)
			var cy := cos(a)
			var p := Vector3(cx * k.y, k.x + cy * k.z * (1.0 if cy > 0.0 else 0.85), z)
			ring.append([p, Vector3(cx / maxf(k.y, 0.2), cy / maxf(k.z, 0.2), 0.0).normalized()])
		rings.append(ring)
	for s in STEPS:
		for r in RING:
			var q := [rings[s][r], rings[s][r + 1], rings[s + 1][r + 1], rings[s + 1][r]]
			for t: Array in [[0, 1, 2], [0, 2, 3]]:
				for e: int in t:
					var c: Array = q[e]
					_v(st, c[0], c[1], 0)
	# the tail fan: the telson and the uropods, flat, spread
	_blob(st, Vector3(0.0, -0.6, 22.5), Vector3(0.5, 0.25, 3.2), 6)
	for side: float in [-1.0, 1.0]:
		_blob(st, Vector3(1.4 * side, -0.6, 22.0), Vector3(1.1, 0.2, 3.4), 6)
		_blob(st, Vector3(2.6 * side, -0.6, 21.5), Vector3(1.0, 0.2, 3.0), 6)
	# the eyes, big, black, on short stalks; a photophore on each stalk
	for side: float in [-1.0, 1.0]:
		_tube(st, [Vector3(0.8 * side, 1.4, -22.0), Vector3(1.9 * side, 1.7, -23.0)], 0.6, 1.0, 0, 0.0, 3)
		_blob(st, Vector3(2.3 * side, 1.8, -23.2), Vector3(1.6, 1.7, 1.6), 1, 0.0, 7, 5)
		_blob(st, Vector3(1.4 * side, 1.1, -22.4), Vector3(0.35, 0.35, 0.35), 5, 0.0, 4, 3)
	# the antennules (two pairs of short whips) and the antennae (long,
	# trailing back a little), their scales
	for side: float in [-1.0, 1.0]:
		for f: float in [0.0, 1.0]:
			_tube(st, [Vector3(0.6 * side, 1.4, -25.0), Vector3((0.9 + 0.5 * f) * side, 2.4 + f, -31.0), Vector3((1.4 + 1.0 * f) * side, 3.2 + 1.5 * f, -38.0)], 0.18, 0.4, 4, f, 3)
		var ant := [Vector3(1.3 * side, 0.2, -24.0)]
		var d := Vector3(0.5 * side, 0.15, -1.0).normalized()
		for k in 8:
			ant.append((ant[ant.size() - 1] as Vector3) + d * 6.0)
			d = d.rotated(Vector3.UP, -0.21 * side) # (out and round, back along it)
		_tube(st, ant, 0.2, 0.3, 4, 0.5, 3)
		_blob(st, Vector3(1.8 * side, 0.0, -26.5), Vector3(0.7, 0.15, 2.4), 0, 0.0, 4, 3)
	# the thoracic legs: six pairs, under the carapace, each with a fringe
	# of bristles, together the feeding basket
	for k in 6:
		var z := -19.0 + 2.2 * k
		for side: float in [-1.0, 1.0]:
			var b := Vector3(1.0 * side, -2.4, z)
			var pts := [b, b + Vector3(0.7 * side, -2.0, -1.0), b + Vector3(0.6 * side, -4.2, -2.4)] # (short, folded in under it)
			_tube(st, pts, 0.2, 0.5, 3, float(k) / 5.0, 3)
			var at: Vector3 = (pts[1] as Vector3)
			_tube(st, [at, at + Vector3(-0.8 * side, -0.6, -0.5)], 0.08, 0.5, 3, float(k) / 5.0, 3) # (its fringe of bristles, inward)
	# the swimmerets: five pairs under the abdomen, long, feathery
	for k in 5:
		var z := -1.0 + 4.0 * k
		var kk := _key(z)
		for side: float in [-1.0, 1.0]:
			var b := Vector3(0.9 * side, kk.x - kk.z * 0.8, z)
			var tip := b + Vector3(0.4 * side, -5.5, 1.5)
			_tube(st, [b, b.lerp(tip, 0.5), tip], 0.25, 0.4, 2, float(k) / 4.0, 3)
			for r: float in [-1.0, 1.0]: # (its two branches)
				_tube(st, [b.lerp(tip, 0.55), tip + Vector3(0.5 * r * side, -1.5, 1.2)], 0.12, 0.4, 2, float(k) / 4.0, 3)
	# the photophores: a pair under the thorax, four down the abdomen
	for z in [-15.0, -8.0]:
		for side: float in [-1.0, 1.0]:
			_blob(st, Vector3(1.2 * side, -2.5, z), Vector3(0.45, 0.45, 0.45), 5, 0.0, 4, 3)
	for z in [0.0, 4.0, 8.0, 12.0]:
		var kk := _key(z)
		_blob(st, Vector3(0.0, kk.x - kk.z * 0.95, z), Vector3(0.4, 0.4, 0.4), 5, 0.0, 4, 3)
	return st.commit()


# --- steering: a state machine's, each one on its own (pilot.gd) -------------------

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
	return 0.01


## feed {seconds}; flee {from}.
func _p_behaviours(_i: int) -> PackedStringArray:
	return PackedStringArray(["feed", "flee"])


func _p_act(i: int, name: String, args: Dictionary) -> bool:
	match name:
		"feed":
			feed(i, float(args.get("seconds", -1.0)))
		"flee":
			task[i] = ESCAPE
			task_t[i] = 1.8
			flip_t[i] = 0.0
			flee_from[i] = args.get("from", pos[i] + heading[i] * 0.1)
		_:
			return false
	return true


func _p_act_done(i: int, name: String) -> bool:
	match name:
		"feed":
			return task[i] != FEED
		"flee":
			return task[i] != ESCAPE
	return false


func _p_act_secs(_i: int, _name: String) -> float:
	return 6.0
