class_name TerrainGenerator
extends RefCounted
## Runs the terrain compute pipeline (shaders/terrain_gen.glsl) on a local
## RenderingDevice in a worker thread and builds mesh arrays from the result.

const COARSE_SPACING := 16.0
const DIFFUSION_STEPS := 40 # must be even: the final field lands in coarse buffer A

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


func start() -> void:
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


## job: {kind (0 near, 1 far), key, origin: Vector2 (world xz of vertex 0), spacing, n (cells)}
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
		var data := _generate(job)
		var res: Dictionary = job.duplicate()
		res["data"] = data
		res["out_n"] = int(job.n) + 3
		res["arrays"] = TerrainMesher.build(data, null, int(job.n), float(job.spacing))
		if job.kind == 0:
			res["river"] = TerrainMesher.build_river(data, int(job.n))
		_mutex.lock()
		_results.append(res)
		_mutex.unlock()
	_rd.free_rid(_pipeline)
	_rd.free_rid(_shader)
	_rd.free()


func _generate(job: Dictionary) -> PackedFloat32Array:
	var n: int = job.n
	var s: float = job.spacing
	var origin: Vector2 = job.origin
	var fine_pad := 3 # 5x5 deposit blur + 1-vertex normal ring
	var fine_n := n + 1 + 2 * fine_pad
	var out_n := n + 3
	var fine_origin := origin - Vector2.ONE * (fine_pad * s)
	var extent := (fine_n - 1) * s
	var c0 := Vector2i(
		floori(fine_origin.x / COARSE_SPACING) - DIFFUSION_STEPS - 2,
		floori(fine_origin.y / COARSE_SPACING) - DIFFUSION_STEPS - 2)
	var coarse_n := ceili(extent / COARSE_SPACING) + 2 * DIFFUSION_STEPS + 6

	var bufs: Array[RID] = [
		_rd.storage_buffer_create(coarse_n * coarse_n * 4),
		_rd.storage_buffer_create(coarse_n * coarse_n * 4),
		_rd.storage_buffer_create(fine_n * fine_n * 16),
		_rd.storage_buffer_create(fine_n * fine_n * 4),
		_rd.storage_buffer_create(fine_n * fine_n * 4),
		_rd.storage_buffer_create(out_n * out_n * 16),
	]
	var uniforms: Array[RDUniform] = []
	for i in bufs.size():
		var u := RDUniform.new()
		u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u.binding = i
		u.add_id(bufs[i])
		uniforms.append(u)
	var uset := _rd.uniform_set_create(uniforms, _shader, 0)

	# Fewer erosion octaves when vertices are too sparse to resolve them.
	var min_wl := s * 2.5

	var cl := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(cl, _pipeline)
	_rd.compute_list_bind_uniform_set(cl, uset, 0)
	var steps: Array = [[0, 0, coarse_n]]
	for k in DIFFUSION_STEPS:
		steps.append([1, k % 2, coarse_n])
	steps.append([2, 0, fine_n])
	steps.append([3, 0, fine_n])
	steps.append([4, 0, out_n])
	for step in steps:
		var pcb := PackedByteArray()
		pcb.resize(64)
		pcb.encode_s32(0, step[0])
		pcb.encode_s32(4, step[1])
		pcb.encode_s32(8, coarse_n)
		pcb.encode_s32(12, fine_n)
		pcb.encode_s32(16, c0.x)
		pcb.encode_s32(20, c0.y)
		pcb.encode_float(24, fine_origin.x)
		pcb.encode_float(28, fine_origin.y)
		pcb.encode_float(32, s)
		pcb.encode_float(36, COARSE_SPACING)
		pcb.encode_s32(40, fine_pad)
		pcb.encode_s32(44, out_n)
		pcb.encode_s32(48, 0)
		pcb.encode_u32(52, seed)
		pcb.encode_float(56, min_wl)
		pcb.encode_float(60, 0.0)
		_rd.compute_list_set_push_constant(cl, pcb, pcb.size())
		var groups := ceili(step[2] / 8.0)
		_rd.compute_list_dispatch(cl, groups, groups, 1)
		_rd.compute_list_add_barrier(cl)
	_rd.compute_list_end()
	_rd.submit()
	_rd.sync()

	var out := _rd.buffer_get_data(bufs[5]).to_float32_array()
	_rd.free_rid(uset)
	for b in bufs:
		_rd.free_rid(b)
	return out
