class_name JoshuaTree
extends RefCounted
## The Joshua tree (Yucca brevifolia), the Mojave's tree-yucca, built whole
## (PlantMesh), life size, ten variants: an old tree (about 7 m, its trunk
## forking and forking again into a broad, open, angular crown), a younger
## one (a few branches), a young one (a single stem, its dead leaves a skirt
## down it to the ground), one in flower; a tall old one (its crown high on a
## long trunk), a tall lanky one forked once, a short squat one branching
## from low down, a short one with three arms, an old many-forked one, a
## tall single stem. In the mesa country, not up on
## the plateau: data/population/props/joshua_tree.tres; the sandbox's trees and
## bushes (tools/creatures/ecology_demo.gd).
##
## What makes it read as a Joshua tree: a thick trunk, its bark grey and
## corky, plated, low down; above, every branch shaggy with its own dead
## leaves, hanging back down it, straw grey; the branches forking where
## each flowered, two or three ways, crooked, angling up and out, each
## ending in one dense ball of stiff dagger leaves, blue green, yellowing to
## their sharp brown points, the inner ones upright, the outer spreading and
## some down; flowers, when it flowers, in a dense cream-green cluster on a
## short stalk up out of a rosette.

const PM := preload("res://scripts/population/plant_mesh.gd") # (by path: found whether or not the editor has seen the class yet)

const VARIANTS := [
	{"height": 2.2, "trunk_r": 0.24, "depth": 4, "fork": 0.92, "len": 1.7, "seed": 701},
	{"height": 1.3, "trunk_r": 0.16, "depth": 2, "fork": 0.85, "len": 0.95, "seed": 717},
	{"height": 1.5, "trunk_r": 0.1, "depth": 0, "fork": 0.0, "len": 0.0, "seed": 733, "skirt": true},
	{"height": 1.4, "trunk_r": 0.17, "depth": 3, "fork": 0.85, "len": 1.0, "seed": 751, "flowers": 0.6},
	# (more: tall and short, few forks and many; "ways": how many ways each
	# fork goes, at least and at most)
	{"height": 4.2, "trunk_r": 0.3, "depth": 3, "fork": 0.9, "len": 1.9, "seed": 769, "ways": [2, 3]}, # (a tall old one, a high crown on a long trunk)
	{"height": 3.4, "trunk_r": 0.22, "depth": 1, "fork": 0.0, "len": 1.9, "seed": 787, "ways": [2, 2], "spread": [0.8, 1.05]}, # (tall, lanky: forked just once, two arms up)
	{"height": 0.7, "trunk_r": 0.2, "depth": 4, "fork": 0.95, "len": 0.85, "seed": 797, "ways": [2, 4], "spread": [0.6, 1.0]}, # (short and squat: branching from low down, dense, round)
	{"height": 1.1, "trunk_r": 0.14, "depth": 1, "fork": 0.0, "len": 1.0, "seed": 811, "ways": [3, 3], "spread": [0.85, 1.15]}, # (short: one fork, three short arms)
	{"height": 2.6, "trunk_r": 0.27, "depth": 5, "fork": 0.85, "len": 1.25, "seed": 829, "ways": [2, 3]}, # (an old one forked and forked again: a broad, many branched crown)
	{"height": 2.0, "trunk_r": 0.12, "depth": 0, "fork": 0.0, "len": 0.0, "seed": 853, "skirt": true}, # (a tall single stem, not yet branched, its skirt to the ground)
]

const LEAF := Color(0.4, 0.5, 0.34)
const LEAF_TIP := Color(0.62, 0.58, 0.34)
const THATCH := Color(0.56, 0.5, 0.4)
const BARK := Color(0.42, 0.38, 0.32)

static var _cache := {}


## Its levels of detail (Population; PlantMesh.levels): where each simpler
## one takes over (m), the last its far card (FarTrees: with the trees'),
## out to FAR (m, at the standard tree render distance).
const LOD := [30.0, 90.0, 160.0]
const FAR := 2000.0


static func build(variant := 0) -> Mesh:
	return _levels(variant)[0]


## Its simpler levels (after the whole one, build()): fewer leaves and dead leaves; the far one
## (each rosette a ball, the branches bare).
static func build_lods(variant := 0) -> Array[Mesh]:
	return _levels(variant)[1]


## Population: its levels' distances and its reach, every variant's.
static func variant_props(_variant: int) -> Dictionary:
	return {"lod_distances": PackedFloat32Array(LOD), "view_distance": LOD[2], "far_distance": FAR}


static func _levels(variant: int) -> Array:
	variant = posmod(variant, VARIANTS.size())
	if not _cache.has(variant):
		var raw := []
		for lod in 3:
			raw.append(_make(VARIANTS[variant], lod))
		_cache[variant] = PM.levels(raw, LOD, LOD[2], "joshua_tree", variant, true)
	return _cache[variant]


static func _make(V: Dictionary, lod: int) -> Mesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(V.seed)
	var wood := PM.begin()
	var leaves := PM.begin()
	var tips := [] # [point, way]: a rosette at each
	var stems := [] # each branch's points: its dead leaves down it
	var sides: int = [9, 7, 5][lod]
	# the trunk, a little flared at its foot, a little crooked
	var h: float = V.height
	var r0: float = V.trunk_r
	var pts := [Vector3.ZERO]
	var radii := [r0 * 1.35]
	var dir := Vector3(rng.randf_range(-0.06, 0.06), 1.0, rng.randf_range(-0.06, 0.06)).normalized()
	var steps := 6
	for i in range(1, steps + 1):
		pts.append((pts[i - 1] as Vector3) + dir * h / steps)
		radii.append(r0 * lerpf(1.1, 0.92, float(i) / steps))
		dir = (dir + Vector3(rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.08, 0.08))).normalized()
	var skirt := bool(V.get("skirt", false))
	PM.tube(wood, pts, radii, sides, func(i: int, a: float, _g: float) -> Color:
		var hgt := float(i) / steps
		var plate := PM.noise(Vector3(floorf(a * 3.0), floorf(hgt * 9.0), 0.0))
		var c := BARK.lerp(THATCH, smoothstep(0.35, 0.9, hgt)) # (corky low, shaggy higher)
		return c * (0.86 + 0.12 * plate))
	var top: Vector3 = pts[pts.size() - 1]
	if int(V.depth) == 0:
		tips.append([top, dir])
	else:
		_branch(wood, rng, top, dir, float(V.len), r0 * 0.78, int(V.depth), float(V.fork), sides, tips, stems, V.get("ways", [2, 3]), V.get("spread", [0.45, 0.85]))
	# the dead leaves hanging down every branch (and a young one's skirt
	# down its stem to the ground)
	if lod < 2:
		var per := 70 if lod == 0 else 30
		if skirt:
			_thatch(leaves, rng, pts, r0, int(per * 2.2))
		else:
			_thatch(leaves, rng, pts.slice(steps / 2), r0, per / 3)
			for s: Array in stems:
				_thatch(leaves, rng, s, r0 * 0.6, per)
	# the rosettes
	var flowers := float(V.get("flowers", 0.0))
	for t: Array in tips:
		var p: Vector3 = t[0]
		var w: Vector3 = t[1]
		_rosette(leaves, rng, p, w, lod)
		if flowers > 0.0 and rng.randf() < flowers:
			_panicle(leaves, rng, p + w * 0.05, w, lod)
	return PM.finish([[wood, PM.painted(0.9)], [leaves, PM.painted(0.6, 0.15, false)]])


## A branch from p along dir (len, radius r), crooked; forking `depth`
## more times (each two or three ways, up and out), else a rosette at its
## end; dead leaves hanging down it.
static func _branch(st: SurfaceTool, rng: RandomNumberGenerator, p: Vector3, dir: Vector3, length: float, r: float, depth: int, fork: float, sides: int, tips: Array, stems: Array, ways: Array = [2, 3], spread_: Array = [0.45, 0.85]) -> void:
	var n := rng.randi_range(int(ways[0]), int(ways[1])) if depth > 0 else 0
	var axis := dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized()
	var turn := rng.randf() * TAU
	for c in n:
		var spread := rng.randf_range(float(spread_[0]), float(spread_[1])) # (how far out from the way it was going: rad)
		var a := turn + TAU * float(c) / n + rng.randf_range(-0.4, 0.4)
		var d := dir.rotated(axis.rotated(dir, a), spread)
		d = (d + Vector3.UP * 0.35).normalized() # (angling up)
		var l := length * rng.randf_range(0.75, 1.05)
		var pts := [p]
		var radii := [r]
		var q := p
		var segs := 4
		for i in segs:
			# (crooked: a kink at each node, bending up again)
			d = (d + Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.05, 0.2), rng.randf_range(-0.25, 0.25))).normalized()
			q += d * l / segs
			pts.append(q)
			radii.append(r * lerpf(1.0, 0.8, float(i + 1) / segs))
		PM.tube(st, pts, radii, sides, func(i: int, a2: float, _g: float) -> Color:
			return THATCH * (0.82 + 0.14 * PM.noise(Vector3(floorf(a2 * 4.0), float(i), float(depth)))))
		var end: Vector3 = pts[pts.size() - 1]
		if depth > 1 and rng.randf() < fork:
			_branch(st, rng, end, d, length * 0.72, r * 0.72, depth - 1, fork, maxi(sides - 1, 5), tips, stems, ways, spread_)
		else:
			tips.append([end, d])
		stems.append(pts)


## Dead leaves hanging back down the stem along pts (each a straw-grey
## blade, reflexed, pressed close), count of them.
static func _thatch(st: SurfaceTool, rng: RandomNumberGenerator, pts: Array, r: float, count: int) -> void:
	var n := pts.size()
	if n < 2:
		return
	for k in count:
		var f := rng.randf()
		var i := mini(int(f * (n - 1)), n - 2)
		var u := f * (n - 1) - i
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var at := a.lerp(b, u)
		var along := (b - a).normalized()
		var out := along.cross(Vector3.RIGHT if absf(along.x) < 0.9 else Vector3.FORWARD).normalized().rotated(along, rng.randf() * TAU)
		var d := (-along * 0.85 + out * rng.randf_range(0.15, 0.4)).normalized()
		var c := THATCH.darkened(rng.randf_range(0.0, 0.3)).lerp(Color(0.66, 0.6, 0.48), rng.randf() * 0.3)
		PM.blade(st, at + out * r * 0.9, d, out, rng.randf_range(0.2, 0.3), 0.012, 0.003, c, c.darkened(0.15), false)


## One rosette: a dense ball of stiff dagger leaves round the branch's tip.
static func _rosette(st: SurfaceTool, rng: RandomNumberGenerator, p: Vector3, way: Vector3, lod: int) -> void:
	var w := way.normalized()
	var a := w.cross(Vector3.RIGHT if absf(w.x) < 0.9 else Vector3.FORWARD).normalized()
	var b := w.cross(a)
	if lod == 2:
		PM.ellipsoid(st, p + w * 0.08, Basis(a * 0.26, w * 0.24, b * 0.26), 8, 5, func(u: Vector3) -> Color:
			return LEAF.lerp(LEAF_TIP, 0.3 + 0.2 * u.y))
		return
	var count := 110 if lod == 0 else 45
	for k in count:
		# (inner leaves upright and short, outer spreading, a few down)
		var t := float(k) / count
		var up := lerpf(1.0, -0.45, pow(t, 0.8)) + rng.randf_range(-0.08, 0.08)
		var ang := k * 2.39996 + rng.randf_range(-0.1, 0.1) # (the golden angle round)
		var side := sqrt(maxf(1.0 - up * up, 0.0))
		var d := (w * up + (a * cos(ang) + b * sin(ang)) * side).normalized()
		var l := lerpf(0.16, 0.3, smoothstep(0.0, 0.4, t)) * rng.randf_range(0.85, 1.1)
		var flat := d.cross(w).cross(d)
		var c0 := LEAF.lerp(Color(0.5, 0.56, 0.38), rng.randf() * 0.4)
		if t > 0.88: # (the lowest yellowing, dying)
			c0 = c0.lerp(THATCH, 0.6)
		PM.blade(st, p + d * 0.015, d, flat, l, 0.016, 0.006, c0, LEAF_TIP.darkened(0.3))


## A flowering stalk up out of a rosette: a dense cluster of waxy,
## cream-green bells.
static func _panicle(st: SurfaceTool, rng: RandomNumberGenerator, p: Vector3, way: Vector3, lod: int) -> void:
	var w := way.normalized()
	var top := p + w * 0.32
	PM.tube(st, [p, p + w * 0.16, top], [0.022, 0.018, 0.012], 5, func(_i: int, _a: float, _g: float) -> Color: return Color(0.55, 0.55, 0.38))
	var n := 36 if lod == 0 else 12
	for k in n:
		var u := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var at := top + w * 0.06 + u * Vector3(0.09, 0.12, 0.09)
		var col := Color(0.86, 0.85, 0.66).lerp(Color(0.7, 0.75, 0.5), rng.randf() * 0.5)
		PM.blob(st, at, Basis().scaled(Vector3(0.022, 0.03, 0.022)), col, 6, 4)
