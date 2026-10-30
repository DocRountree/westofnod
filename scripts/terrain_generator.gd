class_name TerrainGenerator
extends RefCounted
## Worker thread. Simulates islands on demand (Island + IslandSim, cached),
## gathers each tile's island grids and river segments, runs
## shaders/terrain_gen.glsl on a local RenderingDevice and builds mesh arrays.

const OUT_STRIDE := 8 # floats per output vertex

var seed: int = 1337
var arch: Archipelago

var _rd: RenderingDevice
var _sim: IslandSim
var _shader: RID
var _pipeline: RID
var _thread: Thread
var _mutex := Mutex.new()
var _sem := Semaphore.new()
var _jobs: Array = []
var _results: Array = []
var _running := true
var _islands := {} # id -> Island


func start() -> void:
	arch = Archipelago.new(seed)
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
	_sim = IslandSim.new(_rd)
	_shader = Compute.load_shader(_rd, "res://shaders/terrain_gen.glsl")
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
			var data := generate(job)
			res["data"] = data
			res["arrays"] = TerrainMesher.build(data, null, int(job.n), float(job.spacing))
			res["water"] = TerrainMesher.build_water(data, int(job.n), float(job.spacing))
		_mutex.lock()
		_results.append(res)
		_mutex.unlock()
	_rd.free_rid(_pipeline)
	_rd.free_rid(_shader)
	_sim.free_rids()
	_rd.free()


## Builds (once) and returns an island. Only call from the worker thread.
func island(desc: Dictionary) -> Island:
	if not _islands.has(desc.id):
		var t0 := Time.get_ticks_msec()
		var isl := Island.new(desc).build(_sim)
		print("island r=%.0f m simulated in %d ms %s" % [isl.radius, Time.get_ticks_msec() - t0, isl.stats])
		_islands[desc.id] = isl
	return _islands[desc.id]


func _find_spawn() -> Vector3:
	var pick := {}
	for desc in arch.islands_in(Rect2(-100, -100, 200, 200).grow(Archipelago.CELL)):
		if pick.is_empty() or desc.r > pick.r:
			pick = desc
	if pick.is_empty():
		return Vector3(0, 60, 0)
	var best := island(pick)
	if best.spawn != Vector3.INF:
		return best.spawn
	# No suitable river: the highest-up inland cell short of the mountains.
	var k_best := 0
	for k in best.n * best.n:
		if best.sd[k] > best.sd[k_best] and best.h[k] < 60.0:
			k_best = k
	var p := best.cell_pos(k_best)
	return Vector3(p.x, best.h[k_best] + 3.0, p.y)


## Collects island grids (cropped) and river segments near the tile, relative to
## its origin.
func _gather(origin: Vector2, rect: Rect2) -> Dictionary:
	var grids := PackedFloat32Array()
	var info := PackedFloat32Array()
	var segs := PackedFloat32Array()
	for desc in arch.islands_in(rect):
		var isl := island(desc)
		# Crop the grid to the tile plus the bicubic stencil.
		var g0 := Vector2i(floori((rect.position.x - isl.origin.x) / isl.dx) - 2,
				floori((rect.position.y - isl.origin.y) / isl.dx) - 2)
		var g1 := Vector2i(ceili((rect.end.x - isl.origin.x) / isl.dx) + 2,
				ceili((rect.end.y - isl.origin.y) / isl.dx) + 2)
		g0 = g0.clamp(Vector2i.ZERO, Vector2i(isl.n - 1, isl.n - 1))
		g1 = g1.clamp(Vector2i.ZERO, Vector2i(isl.n - 1, isl.n - 1))
		var w := g1.x - g0.x + 1
		var hgt := g1.y - g0.y + 1
		if w < 4 or hgt < 4:
			continue
		var crop_origin := isl.origin + Vector2(g0) * isl.dx - origin
		info.append_array([crop_origin.x, crop_origin.y, isl.dx, w, hgt, grids.size() / 4, 0, 0])
		for j in range(g0.y, g1.y + 1):
			var row := (j * isl.n + g0.x) * 4
			grids.append_array(isl.grid.slice(row, row + w * 4))
		# River segments from the buckets the tile touches.
		var seen := {}
		var b0 := Vector2i(floori(rect.position.x / Island.BUCKET), floori(rect.position.y / Island.BUCKET))
		var b1 := Vector2i(floori(rect.end.x / Island.BUCKET), floori(rect.end.y / Island.BUCKET))
		for bz in range(b0.y, b1.y + 1):
			for bx in range(b0.x, b1.x + 1):
				for si in isl.buckets.get(Vector2i(bx, bz), PackedInt32Array()):
					if seen.has(si):
						continue
					seen[si] = true
					var s: int = si * Island.SEG_STRIDE
					var sg := isl.segs
					segs.append_array([sg[s] - origin.x, sg[s + 1] - origin.y, sg[s + 2] - origin.x, sg[s + 3] - origin.y])
					segs.append_array(sg.slice(s + 4, s + Island.SEG_STRIDE))
	return {"grids": grids, "info": info, "segs": segs}


## Runs the terrain shader for a tile job. Returns out_n^2 vertices of
## OUT_STRIDE floats (see TerrainMesher).
func generate(job: Dictionary) -> PackedFloat32Array:
	var n: int = job.n
	var s: float = job.spacing
	var origin: Vector2 = job.origin
	var out_n := n + 3
	var rect := Rect2(origin - Vector2(s, s), Vector2.ONE * (out_n - 1) * s)
	var prim := _gather(origin, rect)
	var bufs: Array[RID] = [
		Compute.buffer(_rd, prim.grids),
		Compute.buffer(_rd, prim.info),
		Compute.buffer(_rd, prim.segs),
		_rd.storage_buffer_create(out_n * out_n * OUT_STRIDE * 4),
	]
	var uset := Compute.uniform_set(_rd, _shader, bufs)
	var pcb := PackedByteArray()
	pcb.resize(48)
	pcb.encode_s32(0, prim.info.size() / 8)
	pcb.encode_s32(4, prim.segs.size() / Island.SEG_STRIDE)
	pcb.encode_s32(8, out_n)
	pcb.encode_u32(12, seed)
	pcb.encode_float(16, origin.x)
	pcb.encode_float(20, origin.y)
	pcb.encode_float(24, s)
	pcb.encode_float(28, s * 2.5) # skip erosion octaves the grid can't resolve
	pcb.encode_float(32, Island.BANK_REACH)
	var cl := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(cl, _pipeline)
	_rd.compute_list_bind_uniform_set(cl, uset, 0)
	_rd.compute_list_set_push_constant(cl, pcb, pcb.size())
	var groups := ceili(out_n / 8.0)
	_rd.compute_list_dispatch(cl, groups, groups, 1)
	_rd.compute_list_end()
	_rd.submit()
	_rd.sync()
	var out := _rd.buffer_get_data(bufs[3]).to_float32_array()
	_rd.free_rid(uset)
	for b in bufs:
		_rd.free_rid(b)
	return out
