class_name LilyPad
## Water lilies, floating (a PropKind's mesh_script; not placed yet: no
## kind in data/population/props/ has it, for nothing places props on the
## water yet). Built whole (PlantMesh: painted by their vertices), y = 0 the
## water's face, three levels of detail and no card (flat on the water, a
## card stood up would show nothing). Each is picked whole as its item
## (Foraging: Population.pickable_at, as the fungi are, growing again some
## days after), and held (Items.model: held()).
##
## - 0 a pad: the white water lily's (Nymphaea odorata), round, a narrow
##   slit from its rim to its stalk; waxy green above, its veins fanning out
##   from the middle, its rim turned up a little; purple-red beneath.
## - 1 a raft: four pads of all sizes, overlapping, a young one's rim
##   curled up, its red underside showing.
## - 2 in flower: two pads and the flower, open on the water: white petals
##   in whorls, the outer ones spread flat, the inner ones cupped up round
##   the yellow stamens; four green sepals under them.
## - 3 in bud: two pads and a bud, a pointed green-bronze egg on the water,
##   the white just showing at its tip.
## - 4 spatterdock (Nuphar advena): bigger, longer pads, heart-shaped, a
##   wide notch between round lobes, yellow-green; its flower a yellow globe
##   of thick cupped sepals on a stout stalk above the water, its flat
##   stigma showing at the top.
## - 5 an old pad: big, yellowing and browning from its rim in, ragged
##   where it's torn, holed where beetles have eaten it, its rim curling.

const PM := preload("res://scripts/population/plant_mesh.gd")
const LOD := [10.0, 25.0] ## m: where the simpler level takes over, then the simplest (to VIEW)
const VIEW := 70.0
const FADE := 1.5 ## m either side of a switch (small things: a narrow band, as the fungi)
const VARIANTS := 6

## Each: its item and how many it gives picked, where it's picked (pick_at,
## pick_r: its own point, at scale 1).
const PICK := [
	{"item": "lily_pad", "count": 1, "at": Vector3(0.0, 0.0, 0.0), "r": 0.12},
	{"item": "lily_pad", "count": 4, "at": Vector3(0.0, 0.0, 0.0), "r": 0.22},
	{"item": "water_lily", "count": 1, "at": Vector3(0.05, 0.03, 0.04), "r": 0.09},
	{"item": "lily_pad", "count": 2, "at": Vector3(0.0, 0.0, 0.0), "r": 0.16},
	{"item": "spatterdock", "count": 1, "at": Vector3(0.03, 0.08, 0.02), "r": 0.1},
	{"item": "lily_pad", "count": 1, "at": Vector3(0.0, 0.0, 0.0), "r": 0.16},
]

static var _cache := {}


static func build(variant := 0) -> Mesh:
	return levels(variant)[0]


static func build_lods(variant := 0) -> Array[Mesh]:
	return levels(variant)[1]


## Population: its levels, how far it's drawn; what it's picked as.
static func variant_props(variant: int) -> Dictionary:
	var p: Dictionary = PICK[posmod(variant, VARIANTS)]
	return {"lod_distances": PackedFloat32Array(LOD), "view_distance": VIEW, "item": p.item,
			"pick_at": p.at, "pick_r": p.r, "pick_count": p.count}


## [the whole one, [the simpler, the simplest]]
static func levels(variant: int) -> Array:
	variant = posmod(variant, VARIANTS)
	if not _cache.has(variant):
		var raw := []
		for lod in 3:
			raw.append(_make(variant, lod))
		var spans := [[0.0, LOD[0]], [LOD[0], LOD[1]], [LOD[1], VIEW]]
		var meshes := []
		for li in 3:
			var mesh: ArrayMesh = PM._lodded(raw[li], spans[li][0], spans[li][1])
			# (their own copies of the levels' materials: measured from the
			# water, handed over in a narrow band; kept with the trees' for
			# the fade turned off and on, OakTree.set_lod_fade)
			for si in mesh.get_surface_count():
				var m := mesh.surface_get_material(si) as ShaderMaterial
				if m == null:
					continue
				var c := m.duplicate() as ShaderMaterial
				c.set_shader_parameter("lod_mid_height", 0.02)
				c.set_meta("lod_fade", FADE)
				var r = c.get_shader_parameter("lod_range")
				if r is Vector3:
					r.z = FADE if OakTree.lod_fade_on else 0.0
					c.set_shader_parameter("lod_range", r)
				mesh.surface_set_material(si, c)
				OakTree._leaf_mats[["lily", variant, li, si]] = c
			meshes.append(mesh)
		var lods: Array[Mesh] = [meshes[1], meshes[2]]
		_cache[variant] = [meshes[0], lods]
	return _cache[variant]


## One of it, held (Items.model): a pad by its stalk, stood on its edge; a
## flower on its stalk. Its grip at the origin.
static func held(id: String) -> Mesh:
	var key := ["held", id]
	if not _cache.has(key):
		var st := PM.begin()
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		match id:
			"water_lily":
				_stalk(st, [Vector3(0.0, -0.06, 0.0), Vector3(0.0, 0.02, 0.003), Vector3(0.0, 0.09, 0.0)], 0.004, Color(0.36, 0.3, 0.2), 0)
				_flower(st, rng, Transform3D(Basis(), Vector3(0.0, 0.09, 0.0)), 0.8, 0)
			"spatterdock":
				_stalk(st, [Vector3(0.0, -0.06, 0.0), Vector3(0.0, 0.02, 0.004), Vector3(0.0, 0.08, 0.0)], 0.006, Color(0.4, 0.42, 0.2), 0)
				_nuphar_flower(st, rng, Transform3D(Basis(), Vector3(0.0, 0.08, 0.0)), 1.0, 0)
			_: # (the pad hanging from its stalk, stood on its edge, its slit down)
				var b := Basis(Vector3(0.0, -1.0, 0.0), Vector3(0.0, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0))
				_stalk(st, [Vector3(0.0, -0.05, -0.004), Vector3(0.0, 0.03, -0.006), Vector3(0.0, 0.1, -0.002)], 0.003, Color(0.42, 0.26, 0.2), 0)
				_pad(st, rng, Transform3D(b, Vector3(0.0, 0.1, 0.0)), 0.09, {}, 0, false)
		_cache[key] = PM.finish([[st, PM.painted(0.4, 0.15)]])
	return _cache[key]


static func _make(v: int, lod: int) -> Mesh:
	var st := PM.begin()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["lily", v])
	match v:
		0:
			_pad(st, rng, _at(rng, Vector3.ZERO, 0.0), 0.11, {}, lod)
		1:
			var pads := [[Vector3(0.0, 0.0, 0.0), 0.13, {}], [Vector3(0.2, 0.0015, 0.07), 0.09, {}],
					[Vector3(-0.1, 0.003, 0.19), 0.1, {}], [Vector3(0.1, 0.0045, -0.17), 0.055, {"curl": 0.03, "young": true}]]
			for p: Array in pads:
				_pad(st, rng, _at(rng, p[0], 0.0), p[1], p[2], lod)
		2:
			_pad(st, rng, _at(rng, Vector3(-0.08, 0.0, -0.04), 0.0), 0.12, {}, lod)
			_pad(st, rng, _at(rng, Vector3(0.13, 0.0015, -0.1), 0.0), 0.085, {}, lod)
			_flower(st, rng, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(0.05, 0.004, 0.04)), 1.35, lod)
		3:
			_pad(st, rng, _at(rng, Vector3(0.0, 0.0, 0.0), 0.0), 0.1, {}, lod)
			_pad(st, rng, _at(rng, Vector3(-0.15, 0.0015, 0.1), 0.0), 0.075, {}, lod)
			_bud(st, Transform3D(Basis(Vector3.UP, 0.7) * Basis(Vector3.RIGHT, 1.25), Vector3(0.1, 0.016, 0.09)), 1.5, lod)
		4:
			_pad(st, rng, _at(rng, Vector3(-0.06, 0.0, 0.0), 0.0), 0.16, {"nuphar": true, "curl": 0.012}, lod)
			_pad(st, rng, _at(rng, Vector3(0.12, 0.0015, 0.14), 0.0), 0.12, {"nuphar": true, "curl": 0.02}, lod)
			_stalk(st, [Vector3(0.05, -0.02, 0.03), Vector3(0.04, 0.03, 0.025), Vector3(0.03, 0.065, 0.02)], 0.0055, Color(0.42, 0.44, 0.2), lod)
			_nuphar_flower(st, rng, Transform3D(Basis(Vector3.FORWARD, 0.1), Vector3(0.03, 0.065, 0.02)), 1.3, lod)
		5:
			_pad(st, rng, _at(rng, Vector3.ZERO, 0.0), 0.15, {"old": true, "curl": 0.02}, lod)
	return PM.finish([[st, PM.painted(0.4, 0.15)]])


## Laid on the water at p, turned any way.
static func _at(rng: RandomNumberGenerator, p: Vector3, _tilt: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p)


## A thin sheet from a grid of points (rows of [point, colour]), both its
## faces (the under one under_col's, thick m below), its normals from its
## neighbours; its edges closed (the last row, the first and last columns)
## when thick > 0.
static func _sheet(st: SurfaceTool, grid: Array, under_col: Callable, thick: float, up_hint := Vector3.UP) -> void:
	var nr := grid.size()
	var nk: int = (grid[0] as Array).size()
	var nrm := []
	for i in nr:
		var row := []
		for k in nk:
			var a: Vector3 = grid[mini(i + 1, nr - 1)][k][0] - grid[maxi(i - 1, 0)][k][0]
			var b: Vector3 = grid[i][mini(k + 1, nk - 1)][0] - grid[i][maxi(k - 1, 0)][0]
			var n := b.cross(a)
			if n.length() < 1e-10:
				n = up_hint
			n = n.normalized()
			if n.dot(up_hint) < 0.0:
				n = -n
			row.append(n)
		nrm.append(row)
	# (the centre of a pad: every point the same; its normal the ring's next out)
	for i in nr:
		for k in nk:
			if (nrm[i][k] as Vector3) == up_hint and i + 1 < nr:
				nrm[i][k] = nrm[i + 1][k]
	var low := func(i: int, k: int) -> Vector3:
		return (grid[i][k][0] as Vector3) - (nrm[i][k] as Vector3) * thick
	for i in nr - 1:
		for k in nk - 1:
			var ids := [[i, k], [i, k + 1], [i + 1, k + 1], [i + 1, k]]
			if grid[i][k].size() > 2 and grid[i][k][2] == false: # (a hole: this cell gone)
				continue
			for t: Array in [[0, 1, 2], [0, 2, 3]]:
				var p := []
				var n := []
				var c := []
				var pl := []
				var cl := []
				for j: int in t:
					var a: int = ids[j][0]
					var b: int = ids[j][1]
					p.append(grid[a][b][0])
					n.append(nrm[a][b])
					c.append(grid[a][b][1])
					pl.append(low.call(a, b))
					cl.append(under_col.call(grid[a][b][1]))
				PM._tri(st, p[0], p[1], p[2], n[0], n[1], n[2], c[0], c[1], c[2])
				PM._tri(st, pl[0], pl[1], pl[2], -n[0], -n[1], -n[2], cl[0], cl[1], cl[2])
	if thick <= 0.0:
		return
	var edges := []
	var last := []
	for k in nk:
		last.append([nr - 1, k])
	edges.append(last)
	var first_col := []
	var last_col := []
	for i in nr:
		first_col.append([i, 0])
		last_col.append([i, nk - 1])
	edges.append(first_col)
	edges.append(last_col)
	for e: Array in edges:
		for j in e.size() - 1:
			var a: Array = e[j]
			var b: Array = e[j + 1]
			var pa: Vector3 = grid[a[0]][a[1]][0]
			var pb: Vector3 = grid[b[0]][b[1]][0]
			var la: Vector3 = low.call(a[0], a[1])
			var lb: Vector3 = low.call(b[0], b[1])
			var out := (pb - pa).cross(nrm[a[0]][a[1]] as Vector3)
			if out.length() < 1e-10:
				continue
			# (pointing away from the sheet's middle)
			var mid: Vector3 = grid[nr / 2][nk / 2][0]
			if out.dot(pa - mid) < 0.0:
				out = -out
			out = out.normalized()
			var ca: Color = grid[a[0]][a[1]][1]
			var cb: Color = grid[b[0]][b[1]][1]
			var ua: Color = under_col.call(ca)
			var ub: Color = under_col.call(cb)
			PM._tri(st, pa, pb, lb, out, out, out, ca, cb, ub)
			PM._tri(st, pa, lb, la, out, out, out, ca, ub, ua)


## A pad, r across (m) from its stalk, its slit along +x. o: young (a
## brighter green, smaller veins), curl (m: its rim lifted, the more so on
## one side), nuphar (the spatterdock's: longer than wide, heart-shaped, a
## wide notch, yellow-green, no red beneath), old (yellowing, torn, holed).
static func _pad(st: SurfaceTool, rng: RandomNumberGenerator, xf: Transform3D, r: float, o: Dictionary, lod: int, stalk := true) -> void:
	var nuphar := bool(o.get("nuphar", false))
	var old := bool(o.get("old", false))
	var young := bool(o.get("young", false))
	var curl := float(o.get("curl", 0.0))
	var NK: int = [36, 18, 12][lod]
	var NR: int = [10, 4, 2][lod]
	var slit := 0.05 if not nuphar else 0.32 # (half the notch's angle at the rim)
	var ph := rng.randf() * TAU
	var curl_dir := rng.randf() * TAU
	var green := Color(0.07, 0.16, 0.03) * rng.randf_range(0.88, 1.12)
	if young:
		green = Color(0.13, 0.24, 0.05)
	if nuphar:
		green = Color(0.15, 0.24, 0.04) * rng.randf_range(0.92, 1.05)
	var vein := green.lightened(0.12)
	var rim := Color(0.3, 0.12, 0.1) if not nuphar else green.darkened(0.15)
	var under := Color(0.42, 0.14, 0.16) if not nuphar else Color(0.42, 0.42, 0.2)
	var yellow := Color(0.38, 0.32, 0.07)
	var brown := Color(0.26, 0.16, 0.06)
	# (an old one's tear: a bite out of its rim, ragged; its holes)
	var tear_a := rng.randf_range(1.0, TAU - 1.0)
	var holes := []
	if old:
		for h in 7:
			var ha := rng.randf_range(0.3, TAU - 0.3)
			var hf := rng.randf_range(0.35, 0.85)
			holes.append([Vector2(cos(ha), sin(ha)) * hf, rng.randf_range(0.04, 0.09)])
	var grid := []
	for i in NR + 1:
		var f := float(i) / NR
		var row := []
		for k in NK + 1:
			var a := lerpf(slit * f, TAU - slit * f, float(k) / NK) # (the slit a V, shut at the stalk)
			# its outline: round (the white lily's), with its lobes a little
			# pointed at the slit; the spatterdock's an egg, longer than wide,
			# its lobes rounded
			var rr := r * (1.0 + 0.025 * sin(a * 7.0 + ph) + 0.015 * sin(a * 13.0 + ph * 3.0))
			if nuphar:
				var ax := cos(a)
				rr *= 1.0 - 0.28 * absf(sin(a)) + 0.1 * (1.0 - ax) * 0.5 # (long along x; broadest away from the notch)
				rr *= 1.0 - 0.12 * pow(maxf(cos(a), 0.0), 6.0) # (its lobes' rounded ends)
			if old:
				var d := absf(angle_difference(a, tear_a))
				if d < 0.45:
					rr *= 1.0 - 0.45 * (1.0 - d / 0.45) * (0.75 + 0.25 * PM.noise(Vector3(a * 9.0, 0.0, 0.0)))
			var p2 := Vector2(cos(a), sin(a)) * rr * f
			var y := 0.0025
			y += curl * pow(f, 2.5) * (0.15 + 0.85 * pow(maxf(cos(a - curl_dir), 0.0), 2.0)) # (its rim lifted, on one side the most)
			if not nuphar:
				y += 0.003 * smoothstep(0.85, 1.0, f) # (a little lip)
			y += 0.0015 * sin(a * 5.0 + ph) * f * f # (rippled)
			var pt := Vector3(p2.x, y, p2.y)
			# its colour: the veins fanning out (the main ones forking),
			# darker between, its rim edged; an old one going yellow and
			# brown from its rim, spotted
			var vn := pow(absf(cos(a * (15.0 if not nuphar else 11.0) * 0.5)), 40.0) * smoothstep(0.08, 0.3, f) * (1.0 - smoothstep(0.85, 1.0, f))
			var c := green.lerp(vein, vn * (0.25 if young else 0.35))
			c = c.lerp(c.darkened(0.25), (1.0 - f) * 0.25) # (darker in the middle)
			c *= 0.94 + 0.06 * PM.noise(pt, 900.0)
			c = c.lerp(rim, smoothstep(0.94, 1.0, f) * (0.5 if lod == 0 else 0.15)) # (far off, its rim's edge a share of a wide cell)
			if old:
				var dry := smoothstep(0.35, 1.0, f + 0.15 * sin(a * 3.0 + ph))
				c = c.lerp(yellow, dry * 0.8)
				c = c.lerp(brown, smoothstep(0.8, 1.0, f) * (0.7 if lod == 0 else 0.35))
				var spot := 0.5 + 0.5 * sin(p2.x * 160.0) * sin(p2.y * 140.0 + ph)
				c = c.lerp(brown, smoothstep(0.85, 1.0, spot) * 0.6)
			var whole := true
			for h: Array in holes:
				var hd := (p2 / r).distance_to(h[0]) / float(h[1])
				if hd < 1.0:
					whole = false
				c = c.lerp(brown, (1.0 - smoothstep(1.0, 1.8, hd)) * 0.85) # (browned round where it's eaten)
			row.append([xf * pt, c, whole])
		grid.append(row)
	var under_of := func(c: Color) -> Color:
		return under.lerp(c, 0.25)
	_sheet(st, grid, under_of, 0.0022 if not nuphar else 0.003, xf.basis.y.normalized())
	# its stalk, down into the water from its middle (seen when the water's clear)
	if lod < 2 and stalk:
		_stalk(st, [xf * Vector3(0.0, 0.001, 0.0), xf * Vector3(0.01, -0.06, 0.0), xf * Vector3(0.0, -0.2, 0.02)], 0.003 if not nuphar else 0.0045, under.darkened(0.2), lod)


static func _stalk(st: SurfaceTool, pts: Array, radius: float, col: Color, lod: int) -> void:
	var radii := []
	for p in pts:
		radii.append(radius)
	PM.tube(st, pts, radii, [8, 5, 4][lod], func(_i: int, _a: float, _g: float) -> Color: return col)


## A petal (or a sepal) out from base: dir its way out along the water (x
## z), rising at tilt (radians up from the water) and curling up by curl
## more toward its tip; long, wide (m); cupped (m: its middle lower than
## its edges); its colour at its base, its tip, beneath.
static func _petal(st: SurfaceTool, base: Vector3, yaw: float, tilt: float, curl: float, long: float, wide: float, cup: float, c0: Color, c1: Color, under: Color, lod: int, xf: Transform3D, blunt := false) -> void:
	var NU: int = [7, 4, 2][lod]
	var NV: int = [4, 2, 2][lod]
	var out := Vector3(cos(yaw), 0.0, sin(yaw))
	var side := Vector3(-sin(yaw), 0.0, cos(yaw))
	var grid := []
	var at := base
	var last_dir := Vector3.ZERO
	var spine := [base]
	for i in NU:
		var u := (float(i) + 0.5) / NU
		var el := tilt + curl * u
		var d := out * cos(el) + Vector3.UP * sin(el)
		at += d * long / NU
		spine.append(at)
		last_dir = d
	for i in NU + 1:
		var u := float(i) / NU
		var w: float = wide * 0.5 * pow(sin(PI * clampf(u * 0.92 + 0.08, 0.0, 1.0)), 0.75) * (1.0 if blunt or u < 0.6 else lerpf(1.0, 0.75, (u - 0.6) / 0.4))
		if not blunt and i == NU:
			w = wide * 0.02
		var el := tilt + curl * u
		var d := out * cos(el) + Vector3.UP * sin(el)
		var nup := d.cross(side).normalized() * -1.0 # (the petal's face, up-ish)
		if nup.y < 0.0:
			nup = -nup
		var row := []
		for k in NV + 1:
			var v := float(k) / NV * 2.0 - 1.0
			var p: Vector3 = (spine[i] as Vector3) + side * v * w + nup * cup * (v * v - 0.3) * w / maxf(wide * 0.5, 1e-4)
			row.append([xf * p, c0.lerp(c1, u)])
		grid.append(row)
	_sheet(st, grid, func(c: Color) -> Color: return under.lerp(c, 0.4), 0.0008, xf.basis.y.normalized())


## The white water lily's flower, open on the water: four sepals, green
## beneath, under whorls of white petals (the outer spread, the inner
## cupped up); the yellow stamens in the middle, round its stigma. sc: its size.
static func _flower(st: SurfaceTool, rng: RandomNumberGenerator, xf: Transform3D, sc: float, lod: int) -> void:
	var white := Color(0.96, 0.95, 0.92)
	var blush := Color(0.95, 0.9, 0.86)
	var sepal := Color(0.3, 0.32, 0.14)
	var sepal_in := Color(0.86, 0.84, 0.76)
	for k in 4: # (the sepals, under all)
		var yaw := TAU * k / 4.0 + 0.4
		_petal(st, Vector3(0.0, 0.002, 0.0), yaw, 0.12, 0.12, 0.055 * sc, 0.022 * sc, 0.003 * sc, sepal_in, sepal_in, sepal, lod, xf)
	var whorls := [[8, 0.055, 0.018, 0.22, 0.2], [8, 0.05, 0.017, 0.55, 0.3], [8, 0.043, 0.015, 0.9, 0.35], [6, 0.032, 0.012, 1.2, 0.25]]
	if lod == 2:
		whorls = [[8, 0.055, 0.022, 0.25, 0.2], [6, 0.04, 0.02, 0.9, 0.3]]
	for w in whorls.size():
		var W: Array = whorls[w]
		var n: int = W[0]
		var off := rng.randf() * TAU
		for k in n:
			var yaw := off + TAU * (float(k) + 0.5 * (w % 2)) / n + rng.randf_range(-0.12, 0.12)
			var y := 0.004 + 0.002 * w
			_petal(st, Vector3(cos(yaw), 0.0, sin(yaw)) * 0.006 * sc + Vector3(0.0, y * sc, 0.0), yaw, float(W[3]) + rng.randf_range(-0.08, 0.08), float(W[4]),
					float(W[1]) * sc * rng.randf_range(0.92, 1.06), float(W[2]) * sc, 0.003 * sc, blush, white, white.darkened(0.08), lod, xf)
	# the stamens: a ring of little yellow blades, upright, round the stigma
	var yel := Color(0.95, 0.75, 0.12)
	var n_st: int = [36, 14, 0][lod]
	for k in n_st:
		var a := TAU * k / n_st + rng.randf_range(-0.05, 0.05)
		var ring := Vector3(cos(a), 0.0, sin(a))
		var base := ring * 0.007 * sc + Vector3(0.0, 0.008 * sc, 0.0)
		var d := (ring * 0.35 + Vector3.UP).normalized()
		PM.blade(st, xf * base, xf.basis * d, xf.basis * ring, 0.016 * sc * rng.randf_range(0.85, 1.1), 0.0028 * sc, 0.0008 * sc, yel.darkened(0.1), yel.lightened(0.15), false)
	PM.blob(st, xf * Vector3(0.0, 0.011 * sc, 0.0), xf.basis * Basis.from_scale(Vector3(0.008, 0.003, 0.008) * sc), Color(0.85, 0.72, 0.15), [10, 6, 5][lod], [4, 3, 2][lod])


## A bud: a pointed egg, its sepals' seams down it, green and bronze, the
## white just showing at its tip; laid along +y of xf (its foot at the origin).
static func _bud(st: SurfaceTool, xf: Transform3D, sc: float, lod: int) -> void:
	var L := 0.04 * sc
	var R := 0.011 * sc
	var prof := [[0.0, 0.0], [R * 0.45, L * 0.03], [R * 0.85, L * 0.15], [R, L * 0.35], [R * 0.95, L * 0.55], [R * 0.75, L * 0.75], [R * 0.4, L * 0.92], [0.0, L]]
	var green := Color(0.26, 0.3, 0.12)
	var bronze := Color(0.38, 0.22, 0.14)
	var col := func(i: int, a: float, p: Vector3) -> Color:
		var f := p.y / L
		var seam := pow(absf(cos(a * 2.0)), 30.0)
		var c := green.lerp(bronze, 0.35 + 0.35 * sin(a * 2.0 + 0.5))
		c = c.lerp(Color(0.92, 0.9, 0.84), seam * smoothstep(0.55, 0.95, f)) # (the white between the sepals, toward its tip)
		return c.lerp(Color(0.9, 0.88, 0.82), smoothstep(0.9, 1.0, f) * 0.6) if i >= 0 else c
	Fungus._revolve(st, Fungus._thin(prof, lod), [16, 8, 5][lod], col, xf)
	_stalk(st, [xf * Vector3(0.0, 0.0005, 0.0), xf * Vector3(0.0, -0.02, 0.004), xf * Vector3(0.0, -0.05, 0.02) + Vector3(0.0, -0.15, 0.0)], 0.0028 * sc, bronze.darkened(0.2), lod)


## The spatterdock's flower: a yellow globe of six thick sepals, cupped
## round one another, their seams darker, green at their feet, their rims
## curving in; the flat stigma (a yellow-green disc, rayed) in its mouth.
## Its foot at the origin.
static func _nuphar_flower(st: SurfaceTool, _rng: RandomNumberGenerator, xf: Transform3D, sc: float, lod: int) -> void:
	var yel := Color(0.93, 0.74, 0.08)
	var foot := Color(0.4, 0.46, 0.14)
	var seam := Color(0.7, 0.5, 0.08)
	var R := 0.02 * sc
	var H := 0.034 * sc
	var prof := [[0.0, 0.0], [R * 0.35, 0.0], [R * 0.75, H * 0.12], [R * 0.97, H * 0.35], [R, H * 0.55], [R * 0.9, H * 0.78], [R * 0.68, H * 0.95], [R * 0.5, H],
			[R * 0.42, H * 0.98], [R * 0.3, H * 0.94]]
	var MOUTH := 7
	var col := func(i: int, a: float, p: Vector3) -> Color:
		if i >= MOUTH:
			return Color(0.65, 0.45, 0.1) # (inside its mouth)
		var f := p.y / H
		var s6 := pow(absf(cos(a * 3.0)), 18.0) # (where two sepals meet)
		return foot.lerp(yel, smoothstep(0.05, 0.4, f)).lerp(seam, s6 * 0.6)
	# (each sepal bulging, its seams in a little)
	var push := func(i: int, a: float, _p: Vector3) -> float:
		return -0.0016 * sc * pow(absf(cos(a * 3.0)), 6.0) if i < MOUTH else 0.0
	Fungus._revolve(st, Fungus._thin(prof, lod), [30, 12, 6][lod], col, xf, push)
	# the stigma, a flat disc, rayed, in its mouth
	var disc := func(_i: int, a: float, _p: Vector3) -> Color:
		return Color(0.6, 0.62, 0.16).lerp(Color(0.42, 0.28, 0.08), pow(absf(cos(a * 6.0)), 12.0) * 0.7)
	Fungus._revolve(st, [[0.0, H * 0.9], [R * 0.4, H * 0.9], [R * 0.36, H * 0.97], [0.0, H * 0.99]], [12, 7, 5][lod], disc, xf)
