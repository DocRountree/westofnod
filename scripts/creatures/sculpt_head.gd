class_name SculptHead
extends RefCounted
## A mammal's head sculpted, not swept: its upper head (skull and muzzle,
## the upper lips) a surface through cross-sections that change along it
## (round over the cranium, boxier down the muzzle, widest at the cheeks),
## the profile's own line (the dome of the skull, the stop, the bridge of
## the nose), and on it the face's structure pushed out or in: the eye
## sockets, their lids' raised almond rims, the brow over each; the cheek
## bones; the stop between the eyes; the whisker pads; the upper lips
## draping out and down over the lower jaw (a separate, narrower jaw tucked
## under them: no seam to see while the mouth is shut); the nose's pad flat
## fronted. The coat's shader paints its nose leather and nostrils
## (carnivore.gdshader: sculpt).
##
## P (the species' S.sculpt), in the head's own mm (x right, y up, z back):
## z (keys, back to front), top, bot (the upper head's top line and its
## underside, the lips' edge), w (its half width above its middle), wl
## (below: the cheeks), pw (its sections' shape: 2 round, more boxier);
## eye (its centre, the right one), eye_r (its socket's radius), socket
## (how deep), lid (its rim's rise), brow, cheek, stop, pads, flews (how
## far each pushed out or in, mm); nose_r (the nose pad's radius).

const AROUND := 44
const ALONG := 46


## A profile's value at z (keys from the back, z falling).
static func _key(P: Dictionary, name: String, z: float) -> float:
	var zs: Array = P.z
	var vs: Array = P[name]
	var n := zs.size()
	if z >= float(zs[0]):
		return float(vs[0])
	if z <= float(zs[n - 1]):
		return float(vs[n - 1])
	for j in n - 1:
		var z0 := float(zs[j])
		var z1 := float(zs[j + 1])
		if z <= z0 and z >= z1:
			var f := (z0 - z) / maxf(z0 - z1, 1e-3)
			var p0 := float(vs[maxi(j - 1, 0)])
			var p1 := float(vs[j])
			var p2 := float(vs[j + 1])
			var p3 := float(vs[mini(j + 2, n - 1)])
			return 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)
	return float(vs[n - 1])


## The section's point at z, round it by phi (0 its top, PI/2 its right,
## PI its underside), before the features; and its outward normal there in
## the section's plane.
static func _base(P: Dictionary, z: float, phi: float) -> Array:
	var top := _key(P, "top", z)
	var bot := _key(P, "bot", z)
	var w := _key(P, "w", z)
	var wl := _key(P, "wl", z)
	var pw := _key(P, "pw", z)
	var yc := (top + bot) * 0.5
	var hu := maxf(top - yc, 0.5)
	var c := cos(phi)
	var s := sin(phi)
	var ex := signf(s) * pow(absf(s), 2.0 / pw)
	var ey := signf(c) * pow(absf(c), 2.0 / pw)
	var ww := lerpf(wl, w, smoothstep(-0.35, 0.35, c))
	var p := Vector3(ex * ww, yc + ey * hu, z)
	var n := Vector3(ex / maxf(ww, 0.5), ey / hu, 0.0).normalized()
	return [p, n]


static func _g(d: float, r: float) -> float:
	return exp(-2.6 * (d / r) * (d / r))


## The sculpted point at z, phi: the section's, its features pushed in or out.
static func point(P: Dictionary, z: float, phi: float) -> Vector3:
	var b := _base(P, z, phi)
	var p: Vector3 = b[0]
	var n: Vector3 = b[1]
	var e: Vector3 = P.eye
	var er: float = P.eye_r
	var side := signf(p.x) if absf(p.x) > 1e-4 else 1.0
	var em := Vector3(e.x * side, e.y, e.z)
	var dis := 0.0
	# the socket, and its lids' almond rim
	var al := float(P.get("almond", 0.7))
	var sl := float(P.get("slant", 0.0)) # (its outer corner up: the fox's oblique eye)
	var dq := p - em
	dq.y -= sl * dq.z # (its long axis tipped: the corner behind raised)
	var q := dq / Vector3(1.0, al, 1.35)
	var d := q.length()
	if d < er:
		var k := 1.0 - (d / er) * (d / er)
		dis -= float(P.socket) * k * k
	dis += float(P.lid) * exp(-pow((d - er * 0.92) / (er * 0.16), 2.0))
	# the brow over it, the cheek bone under and behind it
	dis += float(P.brow) * _g(p.distance_to(em + Vector3(-side * er * 0.25, er * 1.05, er * 0.35)), er * 1.15)
	dis += float(P.cheek) * _g(p.distance_to(em + Vector3(side * er * 0.1, -er * 1.25, er * 1.0)), er * 1.4)
	# the stop: the dip between the eyes, at the muzzle's root
	var zs := e.z - er * 0.9
	dis -= float(P.stop) * _g(p.distance_to(Vector3(0.0, _key(P, "top", zs), zs)), er * 1.4)
	# the whisker pads, either side of the muzzle near its end
	var zn := float((P.z as Array)[(P.z as Array).size() - 1])
	var zw := zn + er * 3.0
	var pad := Vector3(side * _key(P, "w", zw) * 0.85, lerpf(_key(P, "bot", zw), _key(P, "top", zw), 0.3), zw)
	dis += float(P.pads) * _g(p.distance_to(pad), er * 1.3)
	# the upper lips: out and down over the jaw, along the muzzle's lower sides
	var lower := smoothstep(-0.15, -0.55, cos(atan2(absf(p.x), p.y - (_key(P, "top", z) + _key(P, "bot", z)) * 0.5)))
	var ahead := smoothstep(e.z + er * 0.5, e.z - er * 1.5, z)
	var under := 1.0 - smoothstep(0.65, 0.95, -n.y)
	dis += float(P.flews) * lower * ahead * under
	var out := p + n * dis
	if lower * ahead > 0.3: # (the lips' edge a little down, too)
		out.y -= float(P.flews) * 0.5 * lower * ahead * under
	return out


## Where its right eye sits: [the eyeball's centre, the way it looks] (the
## socket's middle on the surface, the ball set back into it).
static func eye_seat(P: Dictionary, ball_r: float) -> Array:
	var e: Vector3 = P.eye
	var best := Vector3.ZERO
	var best_d := INF
	var phi_best := 0.0
	for k in 180:
		var phi := PI * float(k) / 180.0
		var b := _base(P, e.z, phi)
		var p: Vector3 = b[0]
		var dd := absf(p.y - e.y)
		if p.x > 0.0 and dd < best_d:
			best_d = dd
			best = p
			phi_best = phi
	var n: Vector3 = _base(P, e.z, phi_best)[1]
	var look := (n + Vector3(0.0, 0.0, -float(P.get("look_fwd", 0.55)))).normalized()
	return [best - n * (ball_r * 0.55 + float(P.socket) * 0.6), look]


## The upper head's rows (rest: transformed by xf, the head's), for MammalSkin.surface.
static func rows(P: Dictionary, xf: Transform3D) -> Array:
	var zs: Array = P.z
	var z0 := float(zs[0])
	var z1 := float(zs[zs.size() - 1])
	var out := []
	for i in ALONG + 1:
		var t := float(i) / ALONG
		var z := lerpf(z0, z1, t * t * 0.25 + t * 0.75) # (closer together toward the face)
		var row := []
		for k in AROUND:
			var phi := TAU * float(k) / AROUND
			row.append(xf * point(P, z, phi))
		out.append(row)
	return out


static func row_z(P: Dictionary, i: int) -> float:
	var zs: Array = P.z
	var t := float(i) / ALONG
	return lerpf(float(zs[0]), float(zs[zs.size() - 1]), t * t * 0.25 + t * 0.75)
