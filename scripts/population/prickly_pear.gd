class_name PricklyPear
extends RefCounted
## A prickly pear (Opuntia), built whole (PlantMesh), life size, six
## variants, all low: chains of pads sprawling over the ground, a few pads
## each, here and there one standing up out of them. A spreading clump; a
## small one; one fruiting; one in flower; a long trailing mat; a low ring of
## pads round its old woody middle. In the mesa country, not up on the
## plateau (data/population/props/prickly_pear.tres); its fruit (the tunas,
## the item "prickly_pear") hung on the rims of its top pads where it bears
## them (fruit_spots: Foraging draws and picks them, as a tree's).
##
## What makes it read as a prickly pear: flat, round-ended pads (each a
## stem: obovate, a hand and a half long, two fingers thick at the middle,
## thinning to their rims), joined end to end, each new pad off the rim of
## the last; here creeping, the chains lying along the ground, the pads
## leaning on their edges, rooting where they touch it, a few standing up
## off them; blue green, a bloom on them; the areoles in diagonal rows over
## both faces, each a tuft of brown glochids with a few stout spines, pale
## yellow-white, reddish at the base, pointing out and down; the oldest pads
## at the foot gone woody, grey brown, rounder; the fruits (tunas) on the
## rims of the top pads, egg shaped, wine red to purple; the flowers there
## too, yellow cups, the stamens in their middle.

const PM := preload("res://scripts/population/plant_mesh.gd") # (by path: found whether or not the editor has seen the class yet)

## chains: how many run out from its middle; len: pads in each (at least,
## at most); pad: a pad's length (m); up: pads standing up off the chains;
## old: its first pads woody.
const VARIANTS := [
	{"chains": 3, "len": [2, 3], "pad": 0.22, "up": 1, "old": true, "seed": 901}, # (a spreading clump)
	{"chains": 2, "len": [1, 2], "pad": 0.17, "up": 0, "seed": 919}, # (a small one)
	{"chains": 3, "len": [1, 2], "pad": 0.21, "up": 2, "seed": 937, "fruit": 3}, # (fruiting)
	{"chains": 3, "len": [1, 2], "pad": 0.21, "up": 1, "seed": 947, "flowers": 2}, # (in flower)
	{"chains": 2, "len": [3, 4], "pad": 0.2, "up": 0, "old": true, "seed": 961}, # (a long trailing mat)
	{"chains": 4, "len": [1, 2], "pad": 0.23, "up": 1, "old": true, "seed": 977}, # (a low ring round its old middle)
]

const PAD := Color(0.36, 0.5, 0.36)
const PAD_NEW := Color(0.5, 0.62, 0.36)
const WOOD := Color(0.48, 0.42, 0.34)
const GLOCHID := Color(0.4, 0.28, 0.16)
const SPINE := Color(0.9, 0.87, 0.72)
const SPINE_FOOT := Color(0.55, 0.3, 0.2)

static var _cache := {}
static var _spots := {} # variant -> its fruit's places (its mesh's space)


## The fruit it bears (Items), "" none: the fruiting one's tunas.
static func fruit_of(variant: int) -> String:
	return "prickly_pear" if VARIANTS[posmod(variant, VARIANTS.size())].has("fruit") else ""


## Where its fruit grow (its mesh's space): on the rims of its top pads.
static func fruit_spots(variant: int) -> PackedVector3Array:
	variant = posmod(variant, VARIANTS.size())
	_levels(variant)
	return _spots.get(variant, PackedVector3Array())


## Its levels of detail (Population; PlantMesh.levels): where each simpler
## one takes over (m), the last its far card, out to VIEW (m).
const LOD := [15.0, 35.0, 60.0]
const VIEW := 120.0


static func build(variant := 0) -> Mesh:
	return _levels(variant)[0]


## Its simpler levels (after the whole one, build()): no spines; the far one (the pads coarser,
## no areoles); then its far card.
static func build_lods(variant := 0) -> Array[Mesh]:
	return _levels(variant)[1]


## Population: its levels' distances and its reach, every variant's.
static func variant_props(_variant: int) -> Dictionary:
	return {"lod_distances": PackedFloat32Array(LOD), "view_distance": VIEW}


static func _levels(variant: int) -> Array:
	variant = posmod(variant, VARIANTS.size())
	if not _cache.has(variant):
		var raw := []
		for lod in 3:
			raw.append(_make(VARIANTS[variant], lod, variant))
		_cache[variant] = PM.levels(raw, LOD, VIEW, "prickly_pear", variant)
	return _cache[variant]


static func _make(V: Dictionary, lod: int, variant := -1) -> Mesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(V.seed)
	var pads := PM.begin()
	var bits := PM.begin()
	var extra := PM.begin()
	var tops := [] # the pads fruit and flowers may stand on: [their basis, their origin, length]
	var laid := [] # every pad of the chains: [basis, origin, length, level]
	var n := int(V.chains)
	var L0 := float(V.pad)
	for c in n:
		# a chain: its first pad up out of the middle, leaning out; each next
		# off its tip's rim, on out and round a little, down to lie along the
		# ground (its tip touching it, rooting), on its edge more or less
		var heading := TAU * float(c) / n + rng.randf_range(-0.45, 0.45)
		var at := Vector3(cos(heading), 0.0, sin(heading)) * rng.randf_range(0.0, 0.05)
		var rise := rng.randf_range(0.45, 0.8)
		var L := L0 * rng.randf_range(0.9, 1.1)
		var count := rng.randi_range(int(V.len[0]), int(V.len[1]))
		for k in count:
			var b := _frame(heading, rise, rng.randf_range(0.45, 1.25) * (1.0 if rng.randf() < 0.5 else -1.0))
			var woody: bool = k == 0 and V.get("old", false)
			_pad(pads, bits, rng, at, b, L, woody, k, lod)
			laid.append([b, at, L, k])
			if k == count - 1:
				tops.append([b, at, L])
				break
			var ang := rng.randf_range(-0.45, 0.45)
			var tip := at + _rim(b, L, ang)
			heading += rng.randf_range(-0.5, 0.5) + ang * 0.6
			L *= rng.randf_range(0.85, 1.0)
			# (down toward the ground, but its far end no lower than it)
			rise = rng.randf_range(-0.35, 0.05) if tip.y > 0.1 else rng.randf_range(0.0, 0.3)
			var reach_y := tip.y + sin(rise) * L
			if reach_y < 0.02:
				rise = asin(clampf((0.02 - tip.y) / L, -1.0, 1.0))
			at = tip - Vector3(cos(heading), 0.0, sin(heading)) * 0.012
	# a few pads standing up off the chains' pads, each off its upper rim
	var ups := int(V.get("up", 0))
	for u in ups:
		if laid.is_empty():
			break
		var host: Array = laid[(u * 7 + rng.randi_range(0, laid.size() - 1)) % laid.size()]
		var hb: Basis = host[0]
		var ang := rng.randf_range(-0.6, 0.6)
		var rim: Vector3 = host[1] + _rim(hb, float(host[2]), ang)
		var heading := atan2(hb.y.z, hb.y.x) + rng.randf_range(-0.6, 0.6)
		var b := _frame(heading, rng.randf_range(1.05, 1.35), rng.randf_range(-1.4, 1.4))
		var L := float(host[2]) * rng.randf_range(0.8, 0.95)
		_pad(pads, bits, rng, rim - b.y * 0.012, b, L, false, int(host[3]) + 1, lod)
		tops.append([b, rim - b.y * 0.012, L])
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
			var way := (b.y * cos(ang) + b.x * sin(ang) + Vector3.UP * 0.5).normalized()
			spots.append(rim + way * 0.025) # (its fruit hung there as things to pick, not drawn in it)
		for k in (nfl + rng.randi_range(-1, 0) if nfl > 0 else 0):
			var ang := rng.randf_range(-0.9, 0.9)
			var rim := o + _rim(b, L, ang)
			var way := (b.y * cos(ang) + b.x * sin(ang) + Vector3.UP * 0.6).normalized()
			_flower(extra, rim, way, lod)
	if variant >= 0 and lod == 0:
		_spots[variant] = spots
	return PM.finish([[pads, PM.painted(0.62, 0.15)], [bits, PM.painted(0.8)], [extra, PM.painted(0.5, 0.1, false)]])


## A pad's frame: y along it (heading round from +x, rise up from level,
## rad), x across it, z its face's normal; on its edge by tilt (0 lying
## flat, face up; PI/2 standing on its edge).
static func _frame(heading: float, rise: float, tilt: float) -> Basis:
	var y := Vector3(cos(heading) * cos(rise), sin(rise), sin(heading) * cos(rise)).normalized()
	var flat := Vector3(-sin(heading), 0.0, cos(heading)) # (level, square to it)
	var x := flat.rotated(y, tilt)
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


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


## A pad from `at` along its frame b (y along it) of length L; on it its
## areoles (their spines by their own draws: the levels' pads the same).
static func _pad(st: SurfaceTool, bits: SurfaceTool, rng: RandomNumberGenerator, at: Vector3, b: Basis, L: float, woody: bool, level: int, lod: int) -> void:
	var x := b.x
	var y := b.y
	var z := b.z
	var deco := RandomNumberGenerator.new()
	deco.seed = rng.randi() # (drawn at every level: the next pads the same)
	var thick := 0.022 * (1.6 if woody else 1.0)
	# its surface: rings out from its middle line, both faces, thinning to
	# the rim
	var U: int = [10, 7, 5][lod]
	var A: int = [8, 6, 4][lod]
	var age := clampf(1.0 - float(level) / 3.0, 0.0, 1.0)
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
			var gap := 0.036
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
					PM.blob(bits, p, Basis(x * 0.0024, y * 0.0024, z * 0.0012), GLOCHID, 4, 2)
					if lod == 0:
						for k in deco.randi_range(0, 2):
							var sd := (z * face * 0.6 - y * deco.randf_range(0.2, 0.8) + x * deco.randf_range(-0.6, 0.6)).normalized()
							PM.spine(bits, p, sd, deco.randf_range(0.015, 0.04), 0.0009, SPINE_FOOT, SPINE)


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
