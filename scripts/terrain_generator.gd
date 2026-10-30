class_name TerrainGenerator
extends RefCounted
## Worker thread: plans islands (Archipelago/IslandPlanner, cached), gathers each
## tile's river/lake/coast primitives, runs shaders/terrain_gen.glsl on a local
## RenderingDevice and builds mesh arrays from the result.

const INFLUENCE := 260.0 # metres a valley segment can shape the terrain
const GRAD_RADIUS_M := 6.0 # erosion gradient stencil
const OUT_STRIDE := 8 # floats per output vertex

var seed: int = 1337

var _spirv: RDShaderSPIRV
var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _thread: Thread
var _mutex := Mutex.new()
var _sem := Semaphore.new()
var _jobs: Array = []
var _results: Array = []
var _running := true
var _arch := Archipelago.new()


func start() -> void:
	_arch.seed = seed
	var file: RDShaderFile = load("res://shaders/terrain_gen.glsl")
	_spirv = file.get_spirv()
	if _spirv.compile_error_compute != "":
		push_error("terrain_gen.glsl: " + _spirv.compile_error_compute)
	_thread = Thread.new()
	_thread.start(_loop)


func stop() -> void:
	_mutex.lock()
	_running = false
	_mutex.unlock()
	_sem.post()
	if _thread:
		_thread.wait_to_finish()


## Tile job: {kind (0 near, 1 far), key, origin: Vector2 (world xz of vertex 0), spacing, n (cells)}
## Spawn job: {kind: 2} -> result {kind: 2, spawn: Vector3}
func request(job: Dictionary) -> void:
	_mutex.lock()
	_jobs.append(job)
	_mutex.unlock()
	_sem.post()


func poll() -> Array:
	_mutex.lock()
	var r := _results
	_results = []
	_mutex.unlock()
	return r


func _loop() -> void:
	_rd = RenderingServer.create_local_rendering_device()
	if _rd == null:
		push_error("No RenderingDevice: run with the Forward+ or Mobile renderer (Vulkan).")
		return
	_shader = _rd.shader_create_from_spirv(_spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	while true:
		_sem.wait()
		_mutex.lock()
		var running := _running
		var job = _jobs.pop_front() if not _jobs.is_empty() else null
		_mutex.unlock()
		if not running:
			break
		if job == null:
			continue
		var res: Dictionary = job.duplicate()
		if job.kind == 2:
			res["spawn"] = _find_spawn()
		else:
			var data := _generate(job)
			res["data"] = data
			res["arrays"] = TerrainMesher.build(data, null, int(job.n), float(job.spacing))
			res["water"] = TerrainMesher.build_water(data, int(job.n), float(job.spacing))
		_mutex.lock()
		_results.append(res)
		_mutex.unlock()
	_rd.free_rid(_pipeline)
	_rd.free_rid(_shader)
	_rd.free()


func _find_spawn() -> Vector3:
	for isl in _arch.islands_in(Rect2(-10, -10, 20, 20)):
		var plan := _arch.plan(isl)
		if plan.spawn != Vector3.INF:
			return plan.spawn
	return Vector3(0, 120, 0)


## Collects primitives near the tile, relative to its origin.
func _gather(origin: Vector2, rect: Rect2) -> Dictionary:
	var segs := PackedFloat32Array()
	var lakes := PackedFloat32Array()
	var lobes := PackedFloat32Array()
	var peaks := PackedFloat32Array()
	var reach := rect.grow(INFLUENCE)
	for isl in _arch.islands_in(rect.grow(500.0)):
		var plan := _arch.plan(isl)
		var s := plan.segs
		for i in range(0, s.size(), IslandPlanner.SEG_STRIDE):
			var x0 := minf(s[i], s[i + 2])
			var x1 := maxf(s[i], s[i + 2])
			var z0 := minf(s[i + 1], s[i + 3])
			var z1 := maxf(s[i + 1], s[i + 3])
			if x1 < reach.position.x or x0 > reach.end.x or z1 < reach.position.y or z0 > reach.end.y:
				continue
			segs.append_array([s[i] - origin.x, s[i + 1] - origin.y, s[i + 2] - origin.x, s[i + 3] - origin.y])
			segs.append_array(s.slice(i + 4, i + 12))
		var lk := plan.lakes
		for i in range(0, lk.size(), IslandPlanner.LAKE_STRIDE):
			if rect.grow(lk[i + 2] * 1.3 + 600.0).has_point(Vector2(lk[i], lk[i + 1])):
				lakes.append_array([lk[i] - origin.x, lk[i + 1] - origin.y])
				lakes.append_array(lk.slice(i + 2, i + 8))
		var lb := plan.lobe_data
		for i in range(0, lb.size(), IslandPlanner.LOBE_STRIDE):
			lobes.append_array([lb[i] - origin.x, lb[i + 1] - origin.y])
			lobes.append_array(lb.slice(i + 2, i + IslandPlanner.LOBE_STRIDE))
		var pk := plan.peak_data
		for i in range(0, pk.size(), IslandPlanner.PEAK_STRIDE):
			peaks.append_array([pk[i] - origin.x, pk[i + 1] - origin.y, pk[i + 2], pk[i + 3]])
	return {"segs": segs, "lakes": lakes, "lobes": lobes, "peaks": peaks}


func _buffer(data: PackedFloat32Array) -> RID:
	if data.is_empty():
		data = PackedFloat32Array([0, 0, 0, 0])
	var bytes := data.to_byte_array()
	return _rd.storage_buffer_create(bytes.size(), bytes)


func _generate(job: Dictionary) -> PackedFloat32Array:
	var n: int = job.n
	var s: float = job.spacing
	var origin: Vector2 = job.origin
	var grad_r := maxi(1, roundi(GRAD_RADIUS_M / s))
	var fine_pad := grad_r + 1 # 1-vertex normal ring + gradient stencil
	var fine_n := n + 1 + 2 * fine_pad
	var out_n := n + 3
	var rect := Rect2(origin - Vector2.ONE * fine_pad * s, Vector2.ONE * (fine_n - 1) * s)
	var prim := _gather(origin, rect)

	var bufs: Array[RID] = [
		_buffer(prim.segs),
		_buffer(prim.lakes),
		_buffer(prim.lobes),
		_buffer(prim.peaks),
		_rd.storage_buffer_create(fine_n * fine_n * 16),
		_rd.storage_buffer_create(fine_n * fine_n * 16),
		_rd.storage_buffer_create(out_n * out_n * 32),
	]
	var uniforms: Array[RDUniform] = []
	for i in bufs.size():
		var u := RDUniform.new()
		u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u.binding = i
		u.add_id(bufs[i])
		uniforms.append(u)
	var uset := _rd.uniform_set_create(uniforms, _shader, 0)

	var cl := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(cl, _pipeline)
	_rd.compute_list_bind_uniform_set(cl, uset, 0)
	for stage in 2:
		var pcb := PackedByteArray()
		pcb.resize(64)
		pcb.encode_s32(0, stage)
		pcb.encode_s32(4, prim.segs.size() / IslandPlanner.SEG_STRIDE)
		pcb.encode_s32(8, prim.lakes.size() / IslandPlanner.LAKE_STRIDE)
		pcb.encode_s32(12, prim.lobes.size() / IslandPlanner.LOBE_STRIDE)
		pcb.encode_s32(16, prim.peaks.size() / IslandPlanner.PEAK_STRIDE)
		pcb.encode_s32(20, fine_n)
		pcb.encode_s32(24, out_n)
		pcb.encode_s32(28, fine_pad)
		pcb.encode_float(32, origin.x)
		pcb.encode_float(36, origin.y)
		pcb.encode_float(40, s)
		pcb.encode_float(44, s * 2.5) # skip erosion octaves the grid can't resolve
		pcb.encode_u32(48, seed)
		pcb.encode_float(52, INFLUENCE)
		pcb.encode_float(56, grad_r)
		var dim := fine_n if stage == 0 else out_n
		var groups := ceili(dim / 8.0)
		_rd.compute_list_set_push_constant(cl, pcb, pcb.size())
		_rd.compute_list_dispatch(cl, groups, groups, 1)
		_rd.compute_list_add_barrier(cl)
	_rd.compute_list_end()
	_rd.submit()
	_rd.sync()

	var out := _rd.buffer_get_data(bufs[6]).to_float32_array()
	_rd.free_rid(uset)
	for b in bufs:
		_rd.free_rid(b)
	return out
