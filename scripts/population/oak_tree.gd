class_name OakTree
## The English oak (Quercus robur): four hand-set standing trees, a stump,
## a fallen log and a dead standing tree (variants 0-6), grown into a
## TreeBuilder skeleton and dressed with data/population/textures/oak_*.png
## (tools/trees/bake_oak_textures.py). The prop (data/population/props/
## oak.tres) has variants = 7 and this as its mesh_script.
##
## What makes it read as an oak: a short, stout trunk with flared roots that
## splits low into a few heavy limbs; limbs that spread wide, nearly level,
## and go crooked, changing direction at every node; side branches that
## leave at wide angles and turn up at their ends; leaves crowded in
## clusters at the shoot tips; a broad, rounded crown, often wider than tall.
##
## Levels: 0 trunk, 1 limbs, 2 branches, 3 twigs (the twigs carry the sprigs).
## The crown is an ellipsoid ("crown": horizontal radius, top, bottom, m):
## branches that reach it stop there and leaf out, so the leaves pack into
## a dome as an oak's do.

const VARIANTS := [
	# open-grown: short trunk, five limbs spreading wide, a broad dome
	{"trunk_h": 2.6, "trunk_r": 0.5, "limbs": 5, "limb_angle": 58.0, "limb_len": 9.8, "branch_len": 4.2, "twig_len": 1.26, "leader": false, "lean": 0.0, "droop": 0.0, "seed": 11, "crown": [9.5, 15.5, 3.0]},
	# young: slimmer, upright, still with a leader
	{"trunk_h": 3.4, "trunk_r": 0.28, "limbs": 4, "limb_angle": 38.0, "limb_len": 7.0, "branch_len": 3.08, "twig_len": 1.12, "leader": true, "lean": 0.0, "droop": 0.0, "seed": 23, "crown": [5.5, 14.0, 3.2]},
	# leaning: grown toward the light, the crown heavier on one side
	{"trunk_h": 3.0, "trunk_r": 0.42, "limbs": 5, "limb_angle": 52.0, "limb_len": 9.1, "branch_len": 3.92, "twig_len": 1.19, "leader": false, "lean": 11.0, "droop": 0.03, "seed": 41, "crown": [8.5, 14.5, 3.0]},
	# forest-grown: a tall clean bole, a small high crown
	{"trunk_h": 6.5, "trunk_r": 0.45, "limbs": 4, "limb_angle": 36.0, "limb_len": 6.44, "branch_len": 3.36, "twig_len": 1.12, "leader": true, "lean": 0.0, "droop": 0.0, "seed": 53, "crown": [5.5, 19.5, 7.5]},
	# a stump, sawn off, the roots flaring
	{"kind": "stump", "seed": 61},
	# a fallen trunk, broken at both ends, the stubs of its limbs
	{"kind": "log", "seed": 67},
	# a dead oak still standing: an open-grown oak's skeleton, bare, broken
	{"kind": "dead", "like": 0, "seed": 71, "limb_angle": 40.0, "limb_len": 7.0, "branch_len": 3.0, "crown": [6.0, 13.5, 3.0]},
]

## How a variant differs as a prop (Population applies these to its kind):
## weight is its share of the oaks; the dead wood is half as common as each
## standing tree, the log lies along the ground and can be walked over.
const PROPS := {
	"tree": {},
	"stump": {"weight": 0.5, "radius": 0.55, "align_to_ground": 0.3, "sink": 0.12, "scale_range": Vector2(0.8, 1.2)},
	"log": {"weight": 0.5, "radius": 0.0, "align_to_ground": 0.9, "sink": 0.12, "scale_range": Vector2(0.8, 1.15)},
	"dead": {"weight": 0.5},
}

# per level (0 trunk .. 3 twigs)
const SEG := [0.5, 0.65, 0.45, 0.35] ## m between nodes
const CROOK := [0.05, 0.15, 0.28, 0.32] ## rad, random turn at each node
const UP := [0.0, 0.012, 0.06, 0.1] ## turn toward the sky at each node
const CHILD_ANGLE := [0.0, 0.9, 0.85, 0.8] ## rad off the parent
const TIP_R := 0.006 ## m, the thinnest twig

static var _bark_mat: ShaderMaterial
static var _leaf_mat: ShaderMaterial
static var _cache := {} # variant -> [mesh, lods]


static func bark_material() -> ShaderMaterial:
	if _bark_mat == null:
		_bark_mat = ShaderMaterial.new()
		_bark_mat.shader = load("res://shaders/render/bark.gdshader")
		_bark_mat.set_shader_parameter("bark_tex", load("res://data/population/textures/oak_bark.png"))
	return _bark_mat


static func leaf_material() -> ShaderMaterial:
	if _leaf_mat == null:
		_leaf_mat = ShaderMaterial.new()
		_leaf_mat.shader = load("res://shaders/render/leaves.gdshader")
		_leaf_mat.set_shader_parameter("leaf_tex", load("res://data/population/textures/oak_leaves.png"))
	return _leaf_mat


static var _shadow: Mesh


static func _kind(v: int) -> String:
	return VARIANTS[posmod(v, VARIANTS.size())].get("kind", "tree")


## Population: how variant v differs as a prop.
static func variant_props(v: int) -> Dictionary:
	return PROPS[_kind(v)]


## The whole tree (PropKind.mesh_script).
static func build(variant := 0) -> Mesh:
	return _models(variant)[0]


## The shadow every standing oak casts, whatever its variant: a lumpy dome
## on a stalk (PropKind.shadow_mesh; the trees themselves cast none). The
## stump and the log cast their own (null).
static func build_shadow(variant := 0) -> Mesh:
	if _kind(variant) != "tree":
		return null
	if _shadow == null:
		_shadow = TreeBuilder.shadow_proxy(7.5, 4.0, 14.0, 0.45, 23)
	return _shadow


## Simpler versions for further off: branches and clump cards to 50-180 m,
## limbs and a few big clump cards beyond.
static func build_lods(variant := 0) -> Array[Mesh]:
	return _models(variant)[1]


static func _models(variant: int) -> Array:
	variant = posmod(variant, VARIANTS.size())
	if not _cache.has(variant):
		var b := bark_material()
		var l := leaf_material()
		var tb: TreeBuilder
		var lods: Array[Mesh]
		match _kind(variant):
			"stump":
				tb = grow_stump(VARIANTS[variant])
				lods = [tb.lod(b, l, 0, 2, 0, 1.0), tb.lod(b, l, 0, 3, 0, 1.0)]
			"log":
				tb = grow_log(VARIANTS[variant])
				lods = [tb.lod(b, l, 1, 2, 0, 1.0), tb.lod(b, l, 0, 3, 0, 1.0)]
			"dead":
				tb = grow_dead(VARIANTS[variant])
				lods = [tb.lod(b, l, 2, 2, 0, 1.0), tb.lod(b, l, 1, 3, 0, 1.0)]
			_:
				tb = grow(variant)
				lods = [tb.lod(b, l, 2, 2, 4, 1.0, 50.0), tb.lod(b, l, 1, 3, 14, 2.0, 180.0)]
		_cache[variant] = [tb.build(b, l, 12.0), lods]
	return _cache[variant]


## A stump: snapped off 0.9-1.3 m up, splinters standing up round a
## broken, sunken middle; the roots flaring into buttresses.
static func grow_stump(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	tb.rng.seed = P.seed
	tb.flare = 0.5
	tb.bark_tint = Color(0.92, 0.9, 0.86)
	tb.splinter = true
	var h := tb.rng.randf_range(0.9, 1.3)
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
	tb.bark_tint = Color(0.78, 0.82, 0.7)
	var length := rng.randf_range(5.0, 7.0)
	var r0 := 0.42
	var r1 := 0.3
	var n := 10
	var nodes := PackedInt32Array()
	for i in n:
		var t := float(i) / (n - 1)
		var r := lerpf(r0, r1, t)
		var p := Vector3((t - 0.5) * length, r * 0.85 - 0.05 * sin(PI * t), 0.25 * sin(PI * t * 1.3))
		nodes.append(tb.add_node(p, nodes[i - 1] if i > 0 else -1, 0))
		tb.set_radius(nodes[i], r)
	tb.add_branch(nodes, true, true, 0.12)
	# stubs of the limbs that broke off as it fell
	for k in rng.randi_range(2, 4):
		var at := nodes[rng.randi_range(3, n - 2)]
		var around := rng.randf_range(-1.2, 1.2) + (PI if rng.randf() < 0.3 else 0.0)
		var d := Vector3(rng.randf_range(-0.4, 0.6), cos(around), sin(around)).normalized()
		if d.y < -0.2:
			d.y = -d.y # (not into the ground)
		var len := rng.randf_range(0.35, 1.1)
		var r := rng.randf_range(0.07, 0.12)
		var stub := PackedInt32Array([at])
		for i in 2:
			stub.append(tb.add_node(tb.pos[at] + d * len * (i + 1) / 2.0, stub[i], 1))
			tb.set_radius(stub[i + 1], r * (1.0 - 0.25 * i))
		tb.add_branch(stub, false, true, 0.05)
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
	# the trunk, leaning if it does, a little crooked
	var lean_az := rng.randf() * TAU
	var lean_dir := Vector3(cos(lean_az), 0.0, sin(lean_az))
	var d := (Vector3.UP + lean_dir * tan(deg_to_rad(P.lean))).normalized()
	var c: Array = P.crown
	P = P.duplicate()
	P.env_centre = Vector3(0.0, (c[1] + c[2]) * 0.5, 0.0) + lean_dir * (P.lean / 11.0) * 2.5
	P.env_radii = Vector3(c[0], (c[1] - c[2]) * 0.5, c[0])
	var root := tb.add_node(Vector3.ZERO, -1, 0)
	var trunk := PackedInt32Array([root])
	var steps := maxi(ceili(P.trunk_h / SEG[0]), 2)
	var p := Vector3.ZERO
	for i in steps:
		d = _turn(rng, d, CROOK[0])
		d = (d + Vector3.UP * 0.03).normalized()
		p += d * P.trunk_h / steps
		trunk.append(tb.add_node(p, trunk[trunk.size() - 1], 0))
	# the limbs: from the top of the trunk and a little below, spread round
	var n_limbs: int = P.limbs
	var az0 := rng.randf() * TAU
	for k in n_limbs:
		var az := az0 + TAU * k / n_limbs + rng.randf_range(-0.35, 0.35)
		var tilt := deg_to_rad(P.limb_angle + rng.randf_range(-10.0, 10.0))
		var dir := Vector3(sin(tilt) * cos(az), cos(tilt), sin(tilt) * sin(az))
		var len: float = P.limb_len * rng.randf_range(0.8, 1.15)
		if P.lean > 0.0:
			var toward := Vector2(dir.x, dir.z).normalized().dot(Vector2(lean_dir.x, lean_dir.z))
			len *= 1.0 + 0.3 * toward # the crown heavier toward the lean
			dir = (dir + lean_dir * 0.25 * maxf(toward, 0.0)).normalized()
		var at := trunk[maxi(trunk.size() - 1 - (k % 3), 1)]
		_branch(tb, P, at, dir, len, 1)
	if P.leader:
		_branch(tb, P, trunk[trunk.size() - 1], _turn(rng, Vector3.UP, 0.15), P.limb_len * 0.9, 1)
	tb.add_branch(trunk)
	tb.compute_radii(P.trunk_r, TIP_R)
	return tb


## A branch at level lv from node `from`, heading dir, length m long: crooked,
## turning up, with side branches (or sprigs on the twigs) at its nodes.
static func _branch(tb: TreeBuilder, P: Dictionary, from: int, dir: Vector3, length: float, lv: int) -> void:
	var rng := tb.rng
	var steps := maxi(ceili(length / SEG[lv]), 2)
	var nodes := PackedInt32Array([from])
	var p := tb.pos[from]
	var d := dir
	var spiral := rng.randf() * TAU
	for i in steps:
		var t := float(i + 1) / steps
		d = _turn(rng, d, CROOK[lv])
		# up toward the light; heavy limbs droop first, then sweep up
		var up: float = UP[lv] - (P.droop * (1.0 - t) if lv == 1 else 0.0)
		if p.y < P.trunk_h * 0.5:
			up = maxf(up, 0.25) # (never down into the ground)
		d = (d + Vector3.UP * up).normalized()
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
						_branch(tb, P, node, cd, cl, lv + 1)
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
