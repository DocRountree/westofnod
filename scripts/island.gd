class_name Island
extends RefCounted
## One island, simulated once and cached.
##
## 1. Shape and uplift: a noisy, domain-warped radial mask (sometimes several
##    lobes) gives the land; tectonic uplift is strongest in a ridged mountain
##    core and weakest near the coast.
## 2. Landscape evolution (shaders/island_sim.glsl, GPU): stream power erosion
##    against uplift, run to near steady state. Valleys, ridges, drainage
##    basins and the river network emerge from it.
## 3. Lakes: landslide dams and glacial basins dropped into some valleys, then
##    a priority flood (with epsilon) fills every depression to its spill
##    point, so each lake has a level and an outlet.
## 4. Drainage: steepest descent on the filled surface and drainage area by a
##    topological sweep. Cells with enough area are rivers; width follows
##    hydraulic geometry (w ~ sqrt(area)).
## 5. Rivers become polylines: main stems first, smoothed, tributaries joined
##    onto them, with a little natural sinuosity. Gentle, wide reaches meander
##    by migration (Meander), leaving oxbow lakes and old meander scars.
## 6. Output for the terrain shader: the grid (bed height, signed coast distance,
##    lake level, drainage area) and river segments, bucketed for lookup.

const SEG_STRIDE := 12 # (ax, az, bx, bz) (e0, e1, hw0, hw1) (F0, F1, depth, kind)
const KIND_FLOOR := 0 # valley floor only (meander belt axis)
const KIND_RIVER := 1
const KIND_OXBOW := 2 # still water
const KIND_SCAR := 3 # old, silted-up oxbow
const GRID_MAX := 224
const RIVER_AREA := 3.0e4 # m^2 of drainage before a channel shows (at least RIVER_CELLS cells)
const RIVER_CELLS := 14.0
const BUCKET := 256.0
const NO_LAKE := -1.0e4
const BANK_REACH := 120.0 # metres past a floor edge where its banks still shape the ground

const OFF := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]

var id: int
var center: Vector2
var radius: float
var rng := RandomNumberGenerator.new()

var n: int
var dx: float
var origin: Vector2 # world xz of cell (0, 0)
var rect: Rect2 # simulation domain

var uplift := PackedFloat32Array() # < 0 marks ocean
var h := PackedFloat32Array() # bed elevation
var wsurf := PackedFloat32Array() # filled surface (water level over lakes)
var area := PackedFloat32Array()
var rcv := PackedInt32Array()
var sd := PackedFloat32Array() # signed distance to coast, + inland
var lake := PackedInt32Array() # lake id or -1
var lake_levels := PackedFloat32Array()

var grid := PackedFloat32Array() # 4 floats per cell for the GPU
var segs := PackedFloat32Array()
var buckets := {} # Vector2i -> PackedInt32Array of segment indices
var max_reach := 0.0 # largest floor half-width + bank reach of any segment
var spawn := Vector3.INF
var stats := {}


func _init(desc: Dictionary) -> void:
	id = desc.id
	center = desc.center
	radius = desc.r
	rng.seed = desc.seed
	var half := Archipelago.half_extent(radius)
	dx = maxf(14.0, 2.0 * half / GRID_MAX)
	n = ceili(2.0 * half / dx) + 1
	origin = center - Vector2(half, half)
	rect = Rect2(origin, Vector2(n - 1, n - 1) * dx)


func build(sim: IslandSim) -> Island:
	var t0 := Time.get_ticks_msec()
	_fields()
	var t1 := Time.get_ticks_msec()
	sim.run(self)
	var t2 := Time.get_ticks_msec()
	_make_lakes()
	_flood()
	_drainage()
	_coast_distance()
	_find_lakes()
	var t3 := Time.get_ticks_msec()
	_rivers()
	var t4 := Time.get_ticks_msec()
	_pack()
	stats = {"fields": t1 - t0, "sim": t2 - t1, "hydro": t3 - t2, "rivers": t4 - t3,
			"n": n, "dx": dx, "segs": segs.size() / SEG_STRIDE, "lakes": lake_levels.size()}
	return self


func cell_pos(i: int) -> Vector2:
	return origin + Vector2(i % n, i / n) * dx


func _idx(p: Vector2) -> int:
	var c := Vector2i(clampi(roundi((p.x - origin.x) / dx), 0, n - 1),
			clampi(roundi((p.y - origin.y) / dx), 0, n - 1))
	return c.y * n + c.x


## Bilinear sample of a grid array at world p.
func sample(arr: PackedFloat32Array, p: Vector2) -> float:
	var g := (p - origin) / dx
	var i := clampi(floori(g.x), 0, n - 2)
	var j := clampi(floori(g.y), 0, n - 2)
	var fx := clampf(g.x - i, 0.0, 1.0)
	var fz := clampf(g.y - j, 0.0, 1.0)
	var k := j * n + i
	return lerpf(lerpf(arr[k], arr[k + 1], fx), lerpf(arr[k + n], arr[k + n + 1], fx), fz)


# ------------------------------------------------------------------ 1. shape

func _fields() -> void:
	var shape := FastNoiseLite.new()
	shape.seed = rng.randi()
	shape.frequency = 1.0 / (radius * 0.55)
	shape.fractal_octaves = 5
	shape.domain_warp_enabled = true
	shape.domain_warp_amplitude = radius * 0.35
	shape.domain_warp_frequency = 1.0 / (radius * 0.9)
	var ridges := FastNoiseLite.new()
	ridges.seed = rng.randi()
	ridges.frequency = 1.0 / (radius * 0.6 + 400.0)
	ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridges.fractal_octaves = 3
	var jitter := FastNoiseLite.new()
	jitter.seed = rng.randi()
	jitter.frequency = 1.0 / (dx * 3.0)

	# Lobes: the main body plus up to three satellites.
	var lobes := [[center, radius]]
	for k in rng.randi_range(0, 3):
		var c := center + Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.4, 0.8)
		lobes.append([c, radius * rng.randf_range(0.3, 0.55)])
	var size_f := clampf(radius / 3000.0, 0.15, 1.0)
	var head_slope := 0.55 + 1.0 * size_f # uplift / K, per cell: sets the relief
	var u_max := head_slope * dx
	var plains := rng.randf_range(0.5, 1.0) # how far mountains stay from the coast

	uplift.resize(n * n)
	h.resize(n * n)
	var reach := radius * Archipelago.LAND_EXTENT
	for j in n:
		for i in n:
			var k := j * n + i
			var p := origin + Vector2(i, j) * dx
			var s := -1.0
			for l in lobes:
				s = maxf(s, 1.0 - p.distance_to(l[0]) / l[1])
			s += 0.5 * shape.get_noise_2dv(p)
			s -= 2.0 * smoothstep(reach * 0.8, reach, p.distance_to(center))
			if s <= 0.0 or i == 0 or j == 0 or i == n - 1 or j == n - 1:
				uplift[k] = -1.0
				h[k] = 0.0
				continue
			var core := pow(smoothstep(0.12 * plains, 0.5 + 0.45 * plains, s), 1.6)
			var rid := clampf(ridges.get_noise_2dv(p) * 0.5 + 0.5, 0.0, 1.0)
			uplift[k] = u_max * (0.025 + 0.975 * core * (0.25 + 0.75 * rid))
			h[k] = 2.0 + 4.0 * minf(s, 1.0) + 1.5 * jitter.get_noise_2dv(p)


# ------------------------------------------------------------------ 3. lakes

## Landslide dams and glacial basins in some valleys; the flood fill below turns
## them into lakes with an outlet.
func _make_lakes() -> void:
	# Drainage area from the simulation picks the valleys.
	var sites := PackedInt32Array()
	for k in n * n:
		if uplift[k] > 0.0 and area[k] > 1.5e5 and area[k] < 4.0e7 and h[k] > 4.0:
			sites.append(k)
	if sites.is_empty():
		return
	var count := rng.randi_range(0, 1 + int(radius / 900.0))
	var placed: Array[Vector2] = []
	for t in count * 4:
		if placed.size() >= count:
			break
		var k := sites[rng.randi() % sites.size()]
		var p := cell_pos(k)
		var ok := true
		for q in placed:
			if q.distance_to(p) < 600.0:
				ok = false
		if not ok:
			continue
		placed.append(p)
		if rng.randf() < 0.55:
			# Dam: a mound across the valley; the valley behind it floods.
			var rd := rng.randf_range(1.6, 2.6) * maxf(dx, 30.0)
			var hd := rng.randf_range(4.0, 14.0) + 0.02 * h[k]
			_stamp(p, rd, func(x: float, d: float) -> float:
				return maxf(x, h[k] + hd * (1.0 - d * d)))
		else:
			# Basin: a scoured hollow.
			var rb := rng.randf_range(2.0, 4.5) * maxf(dx, 25.0)
			var db := rng.randf_range(4.0, 12.0)
			_stamp(p, rb, func(x: float, d: float) -> float:
				var f := 1.0 - d * d
				return x - db * f * f)


func _stamp(p: Vector2, r: float, f: Callable) -> void:
	var c := Vector2i(roundi((p.x - origin.x) / dx), roundi((p.y - origin.y) / dx))
	var kr := ceili(r / dx)
	for j in range(maxi(1, c.y - kr), mini(n - 1, c.y + kr + 1)):
		for i in range(maxi(1, c.x - kr), mini(n - 1, c.x + kr + 1)):
			var k := j * n + i
			if uplift[k] < 0.0:
				continue
			var d := (origin + Vector2(i, j) * dx).distance_to(p) / r
			if d < 1.0:
				h[k] = maxf(f.call(h[k], d), 0.3)


## Priority flood with epsilon (Barnes et al. 2014): wsurf >= h everywhere and
## strictly rises away from the sea, so every cell drains.
func _flood() -> void:
	const EPS := 1e-3
	wsurf = PackedFloat32Array(h)
	var closed := PackedByteArray()
	closed.resize(n * n)
	var hk := PackedFloat32Array() # binary heap keys
	var hv := PackedInt32Array()
	var pit := PackedInt32Array() # FIFO for cells inside depressions
	var pit_head := 0
	for k in n * n:
		if uplift[k] < 0.0:
			closed[k] = 1
			wsurf[k] = 0.0
	for k in n * n:
		if uplift[k] < 0.0:
			continue
		var i := k % n
		var j := k / n
		for o in OFF:
			var nk: int = (j + o.y) * n + i + o.x
			if closed[nk] == 1 and uplift[nk] < 0.0:
				_heap_push(hk, hv, 0.0, nk)
				break
	while not hk.is_empty() or pit_head < pit.size():
		var c: int
		if pit_head < pit.size():
			c = pit[pit_head]
			pit_head += 1
		else:
			c = _heap_pop(hk, hv)
		var ci := c % n
		var cj := c / n
		var wc := wsurf[c]
		for o in OFF:
			var ni: int = ci + o.x
			var nj: int = cj + o.y
			if ni < 0 or nj < 0 or ni >= n or nj >= n:
				continue
			var nk := nj * n + ni
			if closed[nk] == 1:
				continue
			closed[nk] = 1
			if wsurf[nk] <= wc + EPS:
				wsurf[nk] = wc + EPS
				pit.append(nk)
			else:
				_heap_push(hk, hv, wsurf[nk], nk)


static func _heap_push(hk: PackedFloat32Array, hv: PackedInt32Array, key: float, v: int) -> void:
	var i := hk.size()
	hk.append(key)
	hv.append(v)
	while i > 0:
		var p := (i - 1) >> 1
		if hk[p] <= key:
			break
		hk[i] = hk[p]
		hv[i] = hv[p]
		i = p
	hk[i] = key
	hv[i] = v


static func _heap_pop(hk: PackedFloat32Array, hv: PackedInt32Array) -> int:
	var top := hv[0]
	var last := hk.size() - 1
	var key := hk[last]
	var v := hv[last]
	hk.resize(last)
	hv.resize(last)
	if last == 0:
		return top
	var i := 0
	while true:
		var l := 2 * i + 1
		if l >= last:
			break
		var r := l + 1
		var m := l if r >= last or hk[l] <= hk[r] else r
		if hk[m] >= key:
			break
		hk[i] = hk[m]
		hv[i] = hv[m]
		i = m
	hk[i] = key
	hv[i] = v
	return top


# ------------------------------------------------------------------ 4. drainage

func _drainage() -> void:
	rcv.resize(n * n)
	rcv.fill(-1)
	var ndon := PackedInt32Array()
	ndon.resize(n * n)
	var diag := dx * sqrt(2.0)
	for k in n * n:
		if uplift[k] < 0.0:
			continue
		var i := k % n
		var j := k / n
		var best := 0.0
		for d in 8:
			var o: Vector2i = OFF[d]
			var nk := (j + o.y) * n + i + o.x
			var s := (wsurf[k] - wsurf[nk]) / (diag if (d & 1) == 1 else dx)
			if s > best:
				best = s
				rcv[k] = nk
		if rcv[k] >= 0:
			ndon[rcv[k]] += 1
	area.resize(n * n)
	area.fill(0.0)
	var stack := PackedInt32Array()
	for k in n * n:
		if uplift[k] >= 0.0:
			area[k] = dx * dx
			if ndon[k] == 0:
				stack.append(k)
	while not stack.is_empty():
		var k := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var r := rcv[k]
		if r < 0 or uplift[r] < 0.0:
			continue
		area[r] += area[k]
		ndon[r] -= 1
		if ndon[r] == 0:
			stack.append(r)


## Chamfer distance transform to the land/sea boundary, signed (+ on land).
func _coast_distance() -> void:
	var big := 1e9
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
		dist[k] = 0.5 * dx if edge else big
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
	sd.resize(n * n)
	for k in n * n:
		sd[k] = dist[k] if uplift[k] >= 0.0 else -dist[k]


func _find_lakes() -> void:
	lake.resize(n * n)
	lake.fill(-1)
	var levels: Array[float] = []
	for k in n * n:
		if lake[k] >= 0 or uplift[k] < 0.0 or wsurf[k] - h[k] < 0.25:
			continue
		var lid := levels.size()
		var level := 0.0
		var depth := 0.0
		var cells := PackedInt32Array([k])
		lake[k] = lid
		var q := 0
		while q < cells.size():
			var c := cells[q]
			q += 1
			level = maxf(level, wsurf[c])
			depth = maxf(depth, wsurf[c] - h[c])
			for o in OFF:
				var nk: int = c + o.y * n + o.x
				if lake[nk] < 0 and uplift[nk] >= 0.0 and wsurf[nk] - h[nk] >= 0.25:
					lake[nk] = lid
					cells.append(nk)
		if depth < 0.8:
			# Too shallow to matter: a wet hollow, not a lake.
			for c in cells:
				lake[c] = -2
		levels.append(level)
	for k in n * n:
		if lake[k] == -2:
			lake[k] = -1
	lake_levels = PackedFloat32Array(levels)


# ------------------------------------------------------------------ 5. rivers

static func width_of(a: float) -> float:
	return clampf(0.8 + 4.5 * sqrt(a / 1e6), 0.8, 60.0)


func _is_river(k: int) -> bool:
	return k >= 0 and uplift[k] >= 0.0 and lake[k] < 0 and area[k] >= maxf(RIVER_AREA, RIVER_CELLS * dx * dx)


func _rivers() -> void:
	var nn := n * n
	var main_donor := PackedInt32Array()
	main_donor.resize(nn)
	main_donor.fill(-1)
	var lake_donor := PackedInt32Array() # largest lake cell draining into a river cell
	lake_donor.resize(nn)
	lake_donor.fill(-1)
	for k in nn:
		var r := rcv[k]
		if r < 0 or not _is_river(r):
			continue
		if _is_river(k):
			if main_donor[r] < 0 or area[k] > area[main_donor[r]]:
				main_donor[r] = k
		elif lake[k] >= 0 and (lake_donor[r] < 0 or area[k] > area[lake_donor[r]]):
			lake_donor[r] = k
	# Chains run from where they end (sea, lake, or a confluence) up their main stem.
	var bottoms := []
	for k in nn:
		if not _is_river(k):
			continue
		var r := rcv[k]
		if not _is_river(r) or main_donor[r] != k:
			bottoms.append(k)
	bottoms.sort_custom(func(a: int, b: int) -> bool: return area[a] > area[b])
	var cell_chain := PackedInt32Array()
	cell_chain.resize(nn)
	cell_chain.fill(-1)
	var finals: Array = [] # per chain: {pts, e, w}
	for b in bottoms:
		var cells := PackedInt32Array()
		var r := rcv[b]
		if r >= 0:
			cells.append(r)
		var k: int = b
		while k >= 0:
			cells.append(k)
			cell_chain[k] = finals.size()
			if main_donor[k] < 0 and lake_donor[k] >= 0:
				cells.append(lake_donor[k]) # outlet: start inside the lake
				break
			k = main_donor[k]
		finals.append(_build_chain(cells, cell_chain, finals))


## Turns a chain of cells (downstream first) into a smoothed (and possibly
## meandering) river, emits its segments and returns its final polyline.
func _build_chain(cells: PackedInt32Array, cell_chain: PackedInt32Array, finals: Array) -> Dictionary:
	var pts := PackedVector2Array()
	var es := PackedFloat32Array()
	var ws := PackedFloat32Array()
	for c in cells:
		pts.append(cell_pos(c))
		es.append(lake_levels[lake[c]] if lake[c] >= 0 else wsurf[c])
		ws.append(width_of(area[c]))
	var first := cells[0]
	var to_sea := uplift[first] < 0.0
	var to_lake := lake[first] >= 0
	if not to_sea and not to_lake:
		ws[0] = ws[1] # a tributary keeps its own width down to the confluence
	if pts.size() < 2:
		return {"pts": pts, "e": es, "w": ws}
	if to_sea:
		var dir := (pts[0] - pts[1]).normalized()
		pts.insert(0, pts[0] + dir * dx * 0.7)
		es.insert(0, -1.2)
		ws.insert(0, ws[0])
	# Soften the eight-direction staircase of the grid path, then round it off.
	pts = _smooth(pts, 3)
	for it in 3:
		var c := _chaikin(pts, es, ws)
		pts = c[0]
		es = c[1]
		ws = c[2]
	# Join a tributary onto its parent's final course.
	if not to_sea and not to_lake and cell_chain[first] >= 0:
		var par: Dictionary = finals[cell_chain[first]]
		var pp: PackedVector2Array = par.pts
		var best := 0
		for i in pp.size():
			if pp[i].distance_squared_to(pts[0]) < pp[best].distance_squared_to(pts[0]):
				best = i
		if not pp.is_empty():
			pts[0] = pp[best]
			es[0] = minf(es[0], par.e[best])
	# Resample by arclength.
	var res := _resample(pts, es, ws, clampf(ws[ws.size() / 2] * 1.5, 5.0, 30.0))
	pts = res[0]
	es = res[1]
	ws = res[2]
	for i in range(1, es.size()):
		es[i] = maxf(es[i], es[i - 1]) # water never flows uphill
	var out := _meander_reach(pts, es, ws, to_sea)
	pts = out[0]
	es = out[1]
	ws = out[2]
	var cum := _cumulative(pts)
	for i in pts.size() - 1:
		var slope := (es[i + 1] - es[i]) / maxf(cum[i + 1] - cum[i], 0.1)
		_emit(pts[i], pts[i + 1], es[i], es[i + 1], ws[i] * 0.5, ws[i + 1] * 0.5,
				_floor_width(ws[i], slope), _floor_width(ws[i + 1], slope),
				_depth(0.5 * (ws[i] + ws[i + 1])), KIND_RIVER)
	if spawn == Vector3.INF and to_sea and ws[ws.size() / 3] > 5.0:
		for i in range(pts.size() / 4, pts.size() - 1):
			if es[i] > 2.0 and es[i] < 25.0:
				var t := (pts[i + 1] - pts[i]).normalized()
				var p := pts[i] + Vector2(-t.y, t.x) * (ws[i] * 0.5 + 8.0)
				spawn = Vector3(p.x, es[i] + 3.0, p.y)
				break
	return {"pts": pts, "e": es, "w": ws}


func _floor_width(w: float, slope: float) -> float:
	# Half-width of the flat valley floor: broad in the lowlands, a narrow
	# strip in steep headwaters.
	return 0.5 * w + lerpf(2.5 * w + 6.0, 0.3 * w + 1.0, smoothstep(0.003, 0.06, slope))


static func _depth(w: float) -> float:
	return clampf(0.35 + 0.09 * w, 0.35, 4.0)


## Natural sinuosity everywhere, and true meandering (with cutoffs and oxbows)
## where the river is wide and the valley gentle.
func _meander_reach(pts: PackedVector2Array, es: PackedFloat32Array, ws: PackedFloat32Array,
		to_sea: bool) -> Array:
	var cum := _cumulative(pts)
	var total := cum[cum.size() - 1]
	var m := pts.size()
	# Find the longest gentle, wide stretch.
	var best_a := -1
	var best_b := -1
	var a := -1
	for i in m:
		var j := mini(i + 4, m - 1)
		var g := (es[j] - es[maxi(i - 4, 0)]) / maxf(cum[j] - cum[maxi(i - 4, 0)], 1.0)
		var ok := g < 0.007 and ws[i] >= 3.5 and es[i] > 0.3
		if ok and a < 0:
			a = i
		if (not ok or i == m - 1) and a >= 0:
			var b := i
			if best_a < 0 or cum[b] - cum[a] > cum[best_b] - cum[best_a]:
				best_a = a
				best_b = b
			a = -1
	var wmid := ws[(best_a + best_b) / 2] if best_a >= 0 else 0.0
	if best_a < 0 or cum[best_b] - cum[best_a] < 6.0 * 11.0 * wmid:
		return _wiggle(pts, es, ws)
	# Valley axis: the stretch smoothed heavily, so the frame mapping can't fold.
	var axis := pts.slice(best_a, best_b + 1)
	var ae := es.slice(best_a, best_b + 1)
	var aw := ws.slice(best_a, best_b + 1)
	axis = _smooth(axis, 6)
	var acum := _cumulative(axis)
	var length := acum[acum.size() - 1]
	# Belt half-width from the room the valley gives: how far one can go across
	# before the ground rises well above the river.
	const BELT_DS := 20.0
	var belt := PackedFloat32Array()
	var x := 0.0
	while x <= length + BELT_DS:
		var fr := _frame(axis, acum, x)
		var e := _lerp_at(ae, acum, x)
		var w := _lerp_at(aw, acum, x)
		var room := 1e9
		for side in [-1.0, 1.0]:
			var d := 0.0
			while d < 16.0 * w:
				d += maxf(w, 6.0)
				if sample(h, fr[0] + fr[1] * d * side) > e + 4.0 + 0.4 * w:
					break
			room = minf(room, d)
		var end_taper := minf(1.0, minf(x, length - x) / (11.0 * w))
		belt.append(clampf(room - w, 1.5 * w, 9.0 * w) * end_taper + 0.5 * w)
		x += BELT_DS
	# Smooth the belt so the bluffs don't zig-zag.
	for it in 3:
		for i in range(1, belt.size() - 1):
			belt[i] = 0.25 * belt[i - 1] + 0.5 * belt[i] + 0.25 * belt[i + 1]
	var sim := Meander.migrate(length, wmid, belt, BELT_DS, rng)
	var mp: PackedVector2Array = sim.pts
	# Back to the world: the valley axis frame.
	var op := PackedVector2Array()
	var oe := PackedFloat32Array()
	var ow := PackedFloat32Array()
	op.append_array(pts.slice(0, best_a))
	oe.append_array(es.slice(0, best_a))
	ow.append_array(ws.slice(0, best_a))
	for q in mp:
		var fr := _frame(axis, acum, q.x)
		op.append(fr[0] + fr[1] * q.y)
		oe.append(_lerp_at(ae, acum, q.x))
		ow.append(_lerp_at(aw, acum, q.x))
	op.append_array(pts.slice(best_b + 1))
	oe.append_array(es.slice(best_b + 1))
	ow.append_array(ws.slice(best_b + 1))
	# The floodplain: flat floor across the whole belt, along the axis.
	for i in axis.size() - 1:
		var bi0 := clampi(int(acum[i] / BELT_DS), 0, belt.size() - 1)
		var bi1 := clampi(int(acum[i + 1] / BELT_DS), 0, belt.size() - 1)
		_emit(axis[i], axis[i + 1], ae[i], ae[i + 1], 0.0, 0.0,
				belt[bi0] + aw[i] * 1.5, belt[bi1] + aw[i + 1] * 1.5, 0.0, KIND_FLOOR)
	# Oxbow lakes (recent) and meander scars (old, silted up).
	for ox in sim.oxbows:
		var opts: PackedVector2Array = ox.pts
		var trim := maxi(1, ceili(wmid * 1.2 / maxf(wmid, 3.0)))
		if opts.size() < 2 * trim + 4:
			continue
		var level := _lerp_at(ae, acum, opts[opts.size() / 2].x) - 0.25
		var kind := KIND_OXBOW if ox.age < 0.55 else KIND_SCAR
		var wo := wmid * (0.85 if kind == KIND_OXBOW else 0.7)
		var prev := Vector2.INF
		for i in range(trim, opts.size() - trim):
			var fr := _frame(axis, acum, opts[i].x)
			var p: Vector2 = fr[0] + fr[1] * opts[i].y
			if prev != Vector2.INF:
				_emit(prev, p, level, level, wo * 0.5, wo * 0.5, 0.0, 0.0,
						_depth(wo) * (1.0 if kind == KIND_OXBOW else 0.3), kind)
			prev = p
	return [op, oe, ow]


## Small streams aren't straight either: an irregular sway from 1D value noise
## at three scales, with its amplitude itself varying along the stream, tapered
## to zero at both ends so joins stay put.
func _wiggle(pts: PackedVector2Array, es: PackedFloat32Array, ws: PackedFloat32Array) -> Array:
	var cum := _cumulative(pts)
	var total := cum[cum.size() - 1]
	var table := PackedFloat32Array()
	for i in 256:
		table.append(rng.randf_range(-1.0, 1.0))
	var out := PackedVector2Array(pts)
	for i in range(1, pts.size() - 1):
		var t := (pts[i + 1] - pts[i - 1]).normalized()
		var w := ws[i]
		var lam := maxf(14.0 * w, 30.0)
		var u := cum[i] / lam
		var taper := minf(1.0, minf(cum[i], total - cum[i]) / lam)
		var amp := 0.6 + 0.8 * absf(_noise1(table, u * 0.31 + 50.0))
		var off := (_noise1(table, u) + 0.45 * _noise1(table, u * 2.3 + 100.0)
				+ 0.2 * _noise1(table, u * 5.1 + 170.0)) * w * 1.6 * amp * taper
		out[i] = pts[i] + Vector2(-t.y, t.x) * clampf(off, -dx * 0.3, dx * 0.3)
	return [out, es, ws]


## Smooth 1D value noise in [-1, 1] over a 256-entry table.
static func _noise1(table: PackedFloat32Array, u: float) -> float:
	var i := floori(u)
	var f := u - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(table[posmod(i, 256)], table[posmod(i + 1, 256)], f)


func _emit(a: Vector2, b: Vector2, e0: float, e1: float, hw0: float, hw1: float,
		f0: float, f1: float, depth: float, kind: int) -> void:
	if a.distance_squared_to(b) < 0.01:
		return
	segs.append_array([a.x, a.y, b.x, b.y, e0, e1, hw0, hw1, f0, f1, depth, float(kind)])


# ------------------------------------------------------------------ polyline helpers

## Chaikin corner cutting with fixed endpoints, carrying per-point values.
static func _chaikin(pts: PackedVector2Array, es: PackedFloat32Array, ws: PackedFloat32Array) -> Array:
	var p2 := PackedVector2Array([pts[0]])
	var e2 := PackedFloat32Array([es[0]])
	var w2 := PackedFloat32Array([ws[0]])
	for i in pts.size() - 1:
		p2.append(pts[i].lerp(pts[i + 1], 0.25))
		e2.append(lerpf(es[i], es[i + 1], 0.25))
		w2.append(lerpf(ws[i], ws[i + 1], 0.25))
		p2.append(pts[i].lerp(pts[i + 1], 0.75))
		e2.append(lerpf(es[i], es[i + 1], 0.75))
		w2.append(lerpf(ws[i], ws[i + 1], 0.75))
	p2.append(pts[pts.size() - 1])
	e2.append(es[es.size() - 1])
	w2.append(ws[ws.size() - 1])
	return [p2, e2, w2]


static func _smooth(pts: PackedVector2Array, iters: int) -> PackedVector2Array:
	var p := PackedVector2Array(pts)
	for it in iters:
		var q := PackedVector2Array(p)
		for i in range(1, p.size() - 1):
			q[i] = p[i - 1] * 0.25 + p[i] * 0.5 + p[i + 1] * 0.25
		p = q
	return p


static func _resample(pts: PackedVector2Array, es: PackedFloat32Array, ws: PackedFloat32Array,
		ds: float) -> Array:
	var cum := _cumulative(pts)
	var total := cum[cum.size() - 1]
	var count := maxi(1, ceili(total / ds))
	var op := PackedVector2Array()
	var oe := PackedFloat32Array()
	var ow := PackedFloat32Array()
	var j := 0
	for s in count + 1:
		var x := total * s / count
		while j < pts.size() - 2 and cum[j + 1] < x:
			j += 1
		var f := clampf((x - cum[j]) / maxf(cum[j + 1] - cum[j], 1e-4), 0.0, 1.0)
		op.append(pts[j].lerp(pts[j + 1], f))
		oe.append(lerpf(es[j], es[j + 1], f))
		ow.append(lerpf(ws[j], ws[j + 1], f))
	return [op, oe, ow]


static func _cumulative(pts: PackedVector2Array) -> PackedFloat32Array:
	var cum := PackedFloat32Array()
	cum.resize(pts.size())
	for k in range(1, pts.size()):
		cum[k] = cum[k - 1] + pts[k].distance_to(pts[k - 1])
	return cum


static func _lerp_at(v: PackedFloat32Array, cum: PackedFloat32Array, x: float) -> float:
	x = clampf(x, 0.0, cum[cum.size() - 1])
	var i := clampi(cum.bsearch(x) - 1, 0, v.size() - 2)
	return lerpf(v[i], v[i + 1], clampf((x - cum[i]) / maxf(cum[i + 1] - cum[i], 1e-4), 0.0, 1.0))


## Point and left normal of the polyline at arclength x.
static func _frame(pts: PackedVector2Array, cum: PackedFloat32Array, x: float) -> Array:
	x = clampf(x, 0.0, cum[cum.size() - 1])
	var i := clampi(cum.bsearch(x) - 1, 0, pts.size() - 2)
	var seg := maxf(cum[i + 1] - cum[i], 1e-4)
	var f := clampf((x - cum[i]) / seg, 0.0, 1.0)
	# Blend tangents of neighbouring segments so the normal turns smoothly.
	var t0 := (pts[i + 1] - pts[i]).normalized()
	var t1 := t0
	if f < 0.5 and i > 0:
		t1 = (pts[i] - pts[i - 1]).normalized()
		f = 0.5 + f
		var t := t1.lerp(t0, f).normalized()
		return [pts[i].lerp(pts[i + 1], (x - cum[i]) / seg), Vector2(-t.y, t.x)]
	elif f >= 0.5 and i < pts.size() - 2:
		t1 = (pts[i + 2] - pts[i + 1]).normalized()
		var t := t0.lerp(t1, f - 0.5).normalized()
		return [pts[i].lerp(pts[i + 1], f), Vector2(-t.y, t.x)]
	return [pts[i].lerp(pts[i + 1], f), Vector2(-t0.y, t0.x)]


# ------------------------------------------------------------------ 6. output

func _pack() -> void:
	grid.resize(n * n * 4)
	for k in n * n:
		grid[k * 4] = h[k]
		grid[k * 4 + 1] = sd[k]
		grid[k * 4 + 2] = lake_levels[lake[k]] if lake[k] >= 0 else NO_LAKE
		grid[k * 4 + 3] = area[k]
	for s in range(0, segs.size(), SEG_STRIDE):
		var f := maxf(segs[s + 8], segs[s + 9])
		var hw := maxf(segs[s + 6], segs[s + 7])
		var r := maxf(f, hw * 1.6 + 2.0) + BANK_REACH
		max_reach = maxf(max_reach, r)
		var lo := Vector2(minf(segs[s], segs[s + 2]), minf(segs[s + 1], segs[s + 3])) - Vector2(r, r)
		var hi := Vector2(maxf(segs[s], segs[s + 2]), maxf(segs[s + 1], segs[s + 3])) + Vector2(r, r)
		for bz in range(floori(lo.y / BUCKET), floori(hi.y / BUCKET) + 1):
			for bx in range(floori(lo.x / BUCKET), floori(hi.x / BUCKET) + 1):
				var key := Vector2i(bx, bz)
				if not buckets.has(key):
					buckets[key] = PackedInt32Array()
				buckets[key].append(s / SEG_STRIDE)
