class_name AntColony
extends MultiMeshInstance3D
## Ants: black carpenter ants (Camponotus pennsylvanicus), workers, drawn at
## twice life size as the wasp is (about 24 mm long). Every ant one instance
## of one mesh, posed by its shader (ant.gdshader: walking, feeding), so a
## colony of hundreds is a draw call; here each is only moved along, as a
## whole, once a frame: where it is, which way it faces, how fast it walks
## and how far into feeding (the shader's INSTANCE_CUSTOM).
##
## Each ant's doing one of two things (no state machine yet: the caller
## says, e.g. tools/creatures/ant_demo):
## - wander(i, centre, radius): walking about, in a wandering line,
##   stopping now and then
## - feed(i, food): to the food (its own place round it), and feeding: head
##   down, mandibles working, antennae drumming, front legs on it; now and
##   then round to another place at it
## - lay(i, at): a beetle's (lays; not the ants): to the spot, and laying
##   there, tipped tail down, an egg left at its tip every few seconds,
##   shuffling a little between: a cluster of them (Brood's, egg_kind)
## - steered, each on its own (a state machine's: member(i), with every
##   creature's calls: go, go_to, face, stop, act (feed {at, seconds}; a
##   beetle's lay {at, seconds}, fly {centre, radius, height, seconds}),
##   behaviours, is_busy, action_finished: pilot.gd)
## They keep a little apart from one another. They walk on the ground the
## height callable gives (x, z -> y), flat at y 0 without one.
##
## Their walking is on the GPU (shaders/compute/ant_colony.glsl, on a local
## RenderingDevice): each frame every ant's mind here (_think: where to go,
## what to do; a beetle's flight, _air, its own), then its body there
## (turning, stepping on, kept apart, set on the ground: a height grid baked
## round the colony, baked again if they wander off it), read back the next
## frame (no stall), its transform with it. Without a RenderingDevice
## (headless, the Compatibility renderer) all of it here (_cpu_process).
##
## A black carpenter ant: a big heart-shaped head with elbowed antennae and
## toothed mandibles, a smoothly arched thorax, a single upright scale for
## its waist, an oval gaster, its segments edged faintly gold; dull black,
## the legs a dark reddish black.

const MM := 0.002 ## m drawn per model mm (twice life size)
const BODY_H := 1.5 ## mm an ant's thorax's middle stands over the ground

# (another kind of crawler made the same way sets these: Beetles)
var body_h := BODY_H ## mm its thorax's middle stands over the ground
var top_speed := 0.06 ## m/s, walking (an ant's 3 cm/s, twice life size)
var reach := 4.6 ## mm from its thorax's middle to its mouth
var apart := 9.0 ## mm they keep between them
var shader: Shader = preload("res://shaders/render/ant.gdshader")
const BroodScript := preload("res://scripts/creatures/brood.gd") # (by path: found whether or not the editor has seen the class yet)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
var colors := {} ## the shader's colours, its own (else an ant's)
var lays := false ## whether it lays (lay(): a beetle's; the ants don't)
var egg_kind := "carpenter" ## Brood's
var egg_back := 5.4 ## mm behind its middle its eggs come out
var lay_tilt := 0.0 ## rad it tips tail down laying
var eggs: Array[Node3D] = [] ## the eggs laid (in its parent), the oldest gone past a hundred

var height: Callable ## (x, z) -> the ground's y; none: 0
var pos := PackedVector3Array()
var yaw := PackedFloat32Array()
var speed := PackedFloat32Array() # m/s now
var task := PackedInt32Array() # 0 wandering, 1 feeding
var target := PackedVector3Array()
var centre := PackedVector3Array() # wandering: round here
var radius := PackedFloat32Array()
var food := PackedVector3Array() # feeding: at this
var slot := PackedFloat32Array() # feeding: its place round the food (rad)
var feed_k := PackedFloat32Array() # 0..1 into feeding
var wait := PackedFloat32Array() # s till it next changes its mind
var seed := PackedFloat32Array()
var pace := PackedFloat32Array() # m/s (its pilot's: <= 0 its own)
var _pilots := {} # i -> its pilot (pilot.gd)
var _members := {} # i -> Member
var lay_k := PackedFloat32Array() # 0..1 into laying
var lay_at := PackedVector3Array()
var lay_wait := PackedFloat32Array()
var rng := RandomNumberGenerator.new()
var _t := 0.0

# the rest pose's joints (m), for the shader
static var _built := {} # script path -> [mesh, pivots]


## n ants round c (within r), wandering.
func setup(n: int, c: Vector3, r: float) -> void:
	rng.randomize()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	var path: String = get_script().resource_path
	if not _built.has(path):
		_built[path] = _build_mesh()
	multimesh.mesh = _built[path][0]
	multimesh.instance_count = n
	var m := ShaderMaterial.new()
	m.shader = shader
	var pivots: Dictionary = _built[path][1]
	for k in pivots:
		m.set_shader_parameter(k, pivots[k])
	for k in colors:
		m.set_shader_parameter(k, colors[k])
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_resize(n)
	for i in n:
		var a := rng.randf() * TAU
		pos[i] = c + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * r
		yaw[i] = rng.randf() * TAU
		seed[i] = rng.randf()
		wander(i, c, r)
		target[i] = pos[i]
	custom_aabb = AABB(c - Vector3(r, 1.0, r) - Vector3.ONE, Vector3(r, 1.0, r) * 2.0 + Vector3.ONE * 2.0)


## Ant i walking about round c, within r (m).
## (Every one's state, for n of them.)
func _resize(n: int) -> void:
	pos.resize(n)
	target.resize(n)
	centre.resize(n)
	food.resize(n)
	yaw.resize(n)
	speed.resize(n)
	radius.resize(n)
	slot.resize(n)
	feed_k.resize(n)
	wait.resize(n)
	seed.resize(n)
	task.resize(n)
	lay_k.resize(n)
	lay_at.resize(n)
	lay_wait.resize(n)
	pace.resize(n)


## Another one (just out of its pupa, say): at `at` (its own space), facing
## yaw, wandering round there (within r). Its index.
func add(at: Vector3, yaw_ := 0.0, r := 0.05) -> int:
	var i := pos.size()
	_resize(i + 1)
	pos[i] = at
	yaw[i] = yaw_
	seed[i] = rng.randf()
	target[i] = at
	wander(i, at, r)
	multimesh.instance_count = i + 1 # (all placed again this frame)
	custom_aabb = custom_aabb.merge(AABB(at - Vector3.ONE * (r + 0.5), Vector3.ONE * (2.0 * r + 1.0)))
	return i


func wander(i: int, c: Vector3, r: float) -> void:
	task[i] = 0
	centre[i] = c
	radius[i] = r
	wait[i] = 0.0


## Beetle i to the spot `at`, and laying there (if it lays: not an ant).
func lay(i: int, at: Vector3) -> void:
	if not lays:
		return
	task[i] = 3
	lay_at[i] = at
	lay_wait[i] = rng.randf_range(1.5, 2.5)
	wait[i] = 0.0


## Ant i to the food at f, and feeding on it.
func feed(i: int, f: Vector3) -> void:
	task[i] = 1
	food[i] = f
	var d := pos[i] - f
	slot[i] = atan2(d.z, d.x)
	wait[i] = rng.randf_range(3.0, 7.0)


func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	if pos.size() < gpu_from: # (a small colony: cheaper here than the GPU's round trip)
		if _sub_n >= 0:
			_gpu_read()
		_cpu_process(dt)
		return
	if not _gpu_tried:
		_gpu_tried = true
		_gpu = _gpu_init()
	if not _gpu:
		_cpu_process(dt)
		return
	dt = minf(dt, 0.05)
	_t += dt
	for i in _pilots:
		(_pilots[i] as PilotScript).tick(dt)
	_gpu_read()
	var n := pos.size()
	_air_flags.resize(n)
	for i in n:
		if _air(i, dt): # (a beetle flying: its own; the GPU leaves it be)
			_air_flags[i] = 1
			continue
		_air_flags[i] = 0
		_think(i, dt)
	_gpu_submit(dt)


# --- on the GPU ------------------------------------------------------------------

## On the GPU from this many (fewer: here, its round trip dearer than they are).
var gpu_from := 150
const G_TABLE := 16384
const G_SLOTS := 16
const HM_RES := 96 ## the height grid's samples a side
var _gpu_tried := false
var _gpu := false
var _rd: RenderingDevice
var _g := {} # name -> RID
var _gset := RID()
var _cap := 0 # (the buffers' room, ants)
var _sub_n := -1 # (how many there were when last sent: -1 none pending)
var _air_flags := PackedInt32Array()
var _no_fly := PackedFloat32Array()
var _no_partner := PackedInt32Array()
var _hm := PackedFloat32Array()
var _hm_at := Vector4.ZERO # (corner x, z, step, samples a side)
var _hm_dirty := true
const _BUFS := ["pos_in", "pos_out", "yaw", "speed", "target", "food", "pace", "seed", "task", "feed_k", "lay_k", "fly", "air", "partner"]


func _gpu_init() -> bool:
	_rd = RenderingServer.create_local_rendering_device()
	if _rd == null:
		return false
	var spirv := compute_spirv(_rd, "res://shaders/compute/ant_colony.glsl")
	if spirv == null:
		_rd.free()
		_rd = null
		return false
	_g.shader = _rd.shader_create_from_spirv(spirv)
	_g.pipeline = _rd.compute_pipeline_create(_g.shader)
	_g.params = _rd.storage_buffer_create(12 * 4)
	_g.gcount = _rd.storage_buffer_create(G_TABLE * 4)
	_g.gslot = _rd.storage_buffer_create(G_TABLE * G_SLOTS * 4)
	_g.ctr = _rd.storage_buffer_create(16)
	_g.heights = _rd.storage_buffer_create(16)
	return true


## A compute shader compiled from its own source (path: a .glsl file), not
## its import (none needed: the editor may not have imported it, the
## .import files aren't kept). Its SPIR-V, or null (and why, pushed).
static func compute_spirv(rd: RenderingDevice, path: String) -> RDShaderSPIRV:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		var sf := load(path) as RDShaderFile if ResourceLoader.exists(path) else null # (an export with it imported)
		return sf.get_spirv() if sf else null
	var code := f.get_as_text()
	code = code.replace("#[compute]", "")
	var src := RDShaderSource.new()
	src.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	src.source_compute = code
	var spirv := rd.shader_compile_spirv_from_source(src)
	if spirv.compile_error_compute != "":
		push_error(path + ": " + spirv.compile_error_compute)
		return null
	return spirv


## (Its fly (a beetle's how far into flying) and its partners (a mating
## beetle's): an ant's none.)
func _fly_array() -> PackedFloat32Array:
	if _no_fly.size() != pos.size():
		_no_fly.resize(pos.size())
		_no_fly.fill(0.0)
	return _no_fly


func _partner_array() -> PackedInt32Array:
	if _no_partner.size() != pos.size():
		_no_partner.resize(pos.size())
		_no_partner.fill(-1)
	return _no_partner


## (The buffers made again with room for n.)
func _gpu_alloc(n: int) -> void:
	_cap = maxi(n + 16, int(n * 1.25))
	for k in _BUFS + ["out"]:
		if _g.has(k):
			_rd.free_rid(_g[k])
	var per := {"pos_in": 12, "pos_out": 12, "target": 12, "food": 12, "out": 64}
	for k in _BUFS + ["out"]:
		_g[k] = _rd.storage_buffer_create(_cap * int(per.get(k, 4)))
	_gpu_set()


func _gpu_set() -> void:
	var order := ["params", "pos_in", "pos_out", "yaw", "speed", "target", "food", "pace", "seed", "task", "feed_k", "lay_k", "fly", "air", "partner", "gcount", "gslot", "out", "heights", "ctr"]
	var us: Array[RDUniform] = []
	for b in order.size():
		var u := RDUniform.new()
		u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u.binding = b
		u.add_id(_g[order[b]])
		us.append(u)
	_gset = _rd.uniform_set_create(us, _g.shader, 0)


## The ground baked round where they are (and a good way out), for the GPU.
func _bake_ground() -> void:
	_hm_dirty = false
	if not height.is_valid() or pos.is_empty():
		_hm_at = Vector4.ZERO
		_hm = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	else:
		var lo := Vector2(INF, INF)
		var hi := -lo
		for i in pos.size():
			lo = lo.min(Vector2(pos[i].x, pos[i].z))
			hi = hi.max(Vector2(pos[i].x, pos[i].z))
			lo = lo.min(Vector2(centre[i].x - radius[i], centre[i].z - radius[i]))
			hi = hi.max(Vector2(centre[i].x + radius[i], centre[i].z + radius[i]))
		lo -= Vector2.ONE * 0.4
		hi += Vector2.ONE * 0.4
		var step := maxf(hi.x - lo.x, hi.y - lo.y) / (HM_RES - 1)
		_hm_at = Vector4(lo.x, lo.y, step, HM_RES)
		_hm.resize(HM_RES * HM_RES)
		for z in HM_RES:
			for x in HM_RES:
				_hm[z * HM_RES + x] = float(height.call(lo.x + x * step, lo.y + z * step))
	_rd.free_rid(_g.heights)
	var bytes := _hm.to_byte_array()
	_g.heights = _rd.storage_buffer_create(bytes.size(), bytes)
	_gpu_set()


## Last frame's walking taken up (where each is now, its way, its speed;
## its transform drawn).
func _gpu_read() -> void:
	if _sub_n < 0:
		return
	_rd.sync()
	var n := _sub_n
	_sub_n = -1
	if n != pos.size():
		return # (one added since: this frame's as they were)
	var moved := _rd.buffer_get_data(_g.pos_out, 0, n * 12).to_vector3_array()
	var air := _air_flags
	for i in n: # (those in the air the CPU's own, moved since)
		if air[i] == 0:
			pos[i] = moved[i]
	yaw = _rd.buffer_get_data(_g.yaw, 0, n * 4).to_float32_array()
	speed = _rd.buffer_get_data(_g.speed, 0, n * 4).to_float32_array()
	RenderingServer.multimesh_set_buffer(multimesh.get_rid(), _rd.buffer_get_data(_g.out, 0, n * 64).to_float32_array())
	if _rd.buffer_get_data(_g.ctr, 0, 4).to_int32_array()[0] > 0:
		_hm_dirty = true


func _gpu_submit(dt: float) -> void:
	var n := pos.size()
	if n == 0:
		return
	if n > _cap:
		_gpu_alloc(n)
	if _hm_dirty:
		_bake_ground()
	var up := {"pos_in": pos.to_byte_array(), "yaw": yaw.to_byte_array(), "speed": speed.to_byte_array(),
			"target": target.to_byte_array(), "food": food.to_byte_array(), "pace": pace.to_byte_array(),
			"seed": seed.to_byte_array(), "task": task.to_byte_array(), "feed_k": feed_k.to_byte_array(),
			"lay_k": lay_k.to_byte_array(), "fly": _fly_array().to_byte_array(), "air": _air_flags.to_byte_array(),
			"partner": _partner_array().to_byte_array()}
	for k in up:
		var b: PackedByteArray = up[k]
		_rd.buffer_update(_g[k], 0, b.size(), b)
	var prm := PackedFloat32Array([dt, _t, float(n), top_speed, apart * MM, body_h * MM, lay_tilt, 0.0,
			_hm_at.x, _hm_at.y, _hm_at.z, _hm_at.w])
	_rd.buffer_update(_g.params, 0, prm.size() * 4, prm.to_byte_array())
	var cl := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(cl, _g.pipeline)
	_rd.compute_list_bind_uniform_set(cl, _gset, 0)
	for pass_ in 3:
		var pc := PackedInt32Array([pass_, 0, 0, 0]).to_byte_array()
		_rd.compute_list_set_push_constant(cl, pc, pc.size())
		_rd.compute_list_dispatch(cl, ceili((G_TABLE if pass_ == 0 else n) / 64.0), 1, 1)
		_rd.compute_list_add_barrier(cl)
	_rd.compute_list_end()
	_rd.submit()
	_sub_n = n


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rd:
		if _sub_n >= 0:
			_rd.sync()
		for k in _g:
			if k != "shader" and k != "pipeline":
				_rd.free_rid(_g[k])
		_rd.free_rid(_g.pipeline)
		_rd.free_rid(_g.shader)
		_rd.free()
		_rd = null


## (All of it here: without the GPU.)
func _cpu_process(dt: float) -> void:
	_t += dt
	for i in _pilots:
		(_pilots[i] as PilotScript).tick(dt)
	var n := pos.size()
	# who's near whom (a grid of cells APART across): to keep apart
	var cell := apart * MM
	var grid := {}
	for i in n:
		var k := Vector2i(floori(pos[i].x / cell), floori(pos[i].z / cell))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(i)
	for i in n:
		if _air(i, dt): # (a beetle flying: moved there, not walking)
			continue
		_think(i, dt)
		var fwd := Vector3(-sin(yaw[i]), 0.0, -cos(yaw[i]))
		var to := target[i] - pos[i]
		to.y = 0.0
		var d := to.length()
		var want := speed[i]
		if d > 0.0012:
			# a wandering line: weaving a little either side of the way
			var wiggle := (sin(_t * 2.3 + seed[i] * 40.0) * 0.35 + sin(_t * 5.1 + seed[i] * 13.0) * 0.15) * clampf(d / 0.03, 0.0, 1.0)
			var a := atan2(-to.x, -to.z) + wiggle
			var turn := wrapf(a - yaw[i], -PI, PI)
			yaw[i] += clampf(turn, -6.0 * dt, 6.0 * dt)
			var own := pace[i] if pace[i] > 0.0 else top_speed * (0.75 + 0.5 * seed[i])
			want = minf(own, d * 5.0) * clampf(1.0 - absf(turn) / 1.3, 0.0, 1.0)
		else:
			want = 0.0
			if task[i] == 1: # (at the food: facing it)
				var f := food[i] - pos[i]
				var turn := wrapf(atan2(-f.x, -f.z) - yaw[i], -PI, PI)
				yaw[i] += clampf(turn, -4.0 * dt, 4.0 * dt)
		speed[i] = move_toward(speed[i], want, dt * 0.6)
		var p := pos[i] + fwd * speed[i] * dt
		# keeping apart: a push from any too near (at food hardly: they
		# crowd round it)
		var crowd := 0.08 if task[i] == 1 and Vector2(p.x - food[i].x, p.z - food[i].z).length() < 0.04 else 1.0
		var k := Vector2i(floori(p.x / cell), floori(p.z / cell))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for j in grid.get(k + Vector2i(dx, dz), []):
					if j == i or _together(i, j):
						continue
					var off := p - pos[j]
					off.y = 0.0
					var l := off.length()
					if l < cell and l > 1e-6:
						p += off / l * minf((cell - l) * minf(dt * 6.0, 0.5), top_speed * 0.4 * dt) * crowd # (never faster than they walk: a band going the same way shoved itself back)
		p.y = height.call(p.x, p.z) if height.is_valid() else 0.0
		pos[i] = p
		var at := Transform3D(Basis(Vector3.UP, yaw[i]) * Basis(Vector3.RIGHT, lay_tilt * lay_k[i]), p + Vector3.UP * body_h * MM)
		multimesh.set_instance_transform(i, at)
		# (laying: told the shader as feeding's negative)
		multimesh.set_instance_custom_data(i, Color(clampf(speed[i] / top_speed, 0.0, 1.0), feed_k[i] - lay_k[i], seed[i], _fly_of(i)))


## (Whether i and j are together, not kept apart: a mating pair's.)
func _together(_i: int, _j: int) -> bool:
	return false


## A flyer's (Beetles): whether i's in the air, moved there (true: not
## walking); an ant never is.
func _air(_i: int, _dt: float) -> bool:
	return false


## A flyer's: how far into flying i's pose is (the shader's), 0 an ant's.
func _fly_of(_i: int) -> float:
	return 0.0


## Where ant i's making for, as it's doing.
func _think(i: int, dt: float) -> void:
	wait[i] -= dt
	if task[i] != 3:
		lay_k[i] = move_toward(lay_k[i], 0.0, dt * 2.0)
	if task[i] == 3:
		_lay_step(i, dt)
		return
	if task[i] == 4: # (its pilot's: going where it's sent, or holding)
		feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
		return
	if task[i] == 0:
		feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
		if wait[i] <= 0.0 or (pos[i].distance_to(target[i]) < 0.002 and wait[i] > 1.0):
			if rng.randf() < 0.3:
				# a stop, to feel about
				target[i] = pos[i]
				wait[i] = rng.randf_range(0.4, 1.5)
			else:
				var a := rng.randf() * TAU
				target[i] = centre[i] + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * radius[i]
				wait[i] = rng.randf_range(2.0, 6.0)
		return
	# feeding: at its place round the food, its mouth on it
	var at := food[i] + Vector3(cos(slot[i]), 0.0, sin(slot[i])) * reach * MM
	target[i] = at
	var there := Vector2(pos[i].x - at.x, pos[i].z - at.z).length() < 0.003
	feed_k[i] = move_toward(feed_k[i], 1.0 if there and speed[i] < 0.015 else 0.0, dt * 2.0)
	if wait[i] <= 0.0:
		# round to another place at it
		slot[i] += rng.randf_range(0.6, 1.8) * (1.0 if rng.randf() < 0.5 else -1.0)
		wait[i] = rng.randf_range(3.0, 7.0)


## Laying: at the spot (shuffling a little about it), the gaster under,
## an egg out at its tip now and then.
func _lay_step(i: int, dt: float) -> void:
	feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
	if wait[i] <= 0.0:
		var a := rng.randf() * TAU
		target[i] = lay_at[i] + Vector3(cos(a), 0.0, sin(a)) * rng.randf() * 1.5 * MM
		wait[i] = rng.randf_range(4.0, 8.0)
	var there := Vector2(pos[i].x - target[i].x, pos[i].z - target[i].z).length() < 0.003 and speed[i] < 0.01
	lay_k[i] = move_toward(lay_k[i], 1.0 if there else 0.0, dt * 1.5)
	if lay_k[i] > 0.9:
		lay_wait[i] -= dt
		if lay_wait[i] <= 0.0:
			lay_wait[i] = rng.randf_range(2.0, 3.5)
			_drop_egg(i)


## An egg at ant i's tip, on the ground.
func _drop_egg(i: int) -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var back := Basis(Vector3.UP, yaw[i]) * Vector3(rng.randf_range(-0.6, 0.6), 0.0, egg_back + rng.randf_range(-0.5, 0.5)) * MM
	var p := pos[i] + back
	p.y = height.call(p.x, p.z) if height.is_valid() else pos[i].y
	var e := BroodScript.egg(egg_kind)
	parent.add_child(e)
	e.global_transform = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), global_transform * p)
	eggs.append(e)
	if eggs.size() > 100:
		eggs.pop_front().queue_free()


# --- steering: a state machine's, each one on its own (pilot.gd) -------------------

## Ant (or beetle) i, to steer: its calls (go, go_to, face, stop, act,
## behaviours, is_busy, action_finished) as every creature's.
func member(i: int) -> Member:
	if not _members.has(i):
		var m := Member.new()
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
	return Vector3(-sin(yaw[i]), 0.0, -cos(yaw[i]))


func _p_steer(i: int, point: Vector3, speed: float) -> void:
	task[i] = 4
	target[i] = point
	pace[i] = speed


func _p_hold(i: int) -> void:
	task[i] = 4
	target[i] = pos[i]
	centre[i] = pos[i] # (a flyer comes down here)
	radius[i] = 0.01
	pace[i] = -1.0


func _p_mobile(_i: int) -> bool:
	return true


func _p_speed(_i: int) -> float:
	return top_speed


func _p_reach(_i: int) -> float:
	return 0.004 + apart * MM * 0.5


## feed {at, seconds}; a beetle's lay {at, seconds}, fly {centre, radius,
## height, seconds}.
func _p_behaviours(_i: int) -> PackedStringArray:
	return PackedStringArray(["feed", "lay"]) if lays else PackedStringArray(["feed"])


func _p_act(i: int, name: String, args: Dictionary) -> bool:
	match name:
		"feed":
			feed(i, args.get("at", pos[i] + _p_heading(i) * 0.01))
		"lay":
			if not lays:
				return false
			lay(i, args.get("at", pos[i]))
		_:
			return false
	return true


func _p_act_done(_i: int, _name: String) -> bool:
	return false


func _p_act_secs(_i: int, name: String) -> float:
	return 12.0 if name == "lay" else 8.0


## One of a colony, steered on its own (AntColony.member(i)).
class Member extends RefCounted:
	signal action_finished(name: String, ok: bool)
	var colony: Object
	var i := 0

	func _pilot() -> RefCounted:
		return colony.get("_pilots")[i]

	func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
		_pilot().call("go", direction, speed, seconds)

	func go_to(point: Vector3, speed := -1.0) -> void:
		_pilot().call("go_to", point, speed)

	func face(direction: Vector3) -> void:
		_pilot().call("face", direction)

	func stop() -> void:
		_pilot().call("stop")

	func act(name: String, args := {}) -> bool:
		return _pilot().call("act", name, args)

	func behaviours() -> PackedStringArray:
		return colony.call("_p_behaviours", i)

	func is_busy() -> bool:
		return _pilot().call("busy")

	## Where it is now.
	func position() -> Vector3:
		return colony.call("_p_here", i)


## A crumb of food (a sugar crumb, say), for them to feed on: about 3 mm
## (twice life size), its origin at its foot.
static func crumb() -> Node3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 8
	s.rings = 5
	mi.mesh = s
	mi.scale = Vector3(0.007, 0.0045, 0.006)
	mi.position.y = 0.0018
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.9, 0.82)
	m.roughness = 0.5
	mi.material_override = m
	var root := Node3D.new()
	root.add_child(mi)
	return root


# --- the mesh ------------------------------------------------------------------

## A black carpenter ant (a major worker), the body as smooth shells
## lofted along it (mm, the mesosoma's middle at the origin, -z forward):
## each a list of keys [z, y (its middle), half width, half height], one
## after another along it; sq how square its cross-sections are (2 round,
## more: squarer). The gaster's segments (gaster_bands: where each ends, z)
## each a little wider at its back edge, lapping over the next, edged with
## fine golden hairs. legs as the beetles' (the right side's: hip, femur,
## tibia, tarsus (mm), home: the foot at rest, x z).
const CARPENTER := {
	"head_at": Vector3(0.0, 0.25, -1.75), # (the neck's front: the head's keys from here)
	"head": [[0.15, 0.0, 0.18, 0.18], [0.0, 0.05, 0.85, 0.7], [-0.3, 0.05, 1.2, 0.95], [-0.9, 0.0, 1.3, 1.0],
			[-1.5, -0.1, 1.15, 0.85], [-2.0, -0.25, 0.85, 0.6], [-2.35, -0.38, 0.48, 0.34], [-2.5, -0.42, 0.1, 0.1]],
	"head_sq": 2.2,
	"head_lobes": true, # (heart-shaped: its back corners full, notched between)
	"eye": [Vector3(1.12, 0.3, -1.3), Vector3(0.42, 0.62, 0.58)],
	"mandible": Vector3(0.4, 0.3, 1.0), # (its blade's size)
	"teeth": 0,
	"beard": false,
	"antenna_at": Vector3(0.45, 0.4, -2.3), "scape": 2.2, "funiculus": [4, 0.65, 0.08],
	"meso": [[-1.85, 0.0, 0.14, 0.14], [-1.6, 0.1, 0.45, 0.45], [-1.2, 0.2, 0.78, 0.72], [-0.7, 0.3, 0.8, 0.8],
			[-0.1, 0.32, 0.64, 0.74], [0.5, 0.25, 0.55, 0.66], [1.0, 0.12, 0.56, 0.6], [1.35, 0.0, 0.42, 0.45], [1.55, -0.05, 0.12, 0.15]],
	"meso_sq": 2.0,
	"spines": [], # (a propodeum's: [base, tip] each, the right one's)
	"waist": [[Vector3(0.0, -0.15, 1.6), Vector3(0.5, 0.45, 0.5)], [Vector3(0.0, 0.08, 1.7), Vector3(0.95, 1.2, 0.36)]], # (one upright scale)
	"gaster_at": Vector3(0.0, -0.05, 2.0),
	"gaster": [[1.95, 0.0, 0.16, 0.16], [2.15, 0.05, 0.6, 0.55], [2.6, 0.08, 1.05, 0.95], [3.3, 0.05, 1.3, 1.15], [4.1, -0.05, 1.32, 1.17],
			[4.9, -0.15, 1.15, 1.02], [5.6, -0.3, 0.78, 0.7], [6.0, -0.38, 0.3, 0.28], [6.15, -0.4, 0.05, 0.05]],
	"gaster_bands": [2.15, 2.95, 3.85, 4.75, 5.5],
	"legs": [
		{"hip": Vector3(0.35, -0.75, -0.95), "f": 2.3, "t": 2.0, "s": 2.0, "home": Vector2(3.6, -4.4)},
		{"hip": Vector3(0.45, -0.75, 0.15), "f": 2.6, "t": 2.4, "s": 2.3, "home": Vector2(5.2, 0.4)},
		{"hip": Vector3(0.5, -0.7, 0.95), "f": 3.2, "t": 3.0, "s": 2.9, "home": Vector2(4.8, 5.6)},
	],
	"leg_r": 0.17,
}
var ant := CARPENTER ## its shape (the species': CARPENTER, or a HarvesterAnts')


## The ant at rest, standing (in metres): every part tagged for the shader
## (CUSTOM0: its part, its segment, along it, banded); its joints noted (the
## shader's uniforms): [mesh, pivots]. (Another crawler: its own.)
func _build_mesh() -> Array:
	var A: Dictionary = ant
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 14
	sphere.rings = 8
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	var S := sphere.get_mesh_arrays()
	var C := cyl.get_mesh_arrays()
	var ball := func(at: Vector3, size: Vector3, part: int, b := Basis(), seg := 0) -> void:
		_add(st, S, Transform3D(b * Basis.from_scale(size), at), part, seg, false)
	var stick := func(a: Vector3, b: Vector3, r: float, part: int, seg := 0) -> void:
		_add(st, C, _seg(a, b, r), part, seg, false)
	# a limb's segment: a spindle from a to b, r thick at its middle
	var limb := func(a: Vector3, b: Vector3, r: float, part: int, seg := 0) -> void:
		_add(st, S, _seg(a, b, r), part, seg, false)
	# the mesosoma, the waist, the gaster
	_loft(st, A.meso, Vector3.ZERO, A.meso_sq, 0, 16, 28)
	for sp: Array in A.spines:
		for side: float in [-1.0, 1.0]:
			var b0: Vector3 = sp[0]
			var b1: Vector3 = sp[1]
			limb.call(Vector3(b0.x * side, b0.y, b0.z), Vector3(b1.x * side, b1.y, b1.z), 0.09, 0)
	for w: Array in A.waist:
		ball.call(w[0], w[1], 0)
	var gat: Vector3 = A.gaster_at
	_loft(st, A.gaster, Vector3.ZERO, 2.0, 14, 18, 44, A.gaster_bands)
	# the head
	var h: Vector3 = A.head_at
	_loft(st, A.head, h, A.head_sq, 1, 16, 26)
	if A.head_lobes: # (heart-shaped: the back corners full)
		for side: float in [-1.0, 1.0]:
			ball.call(h + Vector3(0.62 * side, 0.12, -0.45), Vector3(1.15, 1.45, 1.15), 1)
	var sockets := []
	var elbows := []
	var mands := []
	var head_end: float = (A.head[A.head.size() - 1] as Array)[0]
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		var eo: Vector3 = A.eye[0]
		ball.call(h + Vector3(eo.x * side, eo.y, eo.z), A.eye[1], 15)
		# a mandible: a blade from its pivot, closed across the front, its
		# teeth along its inner edge
		var mp := h + Vector3(0.45 * side, -0.52, head_end + 0.2)
		mands.append(mp)
		var mb := Basis(Vector3.UP, 0.45 * side)
		var msz: Vector3 = A.mandible
		ball.call(mp + mb * Vector3(0.0, 0.0, -msz.z * 0.45), msz, 2 + s, mb)
		for k in int(A.teeth):
			var tp := mp + mb * Vector3(-msz.x * 0.45 * side, 0.0, -msz.z * (0.3 + 0.18 * k))
			ball.call(tp, Vector3(0.16, 0.14, 0.12), 2 + s)
		# an antenna: the scape up, out and forward; the funiculus elbowed
		# down and forward, its last segment thickest
		var ao: Vector3 = A.antenna_at
		var base := h + Vector3(ao.x * side, ao.y, ao.z)
		var elbow := base + _dir(0.5, 0.75, side) * float(A.scape)
		sockets.append(base)
		elbows.append(elbow)
		limb.call(base, elbow, 0.1, 4 + s)
		var fn: Array = A.funiculus
		var p: Vector3 = elbow
		var fp := -0.25
		for k in int(fn[0]):
			var q := p + _dir(0.15, fp, side) * float(fn[1])
			limb.call(p, q, float(fn[2]) * (1.4 if k == int(fn[0]) - 1 else 1.0), 6 + s)
			p = q
			fp -= 0.12
	if A.beard: # (a harvester's psammophore: a basket of long hairs under the head, for carrying sand)
		for k in 14:
			var z := -0.5 - 0.09 * k
			var x := (0.35 + 0.1 * (k % 3)) * (1.0 if k % 2 == 0 else -1.0)
			var r0 := h + Vector3(x, -0.62, z)
			stick.call(r0, r0 + Vector3(x * 0.25, -0.55, -0.25), 0.035, 1)
	# the legs, standing: each foot at its home on the ground, the knee up
	# and out in its own leg's plane (the two-bone reach); the femur a
	# spindle, the tibia slimmer, the tarsus jointed, its claws
	var hips := []
	var knees := []
	var dirs := []
	var up := Vector3.UP
	var lr: float = A.leg_r
	for i in 6:
		var pair := i / 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var L: Dictionary = A.legs[pair]
		var hip0 := Vector3(L.hip.x * side, L.hip.y, L.hip.z)
		var hip := hip0 + Vector3(0.35 * side, -0.25, 0.0)
		var home: Vector2 = L.home
		var foot := Vector3(home.x * side, -body_h + 0.08, home.y)
		var out := Vector3(foot.x - hip.x, 0.0, foot.z - hip.z).normalized()
		var ankle := foot + (-out * 0.9 + up * 0.42) * float(L.s)
		var aout := Vector3(ankle.x - hip.x, 0.0, ankle.z - hip.z).normalized()
		var knee := _knee(hip, ankle, L.f, L.t, up + aout * 0.6)
		limb.call(hip0, hip + (hip - hip0) * 0.15, lr * 1.5, 8 + i, 0)
		limb.call(hip - (knee - hip) * 0.06, knee + (knee - hip) * 0.04, lr * 1.15, 8 + i, 1)
		limb.call(knee, ankle, lr * 0.75, 8 + i, 2)
		var tp := ankle
		for k in 4:
			var tq := ankle.lerp(foot, float(k + 1) / 4.0) + up * sin(PI * float(k + 1) / 4.0) * float(L.s) * 0.06
			limb.call(tp, tq, lr * 0.5, 8 + i, 3)
			tp = tq
		for k in 2:
			stick.call(foot, foot + (out + Vector3(0.3 * (k * 2 - 1), -0.6, 0.0)).normalized() * 0.18, 0.03, 8 + i, 3)
		hips.append(hip0 * MM)
		knees.append(knee * MM)
		dirs.append(out)
	var pivots := {
		"hips": PackedVector3Array(hips), "knees": PackedVector3Array(knees), "leg_dirs": PackedVector3Array(dirs),
		"sockets": PackedVector3Array(sockets.map(func(v): return v * MM)), "elbows": PackedVector3Array(elbows.map(func(v): return v * MM)),
		"mand_pivots": PackedVector3Array(mands.map(func(v): return v * MM)), "neck": (h + Vector3(0.0, -0.1, 0.1)) * MM,
		"petiole": gat * MM,
	}
	st.generate_tangents()
	return [st.commit(), pivots]


## A smooth shell lofted through keys ([z, y, half width, half height]
## each, mm, off `at`), ring_n round, `steps` rings along it (the keys
## eased between: Catmull-Rom); sq how square its cross-sections (2 round);
## part's. bands (z's, ascending: a gaster's segments' edges): each segment
## a little wider at its back, lapping over the next (band_z: 0.5 at its
## back edge, the shader's golden hairs there).
static func _loft(st: SurfaceTool, keys: Array, at: Vector3, sq: float, part: int, ring_n: int, steps: int, bands := []) -> void:
	var K := keys.size()
	var pts := []
	var bz := []
	var key_at := func(j: int, c: int) -> float:
		return float((keys[clampi(j, 0, K - 1)] as Array)[c])
	for i in steps + 1:
		var t := float(i) / steps * (K - 1)
		var j := mini(int(t), K - 2)
		var f := t - j
		var v := [0.0, 0.0, 0.0, 0.0]
		for c in 4:
			var p0: float = key_at.call(j - 1, c)
			var p1: float = key_at.call(j, c)
			var p2: float = key_at.call(j + 1, c)
			var p3: float = key_at.call(j + 2, c)
			v[c] = 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)
		var z: float = v[0]
		# a gaster's segment: how far along it, its back edge a little fuller
		var share := -1.0
		for b in bands.size() - 1:
			var z0: float = bands[b]
			var z1: float = bands[b + 1]
			if z >= z0 and z < z1:
				share = (z - z0) / (z1 - z0)
		var lap := 1.0 + (0.045 * share * share if share >= 0.0 else 0.0)
		var ring := []
		for k in ring_n:
			var a := TAU * k / ring_n
			var ca := cos(a)
			var sa := sin(a)
			var cx := signf(ca) * pow(absf(ca), 2.0 / sq)
			var sy := signf(sa) * pow(absf(sa), 2.0 / sq)
			ring.append(at + Vector3(float(v[2]) * cx * lap, float(v[1]) + float(v[3]) * sy * lap, z))
		pts.append(ring)
		bz.append(share - 0.5 if share >= 0.0 else -1.0)
	# normals: across the grid (outward: away from the ring's middle)
	var normal := func(i: int, k: int) -> Vector3:
		var r: Array = pts[i]
		var pa: Vector3 = (pts[mini(i + 1, steps)] as Array)[k]
		var pb: Vector3 = (pts[maxi(i - 1, 0)] as Array)[k]
		var pc: Vector3 = r[(k + 1) % ring_n]
		var pd: Vector3 = r[(k - 1 + ring_n) % ring_n]
		var n := (pa - pb).cross(pc - pd)
		var mid := Vector3(at.x, (r[0] as Vector3).y * 0.5 + (r[ring_n / 2] as Vector3).y * 0.5, (r[0] as Vector3).z)
		var p: Vector3 = r[k]
		if n.dot(p - mid) < 0.0:
			n = -n
		return n.normalized() if n.length_squared() > 1e-12 else (p - mid).normalized()
	var put := func(i: int, k: int) -> void:
		var p: Vector3 = (pts[i] as Array)[k % ring_n]
		st.set_normal(normal.call(i, k % ring_n))
		st.set_uv(Vector2.ZERO)
		st.set_custom(0, Color(part, 0, bz[i], 1.0 if float(bz[i]) > -0.75 else 0.0))
		st.add_vertex(p * MM)
	for i in steps:
		for k in ring_n:
			# (each triangle turned to face out: a front face is clockwise,
			# its normal along -cross(b - a, c - a))
			var quad := [[i, k], [i + 1, k], [i + 1, k + 1], [i, k + 1]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var q0: Array = quad[tri[0]]
				var q1: Array = quad[tri[1]]
				var q2: Array = quad[tri[2]]
				var a: Vector3 = (pts[q0[0]] as Array)[int(q0[1]) % ring_n]
				var b: Vector3 = (pts[q1[0]] as Array)[int(q1[1]) % ring_n]
				var c: Vector3 = (pts[q2[0]] as Array)[int(q2[1]) % ring_n]
				var face := -(b - a).cross(c - a)
				var want: Vector3 = normal.call(q0[0], int(q0[1]) % ring_n) + normal.call(q1[0], int(q1[1]) % ring_n) + normal.call(q2[0], int(q2[1]) % ring_n)
				if face.dot(want) >= 0.0:
					put.call(q0[0], q0[1])
					put.call(q1[0], q1[1])
					put.call(q2[0], q2[1])
				else:
					put.call(q0[0], q0[1])
					put.call(q2[0], q2[1])
					put.call(q1[0], q1[1])


## A primitive's arrays (a unit sphere or cylinder) into st, placed by xf
## (model mm; made metres), tagged.
static func _add(st: SurfaceTool, arrays: Array, xf: Transform3D, part: int, seg: int, banded: bool) -> void:
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	var verts := []
	for k in vs.size():
		verts.append([(xf * vs[k]) * MM, (nb * ns[k]).normalized(), uvs[k], vs[k].z])
	for k in idx:
		var v: Array = verts[k]
		st.set_normal(v[1])
		st.set_uv(v[2])
		st.set_custom(0, Color(part, seg, v[3], 1.0 if banded else 0.0))
		st.add_vertex(v[0])


## A unit cylinder's placing to span a to b, radius r.
static func _seg(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d := b - a
	if d.length() < 1e-4:
		d = Vector3.UP * 1e-4
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD) if absf(y.z) < 0.9 else y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * 2.0 * r, d, z * 2.0 * r), (a + b) * 0.5)


static func _dir(yaw_a: float, pitch: float, side: float) -> Vector3:
	return Vector3(sin(yaw_a) * side * cos(pitch), sin(pitch), -cos(yaw_a) * cos(pitch))


static func _knee(hip: Vector3, ankle: Vector3, f: float, t: float, pole: Vector3) -> Vector3:
	var d := ankle - hip
	var l := clampf(d.length(), absf(f - t) + 0.01, f + t - 0.01)
	var dir := d.normalized() if d.length() > 1e-4 else Vector3.DOWN
	var a := (f * f - t * t + l * l) / (2.0 * l)
	var hh := sqrt(maxf(f * f - a * a, 0.0))
	var p := pole - dir * pole.dot(dir)
	p = p.normalized() if p.length() > 1e-4 else Vector3.UP
	return hip + dir * a + p * hh
