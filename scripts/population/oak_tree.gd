class_name OakTree
## The English oak (Quercus robur): four hand-set standing trees, a stump,
## a dead standing tree, three fallen logs and two saplings (variants 0-10), grown into a
## TreeBuilder skeleton and dressed with data/population/textures/oak_*.png
## (tools/trees/bake_oak_textures.py). The prop (data/population/props/
## oak.tres) has variants = 11 and this as its mesh_script.
##
## What makes it read as an oak: a short, stout trunk with flared roots that
## runs on into the crown, giving off a few heavy limbs one after another; limbs that spread wide, nearly level,
## and go crooked, changing direction at every node; side branches that
## leave at wide angles and turn up at their ends; leaves crowded in
## clusters at the shoot tips; a broad, rounded crown, often wider than tall.
##
## Levels: 0 trunk, 1 limbs, 2 branches, 3 twigs (the twigs carry the sprigs).
## The crown is an ellipsoid ("crown": horizontal radius, top, bottom, m):
## branches that reach it stop there and leaf out, so the leaves pack into
## a dome as an oak's do.

const VARIANTS := [
	# open-grown: short trunk, limbs spreading wide, a broad dome
	{"trunk_h": 2.8, "leader_h": 4.0, "trunk_r": 0.5, "limbs": 6, "limb_angle": 55.0, "limb_len": 8.0, "branch_len": 3.6, "twig_len": 1.2, "lean": 0.0, "droop": 0.0, "seed": 11, "crown": [7.5, 15.5, 3.5]},
	# young: slimmer, upright, a strong leader
	{"trunk_h": 3.2, "leader_h": 6.5, "trunk_r": 0.28, "limbs": 6, "limb_angle": 42.0, "limb_len": 5.0, "branch_len": 2.6, "twig_len": 1.1, "lean": 0.0, "droop": 0.0, "seed": 23, "crown": [5.0, 14.5, 3.5]},
	# leaning: grown toward the light, the crown heavier on one side
	{"trunk_h": 3.0, "leader_h": 4.5, "trunk_r": 0.42, "limbs": 5, "limb_angle": 50.0, "limb_len": 7.0, "branch_len": 3.3, "twig_len": 1.15, "lean": 9.0, "droop": 0.02, "seed": 41, "crown": [6.8, 14.5, 3.5]},
	# forest-grown: a tall clean bole, a small high crown
	{"trunk_h": 6.5, "leader_h": 5.5, "trunk_r": 0.45, "limbs": 5, "limb_angle": 40.0, "limb_len": 5.2, "branch_len": 2.8, "twig_len": 1.1, "lean": 0.0, "droop": 0.0, "seed": 53, "crown": [5.0, 19.0, 7.5]},
	# a stump, sawn off, the roots flaring
	{"kind": "stump", "seed": 61},
	# a fallen trunk, snapped at both ends, the stubs of its limbs
	{"kind": "log", "seed": 67},
	# a dead oak still standing: an open-grown oak's skeleton, bare, broken
	{"kind": "dead", "like": 0, "seed": 71, "limb_angle": 40.0, "limb_len": 7.0, "branch_len": 3.0, "crown": [6.0, 13.5, 3.0]},
	# a long, slender fallen stem, bristling with snapped limbs
	{"kind": "log", "seed": 73, "length": Vector2(8.0, 9.5), "r0": 0.32, "r1": 0.17, "bow": 0.45, "stubs": Vector2i(4, 6)},
	# a short, heavy section of a big trunk
	{"kind": "log", "seed": 79, "length": Vector2(2.8, 3.6), "r0": 0.58, "r1": 0.52, "bow": 0.06, "stubs": Vector2i(0, 1)},
	# saplings, 3-4 m: a whip with a small crown, and a bushier one forking low
	{"kind": "sapling", "trunk_h": 0.9, "leader_h": 2.0, "trunk_r": 0.045, "limbs": 4, "limb_angle": 40.0, "limb_len": 1.5, "branch_len": 0.8, "twig_len": 0.5, "lean": 0.0, "droop": 0.0, "seed": 83, "crown": [1.3, 3.8, 0.9]},
	{"kind": "sapling", "trunk_h": 0.4, "leader_h": 1.6, "trunk_r": 0.05, "limbs": 5, "limb_angle": 52.0, "limb_len": 1.6, "branch_len": 0.8, "twig_len": 0.5, "lean": 4.0, "droop": 0.0, "seed": 89, "crown": [1.6, 3.2, 0.5]},
]

## How a variant differs as a prop (Population applies these to its kind):
## weight is its share of the oaks; the stump and the dead oak are half as
## common as each standing tree, the three logs together three quarters,
## each sapling half; the logs lie along the ground (out into a swamp's
## edge, too: standing on one lifts you out of the mud), can be stood on
## and cast no shadow, the stumps jumped onto; dead oaks stand in the swamp too, as many as all the
## standing oaks (live, saplings and dead; not the logs or stumps) on the
## prairie, down into its shallows.
const PROPS := {
	"tree": {"standing": true, "foot": 0.75},
	"stump": {"weight": 0.5, "radius": 0.0, "foot": 0.6, "align_to_ground": 0.3, "sink": 0.12, "scale_range": Vector2(0.8, 1.1)},
	"log": {"weight": 0.25, "radius": 0.0, "align_to_ground": 0.9, "sink": 0.12, "scale_range": Vector2(0.8, 1.15), "shadows": false},
	"dead": {"weight": 0.5, "standing": true, "density_like": {"swamp": "prairie"}, "like_group": "standing", "height_range": Vector2(-0.5, 1900.0), "foot": 0.65},
	"sapling": {"weight": 0.5, "standing": true, "radius": 0.1, "foot": 0.08, "scale_range": Vector2(0.75, 1.25)},
}

# per level (0 trunk .. 3 twigs)
const SEG := [0.5, 0.65, 0.45, 0.35] ## m between nodes
const CROOK := [0.05, 0.15, 0.28, 0.32] ## rad, random turn at each node
const UP := [0.0, 0.012, 0.06, 0.1] ## turn toward the sky at each node
const CHILD_ANGLE := [0.0, 0.9, 0.85, 0.8] ## rad off the parent
const TIP_R := 0.006 ## m, the thinnest twig

## Levels of detail: where each simpler one takes over (m), and the last's
## end. Each level has its own materials, which know its span (lod_range)
## for the stippled hand-over (lod_fade.gdshaderinc).
const LOD := [40.0, 120.0, 300.0]
const VIEW := 600.0

static var _bark_mats := {} # level -> ShaderMaterial
static var _leaf_mats := {}
static var _cache := {} # variant -> [mesh, lods]


static func bark_material(level := 0) -> ShaderMaterial:
	if not _bark_mats.has(level):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/bark.gdshader")
		m.set_shader_parameter("bark_tex", _texture("res://data/population/textures/oak_bark.png"))
		_lod_span(m, level)
		_bark_mats[level] = m
	return _bark_mats[level]


static func leaf_material(level := 0) -> ShaderMaterial:
	if not _leaf_mats.has(level):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/leaves.gdshader")
		m.set_shader_parameter("leaf_tex", _texture("res://data/population/textures/oak_leaves.png"))
		_lod_span(m, level)
		_leaf_mats[level] = m
	return _leaf_mats[level]


static var _textures := {}


## A texture with its mipmaps, whatever it was imported with (.import files
## aren't kept in the repository, and Godot's default leaves them out for a
## texture only scripts use): without them the leaves' cut-outs and the bark
## alias, sparkling and crawling as the camera moves.
static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		var t: Texture2D = load(path)
		var img := t.get_image()
		if not img.has_mipmaps():
			if img.is_compressed():
				img.decompress()
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
		_textures[path] = t
	return _textures[path]


static func _lod_span(m: ShaderMaterial, level: int) -> void:
	var begin: float = 0.0 if level == 0 else LOD[level - 1]
	var end: float = VIEW if level == LOD.size() else LOD[level]
	m.set_shader_parameter("lod_range", Vector3(begin, end, Population.LOD_FADE))


## Off: every level drawn wherever it is (e.g. to look at one level alone).
static func set_lod_fade(on: bool) -> void:
	for mats in [_bark_mats, _leaf_mats]:
		for level in mats:
			var r: Vector3 = mats[level].get_shader_parameter("lod_range")
			r.z = Population.LOD_FADE if on else 0.0
			mats[level].set_shader_parameter("lod_range", r)


static var _shadow: Mesh
static var _sapling_shadow: Mesh


static func _kind(v: int) -> String:
	return VARIANTS[posmod(v, VARIANTS.size())].get("kind", "tree")


## Population: how variant v differs as a prop.
static func variant_props(v: int) -> Dictionary:
	var p: Dictionary = PROPS[_kind(v)].duplicate()
	p.lod_distances = PackedFloat32Array(LOD)
	p.view_distance = VIEW
	return p


## The whole tree (PropKind.mesh_script).
static func build(variant := 0) -> Mesh:
	return _models(variant)[0]


## The shadow every standing oak casts, whatever its variant: a lumpy dome
## on a stalk (PropKind.shadow_mesh; the trees themselves cast none). The
## stump and the log cast their own (null).
static func build_shadow(variant := 0) -> Mesh:
	match _kind(variant):
		"tree":
			if _shadow == null:
				_shadow = TreeBuilder.shadow_proxy(7.5, 4.0, 14.0, 0.45, 23)
			return _shadow
		"sapling": # (the same, small)
			if _sapling_shadow == null:
				_sapling_shadow = TreeBuilder.shadow_proxy(1.3, 1.0, 3.6, 0.05, 29)
			return _sapling_shadow
	return null


## Simpler versions for further off: branches and clump cards to 40-120 m,
## limbs and fewer, bigger clumps to 300 m, the stem and a few big clumps
## beyond.
static func build_lods(variant := 0) -> Array[Mesh]:
	return _models(variant)[1]


static func _models(variant: int) -> Array:
	variant = posmod(variant, VARIANTS.size())
	if not _cache.has(variant):
		var b := [bark_material(0), bark_material(1), bark_material(2), bark_material(3)]
		var l := [leaf_material(0), leaf_material(1), leaf_material(2), leaf_material(3)]
		var tb: TreeBuilder
		var lods: Array[Mesh]
		match _kind(variant):
			"stump":
				tb = grow_stump(VARIANTS[variant])
				lods = [tb.lod(b[1], l[1], 0, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			"log":
				tb = grow_log(VARIANTS[variant])
				lods = [tb.lod(b[1], l[1], 1, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			"dead":
				tb = grow_dead(VARIANTS[variant])
				lods = [tb.lod(b[1], l[1], 2, 2, 0, 1.0), tb.lod(b[2], l[2], 1, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			_:
				tb = grow(variant)
				lods = [tb.lod(b[1], l[1], 2, 2, 4, 1.0, LOD[0]), tb.lod(b[2], l[2], 1, 3, 12, 2.0, LOD[1]), tb.lod(b[3], l[3], 0, 4, 36, 3.2, LOD[2])]
		_cache[variant] = [tb.build(b[0], l[0], 12.0), lods]
	return _cache[variant]


## Population: what can be stood on (PropKind.walk): a log's trunk, a
## segment between each pair of its nodes (not the stubs of its limbs); a
## stump, a post to the bottom of its splinters (solid all round, too).
static func build_walk(variant := 0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	variant = posmod(variant, VARIANTS.size())
	if _kind(variant) == "stump":
		var st := grow_stump(VARIANTS[variant])
		var h := st.pos[st.branches[0][-1]].y
		out.append_array([0.0, 0.0, 0.0, 0.0, h, 0.0, 0.55, 0.55])
		return out
	if _kind(variant) != "log":
		return out
	var tb := grow_log(VARIANTS[variant])
	var b := tb.branches[0]
	for i in b.size() - 1:
		var a := tb.pos[b[i]]
		var e := tb.pos[b[i + 1]]
		out.append_array([a.x, a.y, a.z, e.x, e.y, e.z, tb.radius[b[i]], tb.radius[b[i + 1]]])
	return out


## A stump: snapped off 0.75-1.1 m up (low enough to jump onto), splinters standing up round a
## broken, sunken middle; the roots flaring into buttresses.
static func grow_stump(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	tb.rng.seed = P.seed
	tb.flare = 0.5
	tb.bark_tint = Color(0.92, 0.9, 0.86)
	tb.splinter = true
	var h := tb.rng.randf_range(0.75, 1.1)
	var nodes := PackedInt32Array([tb.add_node(Vector3.ZERO, -1, 0)])
	for i in 3:
		var y := h * (i + 1) / 3.0
		nodes.append(tb.add_node(Vector3(0.0, y, 0.0), nodes[i], 0))
	for n in nodes:
		tb.set_radius(n, 0.5 - 0.04 * tb.pos[n].y)
	tb.add_branch(nodes, false, true, 0.45)
	return tb


## A fallen trunk: 5-7 m, lying along x, a little bowed, broken at both
## ends, with the snapped stubs of a few limbs; the bark greyer and greener.
static func grow_log(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	var rng := tb.rng
	rng.seed = P.seed
	tb.flare = 0.0
	tb.splinter = true # (snapped, not sawn)
	tb.bark_tint = Color(0.78, 0.82, 0.7)
	var len_range: Vector2 = P.get("length", Vector2(5.0, 7.0))
	var length := rng.randf_range(len_range.x, len_range.y)
	var r0: float = P.get("r0", 0.42)
	var r1: float = P.get("r1", 0.3)
	var bow: float = P.get("bow", 0.25)
	var n := maxi(int(length / 0.65), 6)
	var nodes := PackedInt32Array()
	for i in n:
		var t := float(i) / (n - 1)
		var r := lerpf(r0, r1, t)
		var p := Vector3((t - 0.5) * length, r * 0.85 - 0.05 * sin(PI * t), bow * sin(PI * t * 1.3))
		nodes.append(tb.add_node(p, nodes[i - 1] if i > 0 else -1, 0))
		tb.set_radius(nodes[i], r)
	tb.add_branch(nodes, true, true, r0 * 0.7)
	# stubs of the limbs that broke off as it fell
	var stubs: Vector2i = P.get("stubs", Vector2i(2, 4))
	for k in rng.randi_range(stubs.x, stubs.y):
		var at := nodes[rng.randi_range(2, n - 2)]
		var around := rng.randf_range(-1.2, 1.2) + (PI if rng.randf() < 0.3 else 0.0)
		var d := Vector3(rng.randf_range(-0.4, 0.6), cos(around), sin(around)).normalized()
		if d.y < -0.2:
			d.y = -d.y # (not into the ground)
		var len := rng.randf_range(0.35, 1.1)
		var r := rng.randf_range(0.07, 0.12) * r0 / 0.42
		var stub := PackedInt32Array([at])
		for i in 2:
			stub.append(tb.add_node(tb.pos[at] + d * len * (i + 1) / 2.0, stub[i], 1))
			tb.set_radius(stub[i + 1], r * (1.0 - 0.25 * i))
		tb.add_branch(stub, false, true, r * 0.9)
	return tb


## A dead oak, still standing: the skeleton of the standing variant it's
## "like", with its own seed and spread, then stripped: the twigs and leaves gone,
## most branches and some limbs snapped off (end grain at the breaks), the
## bark weathered silver-grey. It casts its own shadow.
static func grow_dead(D: Dictionary) -> TreeBuilder:
	var P: Dictionary = VARIANTS[D.like].duplicate()
	for key in D:
		if key != "kind" and key != "like":
			P[key] = D[key] # (its own seed, and a narrower spread)
	var tb := _grow_tree(P)
	var rng := tb.rng
	tb.sprigs.clear()
	tb.bark_tint = Color(0.74, 0.72, 0.68)
	tb.sways = false
	# parents before children, so a branch knows whether its parent still
	# reaches the node it grows from
	var order := range(tb.branches.size())
	order.sort_custom(func(a: int, b: int) -> bool: return tb.level[tb.branches[a][1]] < tb.level[tb.branches[b][1]])
	var gone := {}
	var keep: Array[PackedInt32Array] = []
	var caps: Array = []
	for i in order:
		var b: PackedInt32Array = tb.branches[i]
		var lv := tb.level[b[1]]
		if gone.has(b[0]) or lv >= 3:
			for n in b:
				gone[n] = true
			continue
		var cut := b.size()
		if lv == 2 and rng.randf() < 0.75:
			cut = maxi(2, int(b.size() * rng.randf_range(0.2, 0.7)))
		elif lv == 1 and rng.randf() < 0.5:
			cut = maxi(3, int(b.size() * rng.randf_range(0.45, 0.85)))
		if cut < b.size():
			for j in range(cut, b.size()):
				gone[b[j]] = true
			keep.append(b.slice(0, cut))
			caps.append([false, true, tb.radius[b[cut - 1]] * rng.randf_range(0.8, 1.6)])
		else:
			keep.append(b)
			caps.append(tb.caps[i])
	tb.branches = keep
	tb.caps = caps
	return tb


## The skeleton of variant v (a standing tree).
static func grow(v: int) -> TreeBuilder:
	return _grow_tree(VARIANTS[v])


static func _grow_tree(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	tb.rng.seed = P.seed
	var rng := tb.rng
	tb.flare = 0.45 + P.trunk_r * 0.3
	var lean_az := rng.randf() * TAU
	var lean_dir := Vector3(cos(lean_az), 0.0, sin(lean_az))
	var c: Array = P.crown
	P = P.duplicate()
	P.env_centre = Vector3(0.0, (c[1] + c[2]) * 0.5, 0.0) + lean_dir * (P.lean / 11.0) * 2.0
	P.env_radii = Vector3(c[0], (c[1] - c[2]) * 0.5, c[0])
	# The stem: a clear bole, then on up into the crown as a leader that
	# the limbs leave one by one; it thins as each takes its share (the pipe
	# model), and its top carries on as the highest limb. Leaning if it does,
	# a little crooked.
	var d := (Vector3.UP + lean_dir * tan(deg_to_rad(P.lean))).normalized()
	var root := tb.add_node(Vector3.ZERO, -1, 0)
	var stem := PackedInt32Array([root])
	var total_h: float = P.trunk_h + P.leader_h
	var steps := maxi(ceili(total_h / SEG[0]), 3)
	var p := Vector3.ZERO
	var dirs: Array[Vector3] = [d]
	for i in steps:
		d = _turn(rng, d, CROOK[0] * (1.0 if p.y < P.trunk_h else 2.5))
		d = (d + Vector3.UP * 0.04).normalized()
		p += d * total_h / steps
		stem.append(tb.add_node(p, stem[stem.size() - 1], 0))
		dirs.append(d)
	# the limbs, up the leader in a spiral (137 degrees apart): the lowest
	# longest and flattest, the highest short and steep
	var first := 1
	while first < stem.size() - 1 and tb.pos[stem[first]].y < P.trunk_h:
		first += 1
	var n_limbs: int = P.limbs
	var az := rng.randf() * TAU
	for k in n_limbs:
		var f := float(k) / maxf(n_limbs - 1, 1)
		var at := clampi(first + roundi(f * (stem.size() - 1 - first)), 1, stem.size() - 1)
		az += deg_to_rad(137.5) + rng.randf_range(-0.3, 0.3)
		var tilt := deg_to_rad(lerpf(P.limb_angle, P.limb_angle * 0.55, f) + rng.randf_range(-6.0, 6.0))
		var dir := Vector3(sin(tilt) * cos(az), cos(tilt), sin(tilt) * sin(az))
		var len: float = P.limb_len * lerpf(1.0, 0.65, f) * rng.randf_range(0.85, 1.1)
		if P.lean > 0.0:
			var toward := Vector2(dir.x, dir.z).normalized().dot(Vector2(lean_dir.x, lean_dir.z))
			len *= 1.0 + 0.25 * toward # the crown heavier toward the lean
		_branch(tb, P, stem[at], dir, len, 1, dirs[at])
	# the leader's top, on as a limb
	_branch(tb, P, stem[stem.size() - 1], _turn(rng, dirs[dirs.size() - 1], 0.2), P.limb_len * 0.5, 1, dirs[dirs.size() - 1])
	tb.add_branch(stem)
	tb.compute_radii(P.trunk_r, TIP_R)
	return tb


## A branch at level lv from node `from`, heading dir, length m long: it
## leaves its parent nearly along the parent's way (parent_dir) and bends
## out to its own over its first few nodes, as wood grows; crooked, turning
## up, with side branches (or sprigs on the twigs) at its nodes.
static func _branch(tb: TreeBuilder, P: Dictionary, from: int, dir: Vector3, length: float, lv: int, parent_dir := Vector3.ZERO) -> void:
	var rng := tb.rng
	var steps := maxi(ceili(length / SEG[lv]), 2)
	var nodes := PackedInt32Array([from])
	var p := tb.pos[from]
	var target := dir
	var d := dir if parent_dir == Vector3.ZERO else parent_dir.slerp(dir, 0.3).normalized()
	var spiral := rng.randf() * TAU
	for i in steps:
		var t := float(i + 1) / steps
		if i < 4:
			d = d.slerp(target, 0.4).normalized() # (easing out of the parent)
		d = _turn(rng, d, CROOK[lv])
		# up toward the light; heavy limbs droop first, then sweep up
		var up: float = UP[lv] - (P.droop * (1.0 - t) if lv == 1 else 0.0)
		if p.y < P.trunk_h * 0.5:
			up = maxf(up, 0.25) # (never down into the ground)
		d = (d + Vector3.UP * up).normalized()
		target = (target + Vector3.UP * up * 0.5).normalized()
		var q := p + d * length / steps
		var e: Vector3 = (q - P.env_centre) / P.env_radii
		if e.y < 0.0:
			e.y *= 0.35 # (below its middle the crown is a broad, open bowl)
		if e.length() > (1.08 if lv == 1 else 1.0) and i > 0:
			break # reached the edge of the crown
		p = q
		var node := tb.add_node(p, nodes[nodes.size() - 1], lv)
		nodes.append(node)
		if lv < 3:
			# side branches, alternating round the branch, none near its base
			var start := 0.3 if lv == 1 else 0.15
			if t > start:
				for c in 2:
					spiral += 2.4 + rng.randf_range(-0.3, 0.3)
					var cd := _side(d, spiral, CHILD_ANGLE[lv + 1] + rng.randf_range(-0.2, 0.2))
					cd = _outward(cd, p, 0.35)
					if cd.y < -0.25: # (branches don't hang straight down)
						cd = Vector3(cd.x, -0.25, cd.z).normalized()
					var cl: float = (P.branch_len if lv == 1 else P.twig_len) * (1.0 - 0.45 * t) * rng.randf_range(0.75, 1.2)
					if rng.randf() < (0.8 if lv == 1 else 0.7):
						_branch(tb, P, node, cd, cl, lv + 1, d)
			# a few sprigs on the outer half of the branches too
			if lv == 2 and t > 0.4 and rng.randf() < 0.5:
				tb.add_sprig(node, _outward(_side(d, rng.randf() * TAU, 0.8), p, 0.4))
		elif t > 0.25 and rng.randf() < 0.7:
			tb.add_sprig(node, _outward(_side(d, rng.randf() * TAU, rng.randf_range(0.5, 1.1)), p, 0.3))
	if lv >= 2:
		tb.add_sprig(nodes[nodes.size() - 1], _outward(_turn(rng, d, 0.5), p, 0.3))
	tb.add_branch(nodes)


## d turned by up to `amount` rad in a random direction.
static func _turn(rng: RandomNumberGenerator, d: Vector3, amount: float) -> Vector3:
	return _side(d, rng.randf() * TAU, rng.randf() * amount)


## d tilted by angle toward the side at `around` rad round it.
static func _side(d: Vector3, around: float, angle: float) -> Vector3:
	var u := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
	var w := d.cross(u)
	var s := u * cos(around) + w * sin(around)
	return (d * cos(angle) + s * sin(angle)).normalized()


## d bent away from the trunk's axis (horizontally), by k.
static func _outward(d: Vector3, p: Vector3, k: float) -> Vector3:
	var o := Vector3(p.x, 0.0, p.z)
	if o.length() < 0.01:
		return d
	return (d + o.normalized() * k).normalized()
