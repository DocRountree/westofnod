class_name Krill
extends Node3D
## Antarctic krill (Euphausia superba), life size (about 4 cm): slender,
## see-through red, flecked darker (their chromatophores); the green of the
## gut showing through behind the head; big black eyes on stalks; long
## antennae and antennules; the thoracic legs, fringed with bristles,
## folded into a feeding basket under the head; five pairs of feathery
## swimmerets; the tail fan; and the photophores, little lights under the
## body and on the eyestalks, glowing blue-green (brighter in the dark).
##
## A pool of them: every krill in a body of water, one node (add(n, centre,
## spread) puts more in: a swarm). No swarm is a thing of its own: each
## krill steers by its own neighbours only (apart from the very nearest,
## facing the way the ones round it face, toward them), the water's slow
## currents carrying them about; so swarms are whatever clusters form,
## joining when they drift together, breaking apart when they're scattered
## or the current parts them.
##
## On the GPU (shaders/compute/krill_swarm.glsl, on a local RenderingDevice:
## a hashed neighbour grid, then each krill steered; one frame behind,
## read back as two MultiMeshes' buffers, whole): thousands at well under a
## millisecond. Drawn as two MultiMeshes: the near (build_mesh: legs,
## bristles, swimmerets) and, past FAR m from the camera, the far
## (build_far_mesh: the body, the eyes, the fan), each posed by
## shaders/render/krill.gdshader (the swimmerets beating, the basket
## working, the tail flicked under). Without a RenderingDevice (headless,
## the Compatibility renderer) the same rules run here, slower.
##
## Each krill: swarming; feeding (feed_near: head up, the basket thrown open
## and swept shut), of its own accord now and then too; its escape
## (scatter(from): "lobstering", tail flicks shooting it backward away);
## sent somewhere (swim_to(to, from, r): those near `from`).

const MM := 0.001 ## m per model mm (life size)
const APART := 0.045 ## m: each keeps this far from its neighbours (about a body length)
const REACH := 0.15 ## m: the neighbours each steers by
const FAR := 1.2 ## m from the camera: past this, the far mesh
const Z_HEAD := -26.0 ## mm: the rostrum's tip
const Z_TAIL := 25.0 ## mm: the tail fan's edge
const Z_HINGE := -3.0 ## mm: where the abdomen bends from the carapace
const STRIDE := 28 ## floats a krill's state (7 vec4: krill_swarm.glsl's Krill)
const TABLE := 65536 ## the GPU grid's buckets
const SLOTS := 24 ## krill a bucket holds

var tank_min := Vector3(-0.5, 0.02, -0.5) ## the water (its own space): the bottom's corner
var tank_max := Vector3(0.5, 0.45, 0.5) ## and the surface's
var cruise := 0.045 ## m/s, swarming
var escape_speed := 0.55 ## m/s, lobstering
var currents := 0.25 ## how strongly the water's currents move them
var count := 0 ## how many krill
var rng := RandomNumberGenerator.new()

var _state := PackedFloat32Array() # (the CPU's copy: the fallback's own, or the last read back)
var _near: MultiMeshInstance3D
var _far: MultiMeshInstance3D
var _mat: ShaderMaterial
var _t := 0.0
var _events := {} # name -> [Vector4, Vector4]: asked this frame (the GPU's params)
var _gpu := false
var _rd: RenderingDevice
var _rids := {} # name -> RID
var _sets: Array[RID] = []
var _parity := 0
var _pending := false
var _state_stale := false # (the CPU's copy behind the GPU's)

static var _built: Mesh
static var _built_far: Mesh


func _init() -> void:
	rng.randomize()
	_make()


func _make() -> void:
	if _built == null:
		_built = build_mesh()
		_built_far = build_far_mesh()
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/render/krill.gdshader")
	_mat.set_shader_parameter("z_hinge", Z_HINGE * MM)
	_mat.set_shader_parameter("z_tail", Z_TAIL * MM)
	for k in 2:
		var mi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = _built if k == 0 else _built_far
		mi.multimesh = mm
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF # (small, see-through)
		mi.custom_aabb = AABB(tank_min - Vector3.ONE * 0.1, tank_max - tank_min + Vector3.ONE * 0.2)
		add_child(mi)
		if k == 0:
			_near = mi
		else:
			_far = mi
	_gpu = _gpu_init()


## n more krill, a swarm round centre (its own space), spread across.
func add(n: int, centre: Vector3, spread := 0.22) -> void:
	_sync_state()
	var a := rng.randf() * TAU
	var way := Vector3(cos(a), 0.0, sin(a)) # (a swarm all facing the one way)
	var old := count
	count += n
	_state.resize(count * STRIDE)
	for i in range(old, count):
		var p := centre + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6), rng.randf_range(-1, 1)) * spread
		var b := i * STRIDE
		var vals := [p.x, p.y, p.z, rng.randf_range(0.65, 0.9), # (about 4 cm)
				way.x * cruise, 0.0, way.z * cruise, rng.randf(),
				way.x, 0.0, way.z, 0.0,
				way.x * cruise, 0.0, way.z * cruise, 0.0,
				0.0, rng.randf_range(4.0, 20.0), 0.0, 0.0,
				0.0, 0.0, 0.0, 0.0,
				0.0, 0.0, 0.0, 0.0]
		for q in STRIDE:
			_state[b + q] = vals[q]
	for mi in [_near, _far]:
		mi.custom_aabb = AABB(tank_min - Vector3.ONE * 0.1, tank_max - tank_min + Vector3.ONE * 0.2)
		mi.multimesh.instance_count = count
		mi.multimesh.visible_instance_count = 0
	if _gpu:
		_gpu_buffers()


## (Back compatible: a pool of n.)
func setup(n: int, centre: Vector3, spread := 0.08) -> void:
	add(n, centre, spread)


## Every krill within r of `from` off in its escape.
func scatter(from: Vector3, r := 0.6) -> void:
	_events["esc"] = [Vector4(from.x, from.y, from.z, r), Vector4.ZERO]


## Every krill within r of `at` stops to feed a while.
func feed_near(at: Vector3, r := 100.0) -> void:
	_events["feed"] = [Vector4(at.x, at.y, at.z, r), Vector4.ZERO]


## Those within r of `from` sent to `to` (the rest carry on).
func swim_to(to: Vector3, from := Vector3.INF, r := 0.5, secs := 20.0) -> void:
	if from == Vector3.INF:
		from = middle()
		r = 100.0
	_events["goal"] = [Vector4(from.x, from.y, from.z, r), Vector4(to.x, to.y, to.z, secs)]


## Every krill swarming again (feeding, escaping, sent: let go).
func rejoin_all() -> void:
	_sync_state()
	for i in count:
		_state[i * STRIDE + 16] = 0.0
		_state[i * STRIDE + 19] = 0.0
	_upload_state()


## Where they all are (its own space; read back from the GPU).
func positions() -> PackedVector3Array:
	_sync_state()
	var out := PackedVector3Array()
	out.resize(count)
	for i in count:
		out[i] = Vector3(_state[i * STRIDE], _state[i * STRIDE + 1], _state[i * STRIDE + 2])
	return out


## Their middle, all of them.
func middle() -> Vector3:
	var ps := positions()
	var m := Vector3.ZERO
	for p in ps:
		m += p
	return m / maxf(ps.size(), 1.0)


## The krill nearest p (its position), or p itself if none.
func nearest(p: Vector3) -> Vector3:
	var best := p
	var bd := INF
	for q in positions():
		var d := q.distance_squared_to(p)
		if d < bd:
			bd = d
			best = q
	return best


## How many are feeding (task 1), escaping (2).
func tasks() -> PackedInt32Array:
	_sync_state()
	var out := PackedInt32Array()
	out.resize(count)
	for i in count:
		out[i] = int(round(_state[i * STRIDE + 16]))
	return out


func _cam_local() -> Vector3:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return to_local(cam.global_position) if cam else Vector3(0.0, 1e6, 0.0)


func _process(dt: float) -> void:
	if count == 0 or dt <= 0.0:
		return
	dt = minf(dt, 0.05)
	_t += dt
	if _gpu:
		_gpu_step(dt)
	else:
		_cpu_step(dt)
	_events.clear()


# --- on the GPU ------------------------------------------------------------------

func _gpu_init() -> bool:
	_rd = RenderingServer.create_local_rendering_device()
	if _rd == null:
		return false
	var sf := load("res://shaders/compute/krill_swarm.glsl") as RDShaderFile
	if sf == null:
		_rd.free()
		_rd = null
		return false
	var spirv := sf.get_spirv()
	if spirv.compile_error_compute != "":
		push_error("krill_swarm.glsl: " + spirv.compile_error_compute)
		_rd.free()
		_rd = null
		return false
	_rids.shader = _rd.shader_create_from_spirv(spirv)
	_rids.pipeline = _rd.compute_pipeline_create(_rids.shader)
	_rids.params = _rd.storage_buffer_create(9 * 16)
	_rids.gcount = _rd.storage_buffer_create(TABLE * 4)
	_rids.gslot = _rd.storage_buffer_create(TABLE * SLOTS * 4)
	_rids.ctr = _rd.storage_buffer_create(16)
	return true


## (The state and output buffers made again, for count krill, from the
## CPU's copy.)
func _gpu_buffers() -> void:
	if _pending:
		_rd.sync()
		_pending = false
	for k in ["a", "b", "near", "far"]:
		if _rids.has(k):
			_rd.free_rid(_rids[k])
	_sets.clear()
	var bytes := _state.to_byte_array()
	_rids.a = _rd.storage_buffer_create(bytes.size(), bytes)
	_rids.b = _rd.storage_buffer_create(bytes.size(), bytes)
	_rids.near = _rd.storage_buffer_create(count * 64)
	_rids.far = _rd.storage_buffer_create(count * 64)
	for pair in [[_rids.a, _rids.b], [_rids.b, _rids.a]]:
		var us: Array[RDUniform] = []
		var ids := [_rids.params, pair[0], pair[1], _rids.gcount, _rids.gslot, _rids.near, _rids.far, _rids.ctr]
		for b in ids.size():
			var u := RDUniform.new()
			u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			u.binding = b
			u.add_id(ids[b])
			us.append(u)
		_sets.append(_rd.uniform_set_create(us, _rids.shader, 0))
	_parity = 0
	_state_stale = false


## Last frame's results drawn (read back: the krill as they are now, near
## and far), then this frame's steering sent off.
func _gpu_step(dt: float) -> void:
	if _pending:
		_rd.sync()
		_pending = false
		var cnt := _rd.buffer_get_data(_rids.ctr, 0, 8).to_int32_array()
		var nn := clampi(cnt[0], 0, count)
		var nf := clampi(cnt[1], 0, count)
		for pair in [[_near, _rids.near, nn], [_far, _rids.far, nf]]:
			var mi: MultiMeshInstance3D = pair[0]
			if int(pair[2]) > 0:
				# (the whole buffer: the multimesh takes all its instances; only the first so many drawn)
				RenderingServer.multimesh_set_buffer(mi.multimesh.get_rid(), _rd.buffer_get_data(pair[1], 0, count * 64).to_float32_array())
			mi.multimesh.visible_instance_count = int(pair[2])
		_parity = 1 - _parity
		_state_stale = true
	var cam := _cam_local()
	var e: Dictionary = _events
	var p := PackedFloat32Array([
		tank_min.x, tank_min.y, tank_min.z, 0.0,
		tank_max.x, tank_max.y, tank_max.z, 0.0,
		cam.x, cam.y, cam.z, FAR,
		dt, _t, float(count), cruise])
	for k in ["esc", "feed", "goal"]:
		var v: Vector4 = (e[k] as Array)[0] if e.has(k) else Vector4.ZERO
		p.append_array([v.x, v.y, v.z, v.w])
	var gt: Vector4 = (e["goal"] as Array)[1] if e.has("goal") else Vector4.ZERO
	p.append_array([gt.x, gt.y, gt.z, gt.w, escape_speed, APART, REACH, currents])
	_rd.buffer_update(_rids.params, 0, p.size() * 4, p.to_byte_array())
	var cl := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(cl, _rids.pipeline)
	_rd.compute_list_bind_uniform_set(cl, _sets[_parity], 0)
	for pass_ in 3:
		var pc := PackedInt32Array([pass_, 0, 0, 0]).to_byte_array()
		_rd.compute_list_set_push_constant(cl, pc, pc.size())
		var n := TABLE if pass_ == 0 else count
		_rd.compute_list_dispatch(cl, ceili(n / 64.0), 1, 1)
		_rd.compute_list_add_barrier(cl)
	_rd.compute_list_end()
	_rd.submit()
	_pending = true


## (The CPU's copy brought up to date: read back from the GPU.)
func _sync_state() -> void:
	if not _gpu or not _state_stale or count == 0:
		return
	if _pending:
		_rd.sync()
		_pending = false
		_parity = 1 - _parity # (its results kept: the draw just misses one frame's)
	var cur: RID = _rids.a if _parity == 0 else _rids.b
	_state = _rd.buffer_get_data(cur, 0, count * STRIDE * 4).to_float32_array()
	_state_stale = false


func _upload_state() -> void:
	if not _gpu:
		return
	if _pending:
		_rd.sync()
		_pending = false
		_parity = 1 - _parity
	var cur: RID = _rids.a if _parity == 0 else _rids.b
	var bytes := _state.to_byte_array()
	_rd.buffer_update(cur, 0, bytes.size(), bytes)


func _exit_tree() -> void:
	if _rd:
		if _pending:
			_rd.sync()
		for k in _rids:
			if k != "shader" and k != "pipeline" and _rids[k] is RID and (_rids[k] as RID).is_valid():
				_rd.free_rid(_rids[k])
		_rd.free_rid(_rids.pipeline)
		_rd.free_rid(_rids.shader)
		_rd.free()
		_rd = null
		_gpu = false


# --- the fallback: the same rules, here --------------------------------------------

func _rnd() -> float:
	return rng.randf()


func _cpu_step(dt: float) -> void:
	var n := count
	var S := _state
	var grid := {}
	for i in n:
		var k := Vector3i(floori(S[i * STRIDE] / REACH), floori(S[i * STRIDE + 1] / REACH), floori(S[i * STRIDE + 2] / REACH))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(i)
	var cam := _cam_local()
	var out_n := PackedFloat32Array()
	var out_f := PackedFloat32Array()
	var nxt := S.duplicate()
	var flow_k := currents
	for i in n:
		var b := i * STRIDE
		var p := Vector3(S[b], S[b + 1], S[b + 2])
		var sz := S[b + 3]
		var v := Vector3(S[b + 4], S[b + 5], S[b + 6])
		var seed := S[b + 7]
		var hd := Vector3(S[b + 8], S[b + 9], S[b + 10])
		var feed_k := S[b + 11]
		var vs := Vector3(S[b + 12], S[b + 13], S[b + 14])
		var task := S[b + 16]
		var task_t := S[b + 17]
		var flip_t := S[b + 18]
		var goal_t := S[b + 19]
		var flee := Vector3(S[b + 20], S[b + 21], S[b + 22])
		var goal := Vector3(S[b + 24], S[b + 25], S[b + 26])
		if _events.has("esc"):
			var ev: Vector4 = _events.esc[0]
			if p.distance_to(Vector3(ev.x, ev.y, ev.z)) < ev.w:
				task = 2.0
				task_t = 0.6 + 0.5 * _rnd()
				flip_t = 0.0
				flee = Vector3(ev.x, ev.y, ev.z)
		if _events.has("feed"):
			var ev: Vector4 = _events.feed[0]
			if p.distance_to(Vector3(ev.x, ev.y, ev.z)) < ev.w:
				task = 1.0
				task_t = 4.0 + 5.0 * _rnd()
		if _events.has("goal"):
			var ev: Vector4 = _events.goal[0]
			var to: Vector4 = _events.goal[1]
			if p.distance_to(Vector3(ev.x, ev.y, ev.z)) < ev.w:
				goal = Vector3(to.x, to.y, to.z)
				goal_t = to.w
		var sep := Vector3.ZERO
		var align := Vector3.ZERO
		var coh := Vector3.ZERO
		var wsum := 0.0
		var apart := APART * sz
		var c := Vector3i(floori(p.x / REACH), floori(p.y / REACH), floori(p.z / REACH))
		for dz in range(-1, 2):
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					for j: int in grid.get(c + Vector3i(dx, dy, dz), []):
						if j == i:
							continue
						var q := Vector3(S[j * STRIDE], S[j * STRIDE + 1], S[j * STRIDE + 2])
						var off := p - q
						var d := off.length()
						if d > REACH or d < 1e-6:
							continue
						if d < apart:
							sep += off / d * (apart - d) / apart
						var w := (1.0 - d / REACH) * (1.0 - d / REACH)
						align += Vector3(S[j * STRIDE + 8], S[j * STRIDE + 9], S[j * STRIDE + 10]) * w
						coh += q * w
						wsum += w
		var acc := sep * 1.8
		if wsum > 1e-4:
			acc += (align / wsum * cruise - v) * minf(wsum, 1.0)
			acc += (coh / wsum - p) * 1.4 * minf(wsum, 1.0)
		var flow := Vector3(sin(p.z * 0.9 + _t * 0.07 + 1.3) + 0.5 * sin(p.y * 2.1 - _t * 0.05),
				0.25 * sin(p.x * 1.1 + p.z * 0.7 + _t * 0.04),
				cos(p.x * 0.8 - _t * 0.06 + 0.4) + 0.5 * cos(p.y * 1.7 + _t * 0.03))
		acc += (flow * cruise * 0.7 - v) * flow_k * (0.35 if wsum > 1e-4 else 1.0)
		var want := cruise * (0.7 + 0.6 * seed)
		if goal_t > 0.0:
			goal_t -= dt
			if goal.distance_to(p) > 0.06:
				acc += (goal - p).normalized() * 0.06
		task_t -= dt
		if task < 0.5:
			if task_t <= 0.0:
				task_t = 6.0 + 14.0 * _rnd()
				if _rnd() < 0.35:
					task = 1.0
					task_t = 4.0 + 5.0 * _rnd()
		elif task < 1.5:
			acc = acc * 0.5 - v * 1.5
			want = 0.0
			if task_t <= 0.0:
				task = 0.0
				task_t = 4.0 + 16.0 * _rnd()
		else:
			flip_t += dt
			var away := p - flee
			away.y *= 0.3
			away = away.normalized() if away.length() > 1e-4 else -hd
			var kick := maxf(sin(flip_t * TAU * 3.0), 0.0)
			acc = away * escape_speed * 9.0 * kick - v * 2.0
			want = escape_speed
			if task_t <= 0.0:
				task = 0.0
				task_t = 4.0 + 16.0 * _rnd()
		feed_k = clampf(feed_k + (1.0 if task > 0.5 and task < 1.5 else -1.0) * dt * 1.5, 0.0, 1.0)
		var lo := tank_min + Vector3(0.03, 0.03, 0.03)
		var hi := tank_max - Vector3(0.03, 0.02, 0.03)
		var wall := (lo - p).max(Vector3.ZERO) - (p - hi).max(Vector3.ZERO)
		acc += wall * 40.0
		if task < 0.5:
			acc.y -= v.y * 1.2
		v += acc * dt
		var top := escape_speed if task > 1.5 else maxf(want * 1.6, 0.015)
		if v.length() > top:
			v = v.normalized() * top
		var np := (p + v * dt).clamp(tank_min, tank_max - Vector3(0.0, 0.006, 0.0))
		np.y = maxf(np.y, tank_min.y + 0.006)
		vs = vs.lerp(v, 1.0 - exp(-4.0 * dt))
		var escaping := task > 1.5
		if escaping:
			var away := Vector3(np.x - flee.x, 0.0, np.z - flee.z)
			if away.length() > 1e-4:
				hd = hd.lerp(-away.normalized(), 1.0 - exp(-8.0 * dt))
		elif vs.length() > 0.008:
			var flat := Vector3(vs.x, 0.0, vs.z)
			if flat.length() > 1e-4:
				hd = hd.lerp(flat.normalized(), 1.0 - exp(-3.0 * dt))
		hd.y = 0.0
		hd = hd.normalized() if hd.length() > 1e-4 else Vector3.FORWARD
		var pitch := 0.0 if escaping else clampf(atan2(vs.y, maxf(Vector2(vs.x, vs.z).length(), 0.01)), -0.4, 0.4) * 0.6
		pitch += 0.6 * feed_k
		var bs := Basis.looking_at(hd, Vector3.UP) * Basis(Vector3.RIGHT, pitch) * Basis.from_scale(Vector3.ONE * sz)
		var swim := clampf(vs.length() / (cruise * 2.0), 0.0, 1.0)
		var curl := maxf(sin(flip_t * TAU * 3.0), 0.0) if escaping else 0.0
		var row := [bs.x.x, bs.y.x, bs.z.x, np.x, bs.x.y, bs.y.y, bs.z.y, np.y, bs.x.z, bs.y.z, bs.z.z, np.z, swim, feed_k, seed, curl]
		if np.distance_to(cam) > FAR:
			out_f.append_array(row)
		else:
			out_n.append_array(row)
		var vals := [np.x, np.y, np.z, sz, v.x, v.y, v.z, seed, hd.x, hd.y, hd.z, feed_k, vs.x, vs.y, vs.z, 0.0,
				task, task_t, flip_t, goal_t, flee.x, flee.y, flee.z, 0.0, goal.x, goal.y, goal.z, 0.0]
		for q in STRIDE:
			nxt[b + q] = vals[q]
	_state = nxt
	for pair in [[_near, out_n], [_far, out_f]]:
		var mi: MultiMeshInstance3D = pair[0]
		var data: PackedFloat32Array = pair[1]
		var k := data.size() / 16
		data.resize(count * 16)
		RenderingServer.multimesh_set_buffer(mi.multimesh.get_rid(), data)
		mi.multimesh.visible_instance_count = k


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


## The far mesh: the body (fewer rings), the eyes, the tail fan, no limbs:
## a few hundred triangles less than a tenth of the near one's.
static func build_far_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	const RING := 5
	const STEPS := 7
	var rings := []
	for s in STEPS + 1:
		var z := lerpf(Z_HEAD, 19.5, float(s) / STEPS)
		var k := _key(z)
		var ring := []
		for r in RING + 1:
			var a := TAU * r / RING
			var p := Vector3(sin(a) * k.y, k.x + cos(a) * k.z, z)
			ring.append([p, Vector3(sin(a) / maxf(k.y, 0.2), cos(a) / maxf(k.z, 0.2), 0.0).normalized()])
		rings.append(ring)
	for s in STEPS:
		for r in RING:
			var q := [rings[s][r], rings[s][r + 1], rings[s + 1][r + 1], rings[s + 1][r]]
			for t: Array in [[0, 1, 2], [0, 2, 3]]:
				for e: int in t:
					var c: Array = q[e]
					_v(st, c[0], c[1], 0)
	_blob(st, Vector3(0.0, -0.6, 22.0), Vector3(2.6, 0.2, 3.2), 6, 0.0, 4, 2)
	for side: float in [-1.0, 1.0]:
		_blob(st, Vector3(2.3 * side, 1.8, -23.2), Vector3(1.6, 1.7, 1.6), 1, 0.0, 4, 3)
	return st.commit()
