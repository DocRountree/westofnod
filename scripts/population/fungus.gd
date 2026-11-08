class_name Fungus
## The fungi (each a PropKind's mesh_script through its own little script:
## Morel, FlyAgaric, LittleBrownCap, ChickenOfTheWoods; data/population/
## props/), at life size, built whole (PlantMesh: painted by their
## vertices), a few variants each, three levels of detail and a far card;
## and each picked whole as its item (Foraging: Population.pickable_at),
## growing again some days after (Foraging.FUNGI_REGROW).
##
## - morel (Morchella esculenta): a hollow cream stem, a little swollen at
##   its foot; its cap an upright egg-cone, tan to honey, a honeycomb of
##   deep dark pits between pale ridges. On the ground near trees (the
##   forest's, under them, where nothing else grows too). One, a pair, a few.
## - fly agaric (Amanita muscaria): its cap red, orange toward its rim,
##   flecked with white warts (the veil's remains); white gills; a white
##   stem with a hanging ring and a bulbous foot ringed with the volva's
##   scales. The button (a white-warted egg), young (a dome), grown (flat),
##   a pair. On the forest floor.
## - little brown caps (Psathyrella, Mycena, Galerina and their like: the
##   ones nobody can tell apart): clusters of small bell caps, brown, darker
##   at the top, paler and lined toward the margin, on thin pale stems. On
##   the forest floor and the prairie.
## - chicken of the woods (Laetiporus sulphureus): overlapping shelves, fans
##   with wavy rims, bright orange on top fading to sulphur yellow at the
##   margins, yellow pores beneath; in rosettes and tiers. On fallen logs,
##   stumps, and the lower trunks of living oaks (PropKind.grows_on: its
##   back to the wood, +z out from it).

const PM := preload("res://scripts/population/plant_mesh.gd")
const LOD := [6.0, 16.0, 30.0]
const VIEW := 45.0
const SIDES := [18, 10, 6] ## round a stem or cap, by level
const SPECIES := {
	"morel": {"variants": 4, "item": "morel", "pick_at": Vector3(0.0, 0.05, 0.0), "pick_r": 0.06},
	"fly_agaric": {"variants": 5, "item": "fly_agaric", "pick_at": Vector3(0.0, 0.08, 0.0), "pick_r": 0.11},
	"little_brown": {"variants": 4, "item": "little_brown", "pick_at": Vector3(0.0, 0.03, 0.0), "pick_r": 0.07},
	"chicken_of_the_woods": {"variants": 4, "item": "chicken_of_the_woods", "pick_at": Vector3(0.0, 0.0, 0.1), "pick_r": 0.2},
}

static var _cache := {}


## The kind's levels: [the whole one, [the simpler, the simplest, its card]].
static func levels(species: String, variant: int) -> Array:
	variant = posmod(variant, int(SPECIES[species].variants))
	var key := [species, variant]
	if not _cache.has(key):
		var raw := []
		for lod in 3:
			raw.append(_make(species, variant, lod))
		_cache[key] = PM.levels(raw, LOD, VIEW, species, variant)
	return _cache[key]


## Population: its levels, how far it's drawn; what it's picked as (its
## item, how many: the mushrooms in it), where (pick_at, pick_r).
static func variant_props(species: String, variant: int) -> Dictionary:
	var S: Dictionary = SPECIES[species]
	return {"lod_distances": PackedFloat32Array(LOD), "view_distance": VIEW, "item": S.item,
			"pick_at": S.pick_at, "pick_r": S.pick_r, "pick_count": _count(species, variant)}


## How many it gives picked.
static func _count(species: String, v: int) -> int:
	match species:
		"morel":
			return [1, 2, 3, 1][v]
		"fly_agaric":
			return [1, 1, 1, 1, 2][v]
		"little_brown":
			return [5, 8, 4, 7][v]
		"chicken_of_the_woods":
			return [2, 3, 4, 2][v]
	return 1


## One of it, held (Items.model): its mesh, whole.
static func held(id: String) -> Mesh:
	var key := ["held", id]
	if not _cache.has(key):
		var st := PM.begin()
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		match id:
			"morel":
				_morel(st, rng, Transform3D(), 1.0, 0)
			"fly_agaric":
				_amanita(st, rng, Transform3D(), 2, 0.9, 0)
			"little_brown":
				_lbc(st, rng, Transform3D(), 1.0, 0)
			_:
				_shelf(st, rng, Transform3D(), 0.12, 0)
		_cache[key] = PM.finish([[st, PM.painted(0.7)]])
	return _cache[key]


static func _make(species: String, v: int, lod: int) -> Mesh:
	var st := PM.begin()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([species, v])
	match species:
		"morel":
			var n: int = [1, 2, 3, 1][v]
			for i in n:
				var at := Vector3.ZERO if i == 0 else Vector3(rng.randf_range(-0.05, 0.05), 0.0, rng.randf_range(-0.05, 0.05))
				var sc := 1.35 if v == 3 else rng.randf_range(0.75, 1.1)
				_morel(st, rng, Transform3D(_tilt(rng, 0.12), at), sc, lod)
		"fly_agaric":
			match v:
				0: _amanita(st, rng, Transform3D(Basis(), Vector3.ZERO), 0, 1.0, lod)
				1: _amanita(st, rng, Transform3D(_tilt(rng, 0.08), Vector3.ZERO), 1, 1.0, lod)
				2: _amanita(st, rng, Transform3D(_tilt(rng, 0.06), Vector3.ZERO), 2, 1.0, lod)
				3: _amanita(st, rng, Transform3D(_tilt(rng, 0.1), Vector3.ZERO), 3, 1.15, lod)
				_:
					_amanita(st, rng, Transform3D(_tilt(rng, 0.06), Vector3.ZERO), 2, 0.95, lod)
					_amanita(st, rng, Transform3D(_tilt(rng, 0.15), Vector3(0.09, 0.0, 0.05)), 1, 0.8, lod)
		"little_brown":
			var n := _count(species, v)
			var spread: float = [0.05, 0.07, 0.04, 0.09][v]
			for i in n:
				var a := rng.randf() * TAU
				var at := Vector3(cos(a), 0.0, sin(a)) * spread * sqrt(rng.randf())
				var lean := (at.normalized() if at.length() > 0.001 else Vector3.RIGHT) * rng.randf_range(0.1, 0.35) # (leaning out of the cluster)
				var b := Basis(Quaternion(Vector3.UP, (Vector3.UP + lean).normalized())) * Basis(Vector3.UP, rng.randf() * TAU)
				_lbc(st, rng, Transform3D(b, at), rng.randf_range(0.6, 1.15), lod)
		"chicken_of_the_woods":
			var n: int = [3, 6, 8, 4][v]
			var wide: float = [0.18, 0.2, 0.26, 0.32][v]
			for i in n:
				# (tiers up the wood, each a little to one side, the lower
				# ones bigger)
				var f := float(i) / maxf(n - 1, 1)
				var y := (f - 0.5) * (0.045 * n if v != 3 else 0.08)
				var x := rng.randf_range(-0.06, 0.06) * (1.0 if v != 3 else 2.2)
				var turn := rng.randf_range(-0.35, 0.35)
				var sc := wide * lerpf(1.0, 0.65, f) * rng.randf_range(0.8, 1.1)
				_shelf(st, rng, Transform3D(Basis(Vector3.UP, turn) * Basis(Vector3.RIGHT, rng.randf_range(-0.12, 0.05)), Vector3(x, y, -0.01)), sc, lod)
	return PM.finish([[st, PM.painted(0.75)]])


static func _tilt(rng: RandomNumberGenerator, amount: float) -> Basis:
	var a := rng.randf() * TAU
	return Basis(Vector3(cos(a), 0.0, sin(a)), rng.randf_range(0.0, amount)) * Basis(Vector3.UP, rng.randf() * TAU)


## A surface of revolution about y through prof ([r, y], from the bottom of
## the axis round to its top), sides round; each vertex coloured by
## colour(i (its profile index), angle, its point) and pushed out (m) by
## push(i, angle, its point); placed by xf.
static func _revolve(st: SurfaceTool, prof: Array, sides: int, colour: Callable, xf: Transform3D, push := Callable()) -> void:
	var n := prof.size()
	var grid := []
	for i in n:
		var row := []
		for k in sides + 1:
			var a := TAU * float(k % sides) / sides
			var p := Vector3(cos(a) * float(prof[i][0]), float(prof[i][1]), sin(a) * float(prof[i][0]))
			if push.is_valid() and float(prof[i][0]) > 1e-5:
				p += Vector3(cos(a), 0.0, sin(a)) * float(push.call(i, a, p))
			row.append(p)
		grid.append(row)
	var verts := []
	for i in n:
		var row := []
		for k in sides + 1:
			var a := TAU * float(k % sides) / sides
			var up: Vector3 = grid[mini(i + 1, n - 1)][k] - grid[maxi(i - 1, 0)][k]
			var round_: Vector3 = grid[i][(k + 1) % sides] - grid[i][(k + sides - 1) % sides]
			var nn := round_.cross(up)
			if nn.length() < 1e-12:
				nn = Vector3.UP if i == n - 1 else Vector3.DOWN
			var outward := Vector3(cos(a), 0.0, sin(a))
			if float(prof[i][0]) > 1e-4 and nn.dot(outward) < 0.0:
				nn = -nn
			row.append([grid[i][k], nn.normalized(), colour.call(i, a, grid[i][k])])
		verts.append(row)
	grid = verts
	for i in n - 1:
		for k in sides:
			var a: Array = grid[i][k]
			var b: Array = grid[i][k + 1]
			var c: Array = grid[i + 1][k + 1]
			var d: Array = grid[i + 1][k]
			for t: Array in [[a, b, c], [a, c, d]]:
				var p0: Array = t[0]
				var p1: Array = t[1]
				var p2: Array = t[2]
				PM._tri(st, xf * p0[0], xf * p1[0], xf * p2[0], xf.basis * p0[1], xf.basis * p1[1], xf.basis * p2[1], p0[2], p1[2], p2[2])


## Points on a profile (simplified for the level: every other, every third).
static func _thin(prof: Array, lod: int) -> Array:
	if lod == 0:
		return prof
	var step := lod + 1
	var out := []
	for i in range(0, prof.size(), step):
		out.append(prof[i])
	if out[out.size() - 1] != prof[prof.size() - 1]:
		out.append(prof[prof.size() - 1])
	return out


## Hash noise in 3D, 0..1 (repeatable).
static func _h3(x: float, y: float, z: float) -> float:
	return fposmod(sin(x * 127.1 + y * 311.7 + z * 74.7) * 43758.5453, 1.0)


## A morel: its stem, its pitted cap. sc: its size.
static func _morel(st: SurfaceTool, rng: RandomNumberGenerator, xf: Transform3D, sc: float, lod: int) -> void:
	var stem_h := 0.035 * sc
	var cap_h := 0.06 * sc
	var w := 0.018 * sc * rng.randf_range(0.85, 1.1)
	var prof := [[0.0, 0.0], [0.011 * sc, 0.0], [0.012 * sc, 0.006 * sc], [0.009 * sc, 0.02 * sc], [0.0085 * sc, stem_h],
			[w * 0.92, stem_h + 0.004 * sc], [w, stem_h + cap_h * 0.2], [w * 0.97, stem_h + cap_h * 0.42], [w * 0.85, stem_h + cap_h * 0.62],
			[w * 0.62, stem_h + cap_h * 0.8], [w * 0.33, stem_h + cap_h * 0.93], [0.0, stem_h + cap_h]]
	var CAP := 5
	var cell := 0.0075 * sc
	var seed := rng.randf() * 100.0
	# (its pits: a honeycomb by cells, ridges where two are near alike)
	var pit := func(p: Vector3) -> float:
		var q := p / cell
		var f1 := 9.0
		var f2 := 9.0
		var g := q.floor()
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					var c := g + Vector3(dx, dy, dz)
					var o := c + Vector3(_h3(c.x + seed, c.y, c.z), _h3(c.x, c.y + seed, c.z), _h3(c.x, c.y, c.z + seed))
					var d := q.distance_to(o)
					if d < f1:
						f2 = f1
						f1 = d
					elif d < f2:
						f2 = d
		return clampf((f2 - f1) / 0.35, 0.0, 1.0) # (0 on a ridge .. 1 deep in a pit)
	var ridge := Color(0.56, 0.42, 0.24) * rng.randf_range(0.9, 1.08)
	var hole := Color(0.18, 0.11, 0.06)
	var stem := Color(0.9, 0.85, 0.72)
	var col := func(i: int, _a: float, p: Vector3) -> Color:
		if i < CAP:
			return stem * (0.92 + 0.08 * _h3(p.x * 300.0, p.y * 300.0, p.z * 300.0))
		if lod == 2:
			return ridge.lerp(hole, 0.45)
		return ridge.lerp(hole, pow(float(pit.call(p)), 0.7))
	var push := func(i: int, _a: float, p: Vector3) -> float:
		if i < CAP or lod > 0:
			return 0.0
		return -0.0022 * sc * float(pit.call(p))
	var sides: int = [28, 12, 7][lod]
	var full := []
	if lod == 0: # (the cap finer, for its pits)
		for i in prof.size():
			full.append(prof[i])
			if i >= CAP and i < prof.size() - 1:
				full.append([(float(prof[i][0]) + float(prof[i + 1][0])) * 0.5, (float(prof[i][1]) + float(prof[i + 1][1])) * 0.5])
		var cap_from := CAP
		col = func(i: int, _a: float, p: Vector3) -> Color:
			if i < cap_from:
				return stem * (0.92 + 0.08 * _h3(p.x * 300.0, p.y * 300.0, p.z * 300.0))
			return ridge.lerp(hole, pow(float(pit.call(p)), 0.7))
		push = func(i: int, _a: float, p: Vector3) -> float:
			return 0.0 if i < cap_from else -0.0022 * sc * float(pit.call(p))
	else:
		full = _thin(prof, lod - 1)
	_revolve(st, full, sides, col, xf, push)


## A fly agaric. stage: 0 the button (a warted egg), 1 young (a dome on a
## short stem), 2 grown (flat), 3 old (its rim turned up a little). sc: its size.
static func _amanita(st: SurfaceTool, rng: RandomNumberGenerator, xf: Transform3D, stage: int, sc: float, lod: int) -> void:
	var white := Color(0.94, 0.91, 0.83)
	var red := Color(0.8, 0.1, 0.04) * rng.randf_range(0.92, 1.05)
	var orange := Color(0.92, 0.42, 0.08)
	var prof: Array
	var cap_from: int
	var R: float
	var top: float
	match stage:
		0:
			R = 0.03 * sc
			prof = [[0.0, 0.0], [0.024 * sc, 0.004 * sc], [0.031 * sc, 0.02 * sc], [0.03 * sc, 0.034 * sc], [0.024 * sc, 0.046 * sc], [0.013 * sc, 0.054 * sc], [0.0, 0.057 * sc]]
			cap_from = 3
			top = 0.057 * sc
		1:
			var h := 0.07 * sc
			R = 0.04 * sc
			prof = [[0.0, 0.0], [0.02 * sc, 0.0], [0.024 * sc, 0.014 * sc], [0.016 * sc, 0.03 * sc], [0.012 * sc, h], [0.026 * sc, h + 0.004 * sc],
					[R, h + 0.008 * sc], [R * 1.04, h + 0.018 * sc], [R * 0.9, h + 0.034 * sc], [R * 0.55, h + 0.046 * sc], [0.0, h + 0.05 * sc]]
			cap_from = 7
			top = h + 0.05 * sc
		_:
			var h := (0.14 if stage == 2 else 0.16) * sc
			R = (0.07 if stage == 2 else 0.085) * sc
			var lip := 0.006 * sc if stage == 3 else 0.0 # (an old one's rim turned up)
			prof = [[0.0, 0.0], [0.022 * sc, 0.0], [0.027 * sc, 0.014 * sc], [0.021 * sc, 0.03 * sc], [0.015 * sc, 0.05 * sc], [0.012 * sc, h],
					[0.03 * sc, h + 0.006 * sc], [R * 0.75, h + 0.012 * sc], [R, h + 0.016 * sc + lip], [R * 1.01, h + 0.024 * sc + lip],
					[R * 0.93, h + 0.038 * sc], [R * 0.75, h + 0.05 * sc], [R * 0.45, h + 0.058 * sc], [0.0, h + 0.061 * sc]]
			cap_from = 9
			top = h + 0.061 * sc
	var col := func(i: int, _a: float, p: Vector3) -> Color:
		if stage == 0:
			return white.lerp(red, 0.25 * clampf((p.y - 0.03 * sc) / (0.03 * sc), 0.0, 1.0)) # (the red just showing through the veil)
		if i < cap_from:
			return white * (0.95 + 0.05 * _h3(p.x * 200.0, p.y * 200.0, p.z * 200.0))
		var r := Vector2(p.x, p.z).length() / R
		var c := red.lerp(orange, smoothstep(0.55, 1.0, r))
		if lod == 2: # (its warts painted on, far off)
			c = c.lerp(white, 0.25)
		return c
	_revolve(st, _thin(prof, lod), SIDES[lod], col, xf)
	# its ring, hanging from the stem below the cap; the volva's rings at its foot
	if stage >= 2 and lod < 2:
		var y: float = float(prof[5][1]) - 0.02 * sc
		var ring := [[0.0125 * sc, y], [0.022 * sc, y - 0.008 * sc], [0.026 * sc, y - 0.016 * sc], [0.0125 * sc, y - 0.004 * sc]]
		_revolve(st, ring, SIDES[lod], func(_i: int, _a: float, _p: Vector3) -> Color: return Color(0.96, 0.94, 0.86), xf)
		for k in 2:
			var vy := (0.012 + 0.008 * k) * sc
			var vr := (0.027 - 0.002 * k) * sc
			_revolve(st, [[vr - 0.002 * sc, vy - 0.002 * sc], [vr + 0.003 * sc, vy], [vr - 0.001 * sc, vy + 0.003 * sc]], SIDES[lod], func(_i: int, _a: float, _p: Vector3) -> Color: return Color(0.88, 0.84, 0.72), xf)
	# its warts: white flecks over the cap (thick on the button)
	if lod < 2:
		var n: int = (60 if stage == 0 else 34 if stage == 1 else 46) / (1 + lod * 2)
		for k in n:
			var a := rng.randf() * TAU
			var f := sqrt(rng.randf()) * 0.92
			var px := cos(a) * R * f
			var pz := sin(a) * R * f
			# (the cap's top there: up the profile's dome)
			var py := top - (top - _cap_rim_y(prof, cap_from)) * (1.0 - sqrt(maxf(1.0 - f * f, 0.0))) # (on the dome)
			var nrm := Vector3(px / R * 0.8, 1.0, pz / R * 0.8).normalized()
			var s := (0.003 + 0.004 * rng.randf()) * sc * (1.3 if stage == 0 else 1.0)
			var b := Basis(Quaternion(Vector3.UP, nrm)) * Basis.from_scale(Vector3(s, s * 0.5, s))
			PM.blob(st, xf * Vector3(px, py, pz), xf.basis * b, Color(0.95, 0.92, 0.82) * rng.randf_range(0.92, 1.0), 6 - lod * 2, 3)


static func _cap_rim_y(prof: Array, cap_from: int) -> float:
	return float(prof[maxi(cap_from - 1, 0)][1])


## A little brown cap: a thin pale stem, a small bell cap, brown, its top
## darker, its margin paler and lined. sc: its size.
static func _lbc(st: SurfaceTool, rng: RandomNumberGenerator, xf: Transform3D, sc: float, lod: int) -> void:
	var h := rng.randf_range(0.035, 0.065) * sc
	var R := rng.randf_range(0.009, 0.014) * sc
	var ch := R * rng.randf_range(0.8, 1.1)
	var s := 0.0018 * sc
	var prof := [[0.0, 0.0], [s * 1.3, 0.0], [s, h * 0.5], [s * 0.9, h], [R * 0.5, h + ch * 0.05], [R, h + ch * 0.08],
			[R * 0.98, h + ch * 0.25], [R * 0.82, h + ch * 0.6], [R * 0.45, h + ch * 0.9], [0.0, h + ch]]
	var cap := Color(0.44, 0.3, 0.17) * rng.randf_range(0.85, 1.15)
	var top := Color(0.27, 0.18, 0.1)
	var rim := Color(0.62, 0.5, 0.34)
	var stem := Color(0.74, 0.66, 0.5)
	var gills := Color(0.32, 0.23, 0.16)
	var col := func(i: int, a: float, p: Vector3) -> Color:
		if i < 4:
			return stem
		if i < 6:
			return gills
		var f := clampf((p.y - h) / ch, 0.0, 1.0)
		var c := rim.lerp(cap, smoothstep(0.1, 0.5, f)).lerp(top, smoothstep(0.65, 1.0, f))
		return c * (1.0 - 0.12 * (1.0 - f) * (0.5 + 0.5 * sin(a * 40.0))) # (its lines, toward the margin)
	_revolve(st, _thin(prof, lod), maxi(int(SIDES[lod]) - 6, 5), col, xf)


## A chicken of the woods shelf: a fan out from the wood (+z), w wide; its
## top orange fading to sulphur at its wavy rim, yellow pores beneath, a
## little thick at its base, thin at its rim.
static func _shelf(st: SurfaceTool, rng: RandomNumberGenerator, xf: Transform3D, w: float, lod: int) -> void:
	var NA: int = [14, 8, 5][lod]
	var NR: int = [6, 4, 2][lod]
	var half := rng.randf_range(1.0, 1.35)
	var deep := w * rng.randf_range(0.7, 0.9)
	var ph := rng.randf() * TAU
	var orange := Color(0.9, 0.3, 0.03) * rng.randf_range(0.92, 1.05)
	var sulphur := Color(0.95, 0.68, 0.08)
	var under := Color(0.93, 0.78, 0.3)
	var pt := func(i: int, k: int, upper: bool) -> Array:
		var a := lerpf(-half, half, float(k) / NA)
		var f := float(i) / NR
		var reach := deep * (1.0 + 0.12 * sin(a * 5.0 + ph) + 0.06 * sin(a * 11.0 + ph * 2.0)) * (1.0 - 0.25 * pow(absf(a) / half, 3.0))
		var r := reach * f
		var x := sin(a) * r * (w / deep) * 0.6
		var z := cos(a) * r + 0.004
		var th := lerpf(0.035, 0.006, pow(f, 0.8)) * w / 0.15
		var droop := -0.18 * r * f + 0.003 * sin(a * 9.0 + ph) * f # (sagging toward its rim, rippled)
		var y := droop + (th * 0.5 if upper else -th * 0.5)
		var c: Color
		if upper:
			c = orange.lerp(sulphur, smoothstep(0.55, 1.0, f))
		else:
			c = under
		return [Vector3(x, y, z), c]
	for side: bool in [true, false]:
		var grid := []
		for i in NR + 1:
			var row := []
			for k in NA + 1:
				row.append(pt.call(i, k, side))
			grid.append(row)
		for i in NR:
			for k in NA:
				var a: Array = grid[i][k]
				var b: Array = grid[i][k + 1]
				var c: Array = grid[i + 1][k + 1]
				var d: Array = grid[i + 1][k]
				var nrm := ((b[0] as Vector3) - (a[0] as Vector3)).cross((d[0] as Vector3) - (a[0] as Vector3)).normalized()
				if (nrm.y < 0.0) == side:
					nrm = -nrm
				var nw := xf.basis * nrm
				PM._tri(st, xf * a[0], xf * b[0], xf * c[0], nw, nw, nw, a[1], b[1], c[1])
				PM._tri(st, xf * a[0], xf * c[0], xf * d[0], nw, nw, nw, a[1], c[1], d[1])
	# its rim, closed: the top's edge to the underside's
	for k in NA:
		var a: Array = pt.call(NR, k, true)
		var b: Array = pt.call(NR, k + 1, true)
		var c: Array = pt.call(NR, k + 1, false)
		var d: Array = pt.call(NR, k, false)
		var out := Vector3(sin(lerpf(-half, half, (float(k) + 0.5) / NA)), 0.0, cos(lerpf(-half, half, (float(k) + 0.5) / NA)))
		var nw := xf.basis * out
		PM._tri(st, xf * a[0], xf * b[0], xf * c[0], nw, nw, nw, sulphur, sulphur, under)
		PM._tri(st, xf * a[0], xf * c[0], xf * d[0], nw, nw, nw, sulphur, under, under)
