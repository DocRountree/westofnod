class_name Meander
extends RefCounted
## Meander migration with history, on a straight valley (x along it, y across).
##
## Curvature-driven migration in the form of Howard & Knutson (1984): each step
## every point moves sideways by R(s) = -C(s) + 2.5 * (upstream-weighted average
## of C), C the local curvature. The valley walls confine the belt to
## |y| < belt(x). When two parts of the channel come within a width of each
## other the neck is cut: the river takes the shortcut, and the loop is left as
## an oxbow.
##
## The history is the point: every SNAP steps the channel's course is recorded
## with its time, and every cutoff with the time it happened. The terrain
## composer turns these into scroll bars and swales (the ground each past
## channel swept), oxbow lakes that silt up with age, and scars.

const STEPS := 320
const SNAP := 6
const OMEGA := -1.0
const GAMMA := 2.5


## Index 0 is downstream. Returns {pts: final course, snaps: [{pts, t}],
## oxbows: [{pts, t}]}, t in 0..1 (1 = now), points in valley coordinates.
static func migrate(length: float, w: float, belt: PackedFloat32Array, belt_ds: float,
		rng: RandomNumberGenerator) -> Dictionary:
	var ds := maxf(w, 3.0)
	var n0 := maxi(8, ceili(length / ds) + 1)
	var pts := PackedVector2Array()
	var ph1 := rng.randf() * TAU
	var ph2 := rng.randf() * TAU
	var lam := 11.0 * w
	for i in n0:
		var x := length * i / (n0 - 1)
		var taper := minf(1.0, minf(x, length - x) / lam)
		var y := w * 0.4 * taper * (sin(TAU * x / lam + ph1) + 0.6 * sin(TAU * x / (1.7 * lam) + ph2)
				+ rng.randf_range(-0.3, 0.3))
		pts.append(Vector2(x, y))
	var decay := exp(-ds / (4.0 * w))
	var neck := 1.25 * w
	var min_sep := ceili(PI * 2.0 * w / ds) + 2
	var snaps: Array = []
	var oxbows: Array = []

	for step in STEPS:
		var n := pts.size()
		var curv := PackedFloat32Array()
		curv.resize(n)
		for i in range(1, n - 1):
			var a := pts[i] - pts[i - 1]
			var b := pts[i + 1] - pts[i]
			curv[i] = atan2(a.cross(b), a.dot(b)) * 2.0 / maxf(a.length() + b.length(), 1e-3)
		var cs := PackedFloat32Array()
		cs.resize(n)
		for i in range(1, n - 1):
			cs[i] = 0.25 * curv[i - 1] + 0.5 * curv[i] + 0.25 * curv[i + 1]
		var acc := 0.0
		var rate := PackedFloat32Array()
		rate.resize(n)
		for i in range(n - 2, 0, -1):
			acc = decay * acc + (1.0 - decay) * cs[i + 1]
			rate[i] = OMEGA * cs[i] + GAMMA * acc
		var moved := PackedVector2Array(pts)
		for i in range(2, n - 2):
			var t := (pts[i + 1] - pts[i - 1]).normalized()
			var p := pts[i] + Vector2(-t.y, t.x) * 0.22 * ds * clampf(rate[i] * w, -1.0, 1.0)
			var b := belt[clampi(int(p.x / belt_ds), 0, belt.size() - 1)]
			if absf(p.y) > b:
				p.y -= signf(p.y) * (absf(p.y) - b) * 0.7
			p.x = clampf(p.x, 0.0, length)
			moved[i] = p
		pts = _resample(moved, ds)
		var cut := _find_cutoff(pts, neck, min_sep)
		if cut.x >= 0:
			oxbows.append({"pts": pts.slice(cut.x, cut.y + 1), "t": float(step) / STEPS})
			var kept := pts.slice(0, cut.x + 1)
			kept.append_array(pts.slice(cut.y))
			pts = _resample(kept, ds)
		if step % SNAP == 0:
			snaps.append({"pts": pts, "t": float(step) / STEPS})
	# Drop oxbows the channel has since swept through.
	var grid := _hash(pts, w * 2.0)
	var out_ox: Array = []
	for ox in oxbows:
		var ok := true
		for p in ox.pts:
			if _near(grid, pts, p, w * 2.0, w * 1.4):
				ok = false
				break
		if ok:
			out_ox.append(ox)
	return {"pts": pts, "snaps": snaps, "oxbows": out_ox}


static func _resample(pts: PackedVector2Array, ds: float) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	var carry := 0.0
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var seg := a.distance_to(b)
		var t := ds - carry
		while t <= seg:
			out.append(a.lerp(b, t / seg))
			t += ds
		carry = seg - (t - ds)
	if out[out.size() - 1].distance_to(pts[pts.size() - 1]) > ds * 0.3:
		out.append(pts[pts.size() - 1])
	else:
		out[out.size() - 1] = pts[pts.size() - 1]
	return out


static func _hash(pts: PackedVector2Array, cell: float) -> Dictionary:
	var g := {}
	for i in pts.size():
		var k := Vector2i(floori(pts[i].x / cell), floori(pts[i].y / cell))
		if not g.has(k):
			g[k] = PackedInt32Array()
		g[k].append(i)
	return g


static func _near(grid: Dictionary, pts: PackedVector2Array, p: Vector2, cell: float, r: float) -> bool:
	var k := Vector2i(floori(p.x / cell), floori(p.y / cell))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for i in grid.get(k + Vector2i(dx, dz), PackedInt32Array()):
				if pts[i].distance_to(p) < r:
					return true
	return false


## First pair (i, j), j - i >= min_sep, closer than neck. (-1, -1) if none.
static func _find_cutoff(pts: PackedVector2Array, neck: float, min_sep: int) -> Vector2i:
	var grid := _hash(pts, neck)
	for i in pts.size():
		var p := pts[i]
		var k := Vector2i(floori(p.x / neck), floori(p.y / neck))
		var best := -1
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for j in grid.get(k + Vector2i(dx, dz), PackedInt32Array()):
					if j - i >= min_sep and j > best and pts[j].distance_to(p) < neck:
						best = j
		if best >= 0:
			return Vector2i(i, best)
	return Vector2i(-1, -1)
