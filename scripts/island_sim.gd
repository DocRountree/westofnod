class_name IslandSim
extends RefCounted
## Runs shaders/island_sim.glsl for an Island on a local RenderingDevice.

const ITERATIONS := 2400
const DT := 0.012 # in units where the erodibility K is 1
const BATCH := 300 # iterations per submit, so a slow GPU never stalls for long

var rd: RenderingDevice
var _shader: RID
var _pipeline: RID


func _init(device: RenderingDevice) -> void:
	rd = device
	_shader = Compute.load_shader(rd, "res://shaders/island_sim.glsl")
	_pipeline = rd.compute_pipeline_create(_shader)


func free_rids() -> void:
	rd.free_rid(_pipeline)
	rd.free_rid(_shader)


## Fills isl.h (eroded bed) and isl.area (multiple-flow drainage area).
func run(isl: Island) -> void:
	var n := isl.n
	var cells := n * n
	var area := PackedFloat32Array()
	area.resize(cells)
	area.fill(isl.dx * isl.dx)
	var bufs: Array[RID] = [
		Compute.buffer(rd, isl.h),
		Compute.buffer(rd, isl.h),
		Compute.buffer(rd, area),
		Compute.buffer(rd, area),
		Compute.buffer(rd, isl.uplift),
		rd.storage_buffer_create(cells * 8 * 4),
	]
	var uset := Compute.uniform_set(rd, _shader, bufs)
	var groups := ceili(n / 8.0)
	# Hillslope diffusion: rounds hilltops; kept well inside the explicit limit.
	var kd := 0.004 * isl.dx * isl.dx / DT
	var parity := 0
	var done := 0
	while done < ITERATIONS:
		var cl := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(cl, _pipeline)
		rd.compute_list_bind_uniform_set(cl, uset, 0)
		for it in mini(BATCH, ITERATIONS - done):
			for stage in 2:
				var pcb := PackedByteArray()
				pcb.resize(32)
				pcb.encode_s32(0, stage)
				pcb.encode_s32(4, n)
				pcb.encode_s32(8, parity)
				pcb.encode_float(12, DT)
				pcb.encode_float(16, isl.dx)
				pcb.encode_float(20, kd)
				pcb.encode_float(24, 1.1) # talus slope
				pcb.encode_float(28, 1.6) # flow concentration
				rd.compute_list_set_push_constant(cl, pcb, pcb.size())
				rd.compute_list_dispatch(cl, groups, groups, 1)
				rd.compute_list_add_barrier(cl)
			parity = 1 - parity
		done += BATCH
		rd.compute_list_end()
		rd.submit()
		rd.sync()
	isl.h = rd.buffer_get_data(bufs[parity]).to_float32_array()
	isl.area = rd.buffer_get_data(bufs[2 + parity]).to_float32_array()
	rd.free_rid(uset)
	for b in bufs:
		rd.free_rid(b)
