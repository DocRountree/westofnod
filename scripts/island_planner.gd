class_name IslandPlanner
extends RefCounted
## Hydrology-first plan of one island, built once and cached by Archipelago.
##
## 1. Coastline: a union of star-shaped lobes (radius = Fourier series in angle).
## 2. River network, grown inland from mouths on the coast (after Genevaux et al.
##    2013): nodes are expanded lowest-first; each child is placed upstream with
##    an elevation raised by the local river gradient, so every river flows
##    downhill to the sea. Branching gives tributaries; some nodes open into lakes
##    (river in, outlet out) and some mountain sources end in tarns.
## 3. Drainage area -> channel width; widening into an estuary at the mouth.
## 4. Rivers become polylines: smoothed through the nodes, with lowland main stems
##    meandering (Kinoshita curve) and the tightest bends cut off as oxbow lakes.
##
## Output is flat float arrays the terrain shader consumes (see terrain_gen.glsl).

const SEG_STRIDE := 12 # (x0, z0, x1, z1) (e0, e1, w0, w1) (F0, F1, side slope, kind + 4 * chain)
const LAKE_STRIDE := 8 # (x, z, radius, level) (depth, phase, 0, 0)
const LOBE_STRIDE := 24 # (x, z, R, 0) amp[9] phase[9] 0 0
const PEAK_STRIDE := 4 # (x, z, radius, height)
const HARMONICS := 9
const KIND_DRY := 0 # valley floor without a permanent stream
const KIND_RIVER := 1
const KIND_OXBOW := 2
const WET_WIDTH := 2.0

var center: Vector2
var radius: float
var rng := RandomNumberGenerator.new()
var L := 100.0 # network step

var lobes: Array = [] # [Vector2 c, float R, PackedFloat32Array amp, PackedFloat32Array ph]
var peaks: Array = [] # [Vector2 p, float rad, float h]

# network
var pos := PackedVector2Array()
var elev := PackedFloat32Array()
var parent := PackedInt32Array()
var gradient := PackedFloat32Array() # river slope at node
var lake_r := PackedFloat32Array() # > 0: node is the centre of a lake
var _grid := {} # Vector2i -> Array[int] nodes
var _egrid := {} # Vector2i -> Array[int] edges (edge id = child node id)
var _lakes: Array = [] # [Vector2 c, float R]

# output
var segs := PackedFloat32Array()
var lakes := PackedFloat32Array()
var lobe_data := PackedFloat32Array()
var peak_data := PackedFloat32Array()
var spawn := Vector3.INF
var _chain := 0 # id of the polyline being emitted (valleys of one chain never blend)
var bounds := Rect2()


func _init(c: Vector2, r: float, seed: int) -> void:
	center = c
	radius = r
	rng.seed = seed
	L = clampf(r / 11.0, 55.0, 150.0)


func build() -> IslandPlanner:
	_make_shape()
	_grow_network()
	_emit_rivers()
	return self


# ------------------------------------------------------------------ shape

func _make_shape() -> void:
	var count := 1 + rng.randi_range(0, 3)
	for li in count:
		var c := center
		var R := radius * 0.85
		if li > 0:
			c += Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.35, 1.0)
			R = radius * rng.randf_range(0.3, 0.6)
		var amp := PackedFloat32Array()
		var ph := PackedFloat32Array()
		var total := 0.0
		for k in HARMONICS:
			var a := rng.randf_range(0.0, 0.5) / pow(k + 2.0, 1.0)
			amp.append(a)
			ph.append(rng.randf() * TAU)
			total += a
		if total > 0.6: # keep R*f within [0.4R, 1.6R]
			for k in HARMONICS:
				amp[k] *= 0.6 / total
		lobes.append([c, R, amp, ph])
		lobe_data.append_array([c.x, c.y, R, 0.0])
		lobe_data.append_array(amp)
		lobe_data.append_array(ph)
		lobe_data.append_array([0.0, 0.0])
	var bmin := center
	var bmax := center
	for l in lobes:
		bmin = bmin.min(l[0] - Vector2.ONE * l[1] * 1.6)
		bmax = bmax.max(l[0] + Vector2.ONE * l[1] * 1.6)
	bounds = Rect2(bmin, bmax - bmin)

	var size_f := clampf(radius / 1800.0, 0.3, 1.0)
	var n_peaks := 1 + mini(int(radius / 700.0), 4)
	var tries := 0
	while peaks.size() < n_peaks and tries < 60:
		tries += 1
		var p := center + Vector2.from_angle(rng.randf() * TAU) * radius * sqrt(rng.randf()) * 0.8
		if coast(p) < radius * 0.2:
			continue
		var rad := radius * rng.randf_range(0.3, 0.6)
		var h := rng.randf_range(0.5, 1.0) * size_f
		peaks.append([p, rad, h])
		peak_data.append_array([p.x, p.y, rad, h])


## Signed distance-ish to the coast in metres (positive inland). Mirrors coast() in GLSL.
func coast(p: Vector2) -> float:
	var best := -1e5
	for l in lobes:
		var d: Vector2 = p - l[0]
		var len := d.length()
		if l[1] * 1.6 - len <= best:
			continue
		var th := atan2(d.y, d.x)
		var f := 1.0
		var amp: PackedFloat32Array = l[2]
		var ph: PackedFloat32Array = l[3]
		for k in HARMONICS:
			f += amp[k] * cos((k + 2) * th + ph[k])
		best = maxf(best, l[1] * maxf(f, 0.3) - len)
	return best


## 0..~1 mountain mass. Mirrors mountain() in GLSL.
func mountain(p: Vector2) -> float:
	var m := 0.0
	for pk in peaks:
		var q := 1.0 - minf(p.distance_squared_to(pk[0]) / (pk[1] * pk[1]), 1.0)
		m = maxf(m, pk[2] * q * q)
	return m


func river_slope(p: Vector2) -> float:
	var inland := clampf(coast(p) / 1500.0, 0.0, 1.0)
	var m := mountain(p)
	return 0.003 + 0.008 * inland + 0.09 * m * m


func side_slope(p: Vector2) -> float:
	var inland := clampf(coast(p) / 1500.0, 0.0, 1.0)
	return 0.03 + 0.05 * inland + 0.65 * mountain(p)


# ------------------------------------------------------------------ network growth

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / L), floori(p.y / L))


func _add_node(p: Vector2, e: float, par: int, g: float) -> int:
	var id := pos.size()
	pos.append(p)
	elev.append(e)
	parent.append(par)
	gradient.append(g)
	lake_r.append(0.0)
	var c := _cell(p)
	if not _grid.has(c):
		_grid[c] = []
	_grid[c].append(id)
	if par >= 0:
		var a := pos[par]
		var steps := maxi(1, ceili(a.distance_to(p) / (L * 0.5)))
		var seen := {}
		for k in steps + 1:
			var ec := _cell(a.lerp(p, float(k) / steps))
			if seen.has(ec):
				continue
			seen[ec] = true
			if not _egrid.has(ec):
				_egrid[ec] = []
			_egrid[ec].append(id)
	return id


func _near_nodes(p: Vector2, r: float, ignore: int) -> bool:
	var c := _cell(p)
	var k := ceili(r / L)
	for z in range(c.y - k, c.y + k + 1):
		for x in range(c.x - k, c.x + k + 1):
			for id in _grid.get(Vector2i(x, z), []):
				if id != ignore and pos[id].distance_to(p) < r:
					return true
	return false


func _crosses(a: Vector2, b: Vector2, from_node: int) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / (L * 0.5)))
	var seen := {}
	for k in steps + 1:
		var c := _cell(a.lerp(b, float(k) / steps))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for eid in _egrid.get(c + Vector2i(dx, dz), []):
					if seen.has(eid):
						continue
					seen[eid] = true
					var pa: int = parent[eid]
					if pa == from_node or eid == from_node:
						continue
					if Geometry2D.segment_intersects_segment(a, b, pos[pa], pos[eid]) != null:
						return true
					if Geometry2D.get_closest_point_to_segment(b, pos[pa], pos[eid]).distance_to(b) < L * 0.4:
						return true
	return false


func _in_lake(p: Vector2, margin: float) -> bool:
	for lk in _lakes:
		if p.distance_to(lk[0]) < lk[1] + margin:
			return true
	return false


func _try_child(from: int, angle: float, dist: float) -> int:
	var a := pos[from]
	for attempt in 6:
		var th := angle + rng.randf_range(-0.4, 0.4)
		var len := dist * rng.randf_range(0.85, 1.15)
		var q := a + Vector2.from_angle(th) * len
		if coast(q) < L * 0.45:
			continue
		if _near_nodes(q, L * 0.72, from) or _near_nodes(a.lerp(q, 0.5), L * 0.45, from):
			continue
		if _in_lake(q, L * 0.35) or _crosses(a, q, from):
			continue
		var g := river_slope(q) * rng.randf_range(0.8, 1.25)
		var run := len - (lake_r[from] if lake_r[from] > 0.0 else 0.0)
		return _add_node(q, elev[from] + run * g, from, g)
	return -1


func _grow_network() -> void:
	# Mouths: well-spaced points on the coastline.
	var coastal: Array[Vector2] = []
	for l in lobes:
		var R: float = l[1]
		var n := ceili(TAU * R / (L * 0.3))
		for k in n:
			var th := TAU * k / n
			var d := Vector2.from_angle(th)
			var amp: PackedFloat32Array = l[2]
			var ph: PackedFloat32Array = l[3]
			var f := 1.0
			for h in HARMONICS:
				f += amp[h] * cos((h + 2) * th + ph[h])
			var p: Vector2 = l[0] + d * R * maxf(f, 0.3)
			if absf(coast(p)) < 1.0:
				coastal.append(p)
	for i in range(coastal.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := coastal[i]
		coastal[i] = coastal[j]
		coastal[j] = t
	var mouths: Array[Vector2] = []
	for p in coastal:
		var ok := true
		for m in mouths:
			if m.distance_to(p) < L * 1.7:
				ok = false
				break
		if ok and rng.randf() < 0.75:
			mouths.append(p)
	var open: Array = [] # [key, id], kept sorted descending so pop_back() is lowest
	for p in mouths:
		var id := _add_node(p, 0.0, -1, river_slope(p))
		_push(open, id)

	while not open.is_empty():
		var id: int = open.pop_back()[1]
		_expand(id, open)


func _push(open: Array, id: int) -> void:
	var key := elev[id] + rng.randf() * 3.0
	var lo := 0
	var hi := open.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if open[mid][0] > key:
			lo = mid + 1
		else:
			hi = mid
	open.insert(lo, [key, id])


func _dir_of(id: int) -> float:
	if parent[id] >= 0:
		return (pos[id] - pos[parent[id]]).angle()
	# mouth: head inland, against the coast gradient
	var p := pos[id]
	var e := 5.0
	var g := Vector2(coast(p + Vector2(e, 0)) - coast(p - Vector2(e, 0)),
			coast(p + Vector2(0, e)) - coast(p - Vector2(0, e)))
	return g.angle()


func _expand(id: int, open: Array) -> void:
	var dir := _dir_of(id)
	var p := pos[id]
	var step := L

	# Open a lake upstream of this node: the node becomes the outlet on its shore.
	if parent[id] >= 0 and elev[id] > 1.5 and rng.randf() < 0.06:
		var R := L * rng.randf_range(0.35, 1.3)
		var c := p + Vector2.from_angle(dir) * R
		if coast(c) > R + L * 0.5 and not _near_nodes(c, R + L * 0.4, id) \
				and not _in_lake(c, R + L * 0.5) and not _crosses(p, c + Vector2.from_angle(dir) * R, id):
			var lid := _add_node(c, elev[id] + 0.05, id, gradient[id])
			lake_r[lid] = R
			_lakes.append([c, R])
			lakes.append_array([c.x, c.y, R, elev[lid], 1.5 + 0.06 * R, rng.randf() * TAU, 0.0, 0.0])
			_push(open, lid)
			return
	if lake_r[id] > 0.0:
		step = lake_r[id] + L * 0.75

	var kids := 0
	var u := rng.randf()
	if u < 0.45:
		kids += int(_try_child(id, dir, step) >= 0)
	elif u < 0.82:
		kids += int(_try_child(id, dir + rng.randf_range(-0.2, 0.2), step) >= 0)
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		kids += int(_try_child(id, dir + side * rng.randf_range(0.8, 1.3), step * 0.9) >= 0)
	else:
		kids += int(_try_child(id, dir - rng.randf_range(0.4, 0.8), step) >= 0)
		kids += int(_try_child(id, dir + rng.randf_range(0.4, 0.8), step) >= 0)
	if lake_r[id] > 0.0 and kids < 3:
		kids += int(_try_child(id, dir + PI * rng.randf_range(0.35, 0.6), step) >= 0)
	# Pick up any children that were placed (they are the newest nodes).
	for c in range(pos.size() - kids, pos.size()):
		_push(open, c)

	# Mountain sources sometimes rise from a small tarn.
	if kids == 0 and lake_r[id] == 0.0 and mountain(p) > 0.3 and rng.randf() < 0.18:
		var R := rng.randf_range(14.0, 34.0)
		if not _in_lake(p, R + 20.0):
			lake_r[id] = R
			_lakes.append([p, R])
			lakes.append_array([p.x, p.y, R, elev[id] + 0.05, 1.5 + 0.05 * R, rng.randf() * TAU, 0.0, 0.0])


# ------------------------------------------------------------------ rivers -> segments

func _emit_rivers() -> void:
	var n := pos.size()
	var area := PackedFloat32Array()
	area.resize(n)
	area.fill(L * L)
	for i in range(n - 1, -1, -1):
		if parent[i] >= 0:
			area[parent[i]] += area[i]
	var width := PackedFloat32Array()
	width.resize(n)
	for i in n:
		width[i] = clampf(6.0 * sqrt(area[i] / 1e6) + 0.8, 0.8, 45.0)
	var main_child := PackedInt32Array()
	main_child.resize(n)
	main_child.fill(-1)
	for i in n:
		var pa := parent[i]
		if pa >= 0 and (main_child[pa] < 0 or area[i] > area[main_child[pa]]):
			main_child[pa] = i
	for i in n:
		if parent[i] >= 0 and main_child[parent[i]] == i:
			continue
		var chain := PackedInt32Array()
		if parent[i] >= 0:
			chain.append(parent[i])
		var k := i
		while k >= 0:
			chain.append(k)
			k = main_child[k]
		if chain.size() >= 2:
			_emit_chain(chain, width, parent[i] < 0)


## Catmull-Rom through the chain's nodes, sampled every ds metres.
func _emit_chain(chain: PackedInt32Array, width: PackedFloat32Array, from_mouth: bool) -> void:
	_chain += 1
	var pts := PackedVector2Array()
	var es := PackedFloat32Array()
	var ws := PackedFloat32Array()
	var gs := PackedFloat32Array()
	var wet_chain := width[chain[1]] >= WET_WIDTH
	var ds := 6.0 if wet_chain else 18.0
	var m := chain.size()
	for a in m - 1:
		var p0 := pos[chain[maxi(a - 1, 0)]]
		var p1 := pos[chain[a]]
		var p2 := pos[chain[a + 1]]
		var p3 := pos[chain[mini(a + 2, m - 1)]]
		var steps := maxi(1, ceili(p1.distance_to(p2) / ds))
		# A tributary's first edge (from its junction) carries the tributary's width.
		var w1 := width[chain[a]] if a > 0 or from_mouth else width[chain[1]]
		for s in steps:
			var t := float(s) / steps
			pts.append(_catmull(p0, p1, p2, p3, t))
			es.append(lerpf(elev[chain[a]], elev[chain[a + 1]], t))
			ws.append(lerpf(w1, width[chain[a + 1]], t))
			gs.append(lerpf(gradient[chain[a]], gradient[chain[a + 1]], t))
	pts.append(pos[chain[m - 1]])
	es.append(elev[chain[m - 1]])
	ws.append(width[chain[m - 1]])
	gs.append(gradient[chain[m - 1]])

	var cum := _cumulative(pts)
	var total := cum[cum.size() - 1]
	var estuary := 0.0
	if from_mouth:
		estuary = 120.0 + 6.0 * ws[0]
		for k in pts.size():
			if cum[k] < estuary:
				var f := 1.0 - cum[k] / estuary
				ws[k] *= 1.0 + 3.5 * f * f

	var out := {"pts": pts, "e": es, "w": ws, "g": gs}
	if wet_chain:
		out = _meander(out, cum, estuary)
	var opts: PackedVector2Array = out.pts
	var oe: PackedFloat32Array = out.e
	var ow: PackedFloat32Array = out.w
	var og: PackedFloat32Array = out.g

	if from_mouth:
		# Carry the channel out past the shoreline so it opens to the sea.
		var dir := (opts[0] - opts[mini(3, opts.size() - 1)]).normalized()
		var ext := PackedVector2Array()
		var ee := PackedFloat32Array()
		for k in [3, 2, 1]:
			ext.append(opts[0] + dir * 27.0 * k)
			ee.append(-0.6 * k)
		ext.append_array(opts)
		ee.append_array(oe)
		var ew := PackedFloat32Array([ow[0], ow[0], ow[0]])
		ew.append_array(ow)
		var eg := PackedFloat32Array([og[0], og[0], og[0]])
		eg.append_array(og)
		opts = ext
		oe = ee
		ow = ew
		og = eg

	# Water never flows uphill along the final path.
	for k in range(oe.size() - 2, -1, -1):
		oe[k] = minf(oe[k], oe[k + 1])

	for k in opts.size() - 1:
		_emit_seg(opts[k], opts[k + 1], oe[k], oe[k + 1], ow[k], ow[k + 1], og[k], KIND_RIVER)

	if spawn == Vector3.INF and from_mouth and ws[0] > 4.0:
		for k in range(opts.size() / 3, opts.size()):
			var lowland := 1.0 - smoothstep(0.003, 0.02, og[k])
			if oe[k] > 2.0 and oe[k] < 15.0 and lowland > 0.8 and k + 1 < opts.size():
				var t := (opts[k + 1] - opts[k]).normalized()
				var F := _floodplain(ow[k], og[k], true)
				var p := opts[k] + Vector2(-t.y, t.x) * (0.5 * ow[k] + 0.5 * (F - 0.5 * ow[k]) + 3.0)
				spawn = Vector3(p.x, oe[k] + 3.0, p.y)
				break


func _floodplain(w: float, g: float, wet: bool) -> float:
	var lowland := 1.0 - smoothstep(0.003, 0.02, g)
	if wet:
		return 0.5 * w + lerpf(1.0, 3.0 * w + 18.0, lowland)
	return lerpf(1.0, 8.0, lowland)


func _emit_seg(a: Vector2, b: Vector2, e0: float, e1: float, w0: float, w1: float,
		g: float, kind: int) -> void:
	if a.distance_squared_to(b) < 0.01:
		return
	var wet := kind == KIND_OXBOW or (w0 >= WET_WIDTH and w1 >= WET_WIDTH)
	var k := kind if wet else KIND_DRY
	var mid := (a + b) * 0.5
	segs.append_array([a.x, a.y, b.x, b.y, e0, e1, w0, w1,
			_floodplain(w0, g, wet), _floodplain(w1, g, wet), side_slope(mid), float(k + 4 * _chain)])


## Smooth 1D value noise in [0, 1] over a random table (period 512).
static func _noise1(table: PackedFloat32Array, u: float) -> float:
	var i := floori(u)
	var f := u - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(table[posmod(i, 512)], table[posmod(i + 1, 512)], f)


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
			+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3)


static func _cumulative(pts: PackedVector2Array) -> PackedFloat32Array:
	var cum := PackedFloat32Array()
	cum.resize(pts.size())
	for k in range(1, pts.size()):
		cum[k] = cum[k - 1] + pts[k].distance_to(pts[k - 1])
	return cum


## Interpolated centreline frame at arclength x: [point, left normal, index, frac].
static func _frame(pts: PackedVector2Array, cum: PackedFloat32Array, x: float) -> Array:
	x = clampf(x, 0.0, cum[cum.size() - 1])
	var i := clampi(cum.bsearch(x) - 1, 0, pts.size() - 2)
	var seg := maxf(cum[i + 1] - cum[i], 1e-4)
	var f := clampf((x - cum[i]) / seg, 0.0, 1.0)
	var t := (pts[i + 1] - pts[i]) / seg
	return [pts[i].lerp(pts[i + 1], f), Vector2(-t.y, t.x), i, f]


## Lowland main stems: replace the stretch where the river is gentle and wide
## enough by a Kinoshita meander laid out in the centreline's curvilinear frame,
## then cut off the tightest bends as oxbow lakes.
func _meander(c: Dictionary, cum: PackedFloat32Array, estuary: float) -> Dictionary:
	var pts: PackedVector2Array = c.pts
	var es: PackedFloat32Array = c.e
	var ws: PackedFloat32Array = c.w
	var gs: PackedFloat32Array = c.g
	var a := -1
	var b := pts.size() - 1
	for k in pts.size():
		var ok := gs[k] < 0.009 and ws[k] >= 3.0
		if a < 0 and ok:
			a = k
		elif a >= 0 and not ok:
			b = k
			break
	if a < 0:
		return c
	var xa := cum[a]
	var xb := cum[b]
	var w_ref := ws[(a + b) / 2] # mid-stretch: the mouth's width is estuary-flared
	if xb - xa < 2.5 * maxf(14.0 * w_ref, 70.0):
		return c

	# Integrate the meander: theta(phi) = tmax*sin(phi) + tmax^3*Js*sin(3 phi).
	const DS := 4.0
	var js := rng.randf_range(-0.09, 0.09)
	var phase := rng.randf() * TAU
	var table := PackedFloat32Array()
	for q in 512:
		table.append(rng.randf())
	var arc := 0.0
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	var x := xa
	var y := 0.0
	var phi := 0.0
	while x < xb and xs.size() < 20000:
		xs.append(x)
		ys.append(y)
		var fr := _frame(pts, cum, x)
		var i: int = fr[2]
		var w := lerpf(ws[i], ws[mini(i + 1, ws.size() - 1)], fr[3])
		var lam := maxf(14.0 * w, 70.0)
		var taper := smoothstep(xa, xa + lam, x) * smoothstep(xb, xb - lam, x)
		if estuary > 0.0:
			taper *= smoothstep(estuary * 0.5, estuary * 1.2, x)
		# Bend size, wavelength and skew drift along the river with incommensurate
		# periods, so no two bends match and only some grow into cutoff loops.
		var u := arc / lam
		var tmax := (0.55 + 1.6 * _noise1(table, u * 1.3)) * taper
		var rate := 0.6 + 0.9 * _noise1(table, u * 0.9 + 200.0)
		var skew := js * 2.0 * _noise1(table, u * 0.5 + 400.0)
		var th := tmax * sin(phi + phase) + tmax * tmax * tmax * skew * sin(3.0 * (phi + phase))
		x += cos(th) * DS
		y += sin(th) * DS
		arc += DS
		phi += TAU / lam * DS * rate
	xs.append(xb)
	ys.append(y)
	var y_end := y
	var mp := PackedVector2Array()
	var me := PackedFloat32Array()
	var mw := PackedFloat32Array()
	var mg := PackedFloat32Array()
	for k in xs.size():
		var yy := ys[k] - y_end * (xs[k] - xa) / maxf(xb - xa, 1.0)
		var fr := _frame(pts, cum, xs[k])
		var i: int = fr[2]
		var f: float = fr[3]
		var j := mini(i + 1, pts.size() - 1)
		mp.append(fr[0] + fr[1] * yy)
		me.append(lerpf(es[i], es[j], f))
		mw.append(lerpf(ws[i], ws[j], f))
		mg.append(lerpf(gs[i], gs[j], f))

	# Neck cutoffs -> oxbow lakes.
	var rp := PackedVector2Array()
	var re := PackedFloat32Array()
	var rw := PackedFloat32Array()
	var rg := PackedFloat32Array()
	var k := 0
	var count := mp.size()
	while k < count:
		rp.append(mp[k])
		re.append(me[k])
		rw.append(mw[k])
		rg.append(mg[k])
		var lam := maxf(14.0 * mw[k], 70.0)
		var lo := k + ceili(0.45 * lam / DS)
		var hi := mini(k + ceili(1.2 * lam / DS), count - 1)
		var neck := 2.2 * mw[k] + 6.0
		var best := -1
		var best_d := neck
		for j in range(lo, hi + 1):
			var d := mp[k].distance_to(mp[j])
			if d < best_d:
				best_d = d
				best = j
		if best >= 0 and rng.randf() < 0.5:
			# The old loop, detached from the channel at both ends, becomes an oxbow.
			var trim := ceili((mw[k] + 4.0) / DS)
			if best - k > 2 * trim + 3:
				var level := minf(me[k], me[best]) - 0.15
				var river_chain := _chain
				_chain = 1000000 + _chain * 64 + (k % 64) # oxbow: its own id
				for o in range(k + trim, best - trim):
					_emit_seg(mp[o], mp[o + 1], level, level, mw[o] * 0.85, mw[o + 1] * 0.85,
							mg[o], KIND_OXBOW)
				_chain = river_chain
			# The river takes the shortcut across the neck.
			var steps := maxi(1, ceili(best_d / DS))
			for s in range(1, steps):
				var t := float(s) / steps
				rp.append(mp[k].lerp(mp[best], t))
				re.append(lerpf(me[k], me[best], t))
				rw.append(lerpf(mw[k], mw[best], t))
				rg.append(lerpf(mg[k], mg[best], t))
			k = best
			continue
		k += 1

	var op := PackedVector2Array()
	var oe := PackedFloat32Array()
	var ow := PackedFloat32Array()
	var og := PackedFloat32Array()
	op.append_array(pts.slice(0, a))
	oe.append_array(es.slice(0, a))
	ow.append_array(ws.slice(0, a))
	og.append_array(gs.slice(0, a))
	op.append_array(rp)
	oe.append_array(re)
	ow.append_array(rw)
	og.append_array(rg)
	op.append_array(pts.slice(b + 1))
	oe.append_array(es.slice(b + 1))
	ow.append_array(ws.slice(b + 1))
	og.append_array(gs.slice(b + 1))
	return {"pts": op, "e": oe, "w": ow, "g": og}
