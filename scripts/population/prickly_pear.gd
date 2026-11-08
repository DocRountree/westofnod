class_name PricklyPear
extends RefCounted
## A prickly pear (Engelmann's, Opuntia engelmannii), built whole
## (PlantMesh), life size, four variants: a big sprawling clump (about a
## metre high, two across), a small one, one fruiting, one in flower. In the mesa
## country, not up on the plateau (data/population/props/prickly_pear.tres); its fruit (the tunas,
## the item "prickly_pear") hung on the rims of its top pads where it bears
## them (fruit_spots: Foraging draws and picks them, as a tree's).
##
## What makes it read as a prickly pear: flat, round-ended pads (each a
## stem: obovate, a hand and a half long, two fingers thick at the middle,
## thinning to their rims), joined end to end, each new pad off the rim of
## the last, turned every way; blue green, a bloom on them; the areoles in
## diagonal rows over both faces, each a tuft of brown glochids with one to
## four stout spines, pale yellow-white, reddish at the base, pointing out
## and down; the oldest pads at the foot gone woody, grey brown, rounder;
## the fruits (tunas) on the rims of the top pads, egg shaped, wine red to
## purple, dotted with their own areoles; the flowers there too, yellow
## cups, the stamens in their middle.

const PM := preload("res://scripts/population/plant_mesh.gd") # (by path: found whether or not the editor has seen the class yet)

const VARIANTS := [
	{"roots": 4, "depth": 4, "branch": 0.75, "pad": 0.24, "seed": 901},
	{"roots": 2, "depth": 2, "branch": 0.6, "pad": 0.19, "seed": 919},
	{"roots": 3, "depth": 3, "branch": 0.7, "pad": 0.22, "seed": 937, "fruit": 4},
	{"roots": 3, "depth": 3, "branch": 0.7, "pad": 0.22, "seed": 947, "flowers": 3},
]

const PAD := Color(0.4, 0.55, 0.4)
const PAD_NEW := Color(0.5, 0.62, 0.36)
const WOOD := Color(0.48, 0.42, 0.34)
const GLOCHID := Color(0.4, 0.28, 0.16)
const SPINE := Color(0.9, 0.87, 0.72)
const SPINE_FOOT := Color(0.55, 0.3, 0.2)
const TUNA := Color(0.5, 0.08, 0.26)

static var _cache := {}
static var _spots := {} # variant -> its fruit's places (its mesh's space)


## The fruit it bears (Items), "" none: the fruiting one's tunas.
static func fruit_of(variant: int) -> String:
	return "prickly_pear" if VARIANTS[posmod(variant, VARIANTS.size())].has("fruit") else ""


## Where its fruit grow (its mesh's space): on the rims of its top pads.
static func fruit_spots(variant: int) -> PackedVector3Array:
	variant = posmod(variant, VARIANTS.size())
	build_lods(variant)
	return _spots.get(variant, PackedVector3Array())


static func build(variant := 0) -> Mesh:
	return build_lods(variant)[0]


## Its levels of detail: whole; no spines; the far one (the pads coarser,
## no areoles).
static func build_lods(variant := 0) -> Array[Mesh]:
	if not _cache.has(variant):
		var lods: Array[Mesh] = []
		for lod in 3:
			lods.append(_make(VARIANTS[variant], lod, variant))
		_cache[variant] = lods
	return _cache[variant]


static func _make(V: Dictionary, lod: int, variant := -1) -> Mesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(V.seed)
	var pads := PM.begin()
	var bits := PM.begin()
	var extra := PM.begin()
	var tops := [] # the topmost pads: [their basis, their origin, length]
	for k in int(V.roots):
		var a := TAU * float(k) / float(V.roots) + rng.randf_range(-0.4, 0.4)
		var lean := rng.randf_range(0.25, 0.7)
		var up := Vector3(cos(a) * sin(lean), cos(lean), sin(a) * sin(lean)).normalized()
		var at := Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.02, 0.12)
		_pad(pads, bits, rng, at, up, rng.randf() * TAU, float(V.pad) * rng.randf_range(0.95, 1.15), int(V.depth), float(V.branch), lod, 0, tops)
	# fruit or flowers on the rims of the top pads
	var nf := int(V.get("fruit", 0))
	var nfl := int(V.get("flowers", 0))
	var spots := PackedVector3Array()
	for t: Array in tops:
		var b: Basis = t[0]
		var o: Vector3 = t[1]
		var L: float = t[2]
		for k in (nf + rng.randi_range(-1, 1) if nf > 0 else 0):
			var ang := rng.randf_range(-1.0, 1.0)
			var rim := o + _rim(b, L, ang)
			var way := (b.y * cos(ang) + b.x * sin(ang)).normalized()
			_tuna(null, rng, rim + way * 0.025, way, lod) # (its draws kept as they were: the same pads)
			spots.append(rim + way * 0.025) # (its fruit hung there as things to pick, not drawn in it)
		for k in (nfl + rng.randi_range(-1, 0) if nfl > 0 else 0):
			var ang := rng.randf_range(-0.9, 0.9)
			var rim := o + _rim(b, L, ang)
			var way := (b.y * cos(ang) + b.x * sin(ang) + Vector3.UP * 0.4).normalized()
			_flower(extra, rim, way, lod)
	if variant >= 0 and lod == 0:
		_spots[variant] = spots
	return PM.finish([[pads, PM.painted(0.62, 0.3)], [bits, PM.painted(0.8)], [extra, PM.painted(0.5, 0.1, false)]])


## A point on a pad's rim (its frame: x across, y along, z its face's
## normal; length L), ang from its tip (rad, -PI..PI).
static func _rim(b: Basis, L: float, ang: float) -> Vector3:
	var u := 0.5 + 0.5 * cos(ang) # (0 its foot .. 1 its tip)
	var half := _halfw(u) * L
	return b.y * (L * u) + b.x * sin(ang) * half


## A pad's half breadth at u (0 its foot .. 1 its tip), a share of its
## length: obovate (broadest above its middle).
static func _halfw(u: float) -> float:
	return 0.36 * sqrt(maxf(sin(PI * u), 0.0)) * (0.75 + 0.35 * u)


## A pad from `at` along `up` (its length), turned `twist` round it; on it
## its areoles; off its rim its next pads (depth more), each a chance.
static func _pad(st: SurfaceTool, bits: SurfaceTool, rng: RandomNumberGenerator, at: Vector3, up: Vector3, twist: float, L: float, depth: int, branch: float, lod: int, level: int, tops: Array) -> void:
	var y := up.normalized()
	var x0 := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var x := x0.rotated(y, twist)
	var z := x.cross(y).normalized()
	var b := Basis(x, y, z)
	var woody := level == 0 and depth >= 3 # (the oldest at the foot: woody, rounder)
	var thick := 0.022 * (1.6 if woody else 1.0)
	# its surface: rings out from its middle line, both faces, thinning to
	# the rim
	var U: int = [12, 9, 6][lod]
	var A: int = [10, 7, 4][lod]
	var age := clampf(1.0 - float(level) / 4.0, 0.0, 1.0)
	var col := PAD.lerp(PAD_NEW, 1.0 - age).lerp(WOOD, 0.75 if woody else 0.0)
	for face: float in [1.0, -1.0]:
		for i in U:
			for j in A:
				var q := []
				for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
					var u := float(c[0]) / U
					var v := float(c[1]) / A * 2.0 - 1.0 # (-1 one rim .. 1 the other)
					var w := _halfw(u) * L * (1.0 if not woody else 0.7)
					var hgt := thick * 0.5 * sqrt(maxf(1.0 - v * v, 0.0)) * sqrt(maxf(sin(PI * u), 0.0)) * face
					var p := at + x * v * w + y * u * L + z * hgt
					var n := z * face
					var bend := (z * face * 0.8 + x * v * 0.45).normalized()
					var shade := 0.92 + 0.08 * PM.noise(p, 40.0)
					q.append([p, bend if absf(v) > 0.6 else n, col * shade])
				PM._tri(st, q[0][0], q[1][0], q[2][0], q[0][1], q[1][1], q[2][1], q[0][2], q[1][2], q[2][2])
				PM._tri(st, q[0][0], q[2][0], q[3][0], q[0][1], q[2][1], q[3][1], q[0][2], q[2][2], q[3][2])
		# its areoles: diagonal rows over the face, a tuft of glochids, a
		# few spines out and down
		if lod < 2 and not woody:
			var gap := 0.032
			var rows := int(L / gap)
			for r in rows:
				var u := (float(r) + 0.6) / (rows + 0.4)
				var w := _halfw(u) * L
				var across := int(w * 2.0 / gap)
				for c in across + 1:
					var v := (float(c) - across * 0.5 + (0.5 if r % 2 == 1 else 0.0)) * gap / maxf(w, 1e-3)
					if absf(v) > 0.92:
						continue
					var hgt := thick * 0.5 * sqrt(maxf(1.0 - v * v, 0.0)) * sqrt(maxf(sin(PI * u), 0.0))
					var p := at + x * v * w + y * u * L + z * hgt * face
					PM.blob(bits, p, Basis(x * 0.0022, y * 0.0022, z * 0.0012), GLOCHID, 5, 3)
					if lod == 0:
						var ns := rng.randi_range(0, 3) if level > 0 else rng.randi_range(1, 4)
						for k in ns:
							var sd := (z * face * 0.6 - y * rng.randf_range(0.2, 0.8) + x * rng.randf_range(-0.6, 0.6)).normalized()
							PM.spine(bits, p, sd, rng.randf_range(0.012, 0.04), 0.0009, SPINE_FOOT, SPINE)
	# the next pads, off its rim near its tip
	if depth <= 0:
		tops.append([b, at, L])
		return
	var kids := 0
	for k in 3:
		if rng.randf() > branch * (1.0 if k == 0 else 0.6):
			continue
		kids += 1
		var ang := rng.randf_range(-1.2, 1.2) if k > 0 else rng.randf_range(-0.4, 0.4)
		var rim := at + _rim(b, L, ang)
		var way := (y * cos(ang) + x * sin(ang)).normalized()
		way = (way + Vector3.UP * rng.randf_range(0.1, 0.6) + z * rng.randf_range(-0.4, 0.4)).normalized()
		_pad(st, bits, rng, rim - way * 0.012, way, rng.randf_range(-1.2, 1.2), L * rng.randf_range(0.82, 1.02), depth - 1, branch, lod, level + 1, tops)
	if kids == 0:
		tops.append([b, at, L])


## A fruit (a tuna): egg shaped, wine red, dotted with areoles.
static func _tuna(st: SurfaceTool, rng: RandomNumberGenerator, at: Vector3, way: Vector3, lod: int) -> void:
	var y := way.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var shade := rng.randf_range(0.85, 1.1)
	if st == null: # (its place only: the random draws as they'd be)
		return
	PM.ellipsoid(st, at, Basis(x * 0.018, y * 0.027, z * 0.018), [10, 7, 5][lod], [7, 5, 3][lod], func(u: Vector3) -> Color:
		var c := TUNA * shade
		var dot := PM.noise(Vector3(floorf(u.x * 6.0), floorf(u.y * 6.0), floorf(u.z * 6.0))) > 0.82
		return c.darkened(0.45) if dot else c)


## A flower: a yellow cup of petals on its ovary, the stamens in it.
static func _flower(st: SurfaceTool, at: Vector3, way: Vector3, lod: int) -> void:
	var y := way.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	PM.blob(st, at + y * 0.015, Basis(x * 0.014, y * 0.02, z * 0.014), PAD_NEW, 6, 4) # (its ovary)
	var mouth := at + y * 0.032
	var n: int = [14, 9, 6][lod]
	for k in n:
		var ang := TAU * float(k) / n
		var d := ((x * cos(ang) + z * sin(ang)) * 0.85 + y * 0.6).normalized()
		var c := Color(0.98, 0.85, 0.22).lerp(Color(0.95, 0.65, 0.15), 0.3 * float(k % 3) / 2.0)
		PM.blade(st, mouth, d, y, 0.04, 0.03, 0.002, c, c.lightened(0.1), false)
	PM.blob(st, mouth + y * 0.006, Basis(x * 0.012, y * 0.007, z * 0.012), Color(0.95, 0.9, 0.5), 6, 3) # (the stamens)
