class_name TreeBuilder
extends RefCounted
## Turns a tree's skeleton into meshes; a species script (OakTree, ...) grows
## the skeleton by its own rules and says how to dress it.
##
## The skeleton: nodes (points, each with its parent node, so a parent always
## comes before its children), branches (runs of nodes, the first one where
## the branch leaves its parent) and sprigs (where leaves grow: a node and a
## direction). Branch radii follow the pipe model: a branch's cross-section
## is the sum of its children's, so the radius at a node goes with the root
## of the number of sprigs it carries.
##
## Out come two surfaces, bark (tubes, the texture wrapped round them) and
## leaves (cards: a sprig of leaves on each, its normal bent toward "out
## from the middle of the crown", so the crown shades as a whole and not card
## by card); and simpler versions for further off (lod()).

var pos := PackedVector3Array()
var parent := PackedInt32Array()
var level := PackedInt32Array()
var radius := PackedFloat32Array()
var branches: Array[PackedInt32Array] = []
var caps: Array = [] # per branch: [cap at the start, cap at the end, how jagged the end is (m)]
var sprigs: Array = [] # [node, direction]
var rng := RandomNumberGenerator.new()

# dressing
var bark_tile := 0.6 ## m of bark per texture repeat (round and along)
var card_size := 0.7 ## m, a sprig card's width
var card_crop := 0.25 ## the top of each sprig tile that is empty (cropped off)
var sprig_tiles := 4 ## atlas tiles 0..sprig_tiles-1 are sprigs; the next ones clumps
var clump_tiles := 4
var atlas := Vector2i(4, 2)
var flare := 0.5 ## root flare at the base of the trunk (fraction of its radius)
var bark_tint := Color(1, 1, 1) ## (dead wood: greyer, greener)
var splinter := false ## broken ends are snapped wood: tall splinters round a sunken middle


func add_node(p: Vector3, par: int, lv: int) -> int:
	pos.append(p)
	parent.append(par)
	level.append(lv)
	return pos.size() - 1


## A branch along nodes. Capped ends are cut or broken off (end grain shows;
## jag: how ragged a broken end is, m); otherwise the end tapers shut.
func add_branch(nodes: PackedInt32Array, cap_start := false, cap_end := false, jag := 0.0) -> void:
	if nodes.size() >= 2:
		branches.append(nodes)
		caps.append([cap_start, cap_end, jag])


## Sets the radius of every node by hand (dead wood: no sprigs to go by).
func set_radius(node: int, r: float) -> void:
	if radius.size() < pos.size():
		radius.resize(pos.size())
	radius[node] = r


func add_sprig(node: int, dir: Vector3) -> void:
	sprigs.append([node, dir.normalized()])


## Radii by the pipe model: trunk_r at the root, never thinner than tip_r.
const PIPE_EXPONENT := 2.4 ## (2: da Vinci's rule; measured trees run 2-3)


func compute_radii(trunk_r: float, tip_r: float) -> void:
	var w := PackedFloat32Array()
	w.resize(pos.size())
	for s in sprigs:
		w[s[0]] += 1.0
	for i in range(pos.size() - 1, 0, -1):
		if parent[i] >= 0:
			w[parent[i]] += w[i]
	radius.resize(pos.size())
	var total := maxf(w[0], 1.0)
	for i in pos.size():
		radius[i] = maxf(trunk_r * pow(w[i] / total, 1.0 / PIPE_EXPONENT), tip_r)
	# the radius drops in a step where each child leaves; real wood tapers
	# all along: never thicker further out, and smoothed along each branch
	for b in branches:
		var r := PackedFloat32Array()
		for j in range(1, b.size()):
			r.append(radius[b[j]] if j == 1 else minf(radius[b[j]], r[r.size() - 1]))
		for _k in 3:
			var q := r.duplicate()
			for j in range(1, r.size() - 1):
				q[j] = (r[j - 1] + 2.0 * r[j] + r[j + 1]) * 0.25
			if r.size() > 1:
				q[r.size() - 1] = (r[r.size() - 2] + r[r.size() - 1]) * 0.5
			r = q
		for j in range(1, b.size()):
			radius[b[j]] = maxf(r[j - 1], tip_r)


## The whole tree: [bark, leaves] surfaces in one mesh. thin_from: the
## distance (m) from which the leaf cards thin out (see _card()).
func build(bark_mat: Material, leaf_mat: Material, thin_from := 12.0) -> ArrayMesh:
	return _mesh(bark_mat, leaf_mat, 99, 1.0, 1, 0, thin_from)


## A simpler version: branches up to max_level, a 1/thin share of the sprigs
## as clump cards (clump_size m across), sides_div fewer sides round each
## branch; its leaves thin out from thin_from m on (where it starts).
func lod(bark_mat: Material, leaf_mat: Material, max_level: int, sides_div: int, thin: int, clump_size: float, thin_from := 50.0) -> ArrayMesh:
	return _mesh(bark_mat, leaf_mat, max_level, clump_size, sides_div, thin, thin_from)


func _mesh(bark_mat: Material, leaf_mat: Material, max_level: int, clump_size: float, sides_div: int, thin: int, thin_from: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	_bark_count = 0
	_leaf_count = 0
	_thin_from = thin_from
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in branches.size():
		var b := branches[i]
		if level[b[1]] <= max_level:
			_tube(bark, b, sides_div, caps[i])
	bark.commit(mesh)
	mesh.surface_set_material(0, bark_mat)
	if sprigs.is_empty():
		return mesh
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	leaves.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var centre := _crown_centre()
	var crown_r := _crown_radius(centre)
	var r := RandomNumberGenerator.new()
	r.seed = rng.seed + 77
	for i in sprigs.size():
		var s: Array = sprigs[i]
		var p: Vector3 = pos[s[0]]
		var d: Vector3 = s[1]
		if thin <= 0:
			var tile := r.randi() % sprig_tiles
			var spin := r.randf() * TAU
			_card(leaves, p, d, spin, card_size, tile, centre, crown_r, false, r)
			_card(leaves, p, d, spin + r.randf_range(1.1, 2.0), card_size, (tile + 1) % sprig_tiles, centre, crown_r, false, r)
		elif r.randi() % thin == 0:
			var tile := sprig_tiles + r.randi() % clump_tiles
			var at := p + d * clump_size * 0.3
			var spin := r.randf() * TAU
			_card(leaves, at, d, spin, clump_size, tile, centre, crown_r, true, r)
			_card(leaves, at, d, spin + PI * 0.5, clump_size, sprig_tiles + (tile + 1) % clump_tiles, centre, crown_r, true, r)
	leaves.commit(mesh)
	mesh.surface_set_material(1, leaf_mat)
	return mesh


func _sides(r: float, div: int) -> int:
	if splinter and r > 0.25:
		return maxi(28 / div, 6) # (enough rim for the splinters)
	var n := 12 if r > 0.25 else (9 if r > 0.1 else (6 if r > 0.04 else (4 if r > 0.015 else 3)))
	return maxi(n / div, 3)


## A tube along a branch: a ring at every node (parallel-transported frames,
## so it doesn't twist), the bark texture wrapped round a whole number of
## times.
func _tube(st: SurfaceTool, b: PackedInt32Array, sides_div: int, cap: Array) -> void:
	if radius[b[1]] < 0.03 and b.size() > 3:
		# thin: a ring at every other node is enough
		var thin := PackedInt32Array()
		for i in b.size():
			if i % 2 == 0 or i == b.size() - 1 or i == 1:
				thin.append(b[i])
		b = thin
	var n := b.size()
	var r0 := radius[b[1]]
	var sides := _sides(r0, sides_div)
	var wraps := maxf(roundf(TAU * r0 / bark_tile), 1.0)
	var t_prev := Vector3.ZERO
	var nrm := Vector3.ZERO
	var along := 0.0
	var trunk := level[b[1]] == 0
	var rings: Array = []
	for i in n:
		var p := pos[b[i]]
		var t := (pos[b[mini(i + 1, n - 1)]] - pos[b[maxi(i - 1, 0)]]).normalized()
		if i == 0:
			nrm = t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		else:
			nrm = (nrm - t * nrm.dot(t)).normalized()
			along += p.distance_to(pos[b[i - 1]])
		var bin := nrm.cross(t)
		# the first ring sits inside the parent at the child's own radius;
		# the last closes almost to a point
		var r := radius[b[maxi(i, 1)]] if not cap[0] else radius[b[i]]
		if i == 0 and not cap[0]:
			r *= 1.15 # (a collar where it leaves the parent)
		if i == n - 1 and not cap[1]:
			r *= 0.35
		rings.append([p, t, nrm, bin, r, along])
	for i in n:
		var g: Array = rings[i]
		for k in sides + 1:
			var a := TAU * k / sides
			var dir: Vector3 = g[2] * cos(a) + g[3] * sin(a)
			var rr: float = g[4]
			if trunk:
				# root flare: wider at the foot, in buttresses
				var y: float = g[0].y
				var f := flare * exp(-maxf(y, 0.0) / 0.6)
				rr *= 1.0 + f * (1.0 + 0.35 * cos(5.0 * a + 0.7))
			var at: Vector3 = g[0] + dir * rr
			if i == n - 1 and cap[1]:
				at += g[1] * _jag(a, cap[2], splinter)
			st.set_uv(Vector2(float(k) / sides * wraps, g[5] / bark_tile))
			# y: how much it sways in the wind (the twigs, not the stout wood)
			st.set_uv2(Vector2(0.0, clampf((0.05 - g[4]) / 0.04, 0.0, 1.0)))
			st.set_normal(dir)
			st.set_color(bark_tint)
			st.add_vertex(at)
	# (front faces are clockwise seen from outside)
	var first := _bark_count
	for i in n - 1:
		for k in sides:
			var a := first + i * (sides + 1) + k
			var c := a + sides + 1
			for j in [a, a + 1, c + 1, a, c + 1, c]:
				st.add_index(j)
	_bark_count += n * (sides + 1)
	if cap[0]:
		_cap(st, rings[0], sides, -1.0, 0.0, trunk)
	if cap[1]:
		_cap(st, rings[n - 1], sides, 1.0, cap[2], trunk)


## A cut or broken end: a disc across the branch (UV2.x = 1: the bark shader
## draws end grain, UV the position across it, -1..1).
func _cap(st: SurfaceTool, g: Array, sides: int, facing: float, jag: float, trunk: bool) -> void:
	var t: Vector3 = g[1] * facing
	var first := _bark_count
	for k in sides + 1:
		var a := TAU * k / sides
		var dir: Vector3 = g[2] * cos(a) + g[3] * sin(a)
		var rr: float = g[4]
		if trunk:
			rr *= 1.0 + flare * exp(-maxf(g[0].y, 0.0) / 0.6) * (1.0 + 0.35 * cos(5.0 * a + 0.7))
		st.set_uv(Vector2(cos(a), sin(a)))
		st.set_uv2(Vector2(1.0, 0.0))
		st.set_normal(t)
		st.set_color(bark_tint)
		st.add_vertex(g[0] + dir * rr + g[1] * _jag(a, jag, splinter))
	st.set_uv(Vector2.ZERO)
	st.set_uv2(Vector2(1.0, 0.0))
	st.set_normal(t)
	st.set_color(bark_tint)
	st.add_vertex(g[0] + g[1] * (-jag * 0.35 if splinter else jag * 0.2))
	var centre := first + sides + 1
	for k in sides:
		# (seen from outside, clockwise)
		if facing > 0.0:
			for j in [centre, first + k, first + k + 1]:
				st.add_index(j)
		else:
			for j in [centre, first + k + 1, first + k]:
				st.add_index(j)
	_bark_count += sides + 2


## How far a broken end sticks out round its rim (angle a). Splintered:
## sharp spikes of different heights, nothing below the break.
static func _jag(a: float, jag: float, splinter := false) -> float:
	if splinter:
		var spikes := absf(sin(2.0 * a + 0.4)) * 0.55 + absf(sin(5.0 * a + 1.9)) * 0.3 + absf(sin(11.0 * a + 0.7)) * 0.15
		return jag * pow(spikes, 2.2)
	return jag * (0.6 * sin(3.0 * a + 1.0) + 0.4 * sin(7.0 * a + 2.0))


var _bark_count := 0


var _thin_from := 12.0


## A leaf card: its foot at p, up along d, turned round d by spin. Sprig
## tiles are anchored at the bottom middle (the twig) and cropped at the top;
## clumps are centred.
##
## For thinning with distance (leaves.gdshader) each card carries a random
## rank (UV2.x) and, per corner, its offset from the card's middle and the
## distance it starts thinning from (CUSTOM0): past that distance the
## shader drops the cards ranked above the share it keeps and grows the rest
## to cover for them.
func _card(st: SurfaceTool, p: Vector3, d: Vector3, spin: float, size: float, tile: int, centre: Vector3, crown_r: float, centred: bool, r: RandomNumberGenerator) -> void:
	var side0 := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
	var side := side0.rotated(d, spin)
	var up := d
	var h := size * (1.0 if centred else 1.0 - card_crop)
	var foot := p - up * h * 0.5 if centred else p
	var corners := [foot - side * size * 0.5, foot + side * size * 0.5, foot + side * size * 0.5 + up * h, foot - side * size * 0.5 + up * h]
	var tx := float(tile % atlas.x) / atlas.x
	var ty := float(tile / atlas.x) / atlas.y
	var tw := 1.0 / atlas.x
	var th := 1.0 / atlas.y
	var v_top := ty + (0.0 if centred else card_crop * th)
	var uvs := [Vector2(tx, ty + th), Vector2(tx + tw, ty + th), Vector2(tx + tw, v_top), Vector2(tx, v_top)]
	var face := side.cross(up).normalized()
	var mid := foot + up * h * 0.5
	var out := mid - centre
	if face.dot(out) < 0.0:
		face = -face
	var nrm := (out.normalized() * 0.75 + face * 0.25).normalized()
	var depth := clampf(out.length() / maxf(crown_r, 0.1), 0.0, 1.0)
	var g := r.randf_range(0.9, 1.1)
	var tint := Color(g * r.randf_range(0.95, 1.05), g, g * r.randf_range(0.9, 1.1), lerpf(0.4, 1.0, depth))
	var start := _leaf_count
	var rank := r.randf()
	for k in 4:
		var off: Vector3 = corners[k] - mid
		st.set_uv(uvs[k])
		st.set_uv2(Vector2(rank, 0.0 if k < 2 else 1.0)) # y: how far from the twig (for the flutter)
		st.set_custom(0, Color(off.x, off.y, off.z, _thin_from))
		st.set_normal(nrm)
		st.set_color(tint)
		st.add_vertex(corners[k])
	for i in [0, 1, 2, 0, 2, 3]:
		st.add_index(start + i)
	_leaf_count += 4


var _leaf_count := 0


func _crown_centre() -> Vector3:
	var c := Vector3.ZERO
	for s in sprigs:
		c += pos[s[0]]
	return c / maxf(sprigs.size(), 1.0)


func _crown_radius(c: Vector3) -> float:
	var r := 0.0
	for s in sprigs:
		r += pos[s[0]].distance_to(c)
	return r / maxf(sprigs.size(), 1.0) * 1.3


## A stand-in that only casts the shadow: a lumpy ellipsoid for the crown
## (crown_r across, from bottom to top, m) on a stalk (stalk_r) down to the
## ground. Some hundred triangles instead of tens of thousands, and a solid
## shadow instead of alpha-cut leaves in every shadow map.
static func shadow_proxy(crown_r: float, bottom: float, top: float, stalk_r: float, seed: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3(0.0, (top + bottom) * 0.5, 0.0)
	var radii := Vector3(crown_r, (top - bottom) * 0.5, crown_r)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var bumps: Array[Vector3] = []
	for i in 9:
		bumps.append(Vector3(r.randf_range(-1, 1), r.randf_range(-0.3, 1), r.randf_range(-1, 1)).normalized())
	var ico := _icosphere(2)
	var verts: PackedVector3Array = ico[0]
	for v in verts:
		var k := 1.0
		for b in bumps:
			k += 0.14 * maxf(v.dot(b) - 0.75, 0.0) / 0.25
		k -= 0.08
		st.add_vertex(c + v * radii * k)
	for i in ico[1]:
		st.add_index(i)
	var base := verts.size()
	var sides := 6
	for j in 2:
		for k in sides:
			var a := TAU * k / sides
			st.add_vertex(Vector3(cos(a) * stalk_r, -0.5 if j == 0 else c.y, sin(a) * stalk_r))
	for k in sides:
		var a := base + k
		var b := base + (k + 1) % sides
		for i in [a, b, b + sides, a, b + sides, a + sides]:
			st.add_index(i)
	st.generate_normals()
	return st.commit()


## A unit icosphere: [vertices, indices], front faces outward.
static func _icosphere(subdiv: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = []
	for p in [[-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1]]:
		v.append(Vector3(p[0], p[1], p[2]).normalized())
	var f := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
			[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for s in subdiv:
		var mid := {}
		var nf := []
		for tri in f:
			var m := []
			for e in 3:
				var a: int = tri[e]
				var b: int = tri[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not mid.has(key):
					mid[key] = v.size()
					v.append(((v[a] + v[b]) * 0.5).normalized())
				m.append(mid[key])
			nf.append([tri[0], m[0], m[2]])
			nf.append([tri[1], m[1], m[0]])
			nf.append([tri[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		f = nf
	var idx := PackedInt32Array()
	for tri in f:
		idx.append_array([tri[0], tri[2], tri[1]])
	return [PackedVector3Array(v), idx]
