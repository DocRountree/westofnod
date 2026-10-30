class_name Rivers
extends RefCounted
## Turns the hydrology's river chains into segments for the composer.
##
## Chains (largest first) are smoothed off the grid's eight directions, joined
## onto their parent's final course, and given an irregular natural sway. The
## longest gentle, wide reach of each river meanders with history (Meander): its
## final course, every recorded past course and every cutoff are emitted, along
## with the floodplain the belt occupies.

const STRIDE := 12 # (ax, az, bx, bz) (e_a, e_b, hw_a, hw_b) (F_a, F_b, p, kind); a upstream
const KIND_FLOOR := 0 # meander belt axis: floodplain only
const KIND_RIVER := 1 # active channel; p = depth
const KIND_OXBOW := 2 # cutoff loop; p = time of cutoff (0..1, 1 = now)
const KIND_SNAP := 3 # a past course; p = its time
const BELT_DS := 20.0

var hyd: Hydrology
var rng: RandomNumberGenerator
var segs := PackedFloat32Array()
var finals: Array = [] # per river: {pts, e}
var spawn := Vector3.INF
var stats := {"rivers": 0, "meandering": 0, "oxbows": 0, "snaps": 0}


func _init(hydrology: Hydrology, random: RandomNumberGenerator) -> void:
	hyd = hydrology
	rng = random


func build() -> Rivers:
	for r in hyd.rivers:
		finals.append(_river(r))
	stats.rivers = hyd.rivers.size()
	return self


func _river(r: Dictionary) -> Dictionary:
	var pts: PackedVector2Array = r.pts
	var es: PackedFloat32Array = r.e
	var ws: PackedFloat32Array = r.w
	if pts.size() < 2:
		return {"pts": pts, "e": es}
	pts = _smooth(pts, 3)
	for it in 3:
		var c := _chaikin(pts, es, ws)
		pts = c[0]
		es = c[1]
		ws = c[2]
	if r.parent >= 0 and r.parent < finals.size():
		var par: Dictionary = finals[r.parent]
		var pp: PackedVector2Array = par.pts
		if not pp.is_empty():
			var best := 0
			for i in pp.size():
				if pp[i].distance_squared_to(pts[0]) < pp[best].distance_squared_to(pts[0]):
					best = i
			pts[0] = pp[best]
			es[0] = minf(es[0], par.e[best])
	var res := _resample(pts, es, ws, clampf(ws[ws.size() / 2] * 1.5, 5.0, 30.0))
	pts = res[0]
	es = res[1]
	ws = res[2]
	for i in range(1, es.size()):
		es[i] = maxf(es[i], es[i - 1]) # water never flows uphill
	var out := _meander_reach(pts, es, ws)
	pts = out[0]
	es = out[1]
	ws = out[2]
	var cum := _cumulative(pts)
	for i in pts.size() - 1:
		var slope := (es[i + 1] - es[i]) / maxf(cum[i + 1] - cum[i], 0.1)
		var f0 := _floor_width(ws[i], slope) if not out[3] else 0.0
		var f1 := _floor_width(ws[i + 1], slope) if not out[3] else 0.0
		_emit(pts[i + 1], pts[i], es[i + 1], es[i], ws[i + 1] * 0.5, ws[i] * 0.5, f1, f0,
				_depth(0.5 * (ws[i] + ws[i + 1])), KIND_RIVER)
	if spawn == Vector3.INF and r.to_sea and ws[ws.size() / 3] > 5.0:
		for i in range(pts.size() / 4, pts.size() - 1):
			if es[i] > 2.0 and es[i] < 25.0:
				var t := (pts[i + 1] - pts[i]).normalized()
				var p := pts[i] + Vector2(-t.y, t.x) * (ws[i] * 0.5 + 10.0)
				spawn = Vector3(p.x, es[i] + 3.0, p.y)
				break
	return {"pts": pts, "e": es}


func _floor_width(w: float, slope: float) -> float:
	return 0.5 * w + lerpf(2.5 * w + 6.0, 0.3 * w + 1.0, smoothstep(0.003, 0.06, slope))


static func _depth(w: float) -> float:
	return clampf(0.4 + 0.09 * w, 0.4, 4.0)


## Returns [pts, e, w, meandered]. Pts may be replaced by a meandering course.
func _meander_reach(pts: PackedVector2Array, es: PackedFloat32Array, ws: PackedFloat32Array) -> Array:
	var cum := _cumulative(pts)
	var m := pts.size()
	var best_a := -1
	var best_b := -1
	var a := -1
	for i in m:
		var j := mini(i + 4, m - 1)
		var k := maxi(i - 4, 0)
		var g := (es[j] - es[k]) / maxf(cum[j] - cum[k], 1.0)
		var ok := g < 0.007 and ws[i] >= 3.5 and es[i] > 0.3
		if ok and a < 0:
			a = i
		if (not ok or i == m - 1) and a >= 0:
			if best_a < 0 or cum[i] - cum[a] > cum[best_b] - cum[best_a]:
				best_a = a
				best_b = i
			a = -1
	var wmid := ws[(best_a + best_b) / 2] if best_a >= 0 else 0.0
	if best_a < 0 or cum[best_b] - cum[best_a] < 6.0 * 11.0 * wmid:
		var wig := _wiggle(pts, es, ws)
		wig.append(false)
		return wig
	stats.meandering += 1
	var axis := _smooth(pts.slice(best_a, best_b + 1), 6)
	var ae := es.slice(best_a, best_b + 1)
	var aw := ws.slice(best_a, best_b + 1)
	var acum := _cumulative(axis)
	var length := acum[acum.size() - 1]
	# Belt half-width from the room the valley gives.
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
				if hyd.sample(hyd.h, fr[0] + fr[1] * d * side) > e + 4.0 + 0.4 * w:
					break
			room = minf(room, d)
		var end_taper := minf(1.0, minf(x, length - x) / (11.0 * w))
		belt.append(clampf(room - w, 1.5 * w, 9.0 * w) * end_taper + 0.5 * w)
		x += BELT_DS
	for it in 3:
		for i in range(1, belt.size() - 1):
			belt[i] = 0.25 * belt[i - 1] + 0.5 * belt[i] + 0.25 * belt[i + 1]
	var sim := Meander.migrate(length, wmid, belt, BELT_DS, rng)
	var mp: PackedVector2Array = sim.pts
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
	# The floodplain over the whole belt.
	for i in axis.size() - 1:
		var b0 := belt[clampi(int(acum[i] / BELT_DS), 0, belt.size() - 1)]
		var b1 := belt[clampi(int(acum[i + 1] / BELT_DS), 0, belt.size() - 1)]
		_emit(axis[i + 1], axis[i], ae[i + 1], ae[i], 0.0, 0.0, b1 + aw[i + 1] * 1.5, b0 + aw[i] * 1.5,
				0.0, KIND_FLOOR)
	# Past courses (scroll bars) and cutoffs (oxbows).
	for sn in sim.snaps:
		_emit_course(sn.pts, axis, acum, ae, wmid * 0.5, sn.t, KIND_SNAP, 0)
		stats.snaps += 1
	for ox in sim.oxbows:
		var trim := 2
		if ox.pts.size() < 2 * trim + 4:
			continue
		var level := _lerp_at(ae, acum, ox.pts[ox.pts.size() / 2].x) - 0.25
		_emit_course(ox.pts.slice(trim, ox.pts.size() - trim), axis, acum, PackedFloat32Array([level, level]),
				wmid * 0.45, ox.t, KIND_OXBOW, 1)
		stats.oxbows += 1
	return [op, oe, ow, true]


## Emits a course given in valley coordinates. levels: per-axis water levels, or
## (flat) a two-element array with one level.
func _emit_course(cpts: PackedVector2Array, axis: PackedVector2Array, acum: PackedFloat32Array,
		levels: PackedFloat32Array, hw: float, t: float, kind: int, flat: int) -> void:
	var prev := Vector2.INF
	var prev_e := 0.0
	for q in cpts:
		var fr := _frame(axis, acum, q.x)
		var p: Vector2 = fr[0] + fr[1] * q.y
		var e := levels[0] if flat == 1 else _lerp_at(levels, acum, q.x)
		if prev != Vector2.INF:
			_emit(prev, p, prev_e, e, hw, hw, 0.0, 0.0, t, kind)
		prev = p
		prev_e = e


## Small streams sway irregularly: 1D value noise at three scales, its
## amplitude varying along the stream, tapered at both ends.
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
		out[i] = pts[i] + Vector2(-t.y, t.x) * clampf(off, -hyd.dx * 0.3, hyd.dx * 0.3)
	return [out, es, ws]


func _emit(a: Vector2, b: Vector2, ea: float, eb: float, hwa: float, hwb: float,
		fa: float, fb: float, p: float, kind: int) -> void:
	if a.distance_squared_to(b) < 0.01:
		return
	segs.append_array([a.x, a.y, b.x, b.y, ea, eb, hwa, hwb, fa, fb, p, float(kind)])


# ------------------------------------------------------------------ polyline helpers

static func _noise1(table: PackedFloat32Array, u: float) -> float:
	var i := floori(u)
	var f := u - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(table[posmod(i, 256)], table[posmod(i + 1, 256)], f)


static func _chaikin(pts: PackedVector2Array, es: PackedFloat32Array, ws: PackedFloat32Array) -> Array:
	var p2 := PackedVector2Array([pts[0]])
	var e2 := PackedFloat32Array([es[0]])
	var w2 := PackedFloat32Array([ws[0]])
	for i in pts.size() - 1:
		for f in [0.25, 0.75]:
			p2.append(pts[i].lerp(pts[i + 1], f))
			e2.append(lerpf(es[i], es[i + 1], f))
			w2.append(lerpf(ws[i], ws[i + 1], f))
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


## Point and (smoothly turning) left normal of a polyline at arclength x.
static func _frame(pts: PackedVector2Array, cum: PackedFloat32Array, x: float) -> Array:
	x = clampf(x, 0.0, cum[cum.size() - 1])
	var i := clampi(cum.bsearch(x) - 1, 0, pts.size() - 2)
	var seg := maxf(cum[i + 1] - cum[i], 1e-4)
	var f := clampf((x - cum[i]) / seg, 0.0, 1.0)
	var t0 := (pts[i + 1] - pts[i]).normalized()
	var t := t0
	if f < 0.5 and i > 0:
		t = (pts[i] - pts[i - 1]).normalized().lerp(t0, 0.5 + f).normalized()
	elif f >= 0.5 and i < pts.size() - 2:
		t = t0.lerp((pts[i + 2] - pts[i + 1]).normalized(), f - 0.5).normalized()
	return [pts[i].lerp(pts[i + 1], f), Vector2(-t.y, t.x)]
