class_name SpeciesTree
extends RefCounted
## A tree species' models, grown by one set of rules (OakTree's,
## generalised) from the species' own settings: how its wood grows (segment
## lengths, how crooked, how much it turns up, how wide its side branches
## leave, alternate or opposite), the shape of its crown, its bark and
## leaves (textures from tools/trees/bake_broadleaf_textures.py), and its
## variants (as the oak's: standing trees, a stump, logs, dead trees,
## saplings).
##
## Conifers (a variant with "whorls"): one leader to the top, the branches
## in whorls up it, each whorl's as long as the crown's profile there
## ("cone": widest at the bottom, to a point; "narrow": a slim spire, the
## lodgepole's; "flat": wide almost to the top, then flat, an old bald
## cypress's), nearly level or drooping (limb_angle from the upright, over
## 90 down; the top whorls lifted by lift_top degrees), the crown's edge that profile rather than an ellipsoid. And
## "stubs": dead, snapped branch stubs up the bare bole below the crown
## (the lodgepole's self-pruning); "knees": a bald cypress's knees, knobs of
## root standing up out of the ground round it.
##
## MapleTree, SycamoreTree, LodgepolePine and BaldCypress each make one and hand on its
## models through the same static calls OakTree answers (build, build_lods,
## build_shadow, build_walk, build_climb, variant_props), so either can
## later be a prop's mesh_script as the oak is.
##
## In the game (data/population/props/: each species' .tres), with the oak's
## far-off cards (OakTree._impostor) and its cut variant for felling; not
## yet the moss's sporophytes.

var name := ""
var variants: Array = []
var seg := [0.5, 0.65, 0.45, 0.35] ## m between nodes, per level (0 trunk .. 3 twigs)
var crook := [0.05, 0.15, 0.28, 0.32] ## rad, random turn at each node
var up := [0.0, 0.012, 0.06, 0.1] ## turn toward the sky at each node
var child_angle := [0.0, 0.9, 0.85, 0.8] ## rad off the parent
var tip_r := 0.006 ## m, the thinnest twig
var opposite := false ## side branches in pairs, each pair square to the last (maples); else one by one round the branch
var irregular := 0.0 ## 0 the crown a smooth ellipsoid .. 1 lumpy, reaching out here and there (the sycamore's)
var card_size := 0.7 ## m, a sprig card (as TreeBuilder.card_size: its texture tile's width x 1.4)
var bark_tex := ""
var leaf_tex := ""
var bark_tint := Color(1, 1, 1) ## the living tree's bark
var tint_low := Color(1, 1, 1) ## (TreeBuilder.tint_low / tint_heights)
var tint_heights := Vector2.ZERO ## (shares of the stem's height, bole and leader)
var dead_tint := Color(0.74, 0.72, 0.68)
var log_tint := Color(0.78, 0.82, 0.7)
var shadow := [7.5, 4.0, 14.0, 0.45] ## the shadow stand-in: crown radius, bottom, top, stalk radius
## As a prop, what differs from the oak's (OakTree.PROPS): kind ("all" for
## every kind) -> PropKind settings (variant_props).
var props := {}
## The bark's colour far off (bark.gdshader: far_color; and so its far-off
## card's): alpha 0, its texture's mean.
var far_bark := Color(0, 0, 0, 0)
## The least radius (m) a limb must have where it leaves the trunk to be
## climbed (and stood on).
var climb_limb_r := 0.05
var fruit := "" ## The item its grown trees bear (Items: "pawpaw", ...), "" none.

var _cache := {} # variant -> [mesh, lods]
var _shadows := {}
var _climb_cache := {}
var _bark_mats := {}
var _leaf_mats := {}


func _init(species: String, settings: Dictionary, vars: Array) -> void:
	name = species
	variants = vars
	for k in settings:
		set(k, settings[k])


func kind_of(v: int) -> String:
	return variants[posmod(v, variants.size())].get("kind", "tree")


# ---- materials --------------------------------------------------------------

## The oak's bark material for this level and kind (its lichen and moss),
## with this species' bark texture.
func bark_material(level: int, kind: String) -> ShaderMaterial:
	var key := [level, kind]
	if not _bark_mats.has(key):
		var m := OakTree.bark_material(level, kind).duplicate() as ShaderMaterial
		m.set_shader_parameter("bark_tex", OakTree._texture(bark_tex))
		if far_bark.a > 0.0:
			m.set_shader_parameter("far_color", Vector3(far_bark.r, far_bark.g, far_bark.b))
		_bark_mats[key] = m
		OakTree._bark_mats[[name, level, kind]] = m # (told the night, the biomes, the levels' fade with the oak's)
	return _bark_mats[key]


func leaf_material(level: int) -> ShaderMaterial:
	if not _leaf_mats.has(level):
		var m := OakTree.leaf_material(level).duplicate() as ShaderMaterial
		m.set_shader_parameter("leaf_tex", OakTree._texture(leaf_tex))
		_leaf_mats[level] = m
		OakTree._leaf_mats[[name, level]] = m
	return _leaf_mats[level]


# ---- models -----------------------------------------------------------------

func build(v: int) -> Mesh:
	return _models(v)[0]


func build_lods(v: int) -> Array[Mesh]:
	return _models(v)[1]


## The levels of detail as the oak's (OakTree.LOD): branches and clump
## cards, then limbs and fewer, bigger clumps, then the stem and a few.
func _models(v: int) -> Array:
	v = posmod(v, variants.size())
	if not _cache.has(v):
		var k := kind_of(v)
		var b := [bark_material(0, k), bark_material(1, k), bark_material(2, k), bark_material(3, k)]
		var l := [leaf_material(0), leaf_material(1), leaf_material(2), leaf_material(3)]
		var tb: TreeBuilder
		var lods: Array[Mesh]
		var L: Array = OakTree.LOD
		match k:
			"stump":
				tb = grow_stump(variants[v])
				lods = [tb.lod(b[1], l[1], 0, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			"log":
				tb = grow_log(variants[v])
				lods = [tb.lod(b[1], l[1], 1, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			"dead":
				tb = grow_dead(variants[v])
				lods = [tb.lod(b[1], l[1], 2, 2, 0, 1.0), tb.lod(b[2], l[2], 1, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			_:
				tb = grow(v)
				lods = [tb.lod(b[1], l[1], 2, 2, 4, card_size / 0.7, L[0]), tb.lod(b[2], l[2], 1, 3, 12, 2.0 * card_size / 0.7, L[1]), tb.lod(b[3], l[3], 0, 4, 36, 3.2 * card_size / 0.7, L[2])]
		# a standing tree (live or dead) far off: one card, its photograph
		# (OakTree._impostor, ImpostorBaker), in place of the last level's
		# mesh; the meshes kept whole for the felled (cut_meshes)
		var solid := lods.duplicate()
		if k in ["tree", "dead"]:
			lods[2] = OakTree._impostor(v, lods[1], name)
		_cache[v] = [tb.build(b[0], l[0], 12.0), lods, solid]
	return _cache[v]


## The shadow stand-in for a standing tree or a sapling (as the oak's).
func build_shadow(v: int) -> Mesh:
	var k := kind_of(v)
	if not k in ["tree", "sapling"]:
		return null
	if not _shadows.has(k):
		if k == "tree":
			_shadows[k] = TreeBuilder.shadow_proxy(shadow[0], shadow[1], shadow[2], shadow[3], 23)
		else:
			_shadows[k] = TreeBuilder.shadow_proxy(shadow[0] * 0.18, shadow[1] * 0.25, shadow[2] * 0.26, 0.05, 29)
	return _shadows[k]


## As a prop: the oak's settings for the kind (OakTree.PROPS: its share,
## shadows, footing, the logs out of the swamp, ...), then the species' own
## (props).
func variant_props(v: int) -> Dictionary:
	var p: Dictionary = OakTree.PROPS[kind_of(v)].duplicate()
	p.strays = true
	p.lod_distances = PackedFloat32Array(OakTree.LOD)
	p.view_distance = OakTree.VIEW
	# the species' own: for every kind ("all"), then for this kind
	for k in ["all", kind_of(v)]:
		var o: Dictionary = props.get(k, {})
		for key in o:
			p[key] = o[key]
	return p


## What can be stood on (as OakTree.build_walk).
func build_walk(v: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	v = posmod(v, variants.size())
	var k := kind_of(v)
	if k == "stump":
		var st := grow_stump(variants[v])
		var h := st.pos[st.branches[0][-1]].y
		var r: float = variants[v].get("r", 0.5) * 1.1
		out.append_array([0.0, 0.0, 0.0, 0.0, h, 0.0, r, r])
		return out
	if k in ["tree", "dead"]:
		var lines := _climb_lines(v)
		for li in range(1, lines.size()):
			var l := lines[li]
			for i in range(4, l.size(), 4):
				out.append_array([l[i - 4], l[i - 3], l[i - 2], l[i], l[i + 1], l[i + 2], -l[i - 1], l[i + 3]])
		return out
	if k != "log":
		return out
	var tb := grow_log(variants[v])
	var b := tb.branches[0]
	for i in b.size() - 1:
		var a := tb.pos[b[i]]
		var e := tb.pos[b[i + 1]]
		out.append_array([a.x, a.y, a.z, e.x, e.y, e.z, tb.radius[b[i]], tb.radius[b[i + 1]]])
	return out


## What can be climbed (as OakTree.build_climb).
func build_climb(v: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for line in _climb_lines(v):
		out.append(line.size() / 4)
		out.append_array(line)
	return out


func _climb_lines(v: int) -> Array[PackedFloat32Array]:
	v = posmod(v, variants.size())
	if _climb_cache.has(v):
		return _climb_cache[v]
	var lines: Array[PackedFloat32Array] = []
	var tb: TreeBuilder
	match kind_of(v):
		"tree":
			tb = grow(v)
		"dead":
			tb = grow_dead(variants[v])
	if tb:
		tb.fit_radii()
		var order: Array[PackedInt32Array] = []
		for br in tb.branches:
			if br.size() > 1 and br[0] == 0:
				order.push_front(br)
			elif br.size() > 1 and tb.level[br[1]] == 1 and tb.parent[br[0]] >= 0: # (not a cypress's knee, standing alone)
				order.append(br)
		for br in order:
			# a limb only if it's stout enough to hold you where it leaves the
			# trunk (climb_limb_r: a pine's many little whorled branches
			# got in the way)
			if br[0] != 0 and tb.radius[br[1]] < climb_limb_r:
				continue
			var line := PackedFloat32Array()
			for i in br:
				if tb.radius[i] < 0.05 and line.size() >= 8:
					break
				var p := tb.pos[i]
				line.append_array([p.x, p.y, p.z, tb.radius[i]])
			if line.size() >= 8:
				lines.append(line)
	_climb_cache[v] = lines
	return lines


# ---- felling and picking -------------------------------------------------------

## Whether variant v can be felled (an axe: Felling): the standing ones.
func choppable(v: int) -> bool:
	return kind_of(v) in ["tree", "dead", "sapling"]


## A standing variant's trunk radius at its foot (m, at scale 1).
func trunk_radius(v: int) -> float:
	var P: Dictionary = variants[posmod(v, variants.size())]
	if P.has("trunk_r"):
		return P.trunk_r
	if P.has("like"):
		return variants[P.like].get("trunk_r", 0.3)
	return 0.3


## What fruit variant v bears (an item id, Items), "" none: a standing,
## grown tree's, if the species bears any (fruit).
func fruit_of(v: int) -> String:
	return fruit if kind_of(v) == "tree" else ""


var _fruit_spots := {}


## Where variant v's fruit hang (its own space, at scale 1): under twigs in
## the outer, lower two thirds of its crown, as many places as it can bear,
## in a fixed order (Foraging hangs the first so many, as many as are left).
func fruit_spots(v: int) -> PackedVector3Array:
	v = posmod(v, variants.size())
	if not _fruit_spots.has(v):
		var out := PackedVector3Array()
		if fruit_of(v) != "":
			var tb := grow(v)
			var c: Array = variants[v].crown
			var top: float = c[1]
			var bottom: float = c[2]
			var r := RandomNumberGenerator.new()
			r.seed = int(variants[v].seed) * 7 + 3
			var spots: Array[Vector3] = []
			for sp in tb.sprigs:
				var q: Vector3 = tb.pos[sp[0]]
				if q.y > bottom + 0.3 and q.y < bottom + (top - bottom) * 0.66 and Vector2(q.x, q.z).length() > 0.5:
					spots.append(q)
			# a few spread out: each far from those before
			for i in 24:
				if spots.is_empty():
					break
				var best := spots[r.randi() % spots.size()]
				var far := -1.0
				for t in 6:
					var cand := spots[r.randi() % spots.size()]
					var d := INF
					for o in out:
						d = minf(d, o.distance_to(cand))
					if d > far:
						far = d
						best = cand
				out.append(best + Vector3(r.randf_range(-0.05, 0.05), -0.1, r.randf_range(-0.05, 0.05))) # (hanging below the twig)
		_fruit_spots[v] = out
	return _fruit_spots[v]


var _sections := {}


## [mean radius, outline] of the trunk across y = h (as OakTree._section_at).
func section_at(v: int, h: float) -> Array:
	var key := [posmod(v, variants.size()), snappedf(h, 0.01)]
	if not _sections.has(key):
		var arrays := build(v).surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var mid := Vector2.ZERO
		var near: Array[Vector2] = []
		var reach := trunk_radius(v) * 2.5
		for i in range(0, idx.size(), 3):
			for e in 3:
				var a := verts[idx[i + e]]
				var b := verts[idx[i + (e + 1) % 3]]
				if (a.y - h) * (b.y - h) < 0.0:
					var p := a.lerp(b, (h - a.y) / (b.y - a.y))
					if Vector2(p.x, p.z).length() < reach:
						near.append(Vector2(p.x, p.z))
						mid += Vector2(p.x, p.z)
		var r := trunk_radius(v)
		var outline := PackedVector2Array()
		if near.size() > 4:
			mid /= near.size()
			r = 0.0
			for q in near:
				r += q.distance_to(mid)
			r /= near.size()
			near.sort_custom(func(a: Vector2, b: Vector2) -> bool: return (a - mid).angle() < (b - mid).angle())
			outline.append(mid)
			for q in near:
				outline.append(q)
		_sections[key] = [r, outline]
	return _sections[key]


var _cut_meshes := {}


## The cut variant of v's meshes ([mesh, lods]), as OakTree.cut_meshes: the
## bark compiled with BARK_CUT (a notch a real hollow, a felled foot a cut face).
func cut_meshes(v: int) -> Array:
	v = posmod(v, variants.size())
	if not _cut_meshes.has(v):
		var out := []
		_models(v)
		for m: Mesh in [build(v)] + (_cache[v][2] as Array): # (a felled tree far off: its mesh, not the standing tree's card)
			var c := m.duplicate() as ArrayMesh
			for si in c.get_surface_count():
				var mat := c.surface_get_material(si) as ShaderMaterial
				if mat and mat.shader and mat.shader.resource_path == "res://shaders/render/bark.gdshader":
					c.surface_set_material(si, OakTree.cut_material(mat))
			out.append(c)
		_cut_meshes[v] = [out[0], out.slice(1)]
	return _cut_meshes[v]


# ---- skeletons --------------------------------------------------------------

func _builder() -> TreeBuilder:
	var tb := TreeBuilder.new()
	tb.card_size = card_size
	return tb


## A stump, snapped off 0.75-1.1 m up, the roots flaring.
func grow_stump(P: Dictionary) -> TreeBuilder:
	var tb := _builder()
	tb.rng.seed = P.seed
	tb.flare = P.get("flare", 0.5)
	tb.bark_tint = bark_tint * Color(0.92, 0.9, 0.86)
	tb.splinter = true
	var r0: float = P.get("r", 0.5)
	var h := tb.rng.randf_range(0.75, 1.1)
	var nodes := PackedInt32Array([tb.add_node(Vector3.ZERO, -1, 0)])
	for i in 3:
		nodes.append(tb.add_node(Vector3(0.0, h * (i + 1) / 3.0, 0.0), nodes[i], 0))
	for n in nodes:
		tb.set_radius(n, r0 - 0.04 * tb.pos[n].y)
	tb.add_branch(nodes, false, true, 0.45 * r0 / 0.5)
	return tb


## A fallen trunk lying along x, a little bowed, broken at both ends, the
## stubs of a few limbs; the bark greyer and greener.
func grow_log(P: Dictionary) -> TreeBuilder:
	var tb := _builder()
	var rng := tb.rng
	rng.seed = P.seed
	tb.flare = 0.0
	tb.splinter = true
	tb.bark_tint = log_tint
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
	var stubs: Vector2i = P.get("stubs", Vector2i(2, 4))
	for k in rng.randi_range(stubs.x, stubs.y):
		var at := nodes[rng.randi_range(2, n - 2)]
		var around := rng.randf_range(-1.2, 1.2) + (PI if rng.randf() < 0.3 else 0.0)
		var d := Vector3(rng.randf_range(-0.4, 0.6), cos(around), sin(around)).normalized()
		if d.y < -0.2:
			d.y = -d.y
		var len := rng.randf_range(0.35, 1.1)
		var r := rng.randf_range(0.07, 0.12) * r0 / 0.42
		var stub := PackedInt32Array([at])
		for i in 2:
			stub.append(tb.add_node(tb.pos[at] + d * len * (i + 1) / 2.0, stub[i], 1))
			tb.set_radius(stub[i + 1], r * (1.0 - 0.25 * i))
		tb.add_branch(stub, false, true, r * 0.9)
	return tb


## A dead tree still standing: the skeleton of the standing variant it's
## "like", stripped (twigs and leaves gone, most branches and some limbs
## snapped off), the bark weathered grey.
func grow_dead(D: Dictionary) -> TreeBuilder:
	var P: Dictionary = variants[D.like].duplicate()
	for key in D:
		if key != "kind" and key != "like":
			P[key] = D[key]
	var tb := _grow_tree(P)
	var rng := tb.rng
	tb.sprigs.clear()
	tb.bark_tint = dead_tint
	tb.tint_heights = Vector2.ZERO
	tb.sways = false
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


## The skeleton of standing variant v (a tree or a sapling).
func grow(v: int) -> TreeBuilder:
	return _grow_tree(variants[posmod(v, variants.size())])


func _grow_tree(P: Dictionary) -> TreeBuilder:
	if P.get("whorls", 0) > 0:
		return _grow_conifer(P)
	var tb := _builder()
	tb.rng.seed = P.seed
	var rng := tb.rng
	tb.flare = 0.45 + P.trunk_r * 0.3
	tb.bark_tint = bark_tint
	if P.get("kind", "tree") == "tree": # (a sapling's bark is young all over)
		tb.tint_low = tint_low
		tb.tint_heights = tint_heights * (P.trunk_h + P.leader_h) # (as shares of the stem's height)
	var lean_az := rng.randf() * TAU
	var lean_dir := Vector3(cos(lean_az), 0.0, sin(lean_az))
	var c: Array = P.crown
	P = P.duplicate()
	P.env_centre = Vector3(0.0, (c[1] + c[2]) * 0.5, 0.0) + lean_dir * (P.lean / 11.0) * 2.0
	P.env_radii = Vector3(c[0], (c[1] - c[2]) * 0.5, c[0])
	# the crown's lumps: where it reaches out further (irregular)
	var lumps: Array[Vector3] = []
	for i in 6:
		lumps.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 1), rng.randf_range(-1, 1)).normalized())
	P.lumps = lumps
	# the stem: a clear bole, then a leader the limbs leave one by one
	var d := (Vector3.UP + lean_dir * tan(deg_to_rad(P.lean))).normalized()
	var root := tb.add_node(Vector3.ZERO, -1, 0)
	var stem := PackedInt32Array([root])
	var total_h: float = P.trunk_h + P.leader_h
	var steps := maxi(ceili(total_h / seg[0]), 3)
	var p := Vector3.ZERO
	var dirs: Array[Vector3] = [d]
	for i in steps:
		d = _turn(rng, d, crook[0] * (1.0 if p.y < P.trunk_h else 2.5))
		d = (d + Vector3.UP * 0.04).normalized()
		p += d * total_h / steps
		stem.append(tb.add_node(p, stem[stem.size() - 1], 0))
		dirs.append(d)
	var first := 1
	while first < stem.size() - 1 and tb.pos[stem[first]].y < P.trunk_h:
		first += 1
	var n_limbs: int = P.limbs
	var az := rng.randf() * TAU
	var forks: int = P.get("forks", 0) # (the first few limbs as big as leaders, all from the bole's top: a trunk that divides low)
	for k in n_limbs:
		var f := float(k) / maxf(n_limbs - 1, 1)
		var at := clampi(first + roundi(f * (stem.size() - 1 - first)), 1, stem.size() - 1)
		var tilt := deg_to_rad(lerpf(P.limb_angle, P.limb_angle * 0.55, f) + rng.randf_range(-6.0, 6.0))
		var len: float = P.limb_len * lerpf(1.0, 0.65, f) * rng.randf_range(0.85, 1.1)
		if opposite and k % 2 == 1:
			az += PI + rng.randf_range(-0.25, 0.25) # (the other of the pair, opposite, at the same node)
			at = clampi(first + roundi(float(k - 1) / maxf(n_limbs - 1, 1) * (stem.size() - 1 - first)), 1, stem.size() - 1)
		elif opposite:
			az += PI * 0.5 + rng.randf_range(-0.3, 0.3) # (each pair square to the last)
		else:
			az += deg_to_rad(137.5) + rng.randf_range(-0.3, 0.3)
		if k < forks:
			at = first
			tilt = deg_to_rad(P.get("fork_angle", 30.0) + rng.randf_range(-5.0, 5.0))
			len = P.limb_len * P.get("fork_len", 1.4) * rng.randf_range(0.9, 1.1)
		var dir := Vector3(sin(tilt) * cos(az), cos(tilt), sin(tilt) * sin(az))
		if P.lean > 0.0:
			var toward := Vector2(dir.x, dir.z).normalized().dot(Vector2(lean_dir.x, lean_dir.z))
			len *= 1.0 + 0.25 * toward
		_branch(tb, P, stem[at], dir, len, 1, dirs[at])
	_branch(tb, P, stem[stem.size() - 1], _turn(rng, dirs[dirs.size() - 1], 0.2), P.limb_len * 0.5, 1, dirs[dirs.size() - 1])
	tb.add_branch(stem)
	tb.compute_radii(P.trunk_r, tip_r)
	return tb


## A conifer: the leader straight up to the top, whorls of branches up it
## through the crown, each as long as the crown's profile there; then the
## dead stubs below the crown and the knees round the foot.
func _grow_conifer(P: Dictionary) -> TreeBuilder:
	var tb := _builder()
	tb.rng.seed = P.seed
	var rng := tb.rng
	tb.flare = P.get("flare", 0.45 + P.trunk_r * 0.3)
	tb.bark_tint = bark_tint
	if P.get("kind", "tree") == "tree":
		tb.tint_low = tint_low
		tb.tint_heights = tint_heights * (P.trunk_h + P.leader_h)
	var lean_az := rng.randf() * TAU
	var lean_dir := Vector3(cos(lean_az), 0.0, sin(lean_az))
	var c: Array = P.crown
	P = P.duplicate()
	P.lumps = []
	P.cone_top = c[1]
	P.cone_bottom = c[2]
	P.cone_r = c[0]
	P.lean_dir = lean_dir
	var d := (Vector3.UP + lean_dir * tan(deg_to_rad(P.lean))).normalized()
	var root := tb.add_node(Vector3.ZERO, -1, 0)
	var stem := PackedInt32Array([root])
	var total_h: float = P.trunk_h + P.leader_h
	var steps := maxi(ceili(total_h / seg[0]), 3)
	var p := Vector3.ZERO
	var dirs: Array[Vector3] = [d]
	for i in steps:
		d = _turn(rng, d, crook[0])
		d = (d + Vector3.UP * 0.06).normalized()
		p += d * total_h / steps
		stem.append(tb.add_node(p, stem[stem.size() - 1], 0))
		dirs.append(d)
	var whorls: int = P.whorls
	var per: int = P.get("per_whorl", 4)
	var az := rng.randf() * TAU
	for w in whorls:
		var f := (float(w) + rng.randf_range(-0.3, 0.3)) / maxf(whorls - 1, 1)
		f = clampf(f, 0.0, 1.0)
		var y := lerpf(c[2], c[1] * 0.97, f)
		var at := 1
		while at < stem.size() - 1 and tb.pos[stem[at]].y < y:
			at += 1
		var len: float = P.limb_len * _profile(P, f)
		if len < seg[1] * 1.2:
			continue
		var n := per + rng.randi_range(-1, 1)
		az += rng.randf_range(0.4, 1.2)
		for k in n:
			var a := az + TAU * (k + rng.randf_range(-0.2, 0.2)) / n
			# lower ones droop more; the top ones lift
			var tilt := deg_to_rad(lerpf(P.limb_angle + P.get("droop_low", 10.0), P.limb_angle - P.get("lift_top", 25.0), f) + rng.randf_range(-6.0, 6.0))
			var dir := Vector3(sin(tilt) * cos(a), cos(tilt), sin(tilt) * sin(a))
			_branch(tb, P, stem[at], dir, len * rng.randf_range(0.8, 1.1), 1, dirs[at])
	tb.add_branch(stem)
	tb.compute_radii(P.trunk_r, tip_r)
	# the snapped stubs of the branches it's shed, up the bare bole
	for k in P.get("stubs", 0):
		var y := rng.randf_range(1.5, c[2] - 0.5)
		var at := 1
		while at < stem.size() - 1 and tb.pos[stem[at]].y < y:
			at += 1
		var a := rng.randf() * TAU
		var dir := Vector3(cos(a), rng.randf_range(-0.35, 0.05), sin(a)).normalized()
		var r := rng.randf_range(0.015, 0.035)
		var nodes := PackedInt32Array([stem[at]])
		var l := rng.randf_range(0.15, 0.6)
		var q := tb.pos[stem[at]]
		for i in 2:
			nodes.append(tb.add_node(q + dir * l * (i + 1) / 2.0, nodes[i], 1))
			tb.set_radius(nodes[i + 1], r * (1.0 - 0.3 * i))
		tb.add_branch(nodes, false, true, r * 1.5)
	# knees: knobs of root up out of the ground round the foot
	for k in P.get("knees", 0):
		var a := rng.randf() * TAU
		var dist: float = P.trunk_r * 2.0 + rng.randf_range(0.5, 3.5)
		var at := Vector3(cos(a) * dist, -0.15, sin(a) * dist)
		var h := rng.randf_range(0.25, 0.9)
		var r := rng.randf_range(0.07, 0.15) * (0.6 + h)
		var nodes := PackedInt32Array([tb.add_node(at, -1, 1)])
		var bend := Vector3(rng.randf_range(-0.1, 0.1), 0.0, rng.randf_range(-0.1, 0.1))
		for i in 3:
			nodes.append(tb.add_node(at + Vector3.UP * h * (i + 1) / 3.0 + bend * (i + 1) * h, nodes[i], 1))
		for i in nodes.size():
			tb.set_radius(nodes[i], r * (1.0 - 0.45 * float(i) / 3.0))
		tb.add_branch(nodes)
	return tb


## A conifer's crown's width at f (0 its bottom .. 1 its top), 0..1.
func _profile(P: Dictionary, f: float) -> float:
	match P.get("profile", "cone"):
		"narrow":
			return 0.25 + 0.75 * pow(1.0 - f, 0.8) if f < 0.97 else 0.0
		"flat": # (wide nearly to the top, then cut off: a flat top)
			return sqrt(maxf(1.0 - pow(f, 9.0), 0.0)) * (0.85 + 0.15 * (1.0 - f))
	return pow(1.0 - f, 0.9)


## Whether q is out past the crown's edge (lv: a limb may overreach a little).
func _outside(P: Dictionary, q: Vector3, lv: int) -> bool:
	if P.has("cone_top"):
		var f: float = (q.y - P.cone_bottom) / maxf(P.cone_top - P.cone_bottom, 0.1)
		var r: float = P.cone_r * _profile(P, clampf(f, 0.0, 1.0)) * (1.12 if lv == 1 else 1.0) + 0.3
		return f > 1.02 or Vector2(q.x, q.z).length() > r
	var e: Vector3 = (q - P.env_centre) / P.env_radii
	if e.y < 0.0:
		e.y *= 0.35
	return e.length() > (1.08 if lv == 1 else 1.0) * _reach(P, e)


## How far out the crown reaches the way e points (1: its ellipsoid), lumpy
## as irregular says.
func _reach(P: Dictionary, e: Vector3) -> float:
	if irregular <= 0.0:
		return 1.0
	var n := e.normalized()
	var most := 0.0
	for l: Vector3 in P.lumps:
		most = maxf(most, maxf(n.dot(l) - 0.55, 0.0) / 0.45)
	return 1.0 - 0.22 * irregular + 0.45 * irregular * most


func _branch(tb: TreeBuilder, P: Dictionary, from: int, dir: Vector3, length: float, lv: int, parent_dir := Vector3.ZERO) -> void:
	var rng := tb.rng
	var steps := maxi(ceili(length / seg[lv]), 2)
	var nodes := PackedInt32Array([from])
	var p := tb.pos[from]
	var target := dir
	var d := dir if parent_dir == Vector3.ZERO else parent_dir.slerp(dir, 0.3).normalized()
	var spiral := rng.randf() * TAU
	for i in steps:
		var t := float(i + 1) / steps
		if i < 4:
			d = d.slerp(target, 0.4).normalized()
		d = _turn(rng, d, crook[lv])
		var u: float = up[lv] - (P.droop * (1.0 - t) if lv == 1 else 0.0)
		if p.y < P.trunk_h * 0.5:
			u = maxf(u, 0.25)
		d = (d + Vector3.UP * u).normalized()
		target = (target + Vector3.UP * u * 0.5).normalized()
		var q := p + d * length / steps
		if _outside(P, q, lv) and i > 0:
			break
		p = q
		var node := tb.add_node(p, nodes[nodes.size() - 1], lv)
		nodes.append(node)
		if lv < 3:
			var start := 0.3 if lv == 1 else 0.15
			if t > start:
				if opposite:
					spiral += PI * 0.5 + rng.randf_range(-0.2, 0.2) # (pairs, each square to the last)
				for c in 2:
					if opposite:
						spiral += PI
					else:
						spiral += 2.4 + rng.randf_range(-0.3, 0.3)
					var cd := _side(d, spiral, child_angle[lv + 1] + rng.randf_range(-0.2, 0.2))
					cd = _outward(cd, p, 0.35)
					if cd.y < -0.25:
						cd = Vector3(cd.x, -0.25, cd.z).normalized()
					var cl: float = (P.branch_len if lv == 1 else P.twig_len) * (1.0 - 0.45 * t) * rng.randf_range(0.75, 1.2)
					if rng.randf() < (0.8 if lv == 1 else 0.7):
						_branch(tb, P, node, cd, cl, lv + 1, d)
			if lv == 2 and t > 0.4 and rng.randf() < 0.5:
				tb.add_sprig(node, _outward(_side(d, rng.randf() * TAU, 0.8), p, 0.4))
		elif t > 0.25 and rng.randf() < 0.7:
			tb.add_sprig(node, _outward(_side(d, rng.randf() * TAU, rng.randf_range(0.5, 1.1)), p, 0.3))
	if lv >= 2:
		tb.add_sprig(nodes[nodes.size() - 1], _outward(_turn(rng, d, 0.5), p, 0.3))
	tb.add_branch(nodes)


static func _turn(rng: RandomNumberGenerator, d: Vector3, amount: float) -> Vector3:
	return _side(d, rng.randf() * TAU, rng.randf() * amount)


static func _side(d: Vector3, around: float, angle: float) -> Vector3:
	var u := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
	var w := d.cross(u)
	var s := u * cos(around) + w * sin(around)
	return (d * cos(angle) + s * sin(angle)).normalized()


static func _outward(d: Vector3, p: Vector3, k: float) -> Vector3:
	var o := Vector3(p.x, 0.0, p.z)
	if o.length() < 0.01:
		return d
	return (d + o.normalized() * k).normalized()
