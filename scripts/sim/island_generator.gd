class_name IslandGenerator
extends RefCounted
## Simulates one island, in stages (see README, "Terrain"):
##   1. landscape  uplift vs stream power erosion (GPU, coarse grid)
##   2. erosion    hydraulic + thermal erosion with sediment (GPU, medium grid)
##   3. hydrology  lakes, drainage, river chains (CPU)
##   4. rivers     smoothing, meandering with history (CPU)
##   5. compose    floodplains, scroll bars, oxbows, levees, channels, lakes,
##                 water and material maps (GPU, full resolution)
## Results are cached under user://islands/.

const OCEAN_FLOOR := -95.0

## Grid sizes and domain. "full" is the game's; "test" is quick for previews.
const PRESETS := {
	"full": {"domain": 8192.0, "n0": 256, "n1": 1024, "nh": 512, "nf": 2048, "iters": 2400},
	"test": {"domain": 4096.0, "n0": 128, "n1": 512, "nh": 256, "nf": 1024, "iters": 1500},
}

var seed: int
var cfg: Dictionary
var rng := RandomNumberGenerator.new()
var progress: Callable = func(_msg: String) -> void: pass
var rd: RenderingDevice

var radius: float
var origin: Vector2


func _init(s: int, preset: String = "full") -> void:
	seed = s
	cfg = PRESETS[preset]
	rng.seed = s
	radius = cfg.domain * 0.3
	origin = -Vector2.ONE * cfg.domain * 0.5


static func cache_path(s: int, preset: String) -> String:
	return "user://islands/%s_%d_v%d.island" % [preset, s, IslandData.VERSION]


## Loads the cached island or simulates it. Call from a worker thread.
func generate(preset: String = "full") -> IslandData:
	var path := cache_path(seed, preset)
	var cached := IslandData.load_from(path)
	if cached:
		progress.call("Loaded cached island")
		return cached
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		push_error("No RenderingDevice: run with the Forward+ or Mobile renderer (Vulkan).")
		return null
	var t := Time.get_ticks_msec()
	var times := {}
	progress.call("Raising the island...")
	var b0 := _landscape()
	times.landscape = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	progress.call("Eroding...")
	var er := _erode(b0)
	times.erosion = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	progress.call("Tracing rivers and lakes...")
	var hgrid := _resize(er.b, cfg.n1, cfg.nh, Image.INTERPOLATE_BILINEAR)
	var hyd := Hydrology.new(hgrid, cfg.nh, cfg.domain / (cfg.nh - 1), origin).run(rng, radius)
	times.hydrology = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	progress.call("Meandering...")
	var rv := Rivers.new(hyd, rng).build()
	times.rivers = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	progress.call("Composing the island...")
	var data := _compose(er.b, er.dep, hyd, rv)
	times.compose = Time.get_ticks_msec() - t
	data.stats = {"times": times, "rivers": rv.stats, "lakes": hyd.lake_levels.size()}
	rd.free()
	DirAccess.make_dir_recursive_absolute("user://islands")
	data.save(path)
	return data


# ------------------------------------------------------------------ 1. landscape

## Uplift field and initial relief, then stream power to near steady state.
## Returns the coarse heightfield with bathymetry (n0 x n0).
func _landscape() -> PackedFloat32Array:
	var n: int = cfg.n0
	var dx: float = cfg.domain / (n - 1)
	var center := Vector2.ZERO
	var shape := FastNoiseLite.new()
	shape.seed = rng.randi()
	shape.frequency = 1.0 / (radius * 0.55)
	shape.fractal_octaves = 5
	shape.domain_warp_enabled = true
	shape.domain_warp_amplitude = radius * 0.35
	shape.domain_warp_frequency = 1.0 / (radius * 0.9)
	var ridges := FastNoiseLite.new()
	ridges.seed = rng.randi()
	ridges.frequency = 1.0 / (radius * 0.5)
	ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridges.fractal_octaves = 3
	var jitter := FastNoiseLite.new()
	jitter.seed = rng.randi()
	jitter.frequency = 1.0 / (dx * 3.0)
	var lobes := [[center, radius]]
	for k in rng.randi_range(1, 3):
		lobes.append([center + Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.4, 0.8),
				radius * rng.randf_range(0.3, 0.55)])
	# Uplift / K per cell sets the relief; the mountain core is offset so one
	# side of the island keeps broad coastal plains for rivers to meander on.
	var u_max := 1.4 * dx
	var core_at := Vector2.from_angle(rng.randf() * TAU) * radius * 0.45
	var reach := radius * 1.5
	var uplift := PackedFloat32Array()
	var h := PackedFloat32Array()
	uplift.resize(n * n)
	h.resize(n * n)
	for j in n:
		for i in n:
			var k := j * n + i
			var p := origin + Vector2(i, j) * dx
			var s := -1.0
			for l in lobes:
				s = maxf(s, 1.0 - p.distance_to(l[0]) / l[1])
			s += 0.5 * shape.get_noise_2dv(p)
			s -= 2.0 * smoothstep(reach * 0.8, reach, p.length())
			if s <= 0.0 or i == 0 or j == 0 or i == n - 1 or j == n - 1:
				uplift[k] = -1.0
				continue
			var core := pow(smoothstep(0.15, 0.85, 1.0 - p.distance_to(core_at) / (radius * 1.1)), 1.5)
			core *= smoothstep(0.0, 0.35, s)
			var rid := clampf(ridges.get_noise_2dv(p) * 0.5 + 0.5, 0.0, 1.0)
			uplift[k] = u_max * (0.02 + 0.98 * core * (0.25 + 0.75 * rid))
			h[k] = 2.0 + 4.0 * minf(s, 1.0) + 1.5 * jitter.get_noise_2dv(p)

	var shader := Compute.load_shader(rd, "res://shaders/sim/landscape.glsl")
	var pipeline := rd.compute_pipeline_create(shader)
	var area := PackedFloat32Array()
	area.resize(n * n)
	area.fill(dx * dx)
	var bufs: Array[RID] = [Compute.buffer(rd, h), Compute.buffer(rd, h), Compute.buffer(rd, area),
			Compute.buffer(rd, area), Compute.buffer(rd, uplift), rd.storage_buffer_create(n * n * 32)]
	var uset := Compute.uniform_set(rd, shader, bufs)
	const DT := 0.012
	var groups := ceili(n / 8.0)
	var parity := 0
	var done := 0
	while done < cfg.iters:
		var cl := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(cl, pipeline)
		rd.compute_list_bind_uniform_set(cl, uset, 0)
		for it in mini(300, cfg.iters - done):
			for stage in 2:
				var pcb := PackedByteArray()
				pcb.resize(32)
				pcb.encode_s32(0, stage)
				pcb.encode_s32(4, n)
				pcb.encode_s32(8, parity)
				pcb.encode_float(12, DT)
				pcb.encode_float(16, dx)
				pcb.encode_float(20, 0.004 * dx * dx / DT) # hillslope diffusion
				pcb.encode_float(24, 1.1) # talus slope
				pcb.encode_float(28, 1.6) # flow concentration
				rd.compute_list_set_push_constant(cl, pcb, pcb.size())
				rd.compute_list_dispatch(cl, groups, groups, 1)
				rd.compute_list_add_barrier(cl)
			parity = 1 - parity
		done += 300
		rd.compute_list_end()
		rd.submit()
		rd.sync()
	h = rd.buffer_get_data(bufs[parity]).to_float32_array()
	rd.free_rid(uset)
	for b in bufs:
		rd.free_rid(b)
	rd.free_rid(pipeline)
	rd.free_rid(shader)
	# Bathymetry: a shelf, then the drop to the ocean floor.
	var sd := _coast_distance(uplift, n, dx)
	for k in n * n:
		if uplift[k] < 0.0:
			var s := minf(-sd[k], 650.0)
			h[k] = -(0.04 * s + 0.6) - (absf(OCEAN_FLOOR) - 0.04 * 650.0 - 0.6) * smoothstep(60.0, 650.0, s)
	return h


## Chamfer distance to the land/sea boundary (positive on land).
static func _coast_distance(uplift: PackedFloat32Array, n: int, dx: float) -> PackedFloat32Array:
	var dist := PackedFloat32Array()
	dist.resize(n * n)
	for k in n * n:
		var land := uplift[k] >= 0.0
		var i := k % n
		var j := k / n
		var edge := false
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni: int = i + o.x
			var nj: int = j + o.y
			if ni >= 0 and nj >= 0 and ni < n and nj < n and (uplift[nj * n + ni] >= 0.0) != land:
				edge = true
		dist[k] = 0.5 * dx if edge else 1e9
	var a := dx
	var b := dx * sqrt(2.0)
	for j in n:
		for i in n:
			var k := j * n + i
			var d := dist[k]
			if i > 0: d = minf(d, dist[k - 1] + a)
			if j > 0:
				d = minf(d, dist[k - n] + a)
				if i > 0: d = minf(d, dist[k - n - 1] + b)
				if i < n - 1: d = minf(d, dist[k - n + 1] + b)
			dist[k] = d
	for j in range(n - 1, -1, -1):
		for i in range(n - 1, -1, -1):
			var k := j * n + i
			var d := dist[k]
			if i < n - 1: d = minf(d, dist[k + 1] + a)
			if j < n - 1:
				d = minf(d, dist[k + n] + a)
				if i < n - 1: d = minf(d, dist[k + n + 1] + b)
				if i > 0: d = minf(d, dist[k + n - 1] + b)
			dist[k] = d
	for k in n * n:
		if uplift[k] < 0.0:
			dist[k] = -dist[k]
	return dist


static func _resize(src: PackedFloat32Array, n_from: int, n_to: int, interp: int) -> PackedFloat32Array:
	var img := Image.create_from_data(n_from, n_from, false, Image.FORMAT_RF, src.to_byte_array())
	img.resize(n_to, n_to, interp)
	return img.get_data().to_float32_array()


# ------------------------------------------------------------------ 2. erosion

## Hydraulic + thermal erosion at n1. Returns {b: heights, dep: net deposition}.
func _erode(b0: PackedFloat32Array) -> Dictionary:
	var n: int = cfg.n1
	var l: float = cfg.domain / (n - 1)
	var b := _resize(b0, cfg.n0, n, Image.INTERPOLATE_CUBIC)
	# Small-scale roughness for the water to find and deepen.
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 1.0 / (l * 6.0)
	noise.fractal_octaves = 3
	var rough := noise.get_image(n, n, false, false, false)
	var rain := PackedFloat32Array()
	rain.resize(n * n)
	var initial := PackedFloat32Array(b)
	for k in n * n:
		if b[k] > 0.0:
			var r := rough.get_pixel(k % n, k / n).r - 0.5
			b[k] += r * (0.6 + 0.012 * b[k])
			# Orographic rain: wetter up high.
			rain[k] = 6.0e-4 * (1.0 + b[k] / 300.0)
	var shader := Compute.load_shader(rd, "res://shaders/sim/hydraulic.glsl")
	var pipeline := rd.compute_pipeline_create(shader)
	var b2 := PackedFloat32Array(b)
	b2.append_array(b)
	var zeros := PackedFloat32Array()
	zeros.resize(n * n)
	var zeros2 := PackedFloat32Array()
	zeros2.resize(n * n * 2)
	var depth := PackedFloat32Array()
	depth.resize(n * n)
	for k in n * n:
		depth[k] = maxf(-b[k], 0.0)
	var flux := PackedFloat32Array()
	flux.resize(n * n * 4)
	var bufs: Array[RID] = [Compute.buffer(rd, b2), Compute.buffer(rd, depth), Compute.buffer(rd, zeros2),
			Compute.buffer(rd, flux), Compute.buffer(rd, zeros2), Compute.buffer(rd, rain)]
	var uset := Compute.uniform_set(rd, shader, bufs)
	var groups := ceili(n / 8.0)
	var iters: int = cfg.iters
	var done := 0
	while done < iters:
		var cl := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(cl, pipeline)
		rd.compute_list_bind_uniform_set(cl, uset, 0)
		for it in mini(200, iters - done):
			for stage in 5:
				var pcb := PackedByteArray()
				pcb.resize(48)
				pcb.encode_s32(0, stage)
				pcb.encode_s32(4, n)
				pcb.encode_float(8, 0.5) # dt (s)
				pcb.encode_float(12, l)
				pcb.encode_float(16, 0.25) # capacity
				pcb.encode_float(20, 0.02) # dissolving
				pcb.encode_float(24, 0.1) # deposition
				pcb.encode_float(28, 0.004) # evaporation
				pcb.encode_float(32, 0.75) # talus slope
				pcb.encode_float(36, 0.5) # thermal rate
				rd.compute_list_set_push_constant(cl, pcb, pcb.size())
				rd.compute_list_dispatch(cl, groups, groups, 1)
				rd.compute_list_add_barrier(cl)
		done += 200
		rd.compute_list_end()
		rd.submit()
		rd.sync()
		progress.call("Eroding... %d%%" % (100 * done / iters))
	var out := rd.buffer_get_data(bufs[0]).to_float32_array().slice(0, n * n)
	rd.free_rid(uset)
	for x in bufs:
		rd.free_rid(x)
	rd.free_rid(pipeline)
	rd.free_rid(shader)
	var dep := PackedFloat32Array()
	dep.resize(n * n)
	for k in n * n:
		dep[k] = maxf(out[k] - initial[k], 0.0)
	return {"b": out, "dep": dep}


# ------------------------------------------------------------------ 5. compose

func _compose(b1: PackedFloat32Array, dep: PackedFloat32Array, hyd: Hydrology, rv: Rivers) -> IslandData:
	var nf: int = cfg.nf
	var domain: float = cfg.domain
	var lakes := PackedFloat32Array()
	lakes.resize(hyd.n * hyd.n)
	for k in hyd.n * hyd.n:
		lakes[k] = hyd.lake_levels[hyd.lake[k]] if hyd.lake[k] >= 0 else -1.0e4
	# Bucket the segments by the area they can affect.
	var bsize := 64.0
	var nb := ceili(domain / bsize)
	var lists := []
	lists.resize(nb * nb)
	for i in lists.size():
		lists[i] = PackedInt32Array()
	var sg := rv.segs
	for s in range(0, sg.size(), Rivers.STRIDE):
		var kind := int(sg[s + 11])
		var hw := maxf(sg[s + 6], sg[s + 7])
		var f := maxf(sg[s + 8], sg[s + 9])
		var r := hw * 1.6 + 4.0
		if kind <= 1:
			r = maxf(r, f + minf(0.5 * f + 20.0, 100.0))
		if kind == 1:
			r = maxf(r, hw + 8.0 * (3.0 * hw + 4.0))
		var lo := Vector2(minf(sg[s], sg[s + 2]), minf(sg[s + 1], sg[s + 3])) - origin - Vector2(r, r)
		var hi := Vector2(maxf(sg[s], sg[s + 2]), maxf(sg[s + 1], sg[s + 3])) - origin + Vector2(r, r)
		for bz in range(clampi(floori(lo.y / bsize), 0, nb - 1), clampi(floori(hi.y / bsize), 0, nb - 1) + 1):
			for bx in range(clampi(floori(lo.x / bsize), 0, nb - 1), clampi(floori(hi.x / bsize), 0, nb - 1) + 1):
				lists[bz * nb + bx].append(s / Rivers.STRIDE)
	var table := PackedInt32Array()
	var index := PackedInt32Array()
	for lst in lists:
		table.append_array([index.size(), lst.size()])
		index.append_array(lst)
	if index.is_empty():
		index.append(0)

	var shader := Compute.load_shader(rd, "res://shaders/sim/compose.glsl")
	var pipeline := rd.compute_pipeline_create(shader)
	var segs := sg if not sg.is_empty() else PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var bufs: Array[RID] = [
		Compute.buffer(rd, b1), Compute.buffer(rd, dep), Compute.buffer(rd, lakes), Compute.buffer(rd, segs),
		_ibuffer(table), _ibuffer(index),
		rd.storage_buffer_create(nf * nf * 4), rd.storage_buffer_create(nf * nf * 4),
		rd.storage_buffer_create(nf * nf * 4), rd.storage_buffer_create(nf * nf * 4),
	]
	var uset := Compute.uniform_set(rd, shader, bufs)
	var pcb := PackedByteArray()
	pcb.resize(32)
	pcb.encode_s32(0, cfg.n1)
	pcb.encode_s32(4, hyd.n)
	pcb.encode_s32(8, nf)
	pcb.encode_s32(12, nb)
	pcb.encode_float(16, origin.x)
	pcb.encode_float(20, origin.y)
	pcb.encode_float(24, domain)
	pcb.encode_float(28, bsize)
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline)
	rd.compute_list_bind_uniform_set(cl, uset, 0)
	rd.compute_list_set_push_constant(cl, pcb, pcb.size())
	rd.compute_list_dispatch(cl, ceili(nf / 8.0), ceili(nf / 8.0), 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	var data := IslandData.new()
	data.size = nf
	data.domain = domain
	data.origin = origin
	data.heights = rd.buffer_get_data(bufs[6]).to_float32_array()
	data.water = rd.buffer_get_data(bufs[7]).to_float32_array()
	data.material = rd.buffer_get_data(bufs[8])
	data.wattr = rd.buffer_get_data(bufs[9])
	data.spawn = rv.spawn
	if data.spawn == Vector3.INF:
		data.spawn = Vector3(0.0, 50.0, 0.0)
	rd.free_rid(uset)
	for x in bufs:
		rd.free_rid(x)
	rd.free_rid(pipeline)
	rd.free_rid(shader)
	return data


func _ibuffer(data: PackedInt32Array) -> RID:
	var bytes := data.to_byte_array()
	if bytes.is_empty():
		bytes.resize(8)
	return rd.storage_buffer_create(bytes.size(), bytes)
