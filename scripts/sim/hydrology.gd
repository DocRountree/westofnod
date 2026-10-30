class_name Hydrology
extends RefCounted
## Drainage of an eroded heightfield (CPU, on a grid of a few hundred cells a side).
##
##  - Lakes: a few landslide dams and glacial hollows are dropped into valleys,
##    then a priority flood with epsilon (Barnes et al. 2014) fills every
##    depression to its spill point, so each lake has a level and an outlet.
##  - Drainage: steepest descent on the filled surface, area by a topological
##    sweep.
##  - Rivers: cells with enough area. Chains run from where they end (the sea, a
##    lake, a confluence) up each main stem, largest first, as polylines with
##    water level and width (hydraulic geometry, w ~ sqrt(area)).

const RIVER_AREA := 4.0e4 # m^2
const RIVER_CELLS := 12.0 # ... and at least this many cells
const OFF := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]

var n: int
var dx: float
var origin: Vector2 # world xz of cell (0, 0)
var h: PackedFloat32Array # bed (lake hollows included)
var sea := PackedByteArray()
var wsurf := PackedFloat32Array() # filled surface: water level over lakes
var rcv := PackedInt32Array()
var area := PackedFloat32Array()
var lake := PackedInt32Array() # lake id or -1
var lake_levels := PackedFloat32Array()
var rivers: Array = [] # {pts, e, w, to_sea, to_lake, parent (river index or -1), join}


func _init(heights: PackedFloat32Array, size: int, cell: float, org: Vector2) -> void:
	h = PackedFloat32Array(heights)
	n = size
	dx = cell
	origin = org
	sea.resize(n * n)
	for k in n * n:
		var i := k % n
		var j := k / n
		if h[k] <= 0.0 or i == 0 or j == 0 or i == n - 1 or j == n - 1:
			sea[k] = 1


func run(rng: RandomNumberGenerator, island_radius: float) -> Hydrology:
	_flood()
	_drainage()
	_make_lakes(rng, island_radius)
	_flood()
	_drainage()
	_find_lakes()
	_rivers()
	return self


func cell_pos(k: int) -> Vector2:
	return origin + Vector2(k % n, k / n) * dx


static func width_of(a: float) -> float:
	return clampf(1.0 + 4.5 * sqrt(a / 1e6), 1.0, 60.0)


## Bilinear sample of a grid array at world p.
func sample(arr: PackedFloat32Array, p: Vector2) -> float:
	var g := (p - origin) / dx
	var i := clampi(floori(g.x), 0, n - 2)
	var j := clampi(floori(g.y), 0, n - 2)
	var fx := clampf(g.x - i, 0.0, 1.0)
	var fz := clampf(g.y - j, 0.0, 1.0)
	var k := j * n + i
	return lerpf(lerpf(arr[k], arr[k + 1], fx), lerpf(arr[k + n], arr[k + n + 1], fx), fz)


# ------------------------------------------------------------------ lakes

func _make_lakes(rng: RandomNumberGenerator, island_radius: float) -> void:
	var sites := PackedInt32Array()
	for k in n * n:
		if sea[k] == 0 and area[k] > 2.0e5 and area[k] < 3.0e7 and h[k] > 6.0:
			sites.append(k)
	if sites.is_empty():
		return
	var count := rng.randi_range(1, 2 + int(island_radius / 1500.0))
	var placed: Array[Vector2] = []
	for t in count * 6:
		if placed.size() >= count:
			break
		var k := sites[rng.randi() % sites.size()]
		var p := cell_pos(k)
		var ok := true
		for q in placed:
			if q.distance_to(p) < 700.0:
				ok = false
		if not ok:
			continue
		placed.append(p)
		var base := h[k]
		if rng.randf() < 0.55:
			# Landslide dam: a mound across the valley; the valley behind floods.
			var rd := rng.randf_range(2.0, 3.0) * maxf(dx, 25.0)
			var hd := rng.randf_range(5.0, 15.0)
			_stamp(p, rd, func(x: float, d: float) -> float: return maxf(x, base + hd * (1.0 - d * d)))
		else:
			# Glacial hollow.
			var rb := rng.randf_range(2.5, 5.0) * maxf(dx, 20.0)
			var db := rng.randf_range(5.0, 14.0)
			_stamp(p, rb, func(x: float, d: float) -> float:
				var f := 1.0 - d * d
				return x - db * f * f)


func _stamp(p: Vector2, r: float, f: Callable) -> void:
	var c := Vector2i(roundi((p.x - origin.x) / dx), roundi((p.y - origin.y) / dx))
	var kr := ceili(r / dx)
	for j in range(maxi(1, c.y - kr), mini(n - 1, c.y + kr + 1)):
		for i in range(maxi(1, c.x - kr), mini(n - 1, c.x + kr + 1)):
			var k := j * n + i
			if sea[k] == 1:
				continue
			var d := (origin + Vector2(i, j) * dx).distance_to(p) / r
			if d < 1.0:
				h[k] = maxf(f.call(h[k], d), 0.3)


## Priority flood with epsilon: wsurf >= h, strictly rising away from the sea.
func _flood() -> void:
	const EPS := 1e-3
	wsurf = PackedFloat32Array(h)
	var closed := PackedByteArray()
	closed.resize(n * n)
	var hk := PackedFloat32Array()
	var hv := PackedInt32Array()
	var pit := PackedInt32Array()
	var head := 0
	for k in n * n:
		if sea[k] == 1:
			closed[k] = 1
			wsurf[k] = 0.0
	for k in n * n:
		if sea[k] == 1:
			continue
		var i := k % n
		var j := k / n
		for o in OFF:
			var nk: int = (j + o.y) * n + i + o.x
			if sea[nk] == 1:
				_push(hk, hv, 0.0, nk)
				break
	while not hk.is_empty() or head < pit.size():
		var c: int
		if head < pit.size():
			c = pit[head]
			head += 1
		else:
			c = _pop(hk, hv)
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
				_push(hk, hv, wsurf[nk], nk)


static func _push(hk: PackedFloat32Array, hv: PackedInt32Array, key: float, v: int) -> void:
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


static func _pop(hk: PackedFloat32Array, hv: PackedInt32Array) -> int:
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


# ------------------------------------------------------------------ drainage

func _drainage() -> void:
	rcv.resize(n * n)
	rcv.fill(-1)
	var ndon := PackedInt32Array()
	ndon.resize(n * n)
	var diag := dx * sqrt(2.0)
	for k in n * n:
		if sea[k] == 1:
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
		if sea[k] == 0:
			area[k] = dx * dx
			if ndon[k] == 0:
				stack.append(k)
	while not stack.is_empty():
		var k := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var r := rcv[k]
		if r < 0 or sea[r] == 1:
			continue
		area[r] += area[k]
		ndon[r] -= 1
		if ndon[r] == 0:
			stack.append(r)


func _find_lakes() -> void:
	lake.resize(n * n)
	lake.fill(-1)
	var levels: Array[float] = []
	for k in n * n:
		if lake[k] >= 0 or sea[k] == 1 or wsurf[k] - h[k] < 0.25:
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
				if lake[nk] < 0 and sea[nk] == 0 and wsurf[nk] - h[nk] >= 0.25:
					lake[nk] = lid
					cells.append(nk)
		if depth < 1.5 or cells.size() < 8:
			for c in cells:
				lake[c] = -2 # a wet hollow, not a lake
		levels.append(level)
	for k in n * n:
		if lake[k] == -2:
			lake[k] = -1
	lake_levels = PackedFloat32Array(levels)


# ------------------------------------------------------------------ rivers

func _is_river(k: int) -> bool:
	return k >= 0 and sea[k] == 0 and lake[k] < 0 and area[k] >= maxf(RIVER_AREA, RIVER_CELLS * dx * dx)


func _rivers() -> void:
	var nn := n * n
	var main_donor := PackedInt32Array()
	main_donor.resize(nn)
	main_donor.fill(-1)
	var lake_donor := PackedInt32Array()
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
	var bottoms := []
	for k in nn:
		if _is_river(k) and (not _is_river(rcv[k]) or main_donor[rcv[k]] != k):
			bottoms.append(k)
	bottoms.sort_custom(func(a: int, b: int) -> bool: return area[a] > area[b])
	var cell_river := PackedInt32Array()
	cell_river.resize(nn)
	cell_river.fill(-1)
	for b in bottoms:
		var cells := PackedInt32Array()
		var r := rcv[b]
		if r >= 0:
			cells.append(r)
		var k: int = b
		while k >= 0:
			cells.append(k)
			cell_river[k] = rivers.size()
			if main_donor[k] < 0 and lake_donor[k] >= 0:
				cells.append(lake_donor[k]) # starts at a lake outlet
				break
			k = main_donor[k]
		var first := cells[0]
		var pts := PackedVector2Array()
		var es := PackedFloat32Array()
		var ws := PackedFloat32Array()
		for c in cells:
			pts.append(cell_pos(c))
			es.append(lake_levels[lake[c]] if lake[c] >= 0 else wsurf[c])
			ws.append(width_of(area[c]))
		var to_sea := sea[first] == 1
		var to_lake := lake[first] >= 0
		var parent := -1 if to_sea or to_lake else cell_river[first]
		if parent >= 0:
			ws[0] = ws[1] # a tributary keeps its own width down to the confluence
		if to_sea:
			# Carry the channel out past the coast so it opens to the sea.
			var dir := (pts[0] - pts[1]).normalized()
			pts.insert(0, pts[0] + dir * dx)
			es.insert(0, -1.5)
			ws.insert(0, ws[0])
			es[1] = minf(es[1], 0.0)
		rivers.append({"pts": pts, "e": es, "w": ws, "to_sea": to_sea, "to_lake": to_lake,
				"parent": parent})
