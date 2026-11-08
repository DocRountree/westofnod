class_name Meal
extends Node3D
## A meal eaten piece by piece (any creature's food: a kill, an insect, a
## seed, a nut): no shrinking away. Its meshes are cut into pieces (a few
## across it each way; a skinned body baked first in the pose it died in),
## the originals hidden; each frame the eater says how much of it's gone
## (tear(k, mouth): 0..1) and where its mouth is, and each next piece, the
## one nearest its mouth now, is bitten off once the mouth's on it: simply
## gone, there, at once (not shrinking). Small food (a seed, a berry, an
## insect, for a mammal): one piece, across 1, gone in a single bite. The food never moves: not drawn to the
## mouth, not held up to it; the eater brings its mouth to it (next_at). What's left goes on being carried
## as the food is (the pieces are its children).
##
## Bloody (a vertebrate: a mammal above all, a fish, a frog, a lizard, a
## snake): each tear leaves raw, wet flesh in the edge of what's left (on
## the piece beside it, so eaten with it in turn), the piece torn away red
## inside, and, the food lying on the ground (ground: its height), blood
## run out under it, spreading, soaking in after a while.
## swallow (a snake's: whole, no tearing): each piece gone as the jaws come
## over it.
##
## A piece is bitten off only once the mouth's on it (a mouth that never
## gets there, after a while: the piece gone all the same, where it is).
## (held, dragged, in_place: no longer anything; the food lies still,
## whatever.)
##
##   var meal := Meal.of(prey)         # (once: bloody if it's a vertebrate)
##   meal.tear(k, mouth_world)         # (each frame, k 0..1)
##   prey.queue_free()                 # (done: the meal finishes the pieces
##                                     #  still on their way, then itself)

const POOL_SECS := 90.0 ## s: blood on the ground, before it's soaked in
const INSTANCE_PARAMS := ["shell", "fur_obj", "fur_dens", "bars", "tree_at"]
const BLEEDS := ["fish", "mouse", "squirrel", "hare", "deer", "moose", "bison", "beaver", "canid", "coyote", "wolf", "fox", "bobcat",
		"bear", "ursid", "carnivore", "anole", "frog", "toad", "snake", "turtle"] # (not the fish: no blood on them)

var food: Node3D
var bloody := false
var swallow := false
var ground := NAN ## the ground's height under it (lying there: blood runs out), or NAN
var held := false ## (no longer anything: the food's never moved)
var dragged := false ## (no longer anything)
var in_place := false ## (no longer anything: always so)

var _pieces: Array[Node3D] = [] # still on it (its children)
var _pools: Array = [] # [disc, age, radius]
var _n := 0
var _torn := 0
var _cell := 0.01 # (a piece's size, the food's own units)
var _w := 1.0 # (the food's units to metres)
var _span := 0.1 # (m: its length, its longest way)
var _mouth := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _idle := 0.0
var _due := 0 # (pieces it should have torn off by now)
var _late := 0.0 # (s a piece has been due, the mouth not yet on it)
static var _flesh: StandardMaterial3D
static var _blood: StandardMaterial3D
static var _ball: SphereMesh
static var _disc: CylinderMesh


## The meal of food (made once: asked again, the same one). across: how many
## pieces along its longest way (more, smaller bites). bloody: -1 by what it
## is (a vertebrate's), else 0 or 1.
static func of(f: Node3D, across := 5, bleeds := -1, ground_y := NAN) -> Node3D:
	if f == null or not is_instance_valid(f):
		return null
	if f.has_meta("meal"):
		var old = f.get_meta("meal")
		if is_instance_valid(old):
			return old
	var m: Node3D = load("res://scripts/creatures/meal.gd").new()
	m.set("food", f)
	m.set("bloody", is_vertebrate(f) if bleeds < 0 else bleeds > 0)
	m.set("ground", ground_y)
	var parent := f.get_parent()
	if parent == null:
		return null
	parent.add_child(m)
	m.top_level = true
	m.process_priority = 1000 # (after the eater's moved it, and itself)
	m.global_transform = Transform3D.IDENTITY
	f.set_meta("meal", m)
	m.call("_build", across)
	return m


## Whether food is kept (meta "keep": a mushroom, as a bush's berries,
## eaten at and never used up: no meal made of it, nothing torn off).
static func kept(f: Node) -> bool:
	return f != null and is_instance_valid(f) and f.has_meta("keep")


## Where food kept is bitten at (the world's): its place, up by its meta
## "bite_y" (m: a mushroom's cap).
static func bite_at(f: Node3D) -> Vector3:
	return f.global_position + Vector3(0.0, float(f.get_meta("bite_y", 0.0)), 0.0)


## A live animal caught (in jaws, forelegs, chelae, talons): killed, or
## stilled, limp, no longer moving itself (its hunter moves it from now on).
static func subdue(n: Node) -> void:
	if n == null or not is_instance_valid(n):
		return
	if n.has_method("die") and n.get("dead") != true:
		n.call("die")
	n.set_process(false)
	n.set_physics_process(false)


## Whether it bleeds red (a vertebrate's body, by its script or its name).
static func is_vertebrate(f: Node) -> bool:
	var path := ""
	if f.get_script():
		path = (f.get_script() as Script).resource_path.to_lower()
	path += " " + String(f.name).to_lower()
	for w: String in BLEEDS:
		if w in path:
			return true
	return f.get("S") is Dictionary and f.has_method("hunt") # (a carnivore's make)


## As much of it gone as k says (0..1), the pieces into the mouth (world).
func tear(k: float, mouth: Vector3) -> void:
	_mouth = mouth
	_idle = 0.0
	_prune()
	_due = int(ceil(clampf(k, 0.0, 1.0) * _n - 1e-4))
	while _torn < _due and not _pieces.is_empty():
		var i := _nearest()
		if _pieces[i].global_position.distance_to(_mouth) > _reach() and _late < 2.5:
			break # (not till its mouth's on it)
		_tear_next(i)
		_late = 0.0


## Where the next bite is (the piece nearest the mouth: the world's), or
## the mouth itself, nothing left.
func next_at() -> Vector3:
	_prune()
	return _pieces[_nearest()].global_position if not _pieces.is_empty() else _mouth


## (Its pieces gone with what they were part of, freed: no longer to eat.)
func _prune() -> void:
	for i in range(_pieces.size() - 1, -1, -1):
		if not is_instance_valid(_pieces[i]):
			_pieces.remove_at(i)


## (How near the mouth a piece must be, to be bitten off (m): about a
## piece's size, and a little more, the more for bigger food (a big
## mammal's kill), the less for an insect's (a wasp's caterpillar).)
func _reach() -> float:
	return _cell * _w * 0.75 + 0.012 * clampf(_span / 0.12, 0.1, 1.0)


func _nearest() -> int:
	_prune()
	var best := 0
	var bd := INF
	for i in _pieces.size():
		var d := _pieces[i].global_position.distance_squared_to(_mouth)
		if d < bd:
			bd = d
			best = i
	return best


## (Its length, m: its longest way.)
func span() -> float:
	return _span


## (How much of it's left: 1 whole .. 0 gone.)
func left() -> float:
	return 1.0 - float(_torn) / maxf(_n, 1)


## Every piece taken at once (done: what's still on it into the mouth).
func finish(mouth: Vector3) -> void:
	tear(1.0, mouth)


# --- building: its meshes cut into pieces --------------------------------------------

func _build(across: int) -> void:
	_rng.seed = hash(food.get_instance_id())
	var mis: Array[MeshInstance3D] = []
	if food is MeshInstance3D and (food as MeshInstance3D).mesh != null and food.is_visible_in_tree(): # (a bare mesh: a fish taken from its school)
		mis.append(food)
	_collect(food, mis)
	var inv := food.global_transform.affine_inverse()
	# its surfaces (a skinned one posed), and its extent: from where their
	# vertices are now (a skinned mesh's own bounds are padded)
	var surfs := [] # [mi, surface, arrays, mi -> food transform]
	var box := AABB()
	var first := true
	for mi in mis:
		var xf := inv * mi.global_transform
		var mesh := mi.mesh
		for s in mesh.get_surface_count():
			if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arrays := _posed(mi, mesh.surface_get_arrays(s))
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if verts.is_empty():
				continue
			var where := _bent(mi, s, verts) # (where its vertices are drawn: a shader-bent body's bent)
			surfs.append([mi, s, arrays, xf, where])
			for v in where:
				var p := xf * v
				if first:
					box = AABB(p, Vector3.ZERO)
					first = false
				else:
					box = box.expand(p)
	if first:
		return
	_cell = maxf(box.get_longest_axis_size() / maxf(across, 1), 1e-5)
	_w = food.global_transform.basis.get_scale().x
	_span = _cell * maxf(across, 1) * _w
	# each triangle to the cell its middle's in; each cell a piece
	var cells := {} # Vector3i -> {"mi:surface": [mi, surface, arrays, its triangles' indices]}
	var sums := {} # Vector3i -> [sum of middles, count]
	for sf: Array in surfs:
		var mi: MeshInstance3D = sf[0]
		var s: int = sf[1]
		var arrays: Array = sf[2]
		var xf: Transform3D = sf[3]
		var verts: PackedVector3Array = sf[4]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			idx.resize(verts.size())
			for i in verts.size():
				idx[i] = i
		var key_s := "%d:%d" % [mi.get_instance_id(), s]
		for t in range(0, idx.size() - 2, 3):
			var mid := xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
			var c := Vector3i(((mid - box.position) / _cell).floor())
			if not cells.has(c):
				cells[c] = {}
				sums[c] = [Vector3.ZERO, 0]
			var groups: Dictionary = cells[c]
			if not groups.has(key_s):
				groups[key_s] = [mi, s, arrays, []]
			var tri: Array = groups[key_s][3] # (an Array: added to where it is)
			tri.append(idx[t])
			tri.append(idx[t + 1])
			tri.append(idx[t + 2])
			sums[c][0] += mid
			sums[c][1] += 1
	for c: Vector3i in cells:
		var centre: Vector3 = sums[c][0] / float(sums[c][1])
		var piece := Node3D.new()
		piece.name = "meal_piece"
		piece.position = centre
		food.add_child(piece)
		var groups: Dictionary = cells[c]
		for key_s: String in groups:
			var g: Array = groups[key_s]
			var mi: MeshInstance3D = g[0]
			var s: int = g[1]
			var sub := _sub(g[2], PackedInt32Array(g[3]))
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sub, [], {}, _custom_flags(mi.mesh, s))
			var part := MeshInstance3D.new()
			part.mesh = am
			if mi.material_override:
				part.material_override = mi.material_override
			else:
				am.surface_set_material(0, mi.get_active_material(s))
			part.material_overlay = mi.material_overlay
			part.cast_shadow = mi.cast_shadow
			if mi.custom_aabb.size != Vector3.ZERO: # (placed by its shader: culled by where it may be)
				part.custom_aabb = mi.custom_aabb
			else:
				var pm := mi.material_override if mi.material_override else mi.get_active_material(s)
				if pm is ShaderMaterial and (pm as ShaderMaterial).get_shader_parameter("sp") != null: # (bent by its shader: its mesh's own bounds aren't where it's seen)
					part.custom_aabb = AABB(Vector3(-3.0, -3.0, -3.0), Vector3(6.0, 6.0, 6.0))
			part.transform = Transform3D(Basis(), -centre) * (inv * mi.global_transform)
			piece.add_child(part)
			for p: String in INSTANCE_PARAMS:
				var v = mi.get_instance_shader_parameter(p)
				if v != null:
					part.set_instance_shader_parameter(p, v)
		_pieces.append(piece)
	for mi in mis:
		if mi == food:
			mi.mesh = null # (its pieces are its children: still to be seen)
		else:
			mi.visible = false
	_n = _pieces.size()


## Its meshes showing (not this meal's own).
static func _collect(n: Node, out: Array[MeshInstance3D]) -> void:
	for c in n.get_children():
		if c.name == "meal_piece":
			continue
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and (c as MeshInstance3D).is_visible_in_tree():
			out.append(c)
		_collect(c, out)


## A skinned mesh's arrays in the pose its skeleton has now (rigid after:
## no bones, no weights); any other's as they are.
static func _posed(mi: MeshInstance3D, arrays: Array) -> Array:
	if mi.skin == null or arrays[Mesh.ARRAY_BONES] == null or arrays[Mesh.ARRAY_WEIGHTS] == null:
		return arrays
	var sk := mi.get_node_or_null(mi.skeleton) as Skeleton3D
	if sk == null:
		return arrays
	var skin := mi.skin
	var to_mi := mi.global_transform.affine_inverse() * sk.global_transform
	var mats: Array[Transform3D] = []
	for b in skin.get_bind_count():
		var bone := skin.get_bind_bone(b)
		if bone < 0:
			bone = sk.find_bone(skin.get_bind_name(b))
		mats.append(to_mi * (sk.get_bone_global_pose(bone) if bone >= 0 else Transform3D()) * skin.get_bind_pose(b))
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms = arrays[Mesh.ARRAY_NORMAL]
	var tans = arrays[Mesh.ARRAY_TANGENT]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var nb := bones.size() / maxi(verts.size(), 1)
	var out := arrays.duplicate()
	var v2 := verts.duplicate()
	var n2: PackedVector3Array = norms.duplicate() if norms != null else PackedVector3Array()
	var t2: PackedFloat32Array = tans.duplicate() if tans != null else PackedFloat32Array()
	for i in verts.size():
		var p := Vector3.ZERO
		var b := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
		var wsum := 0.0
		for j in nb:
			var w := weights[i * nb + j]
			if w <= 0.0:
				continue
			var bi := bones[i * nb + j]
			if bi < 0 or bi >= mats.size():
				continue
			var m := mats[bi]
			p += (m * verts[i]) * w
			b = Basis(b.x + m.basis.x * w, b.y + m.basis.y * w, b.z + m.basis.z * w)
			wsum += w
		if wsum <= 0.0:
			continue
		v2[i] = p / wsum
		if not n2.is_empty():
			n2[i] = (b * n2[i]).normalized()
		if not t2.is_empty():
			var tv := (b * Vector3(t2[i * 4], t2[i * 4 + 1], t2[i * 4 + 2])).normalized()
			t2[i * 4] = tv.x
			t2[i * 4 + 1] = tv.y
			t2[i * 4 + 2] = tv.z
	out[Mesh.ARRAY_VERTEX] = v2
	if not n2.is_empty():
		out[Mesh.ARRAY_NORMAL] = n2
	if not t2.is_empty():
		out[Mesh.ARRAY_TANGENT] = t2
	out[Mesh.ARRAY_BONES] = null
	out[Mesh.ARRAY_WEIGHTS] = null
	return out


## Where a surface's vertices are drawn (its mesh's space): as they are; or,
## a body its shader bends along a spine (a snake's, a larva's skin: sp, sx,
## sy, count, size; the tube's place along it in VERTEX.z), bent as the
## shader bends them (Catmull-Rom through the spine's points), for cutting
## it where it's seen. Its pieces keep the mesh unbent and the material:
## the shader, its spine held still now, bends them just the same.
static func _bent(mi: MeshInstance3D, s: int, verts: PackedVector3Array) -> PackedVector3Array:
	var mat := mi.material_override if mi.material_override else mi.get_active_material(s)
	if not (mat is ShaderMaterial):
		return verts
	var sm := mat as ShaderMaterial
	var spv = sm.get_shader_parameter("sp")
	if not (spv is PackedVector3Array) or (spv as PackedVector3Array).size() < 2 or sm.get_shader_parameter("skinned") == false:
		return verts
	var sp: PackedVector3Array = spv
	var sx: PackedVector3Array = sm.get_shader_parameter("sx")
	var sy: PackedVector3Array = sm.get_shader_parameter("sy")
	var cv = sm.get_shader_parameter("count")
	var n: int = mini(int(cv) if cv != null else sp.size(), sp.size())
	var szv = sm.get_shader_parameter("size")
	var size: float = float(szv) if szv != null else 1.0
	var bs = sm.get_shader_parameter("bulge_s")
	var br = sm.get_shader_parameter("bulge_r")
	var out := PackedVector3Array()
	out.resize(verts.size())
	for k in verts.size():
		var v := verts[k]
		var sv := v.z
		var i0 := clampi(int(floorf(sv)), 0, n - 2)
		var i1 := i0 + 1
		var f := sv - float(i0)
		var p: Vector3
		if f >= 0.0 and f <= 1.0:
			var a := sp[maxi(i0 - 1, 0)]
			var b := sp[i0]
			var c := sp[i1]
			var d := sp[mini(i1 + 1, n - 1)]
			p = 0.5 * (2.0 * b + (c - a) * f + (2.0 * a - 5.0 * b + 4.0 * c - d) * f * f + (3.0 * b - a - 3.0 * c + d) * f * f * f)
		else:
			p = sp[i0].lerp(sp[i1], f)
		var kk := clampf(f, 0.0, 1.0)
		var x := sx[i0].lerp(sx[i1], kk).normalized() if i1 < sx.size() else Vector3.RIGHT
		var y := sy[i0].lerp(sy[i1], kk).normalized() if i1 < sy.size() else Vector3.UP
		var swell := 1.0
		if bs != null and br != null:
			swell = 1.0 + float(br) * exp(-pow((sv - float(bs)) / 1.8, 2.0))
		out[k] = p + (x * v.x + y * v.y) * size * swell
	return out


## The arrays of just these triangles (their vertices only, renumbered).
static func _sub(arrays: Array, tris: PackedInt32Array) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var vc := verts.size()
	var map := PackedInt32Array()
	map.resize(vc)
	map.fill(-1)
	var order := PackedInt32Array()
	var nidx := PackedInt32Array()
	nidx.resize(tris.size())
	for k in tris.size():
		var i := tris[k]
		if map[i] < 0:
			map[i] = order.size()
			order.append(i)
		nidx[k] = map[i]
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for a in Mesh.ARRAY_MAX:
		if a == Mesh.ARRAY_INDEX or a == Mesh.ARRAY_BONES or a == Mesh.ARRAY_WEIGHTS:
			continue
		var src = arrays[a]
		if src == null or src.size() == 0:
			continue
		var stride: int = src.size() / vc
		if stride < 1:
			continue
		var dst = src.slice(0, 0)
		dst.resize(order.size() * stride)
		for j in order.size():
			var o := order[j] * stride
			for c in stride:
				dst[j * stride + c] = src[o + c]
		out[a] = dst
	out[Mesh.ARRAY_INDEX] = nidx
	return out


## (A surface's custom channels' formats, to make it again with them.)
static func _custom_flags(mesh: Mesh, s: int) -> int:
	if not (mesh is ArrayMesh):
		return 0
	var fmt := (mesh as ArrayMesh).surface_get_format(s)
	var flags := 0
	for sh in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
		flags |= fmt & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << sh)
	return flags


# --- eating ------------------------------------------------------------------------

func _tear_next(best: int) -> void:
	var piece: Node3D = _pieces[best]
	_pieces.remove_at(best)
	_torn += 1
	if bloody and not swallow:
		_wound(piece) # (the raw edge left on what's left)
	piece.queue_free() # (bitten off: simply gone, there, at once)


## Torn off a bleeding body: raw flesh in the piece torn away (showing in
## its open edge), and in the edge of what's left beside it (on the
## nearest piece, eaten with it in turn); blood run out under it.
func _wound(torn: Node3D) -> void:
	_mats()
	var r := _cell * 0.38
	var raw := MeshInstance3D.new()
	raw.mesh = _ball
	raw.material_override = _flesh
	raw.scale = Vector3(1.0, 0.8, 1.0) * r * _rng.randf_range(0.8, 1.05)
	torn.add_child(raw)
	var nb: Node3D = null
	var nd := INF
	for p in _pieces:
		var d := p.position.distance_to(torn.position)
		if d < nd:
			nd = d
			nb = p
	if nb != null and nd < _cell * 2.2:
		for k in 2: # (the torn edge: raw flesh, a smear of blood beside it)
			var w := MeshInstance3D.new()
			w.mesh = _ball
			w.material_override = _flesh if k == 0 else _blood
			var toward := (torn.position - nb.position)
			w.position = toward * (0.5 if k == 0 else 0.42) + Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2)) * r
			w.scale = Vector3.ONE * r * (0.75 if k == 0 else 0.95) * _rng.randf_range(0.85, 1.15)
			w.scale.y *= 0.7
			nb.add_child(w)
	if not is_nan(ground):
		var at := torn.global_position
		r *= _w
		var pool := MeshInstance3D.new()
		pool.mesh = _disc
		pool.material_override = _blood
		add_child(pool)
		pool.global_position = Vector3(at.x + _rng.randf_range(-1.0, 1.0) * r, ground + 0.0006 + 0.0002 * float(_pools.size() % 5), at.z + _rng.randf_range(-1.0, 1.0) * r)
		pool.scale = Vector3(0.01, 1.0, 0.01) * r
		_pools.append([pool, 0.0, r * _rng.randf_range(1.2, 2.0)])


func _process(dt: float) -> void:
	if _torn < _due:
		_late += dt
	for p: Array in _pools:
		p[1] = float(p[1]) + dt
		var pool: MeshInstance3D = p[0]
		var age: float = p[1]
		var rr: float = p[2] * clampf(sqrt(age / 6.0), 0.05, 1.0) # (spreading)
		pool.scale = Vector3(rr, 1.0, rr)
		if age > POOL_SECS: # (soaked in)
			pool.position.y -= dt * 0.0004
	if not is_instance_valid(food) or food.is_queued_for_deletion():
		_idle += dt
		var pooled := not _pools.is_empty() and _idle < POOL_SECS + 10.0
		if not pooled:
			queue_free()


static func _mats() -> void:
	if _flesh != null:
		return
	_flesh = StandardMaterial3D.new()
	_flesh.albedo_color = Color(0.45, 0.04, 0.05)
	_flesh.roughness = 0.3
	_flesh.metallic_specular = 0.7
	_blood = StandardMaterial3D.new()
	_blood.albedo_color = Color(0.22, 0.01, 0.015)
	_blood.roughness = 0.12
	_blood.metallic_specular = 0.9
	_ball = SphereMesh.new()
	_ball.radius = 1.0
	_ball.height = 2.0
	_ball.radial_segments = 10
	_ball.rings = 6
	_disc = CylinderMesh.new()
	_disc.top_radius = 1.0
	_disc.bottom_radius = 1.0
	_disc.height = 0.0004
	_disc.radial_segments = 14
	_disc.rings = 1
