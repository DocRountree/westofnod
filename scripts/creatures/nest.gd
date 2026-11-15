class_name TreeNest
extends RefCounted
## The nests of the birds and the squirrels that nest in trees, life size,
## and where in a tree each is built.
##
## A nest: TreeNest.of(kind, scale, seed) (a Node3D, its origin where it rests on
## its branch; meta "top": the floor of its bowl above that, where the eggs
## lie; meta "inner": its bowl's radius). Each of one mesh, its sticks and
## fibres laid one by one:
## - "eagle": a great platform of sticks a metre and a half across, deep
##   (added to year on year), its bowl lined with grass, moss and green
##   sprigs.
## - "hawk" (Cooper's): a platform of sticks, its shallow bowl lined with
##   flakes of bark and a few green sprigs.
## - "owl" (great horned: another's old stick nest, taken over): weathered
##   grey sticks, flattened, a few feathers and bark shreds in it.
## - "falcon" (peregrine, in a tree: an old stick nest): weathered, flat,
##   nothing added.
## - "heron": a platform of long sticks, its bowl lined with fine twigs and
##   dry grass.
## - "pigeon": a flimsy platform, a few dozen twigs.
## - "robin": a cup of coarse grass and twigs, walled inside with mud,
##   lined with fine dry grass.
## - "jay": a bulky cup, twigs outside, dark rootlets within.
## - "cardinal": a loose cup: twigs, strips of grapevine bark, dead leaves,
##   lined with fine grass.
## - "finch" (house finch): a compact cup of fine stems and grass.
## - "goldfinch": a tight, neat cup of plant fibres, pale with thistle down.
## - "blackbird" (red-winged): a deep cup woven of sedge and cattail strips.
## - "hummingbird": a thimble of plant down bound with spider silk, its
##   outside shingled with flakes of lichen, saddled on a twig.
## - "bluebird", "screech_owl", "barn_owl": a hollow in the tree: a swollen
##   knot on the trunk, its mouth open, dark within; the bluebird's with a
##   cup of fine grass in it, the owls' bare but for wood chips and litter.
## - "drey" (a squirrel's): a ball of dead leaves on a frame of twigs, 40 cm
##   across, its way in at one side, hollow, lined with shredded bark.
## On the ground (the two that nest there): "goose" (a bowl of reeds and
## grass on the bank, lined with her grey down), "turkey" (a scrape among
## dead leaves).
##
## Where: TreeNest.site(lines, kind, seed, taken, radius): in a tree whose limbs are
## given (OakTree._climb_lines(variant): its trunk first, then each limb, as
## x, y, z, radius), the place this kind builds: a platform in a high crotch
## where a great limb leaves the trunk; a cup out along a limb, where it
## forks; a hollow in the trunk's side; a drey in an upper crotch. Not where
## another already is (taken). {pos, out (level, away from the trunk), ok}.
## TreeNest.kind_of(bird): which is its kind's.

const STYLE := {
	"eagle": "sticks", "hawk": "sticks", "owl": "sticks", "falcon": "sticks", "heron": "sticks", "pigeon": "sticks",
	"robin": "cup", "jay": "cup", "cardinal": "cup", "finch": "cup", "goldfinch": "cup", "blackbird": "cup", "hummingbird": "cup",
	"bluebird": "cavity", "screech_owl": "cavity", "barn_owl": "cavity", "drey": "drey", "goose": "ground", "turkey": "ground",
}
const BY_SCRIPT := {
	"bald_eagle.gd": "eagle", "golden_eagle.gd": "eagle", "eagle.gd": "eagle", "coopers_hawk.gd": "hawk", "great_horned_owl.gd": "owl",
	"peregrine_falcon.gd": "falcon", "great_blue_heron.gd": "heron", "pigeon.gd": "pigeon", "passenger_pigeon.gd": "pigeon",
	"american_robin.gd": "robin", "blue_jay.gd": "jay", "northern_cardinal.gd": "cardinal", "house_finch.gd": "finch", "finch.gd": "finch",
	"american_goldfinch.gd": "goldfinch", "red_winged_blackbird.gd": "blackbird", "ruby_throated_hummingbird.gd": "hummingbird",
	"eastern_bluebird.gd": "bluebird", "eastern_screech_owl.gd": "screech_owl", "barn_owl.gd": "barn_owl",
	"canada_goose.gd": "goose", "wild_turkey.gd": "turkey", "fox_squirrel.gd": "drey", "grey_squirrel.gd": "drey",
}

static var _mat: StandardMaterial3D


static func kind_of(bird: Object) -> String:
	var sc: Script = bird.get_script()
	while sc != null:
		var f := sc.resource_path.get_file()
		if BY_SCRIPT.has(f):
			return BY_SCRIPT[f]
		sc = sc.get_base_script()
	var style := String(bird.get("nest_style"))
	return "hawk" if style == "sticks" else ("barn_owl" if style == "scrape" else "robin")


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.vertex_color_is_srgb = true
		_mat.roughness = 0.95
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mat


## A nest of this kind. scale: the bird's nest_scale (its bowl sized to its
## brood as the bird lays it out: 1 a hawk's, 3 an eagle's, 0.35 a robin's).
static func of(kind: String, scale := 1.0, seed_ := 1) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 7919 + kind.hash()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Node3D.new()
	n.set_meta("prop", true)
	n.set_meta("nest", kind)
	var top := 0.0
	var inner := 0.1
	match STYLE.get(kind, "cup"):
		"sticks":
			var R := 0.27 * scale
			var res := _sticks(st, rng, kind, R)
			top = res[0]
			inner = res[1]
		"cup":
			var r := 0.215 * scale
			var res := _cup(st, rng, kind, r)
			top = res[0]
			inner = res[1]
		"cavity":
			var res := _cavity(st, rng, kind, scale)
			top = res[0]
			inner = res[1]
		"drey":
			var res := _drey(st, rng, 0.2 * scale)
			top = res[0]
			inner = res[1]
		"ground":
			var res := _ground(st, rng, kind, scale)
			top = res[0]
			inner = res[1]
	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material()
	n.add_child(mi)
	n.set_meta("top", top)
	n.set_meta("inner", inner)
	return n


# --- where in a tree --------------------------------------------------------------------

## The place in a tree (its limbs: lines, the trunk's first) this kind
## builds. taken: the places already built on (tree space).
static func site(lines: Array, kind: String, seed_ := 1, taken: Array = [], radius := 0.1) -> Dictionary:
	if lines.is_empty():
		return {"ok": false, "pos": Vector3.ZERO, "out": Vector3.RIGHT}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var trunk: PackedFloat32Array = lines[0]
	var tp := func(k: int) -> Vector3: return Vector3(trunk[k * 4], trunk[k * 4 + 1], trunk[k * 4 + 2])
	var tn := trunk.size() / 4
	var trunk_top: Vector3 = tp.call(tn - 1)
	var cands := [] # ([pos, out, score])
	var style: String = STYLE.get(kind, "cup")
	var limbs := []
	for i in range(1, lines.size()):
		var ln: PackedFloat32Array = lines[i]
		if ln.size() >= 8:
			limbs.append(ln)
	if style == "cavity": # (in the trunk's side, between a third and two thirds of the way up to its first limbs: facing away from the limb above)
		var first_limb_y := trunk_top.y
		for ln: PackedFloat32Array in limbs:
			first_limb_y = minf(first_limb_y, ln[1])
		var lo := maxf(first_limb_y * 0.55, 1.6)
		var hi := maxf(first_limb_y * 0.9, lo + 0.3)
		for k in 8:
			var y := lerpf(lo, hi, (float(k) + rng.randf()) / 8.0)
			var a := rng.randf() * TAU
			var c := _on_line(trunk, y)
			var out := Vector3(cos(a), 0.0, sin(a))
			cands.append([Vector3(c.x, y, c.z) + out * (c.w * 0.9 + radius * 0.45), out, rng.randf()]) # (its floor's middle: the knot half in the trunk)
	elif style == "sticks" or style == "drey": # (a crotch: where a limb leaves the trunk; the great nests in the highest that'll bear them)
		for ln: PackedFloat32Array in limbs:
			var base := Vector3(ln[0], ln[1], ln[2])
			var nxt := Vector3(ln[4], ln[5], ln[6])
			var out := Vector3(nxt.x - base.x, 0.0, nxt.z - base.z)
			if out.length() < 0.01:
				continue
			out = out.normalized()
			var tr := _on_line(trunk, base.y)
			var want_h := 0.75 if kind in ["eagle", "heron", "hawk", "owl", "falcon"] else 0.5
			var score := -absf(base.y / maxf(trunk_top.y, 0.1) - want_h) + ln[3] * (2.0 if kind == "eagle" else 0.5) + rng.randf() * 0.1
			# (out along the limb till the nest clears the trunk: resting on the limb, the trunk at its back)
			var need := tr.w + radius * 1.05
			var at := Vector3(ln[0], ln[1], ln[2])
			var lr := ln[3]
			for k in range(1, ln.size() / 4):
				var p0 := Vector3(ln[(k - 1) * 4], ln[(k - 1) * 4 + 1], ln[(k - 1) * 4 + 2])
				var p1 := Vector3(ln[k * 4], ln[k * 4 + 1], ln[k * 4 + 2])
				var d0 := Vector2(p0.x - tr.x, p0.z - tr.z).length()
				var d1 := Vector2(p1.x - tr.x, p1.z - tr.z).length()
				at = p1
				lr = ln[k * 4 + 3]
				if d1 >= need:
					var f := clampf((need - d0) / maxf(d1 - d0, 1e-4), 0.0, 1.0)
					at = p0.lerp(p1, f)
					lr = lerpf(ln[(k - 1) * 4 + 3], ln[k * 4 + 3], f)
					break
			cands.append([at + Vector3(0.0, lr * 0.7, 0.0), out, score])
		if cands.is_empty(): # (no limbs: the trunk's top)
			cands.append([trunk_top, Vector3.RIGHT, 0.0])
	else: # (a cup: out along a limb, well out from the trunk; the low nesters on the lowest limbs)
		for ln: PackedFloat32Array in limbs:
			var m := ln.size() / 4
			for f: float in [0.7, 0.85, 1.0]: # (toward its end, where it's thin and forks)
				var k := clampi(int(round(f * float(m - 1))), 1, m - 1)
				var p := Vector3(ln[k * 4], ln[k * 4 + 1], ln[k * 4 + 2])
				var prev := Vector3(ln[(k - 1) * 4], ln[(k - 1) * 4 + 1], ln[(k - 1) * 4 + 2])
				var out := Vector3(p.x - prev.x, 0.0, p.z - prev.z)
				out = out.normalized() if out.length() > 0.01 else Vector3.RIGHT
				var low := kind in ["cardinal", "blackbird", "goldfinch", "robin"]
				var score := (-p.y * 0.15 if low else -absf(p.y / maxf(trunk_top.y, 0.1) - 0.7)) + f * 0.6 + Vector2(p.x - trunk[0], p.z - trunk[2]).length() * 0.2 + rng.randf() * 0.15
				cands.append([p + Vector3(0.0, ln[k * 4 + 3] * 0.85, 0.0), out, score])
		if cands.is_empty():
			cands.append([trunk_top, Vector3.RIGHT, 0.0])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) > float(b[2]))
	var room := 0.9 if kind == "eagle" else 0.45
	for c: Array in cands:
		var free := true
		for t: Vector3 in taken:
			if t.distance_to(c[0]) < room:
				free = false
		if free:
			return {"ok": true, "pos": c[0], "out": c[1]}
	return {"ok": true, "pos": cands[0][0], "out": cands[0][1]}


## (A limb's line at height y: its middle there, and its radius (w).)
static func _on_line(ln: PackedFloat32Array, y: float) -> Vector4:
	var m := ln.size() / 4
	for k in m - 1:
		var y0 := ln[k * 4 + 1]
		var y1 := ln[k * 4 + 5]
		if y <= y1 or k == m - 2:
			var t := clampf((y - y0) / maxf(y1 - y0, 1e-4), 0.0, 1.0)
			return Vector4(lerpf(ln[k * 4], ln[k * 4 + 4], t), y, lerpf(ln[k * 4 + 2], ln[k * 4 + 6], t), lerpf(ln[k * 4 + 3], ln[k * 4 + 7], t))
	return Vector4(ln[0], y, ln[2], ln[3])


# --- the makes ----------------------------------------------------------------------------

## A stick, a stem, a fibre: a tube along pts, r0 to r1, coloured.
static func _strand(st: SurfaceTool, pts: Array, r0: float, r1: float, col: Color, sides := 4) -> void:
	var m := pts.size()
	var prev_a := Vector3.ZERO
	var rings := []
	for j in m:
		var tng: Vector3 = ((pts[mini(j + 1, m - 1)] as Vector3) - (pts[maxi(j - 1, 0)] as Vector3)).normalized()
		var a := tng.cross(Vector3.UP if absf(tng.y) < 0.9 else Vector3.RIGHT).normalized()
		if j > 0 and a.dot(prev_a) < 0.0:
			a = -a
		prev_a = a
		var b := tng.cross(a)
		var r := lerpf(r0, r1, float(j) / maxf(m - 1, 1))
		var ring := []
		for s in sides:
			var an := TAU * float(s) / sides
			ring.append((pts[j] as Vector3) + (a * cos(an) + b * sin(an)) * r)
		rings.append(ring)
	for j in m - 1:
		for s in sides:
			var s1 := (s + 1) % sides
			var shade := 0.8 + 0.3 * float(s) / sides
			var c := Color(col.r * shade, col.g * shade, col.b * shade)
			for v: Vector3 in [rings[j][s], rings[j + 1][s], rings[j + 1][s1], rings[j][s], rings[j + 1][s1], rings[j][s1]]:
				st.set_color(c)
				st.add_vertex(v)


static func _tint(rng: RandomNumberGenerator, a: Color, b: Color, vary := 0.12) -> Color:
	var c := a.lerp(b, rng.randf())
	var k := 1.0 + rng.randf_range(-vary, vary)
	return Color(c.r * k, c.g * k, c.b * k)


## A flat scrap (a leaf, a flake of bark or lichen, a feather): a bent
## quad, at p, lying along dir, its face to nrm.
static func _scrap(st: SurfaceTool, p: Vector3, dir: Vector3, nrm: Vector3, ln: float, w: float, col: Color, pointed := true) -> void:
	var across := dir.cross(nrm).normalized()
	var mid := p + dir * ln * 0.5 + nrm * ln * 0.08
	var tip := p + dir * ln
	var a := mid - across * w * 0.5
	var b := mid + across * w * 0.5
	var dark := Color(col.r * 0.8, col.g * 0.8, col.b * 0.8)
	var tris := [[p, a, b, col], [a, tip, b, dark]] if pointed else [[p - across * w * 0.4, a, b, col], [p - across * w * 0.4, b, p + across * w * 0.4, col], [a, tip - across * w * 0.4, tip + across * w * 0.4, dark], [a, tip + across * w * 0.4, b, dark]]
	for t: Array in tris:
		for k in 3:
			st.set_color(t[3])
			st.add_vertex(t[k])


## A bowl's floor: a shallow dish (so nothing shows through the weave),
## radius r, its middle at y, rising h to its edge.
static func _dish(st: SurfaceTool, rng: RandomNumberGenerator, r: float, y: float, h: float, ca: Color, cb: Color) -> void:
	var NA := 14
	var NR := 4
	var pt := func(i: int, j: int) -> Vector3:
		var f := float(i) / NR
		var a := TAU * float(j % NA) / NA
		return Vector3(cos(a) * r * f, y + h * f * f, sin(a) * r * f)
	var cols := []
	for i in NR + 1:
		var row := []
		for j in NA:
			row.append(_tint(rng, ca, cb, 0.08))
		cols.append(row)
	for i in NR:
		for j in NA:
			var q := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
			for k: int in [0, 2, 1, 0, 3, 2]:
				st.set_color(cols[q[k][0]][q[k][1] % NA])
				st.add_vertex(pt.call(q[k][0], q[k][1]))


## A platform of sticks. Returns [its bowl's floor (y), its bowl's radius].
static func _sticks(st: SurfaceTool, rng: RandomNumberGenerator, kind: String, R: float) -> Array:
	var P: Dictionary = {
		"eagle": {"n": 520, "deep": 0.55, "rim": 0.2, "thick": 1.0, "grey": 0.2, "len": 0.9},
		"hawk": {"n": 300, "deep": 0.3, "rim": 0.22, "thick": 0.8, "grey": 0.15, "len": 1.0},
		"owl": {"n": 240, "deep": 0.22, "rim": 0.1, "thick": 0.8, "grey": 0.7, "len": 1.0},
		"falcon": {"n": 220, "deep": 0.2, "rim": 0.06, "thick": 0.8, "grey": 0.85, "len": 1.0},
		"heron": {"n": 280, "deep": 0.22, "rim": 0.14, "thick": 0.7, "grey": 0.35, "len": 1.25},
		"pigeon": {"n": 110, "deep": 0.05, "rim": 0.04, "thick": 0.55, "grey": 0.3, "len": 1.1},
	}[kind]
	var bark_a := Color(0.3, 0.23, 0.16).lerp(Color(0.5, 0.48, 0.45), P.grey)
	var bark_b := Color(0.45, 0.36, 0.26).lerp(Color(0.62, 0.6, 0.56), P.grey)
	var bowl := R * (0.5 if kind != "pigeon" else 0.6)
	var floor_y := R * float(P.rim) * 0.35 + 0.004
	for k in int(P.n):
		# (laid round and round: each across the pile, most along its rim; the pile deep under its middle)
		var u := rng.randf()
		var rr := R * lerpf(0.3, 1.0, sqrt(u))
		var a := rng.randf() * TAU
		var above := rng.randf() < 0.55
		var y := 0.0
		if above:
			y = R * float(P.rim) * smoothstep(0.35, 1.0, rr / R) * rng.randf_range(0.5, 1.15) + floor_y * (1.0 - rr / R) * 0.5
		else:
			y = -R * float(P.deep) * rng.randf() * (1.0 - 0.75 * rr / R)
			rr *= lerpf(1.0, 0.55, -y / maxf(R * float(P.deep), 1e-4)) # (narrowing below: wedged in its crotch)
		var c := Vector3(cos(a) * rr, y, sin(a) * rr)
		var tang := Vector3(-sin(a), 0.0, cos(a)).rotated(Vector3.UP, rng.randf_range(-0.55, 0.55))
		tang.y = rng.randf_range(-0.18, 0.18)
		tang = tang.normalized()
		var ln := R * float(P.len) * rng.randf_range(0.45, 1.0) * (0.75 if rr < R * 0.5 else 1.0)
		var bend := Vector3(cos(a), rng.randf_range(-0.3, 0.3), sin(a)) * ln * rng.randf_range(-0.08, 0.05)
		var th := 0.02 * R * float(P.thick) * rng.randf_range(0.5, 1.3) + 0.0015
		var pts := [c - tang * ln * 0.5, c - tang * ln * 0.17 + bend, c + tang * ln * 0.17 + bend * 1.1, c + tang * ln * 0.5]
		_strand(st, pts, th, th * rng.randf_range(0.4, 0.8), _tint(rng, bark_a, bark_b), 5)
		if rng.randf() < 0.25: # (a side twig off it)
			var off := tang.rotated(Vector3.UP, rng.randf_range(0.5, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0))
			_strand(st, [c + tang * ln * 0.1, c + tang * ln * 0.1 + off * ln * 0.3], th * 0.5, th * 0.2, _tint(rng, bark_a, bark_b), 4)
	# its bowl: a floor, and what it's lined with
	var line_a := Color(0.6, 0.52, 0.34)
	var line_b := Color(0.74, 0.66, 0.45)
	if kind in ["owl", "falcon", "pigeon"]:
		line_a = bark_a * 1.05
		line_b = bark_b
	_dish(st, rng, bowl * (1.15 if kind != "pigeon" else 0.7), floor_y - 0.004, R * float(P.rim) * 0.5, line_a * 0.8, line_b * 0.8)
	var n_line := {"eagle": 420, "hawk": 200, "heron": 260, "owl": 60, "falcon": 30, "pigeon": 20}[kind] as int
	for k in n_line:
		var a := rng.randf() * TAU
		var rr := bowl * sqrt(rng.randf()) * 1.05
		var c := Vector3(cos(a) * rr, floor_y + R * float(P.rim) * 0.5 * pow(rr / (bowl * 1.15), 2.0) + 0.003, sin(a) * rr)
		var d := Vector3(-sin(a), 0.0, cos(a)).rotated(Vector3.UP, rng.randf_range(-0.8, 0.8))
		var ln := bowl * rng.randf_range(0.3, 0.7)
		if kind == "hawk" and rng.randf() < 0.5: # (flakes of bark)
			_scrap(st, c, d, Vector3.UP, ln * 0.35, ln * 0.2, _tint(rng, Color(0.42, 0.32, 0.22), Color(0.55, 0.45, 0.33)), false)
		else:
			_strand(st, [c - d * ln * 0.5, c + Vector3(0.0, 0.004, 0.0), c + d * ln * 0.5], 0.0016 + 0.002 * R, 0.001, _tint(rng, line_a, line_b), 3)
	if kind in ["eagle", "hawk"]: # (green sprigs, brought fresh)
		for k in (9 if kind == "eagle" else 5):
			var a := rng.randf() * TAU
			var rr := bowl * rng.randf_range(0.5, 1.2)
			var c := Vector3(cos(a) * rr, floor_y + R * float(P.rim) * 0.4, sin(a) * rr)
			var d := Vector3(cos(a + 1.3), 0.1, sin(a + 1.3)).normalized()
			_strand(st, [c, c + d * R * 0.22], 0.003, 0.0015, Color(0.3, 0.25, 0.15), 4)
			for j in 6:
				var at := c + d * R * 0.22 * (0.25 + 0.13 * j)
				var side := d.cross(Vector3.UP).normalized() * (1.0 if j % 2 == 0 else -1.0)
				_scrap(st, at, (side + d * 0.5).normalized(), Vector3.UP, R * 0.09, R * 0.035, _tint(rng, Color(0.2, 0.36, 0.14), Color(0.3, 0.46, 0.18)))
	if kind == "owl": # (a few of her own feathers, shed into it)
		for k in 7:
			var a := rng.randf() * TAU
			var rr := bowl * rng.randf_range(0.2, 1.0)
			var c := Vector3(cos(a) * rr, floor_y + 0.01 + R * float(P.rim) * 0.5 * pow(rr / bowl, 2.0), sin(a) * rr)
			_scrap(st, c, Vector3(cos(a * 3.0), 0.05, sin(a * 3.0)).normalized(), Vector3.UP, R * 0.16, R * 0.05, _tint(rng, Color(0.62, 0.52, 0.4), Color(0.8, 0.74, 0.64)))
	return [floor_y, bowl]


## A woven cup. Returns [its floor, its inside radius].
static func _cup(st: SurfaceTool, rng: RandomNumberGenerator, kind: String, r: float) -> Array:
	var P: Dictionary = {
		"robin": {"h": 0.85, "wall": 0.32, "out_a": Color(0.5, 0.42, 0.27), "out_b": Color(0.68, 0.6, 0.4), "in_a": Color(0.62, 0.54, 0.36), "in_b": Color(0.76, 0.68, 0.46), "n": 190, "coarse": 1.2, "loose": 0.5, "twig": 0.25},
		"jay": {"h": 0.75, "wall": 0.36, "out_a": Color(0.3, 0.23, 0.16), "out_b": Color(0.46, 0.38, 0.28), "in_a": Color(0.2, 0.15, 0.11), "in_b": Color(0.34, 0.26, 0.18), "n": 200, "coarse": 1.9, "loose": 0.9, "twig": 0.9},
		"cardinal": {"h": 0.7, "wall": 0.3, "out_a": Color(0.36, 0.28, 0.2), "out_b": Color(0.55, 0.45, 0.32), "in_a": Color(0.6, 0.52, 0.34), "in_b": Color(0.74, 0.66, 0.44), "n": 150, "coarse": 1.5, "loose": 1.2, "twig": 0.7},
		"finch": {"h": 0.8, "wall": 0.3, "out_a": Color(0.52, 0.45, 0.3), "out_b": Color(0.7, 0.62, 0.42), "in_a": Color(0.66, 0.6, 0.45), "in_b": Color(0.8, 0.75, 0.6), "n": 200, "coarse": 0.9, "loose": 0.5, "twig": 0.15},
		"goldfinch": {"h": 0.95, "wall": 0.3, "out_a": Color(0.6, 0.55, 0.42), "out_b": Color(0.78, 0.74, 0.62), "in_a": Color(0.86, 0.84, 0.78), "in_b": Color(0.95, 0.94, 0.9), "n": 240, "coarse": 0.7, "loose": 0.2, "twig": 0.0},
		"blackbird": {"h": 1.05, "wall": 0.28, "out_a": Color(0.56, 0.5, 0.3), "out_b": Color(0.72, 0.66, 0.42), "in_a": Color(0.64, 0.58, 0.38), "in_b": Color(0.78, 0.72, 0.5), "n": 210, "coarse": 1.3, "loose": 0.35, "twig": 0.0},
		"hummingbird": {"h": 1.1, "wall": 0.3, "out_a": Color(0.62, 0.6, 0.5), "out_b": Color(0.8, 0.78, 0.68), "in_a": Color(0.88, 0.86, 0.8), "in_b": Color(0.96, 0.95, 0.9), "n": 90, "coarse": 0.8, "loose": 0.05, "twig": 0.0},
	}.get(kind, {})
	var h := r * float(P.h)
	var ri := r * (1.0 - float(P.wall))
	var floor_y := h * 0.3
	# its body: the wall, lathed (out, over the rim, in), lumpy; so the weave has no holes
	var prof := [] # ([radius, y, inside])
	for i in 7:
		var t := float(i) / 6.0
		prof.append([r * sin(t * PI * 0.5) * (0.96 + 0.04 * t), h * (1.0 - cos(t * PI * 0.5)) * 0.92 + h * 0.08 * t, false])
	prof.append([(r + ri) * 0.5, h * 1.02, false])
	for i in 6:
		var t := float(i) / 5.0
		prof.append([ri * cos(t * PI * 0.5), lerpf(h * 0.98, floor_y, sin(t * PI * 0.5)), true])
	var NA := 22
	var grid := []
	var gcol := []
	for i in prof.size():
		var row := []
		var crow := []
		for j in NA:
			var a := TAU * float(j) / NA
			var rr: float = float(prof[i][0]) * (1.0 + rng.randf_range(-0.05, 0.05) * (0.3 if prof[i][2] else 1.0))
			row.append(Vector3(cos(a) * rr, float(prof[i][1]) + rng.randf_range(-0.01, 0.01) * r, sin(a) * rr))
			var c := _tint(rng, P.in_a, P.in_b, 0.08) if prof[i][2] else _tint(rng, P.out_a, P.out_b, 0.1) * 0.85
			if kind == "robin" and prof[i][2] and i < prof.size() - 2: # (its wall of mud, showing above the lining)
				c = _tint(rng, Color(0.27, 0.21, 0.15), Color(0.36, 0.29, 0.21), 0.06)
			crow.append(c)
		grid.append(row)
		gcol.append(crow)
	for i in prof.size() - 1:
		for j in NA:
			var j1 := (j + 1) % NA
			for e: Array in [[i, j], [i + 1, j1], [i + 1, j], [i, j], [i, j1], [i + 1, j1]]:
				st.set_color(gcol[e[0]][e[1]])
				st.add_vertex(grid[e[0]][e[1]])
	# the weave: stems laid round it, over and under, their ends sticking out
	var th := 0.011 * r * float(P.coarse) + 0.0004
	for k in int(P.n):
		var yy := rng.randf()
		var twig := rng.randf() < float(P.twig) * (1.0 - yy * 0.5)
		var y := h * yy * 1.02
		var t := clampf(y / h, 0.0, 1.0)
		var rad := r * sin(acos(clampf(1.0 - t, 0.0, 1.0))) * 0.98 + th
		if rad < r * 0.25:
			rad = r * 0.25
		var a0 := rng.randf() * TAU
		var span := rng.randf_range(0.7, 2.4) if not twig else rng.randf_range(0.5, 1.0)
		var tilt := rng.randf_range(-0.35, 0.35)
		var pts := []
		var NSg := 6 if not twig else 3
		for s in NSg + 1:
			var f := float(s) / NSg
			var a := a0 + span * f
			var out := 1.0 + float(P.loose) * 0.12 * (absf(f - 0.5) * 2.0) * rng.randf() + (0.04 if s % 2 == 0 else 0.0)
			if twig:
				out = 1.0 + 0.25 * pow(absf(f - 0.5) * 2.0, 2.0) # (a straight twig: a chord, its ends standing off)
			pts.append(Vector3(cos(a) * rad * out, y + (f - 0.5) * tilt * r, sin(a) * rad * out))
		var col := _tint(rng, P.out_a, P.out_b)
		if twig:
			col = _tint(rng, Color(0.28, 0.21, 0.15), Color(0.44, 0.36, 0.27))
		_strand(st, pts, th * (1.6 if twig else 1.0), th * (0.9 if twig else 0.5), col, 4 if twig else 3)
	for k in int(float(P.n) * 0.35): # (the rim, bound round; the lining, finer, coiled in the bowl)
		var rim := k % 2 == 0
		var a0 := rng.randf() * TAU
		var span := rng.randf_range(1.0, 2.6)
		var yy := h * (1.0 + rng.randf_range(-0.02, 0.03)) if rim else lerpf(floor_y, h * 0.9, rng.randf() * rng.randf())
		var rad := (r + ri) * 0.5 + rng.randf_range(-0.5, 0.5) * (r - ri) * 0.6 if rim else ri * cos(asin(clampf((h * 0.98 - yy) / (h * 0.98 - floor_y), 0.0, 1.0))) * 0.97 + ri * 0.03
		var pts := []
		for s in 7:
			var a := a0 + span * float(s) / 6.0
			pts.append(Vector3(cos(a) * rad, yy + rng.randf_range(-0.01, 0.01) * r, sin(a) * rad))
		_strand(st, pts, th * 0.7, th * 0.4, _tint(rng, P.in_a, P.in_b) if not rim else _tint(rng, P.out_a, P.out_b), 3)
	if kind == "cardinal": # (dead leaves and strips of bark worked into its outside)
		for k in 14:
			var a := rng.randf() * TAU
			var y := h * rng.randf_range(0.1, 0.7)
			var rad := r * sin(acos(1.0 - y / h)) + 0.004
			var p := Vector3(cos(a) * rad, y, sin(a) * rad)
			_scrap(st, p, Vector3(-sin(a), rng.randf_range(-0.4, 0.2), cos(a)).normalized(), Vector3(cos(a), 0.2, sin(a)).normalized(), r * rng.randf_range(0.5, 0.9), r * 0.3, _tint(rng, Color(0.4, 0.28, 0.16), Color(0.56, 0.42, 0.24)))
	if kind == "hummingbird": # (shingled with lichen, grey green)
		for k in 260:
			var a := rng.randf() * TAU
			var y := h * rng.randf_range(0.0, 0.98)
			var rad := maxf(r * sin(acos(clampf(1.0 - y / h, 0.0, 1.0))), r * 0.3) + 0.0008
			var p := Vector3(cos(a) * rad, y, sin(a) * rad)
			_scrap(st, p, Vector3(-sin(a), rng.randf_range(-0.5, 0.5), cos(a)).normalized(), Vector3(cos(a), 0.0, sin(a)), r * rng.randf_range(0.1, 0.2), r * 0.14, _tint(rng, Color(0.5, 0.58, 0.48), Color(0.7, 0.76, 0.66)), false)
	if kind in ["goldfinch", "finch"]: # (tufts of down at its rim)
		for k in (16 if kind == "goldfinch" else 6):
			var a := rng.randf() * TAU
			var p := Vector3(cos(a) * (r + ri) * 0.5, h, sin(a) * (r + ri) * 0.5)
			for j in 3:
				var d := Vector3(cos(a) + rng.randf_range(-0.6, 0.6), rng.randf_range(0.2, 0.9), sin(a) + rng.randf_range(-0.6, 0.6)).normalized()
				_strand(st, [p, p + d * r * 0.22], th * 0.5, th * 0.15, Color(0.94, 0.93, 0.88), 3)
	return [floor_y + 0.002, ri * 0.8]


static func cavity_radius(kind: String, scale := 1.0) -> float:
	var ri: float = {"bluebird": 0.08, "screech_owl": 0.12, "barn_owl": 0.2}.get(kind, 0.1) * maxf(scale, 0.6) / ({"bluebird": 0.35, "screech_owl": 1.0, "barn_owl": 1.0}.get(kind, 1.0) as float)
	return clampf(ri, 0.07, 0.26)


## A nest's reach: what it needs clear of the trunk (its radius).
static func radius_of(kind: String, scale := 1.0) -> float:
	match STYLE.get(kind, "cup"):
		"sticks": return 0.27 * scale
		"cavity": return cavity_radius(kind, scale)
		"drey": return 0.2 * scale
	return 0.215 * scale


## A hollow in the tree: a swollen knot on the trunk's side (the trunk
## behind it at -x), its mouth open to +x and up, dark inside. Its origin
## on its floor's middle.
static func _cavity(st: SurfaceTool, rng: RandomNumberGenerator, kind: String, scale: float) -> Array:
	var ri := cavity_radius(kind, scale)
	var ro := ri * 1.22 + 0.01
	var tall := 1.6
	var axis := Vector3(0.75, 0.66, 0.0).normalized() # (its mouth's way)
	var mouth := 0.7 # (the cosine of its half angle: open wide, what's in it seen)
	var bark_a := Color(0.16, 0.13, 0.1)
	var bark_b := Color(0.3, 0.25, 0.2)
	var NA := 28
	var NP := 18
	var c := Vector3(0.0, ri * tall * 0.78, 0.0)
	var sn := sqrt(1.0 - mouth * mouth)
	# (a way out from its middle, to the shell there: the knot's lumps outside, smooth within; a way into the mouth brought to its edge)
	var shell := func(d: Vector3, inside: bool) -> Vector3:
		if d.dot(axis) > mouth:
			var perp := d - axis * d.dot(axis)
			perp = perp.normalized() if perp.length() > 1e-4 else axis.cross(Vector3.FORWARD).normalized()
			d = axis * mouth + perp * sn
		var th := atan2(d.z, d.x)
		var ph := acos(clampf(d.y, -1.0, 1.0))
		var rr := ri if inside else ro
		var lump := 1.0 + (0.07 * sin(th * 5.0 + ph * 3.0) + 0.05 * sin(ph * 9.0 + th * 2.0)) * (0.0 if inside else 1.0)
		var taper := 1.0 - 0.3 * absf(d.y) * (0.0 if inside else 1.0) # (run out into the trunk above and below)
		return c + Vector3(d.x * rr * lump * taper, d.y * rr * tall * lump * (1.25 if not inside else 1.0), d.z * rr * lump * taper * 0.92)
	for inside in [false, true]:
		var grid := []
		var cols := []
		for i in NP + 1:
			var row := []
			var crow := []
			var ph := PI * float(i) / NP
			for j in NA + 1:
				var th := TAU * float(j % NA) / NA
				var d := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
				row.append([shell.call(d, inside), d.dot(axis)])
				var ridged := 0.75 + 0.35 * absf(sin(th * 9.0 + sin(ph * 4.0) * 1.5)) # (the bark's ridges, running up it)
				var col := _tint(rng, bark_a, bark_b, 0.06) * ridged
				if inside:
					col = Color(0.1, 0.075, 0.055).lerp(Color(0.22, 0.17, 0.12), clampf(d.dot(axis) * 0.5 + 0.5, 0.0, 1.0))
				crow.append(col)
			grid.append(row)
			cols.append(crow)
		for i in NP:
			for j in NA:
				var q := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
				var open := 0
				for e: Array in q:
					if float(grid[e[0]][e[1]][1]) > mouth:
						open += 1
				if open == 4:
					continue
				for k: int in [0, 1, 2, 0, 2, 3]:
					st.set_color(cols[q[k][0]][q[k][1]])
					st.add_vertex(grid[q[k][0]][q[k][1]][0])
	# its lip: the bark grown in round the mouth, a rolled rim (the callus of an old wound), outside to inside
	var u := axis.cross(Vector3.FORWARD).normalized()
	var w := axis.cross(u)
	var lip := []
	for j in 37:
		var a := TAU * float(j % 36) / 36.0
		var d := axis * mouth + (u * cos(a) + w * sin(a)) * sn
		var po: Vector3 = shell.call(d, false)
		var pi_: Vector3 = shell.call(d, true)
		lip.append([po, pi_, (po + pi_) * 0.5 + axis * (0.012 + ri * 0.08)])
	for j in 36:
		var lc := _tint(rng, Color(0.3, 0.24, 0.18), Color(0.42, 0.35, 0.27), 0.05)
		for t: Array in [[lip[j][0], lip[j + 1][0], lip[j + 1][2]], [lip[j][0], lip[j + 1][2], lip[j][2]], [lip[j][2], lip[j + 1][2], lip[j + 1][1]], [lip[j][2], lip[j + 1][1], lip[j][1]]]:
			for v: Vector3 in t:
				st.set_color(lc)
				st.add_vertex(v)
	# its floor: wood chips and litter; the bluebird's cup of fine grass
	var floor_y := c.y - ri * tall * 0.72
	var fr := ri * 0.7
	_dish(st, rng, fr * 1.15, floor_y, ri * 0.18, Color(0.3, 0.23, 0.16), Color(0.45, 0.36, 0.25))
	if kind == "bluebird":
		for k in 120:
			var a0 := rng.randf() * TAU
			var rad := fr * rng.randf_range(0.45, 1.05)
			var y := floor_y + ri * 0.2 * pow(rad / fr, 2.0) + 0.003
			var pts := []
			var span := rng.randf_range(0.9, 2.2)
			for s in 6:
				var a := a0 + span * float(s) / 5.0
				pts.append(Vector3(cos(a) * rad, y + rng.randf_range(-0.002, 0.002), sin(a) * rad))
			_strand(st, pts, 0.0011, 0.0006, _tint(rng, Color(0.62, 0.55, 0.36), Color(0.78, 0.7, 0.48)), 3)
	else:
		for k in 50: # (chips of rotten wood; a barn owl's: its pellets too, trodden down, dark)
			var a := rng.randf() * TAU
			var rad := fr * sqrt(rng.randf())
			var p := Vector3(cos(a) * rad, floor_y + ri * 0.18 * pow(rad / fr, 2.0) + 0.002, sin(a) * rad)
			var col := _tint(rng, Color(0.5, 0.4, 0.27), Color(0.68, 0.58, 0.42))
			if kind == "barn_owl" and k % 3 == 0:
				col = _tint(rng, Color(0.14, 0.12, 0.11), Color(0.25, 0.22, 0.2))
			_scrap(st, p, Vector3(cos(a * 7.0), 0.0, sin(a * 7.0)), Vector3.UP, ri * rng.randf_range(0.12, 0.25), ri * 0.09, col, false)
	return [floor_y - (ri * 0.0) + 0.004, fr * 0.8]


## A squirrel's drey: a hollow ball of dead leaves on a frame of twigs, its
## way in at one side (+x); its origin at its middle's foot.
static func _drey(st: SurfaceTool, rng: RandomNumberGenerator, r: float) -> Array:
	var c := Vector3(0.0, r * 0.9, 0.0)
	var axis := Vector3(0.9, 0.25, 0.0).normalized()
	var mouth := 0.78
	var NA := 18
	var NP := 12
	for inside in [false, true]: # (its shell: bark shreds, dark, behind the leaves)
		var rr := r * (0.74 if inside else 0.9)
		var grid := []
		for i in NP + 1:
			var row := []
			var ph := PI * float(i) / NP
			for j in NA + 1:
				var th := TAU * float(j % NA) / NA
				var d := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
				var d0 := d
				if d.dot(axis) > mouth: # (into its way in: brought to its edge, a clean round)
					var perp := (d - axis * d.dot(axis))
					perp = perp.normalized() if perp.length() > 1e-4 else Vector3.FORWARD
					d = axis * mouth + perp * sqrt(1.0 - mouth * mouth)
				row.append([c + d * rr * Vector3(1.0, 0.92, 1.0), d0.dot(axis), _tint(rng, Color(0.2, 0.15, 0.1), Color(0.32, 0.25, 0.17), 0.06) if not inside else _tint(rng, Color(0.36, 0.28, 0.19), Color(0.5, 0.4, 0.28), 0.06)])
			grid.append(row)
		for i in NP:
			for j in NA:
				var q := [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
				if float(q[0][1]) > mouth and float(q[1][1]) > mouth and float(q[2][1]) > mouth and float(q[3][1]) > mouth:
					continue
				for k: int in [0, 1, 2, 0, 2, 3]:
					st.set_color(q[k][2])
					st.add_vertex(q[k][0])
	for k in 70: # (its frame: twigs woven round, their ends out)
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		if d.dot(axis) > mouth - 0.05:
			continue
		var t := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized().rotated(d, rng.randf() * TAU)
		var ln := r * rng.randf_range(0.7, 1.3)
		var p := c + d * r * 0.93
		_strand(st, [p - t * ln * 0.5 + d * r * 0.1, p + d * r * 0.03, p + t * ln * 0.5 + d * r * 0.12], 0.004, 0.002, _tint(rng, Color(0.26, 0.2, 0.14), Color(0.42, 0.34, 0.25)), 4)
	for k in 700: # (its leaves: dead oak leaves, overlapping, brown and tan, curled)
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		if d.dot(axis) > mouth + 0.04:
			continue
		var t := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized().rotated(d, rng.randf() * TAU)
		var p := c + d * r * rng.randf_range(0.9, 1.02) * Vector3(1.0, 0.92, 1.0)
		var col := _tint(rng, Color(0.36, 0.24, 0.12), Color(0.6, 0.45, 0.24), 0.15)
		if rng.randf() < 0.12:
			col = _tint(rng, Color(0.3, 0.36, 0.14), Color(0.42, 0.44, 0.18)) # (a few still green: cut fresh)
		_scrap(st, p - t * r * 0.15, (t + d * rng.randf_range(0.0, 0.35)).normalized(), d, r * rng.randf_range(0.3, 0.45), r * rng.randf_range(0.14, 0.22), col)
	var floor_y := c.y - r * 0.74 * 0.92 + r * 0.12
	_dish(st, rng, r * 0.55, floor_y, r * 0.12, Color(0.4, 0.31, 0.2), Color(0.56, 0.45, 0.3))
	return [floor_y, r * 0.4]


## A nest on the ground: a goose's (a bowl of reeds and dry grass, lined
## with grey down), a turkey's (a scrape in dead leaves).
static func _ground(st: SurfaceTool, rng: RandomNumberGenerator, kind: String, scale: float) -> Array:
	if kind == "turkey":
		var r := 0.3 * scale
		_dish(st, rng, r * 0.8, 0.004, r * 0.1, Color(0.3, 0.24, 0.16), Color(0.42, 0.34, 0.23))
		for k in 150:
			var a := rng.randf() * TAU
			var rr := r * lerpf(0.25, 1.25, sqrt(rng.randf()))
			var p := Vector3(cos(a) * rr, 0.006 + 0.05 * r * pow(rr / r, 2.0) + rng.randf() * 0.01, sin(a) * rr)
			var d := Vector3(cos(a * 5.0 + k), 0.0, sin(a * 5.0 + k))
			_scrap(st, p, d, Vector3(0.0, 1.0, 0.0).rotated(d, rng.randf_range(-0.4, 0.4)), 0.11 * rng.randf_range(0.6, 1.0), 0.05, _tint(rng, Color(0.36, 0.25, 0.13), Color(0.6, 0.46, 0.25), 0.15))
		return [0.012, r * 0.6]
	var r := 0.36 * scale
	var h := r * 0.3
	_dish(st, rng, r * 0.62, 0.02, h * 0.6, Color(0.5, 0.48, 0.44), Color(0.66, 0.64, 0.6))
	for k in 420: # (reeds and grass, laid round in a ring, mounded)
		var a0 := rng.randf() * TAU
		var rad := r * rng.randf_range(0.55, 1.0)
		var y := h * (1.0 - pow(absf(rad / r - 0.75) / 0.3, 2.0)) * rng.randf_range(0.3, 1.0) + 0.004
		var span := rng.randf_range(0.5, 1.5)
		var pts := []
		for s in 5:
			var a := a0 + span * float(s) / 4.0
			pts.append(Vector3(cos(a) * rad * (1.0 + 0.05 * absf(float(s) - 2.0)), y + rng.randf_range(-0.004, 0.004), sin(a) * rad * (1.0 + 0.05 * absf(float(s) - 2.0))))
		_strand(st, pts, 0.004 * rng.randf_range(0.6, 1.3), 0.002, _tint(rng, Color(0.52, 0.46, 0.27), Color(0.72, 0.66, 0.42)), 4)
	for k in 160: # (her down, plucked from her breast: pale grey tufts round the bowl)
		var a := rng.randf() * TAU
		var rad := r * rng.randf_range(0.2, 0.68)
		var p := Vector3(cos(a) * rad, 0.022 + h * 0.6 * pow(rad / (r * 0.62), 2.0), sin(a) * rad)
		for j in 3:
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.3, 1.0), rng.randf_range(-1, 1)).normalized()
			_strand(st, [p, p + d * 0.03], 0.003, 0.0006, _tint(rng, Color(0.7, 0.68, 0.66), Color(0.86, 0.85, 0.83), 0.05), 3)
	return [0.03, r * 0.5]
