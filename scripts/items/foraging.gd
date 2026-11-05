class_name Foraging
extends Node
## Fruit on the trees, and picking it; and the flowers and cattails
## (GroundCover.pick_near), picked the same way, a clump a click, gone till
## the next day (GroundCover.set_gone). Each grown fruiting tree (a pawpaw:
## Population.fruit_trees_near) bears a few fruit of its own (none on some),
## hanging in its crown (its mesh_script's fruit_spots) as real things,
## drawn on the trees near you: as many as are left on it. A left click with
## a hand free, looking at one of the fruit itself within reach (PICK_REACH:
## up in a tall tree's crown, climb it), picks that one into the hand; what's
## picked is gone from the tree till the next day, when it bears again. Saved
## with the game (to_dict).

const PICK_REACH := 2.8 ## m from the eye a fruit can be picked
const PICK_SLACK := 0.04 ## m round a fruit the view may pass and still pick it
const MOST := 6 ## fruit a tree bears, at most
const SHOW := 45.0 ## m: the fruit drawn on the trees this near
const RESHOW := 3.0 ## m you move before the trees near are looked at again
const PLANT_REACH := 2.6 ## m along the view a flower or cattail is picked from

var main: Node
var _taken := {} # tree uid -> {"day": the day, "mask": which of its spots were picked that day (bits)}; or from older saves {"day", "n": how many, the last ones}
var _shown := {} # fruit id -> MultiMeshInstance3D
var _shown_at := Vector3.INF
var _shown_day := -1
var _dirty := true
var _plants := {} # item id -> the cells (GroundCover: that item's layer's) picked today
var _plants_day := -1


## How many fruit a tree bears (a day), by its own hash: 0..most (its
## fruit's "bears" in Items, else MOST), none on about a third.
static func bears(uid: int, most := MOST) -> int:
	var h := fposmod(sin(float(uid % 1000003) * 12.9898 + 4.1) * 43758.5453, 1.0)
	return maxi(int(h * (most + 3)) - 2, 0)


## The most fruit of id a tree bears.
static func most_of(id: String) -> int:
	return int(Items.KINDS.get(id, {}).get("bears", MOST))


## Which of a tree's fruit spots were picked today (bits).
func _picked(uid: int, spots: int, most := MOST) -> int:
	var t: Dictionary = _taken.get(uid, {})
	if t.is_empty() or int(t.get("day", -1)) != main.clock.day:
		return 0
	if t.has("mask"):
		return int(t.mask)
	# (saved before the fruit were picked one by one: so many, the last borne)
	var borne := mini(bears(uid, most), spots)
	var mask := 0
	for i in range(maxi(borne - int(t.get("n", 0)), 0), borne):
		mask |= 1 << i
	return mask


## The spots (indices into its mesh_script's fruit_spots) of the fruit
## hanging on the tree today.
func hanging(uid: int, spots: int, most := MOST) -> PackedInt32Array:
	var out := PackedInt32Array()
	var picked := _picked(uid, spots, most)
	for i in mini(bears(uid, most), spots):
		if not picked & (1 << i):
			out.append(i)
	return out


## How many are left on the tree today.
func left_on(uid: int, spots: int, most := MOST) -> int:
	return hanging(uid, spots, most).size()


## Where a tree's fruit at spot i hangs, as drawn (on the map; its middle):
## its transform, sized as its item.
static func _fruit_xf(tree: Dictionary, spot: Vector3, i: int) -> Transform3D:
	var xf: Transform3D = tree.transform
	var size: Vector3 = Items.KINDS.get(tree.fruit, {}).get("size", Vector3.ONE * 0.05)
	var p := xf * spot
	# hanging, tipped a little this way or that
	var h := fposmod(sin(float(int(tree.uid) % 9973) * 3.17 + i * 7.31) * 9131.7, 1.0)
	var b := Basis(Vector3.UP, h * TAU) * Basis(Vector3.RIGHT, (h - 0.5) * 0.5)
	return Transform3D(b.scaled(size), p - Vector3.UP * size.y * 0.5)


## The hanging fruit the view from eye along fwd (unit) meets first within
## PICK_REACH: {tree, spot, fruit}, or {} none.
func fruit_at(eye: Vector3, fwd: Vector3) -> Dictionary:
	var best := {}
	var best_t := INF
	for tree in main.population.fruit_trees_near(eye, PICK_REACH + 12.0):
		var kind: PropKind = tree.kind
		var spots: PackedVector3Array = kind.mesh_script.fruit_spots(tree.variant)
		var size: Vector3 = Items.KINDS.get(tree.fruit, {}).get("size", Vector3.ONE * 0.05)
		var r := maxf(size.x, maxf(size.y, size.z)) * 0.5 + PICK_SLACK
		for i in hanging(tree.uid, spots.size(), most_of(tree.fruit)):
			var c := _fruit_xf(tree, spots[i], i).origin
			var t := (c - eye).dot(fwd)
			if t < 0.0 or t > PICK_REACH + r or t >= best_t:
				continue
			if (eye + fwd * t).distance_to(c) <= r:
				best_t = t
				best = {"tree": tree, "spot": i, "fruit": tree.fruit}
	return best


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Player = main.player
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or p.typing or p.frozen:
		return
	var inv: Inventory = main.inventory
	var eye := Origin.map(p.camera.global_position)
	var fwd := -p.camera.global_basis.z
	# a fruit looked at, else a flower or a cattail
	var fruit := fruit_at(eye, fwd)
	var plant := {}
	var id := ""
	if not fruit.is_empty():
		id = fruit.fruit
	elif main.ground_cover:
		plant = main.ground_cover.pick_near(eye, fwd, PLANT_REACH)
		if plant.is_empty():
			return
		id = plant.item
	else:
		return
	# the left hand, if it's empty (or has room for it), else the right
	var hand := Inventory.LEFT if _room(inv.get_at(Inventory.LEFT), id) else (Inventory.RIGHT if _room(inv.get_at(Inventory.RIGHT), id) else -1)
	if hand < 0:
		return # (no hand free: nothing to pick with)
	get_viewport().set_input_as_handled()
	if not fruit.is_empty():
		var tree: Dictionary = fruit.tree
		var kind: PropKind = tree.kind
		var spots: int = kind.mesh_script.fruit_spots(tree.variant).size()
		_taken[tree.uid] = {"day": main.clock.day, "mask": _picked(tree.uid, spots, most_of(tree.fruit)) | (1 << int(fruit.spot))}
		_dirty = true
	else:
		var cells: Array = _plants.get(id, [])
		cells.append(plant.cell)
		_plants[id] = cells
		_plants_day = main.clock.day
		main.ground_cover.set_gone(_plants)
	var held: Dictionary = inv.get_at(hand)
	inv.set_at(hand, {"id": id, "count": int(held.get("count", 0)) + 1})
	main.chat.say("Picked a %s." % Items.name_of(id).to_lower(), Color(0.8, 1.0, 0.75))


## Whether a hand holding `held` can take one more of id.
static func _room(held: Dictionary, id: String) -> bool:
	return held.is_empty() or (held.get("id", "") == id and int(held.get("count", 0)) < Items.stack_of(id))


func _process(_delta: float) -> void:
	if main == null or main.player == null or main.population == null:
		return
	var at := Origin.map(main.player.global_position)
	# the flowers and cattails picked grow again the next day
	if _plants_day != main.clock.day and not _plants.is_empty():
		_plants.clear()
		if main.ground_cover:
			main.ground_cover.set_gone(_plants)
	_plants_day = main.clock.day
	if not _dirty and at.distance_to(_shown_at) < RESHOW and main.clock.day == _shown_day:
		return
	_dirty = false
	_shown_at = at
	_shown_day = main.clock.day
	_show(at)


## Hangs the fruit left on the trees near `at`: one MultiMesh a kind of fruit.
func _show(at: Vector3) -> void:
	var by_fruit := {} # fruit id -> Array[Transform3D] (on the map)
	for tree in main.population.fruit_trees_near(at, SHOW):
		var kind: PropKind = tree.kind
		var spots: PackedVector3Array = kind.mesh_script.fruit_spots(tree.variant)
		var on := hanging(tree.uid, spots.size(), most_of(tree.fruit))
		if on.is_empty():
			continue
		var list: Array = by_fruit.get(tree.fruit, [])
		for i in on:
			list.append(_fruit_xf(tree, spots[i], i))
		by_fruit[tree.fruit] = list
	for id in _shown.keys():
		if not by_fruit.has(id):
			_shown[id].multimesh.instance_count = 0
	for id in by_fruit:
		var mi: MultiMeshInstance3D = _shown.get(id)
		if mi == null:
			mi = MultiMeshInstance3D.new()
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = _fruit_mesh(id)
			mi.multimesh = mm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			Origin.root.add_child(mi) # (on the map: the floating origin moves it)
			_shown[id] = mi
		var list: Array = by_fruit[id]
		mi.multimesh.instance_count = list.size()
		for i in list.size():
			mi.multimesh.set_instance_transform(i, list[i])
		mi.custom_aabb = AABB(at - Vector3(SHOW, 60.0, SHOW), Vector3(SHOW, 60.0, SHOW) * 2.0)


## A fruit as it hangs (unit size: scaled by its item's size): a smooth
## ellipsoid in its item's colour (an acorn: in its cup, on its stalk).
static func _fruit_mesh(id: String) -> Mesh:
	if id == "acorn":
		return _acorn_mesh()
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 10
	m.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Items.color_of(id)
	mat.roughness = 0.6
	m.material = mat
	return m


## An acorn hanging (unit size): the nut, glossy, its cup over its top
## third, scaly, grey brown, and its long stalk up to the twig: one mesh,
## coloured by vertex.
static func _acorn_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 10
	sphere.rings = 6
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	var nut := Items.color_of("acorn")
	for part: Array in [[sphere, Transform3D(Basis(), Vector3.ZERO), nut], [sphere, Transform3D(Basis.from_scale(Vector3(1.12, 0.55, 1.12)), Vector3(0.0, 0.3, 0.0)), Items.ACORN_CUP],
			[cyl, Transform3D(Basis.from_scale(Vector3(0.14, 1.2, 0.14)), Vector3(0.0, 1.1, 0.0)), Color(0.36, 0.32, 0.2)]]:
		var a: Array = (part[0] as PrimitiveMesh).get_mesh_arrays()
		var xf: Transform3D = part[1]
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		for k in idx:
			st.set_color(part[2])
			st.set_normal((xf.basis.inverse().transposed() * ns[k]).normalized())
			st.add_vertex(xf * vs[k])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true # (its colours as Items gives them)
	mat.roughness = 0.5
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m


func to_dict() -> Dictionary:
	var out := {}
	for uid in _taken:
		out[str(uid)] = _taken[uid]
	# the flowers and cattails picked today: "p:<item>" -> [day, x, z, x, z, ...]
	for id in _plants:
		var a := [_plants_day]
		for c: Vector2i in _plants[id]:
			a.append_array([c.x, c.y])
		out["p:" + id] = a
	return out


func from_dict(d: Dictionary) -> void:
	_taken.clear()
	_plants.clear()
	for k in d:
		var v = d[k]
		if String(k).begins_with("p:"):
			if v is Array and v.size() >= 1 and main and int(v[0]) == main.clock.day:
				var cells := []
				for i in range(1, v.size() - 1, 2):
					cells.append(Vector2i(int(v[i]), int(v[i + 1])))
				_plants[String(k).substr(2)] = cells
		elif v is Dictionary:
			_taken[int(k)] = {"day": int(v.get("day", -1)), "mask": int(v.get("mask", 0))}
		elif v is Array and v.size() == 2: # (saved before they were picked one by one: how many)
			_taken[int(k)] = {"day": int(v[0]), "n": int(v[1])}
	_plants_day = main.clock.day if main else -1
	if main and main.ground_cover:
		main.ground_cover.set_gone(_plants)
	_dirty = true
