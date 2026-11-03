class_name Foraging
extends Node
## Fruit on the trees, and picking it. Each grown fruiting tree (a pawpaw:
## Population.fruit_trees_near) bears a few fruit of its own (none on some),
## hanging in its crown (its mesh_script's fruit_spots) as real things,
## drawn on the trees near you: as many as are left on it. A click (left or
## right) with a hand empty, under a fruiting tree's crown in front of you
## (Population.fruit_near), picks one into that hand; what's picked is gone
## from the tree till the next day, when it bears again. Saved with the game
## (to_dict).

const REACH := 2.8 ## m from the trunk: under its crown
const MOST := 6 ## fruit a tree bears, at most
const SHOW := 45.0 ## m: the fruit drawn on the trees this near
const RESHOW := 3.0 ## m you move before the trees near are looked at again

var main: Node
var _taken := {} # tree uid -> [day, how many picked that day]
var _shown := {} # fruit id -> MultiMeshInstance3D
var _shown_at := Vector3.INF
var _shown_day := -1
var _dirty := true


## How many fruit a tree bears (a day), by its own hash: 0..MOST, none on
## about a third.
static func bears(uid: int) -> int:
	var h := fposmod(sin(float(uid % 1000003) * 12.9898 + 4.1) * 43758.5453, 1.0)
	return maxi(int(h * (MOST + 3)) - 2, 0)


## How many are left on the tree today.
func left_on(uid: int, spots: int) -> int:
	var n := mini(bears(uid), spots)
	var t: Array = _taken.get(uid, [])
	if t.size() == 2 and int(t[0]) == main.clock.day:
		n -= int(t[1])
	return maxi(n, 0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]):
		return
	var p: Player = main.player
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or p.typing or p.frozen:
		return
	var inv: Inventory = main.inventory
	# the clicked side's hand first, if it's empty, else the other
	var first := Inventory.LEFT if event.button_index == MOUSE_BUTTON_LEFT else Inventory.RIGHT
	var other := Inventory.RIGHT if first == Inventory.LEFT else Inventory.LEFT
	var hand := first if inv.get_at(first).is_empty() else (other if inv.get_at(other).is_empty() else -1)
	if hand < 0:
		return # (no hand empty: nothing to pick with)
	var tree: Dictionary = main.population.fruit_near(Origin.map(p.camera.global_position), -p.camera.global_basis.z, REACH)
	if tree.is_empty():
		return
	get_viewport().set_input_as_handled()
	var kind: PropKind = tree.kind
	var spots: PackedVector3Array = kind.mesh_script.fruit_spots(tree.variant)
	if left_on(tree.uid, spots.size()) <= 0:
		main.chat.say("There's no fruit left on it to pick.", Color(0.85, 0.85, 0.8))
		return
	var day: int = main.clock.day
	var t: Array = _taken.get(tree.uid, [])
	var n := int(t[1]) + 1 if t.size() == 2 and int(t[0]) == day else 1
	_taken[tree.uid] = [day, n]
	inv.set_at(hand, {"id": tree.fruit, "count": 1})
	main.chat.say("Picked a %s." % Items.name_of(tree.fruit).to_lower(), Color(0.8, 1.0, 0.75))
	_dirty = true


func _process(_delta: float) -> void:
	if main == null or main.player == null or main.population == null:
		return
	var at := Origin.map(main.player.global_position)
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
		var n := left_on(tree.uid, spots.size())
		if n <= 0:
			continue
		var xf: Transform3D = tree.transform
		var size: Vector3 = Items.KINDS.get(tree.fruit, {}).get("size", Vector3.ONE * 0.05)
		var list: Array = by_fruit.get(tree.fruit, [])
		for i in n:
			var p := xf * spots[i]
			# hanging, tipped a little this way or that
			var h := fposmod(sin(float(tree.uid % 9973) * 3.17 + i * 7.31) * 9131.7, 1.0)
			var b := Basis(Vector3.UP, h * TAU) * Basis(Vector3.RIGHT, (h - 0.5) * 0.5)
			list.append(Transform3D(b.scaled(size), p - Vector3.UP * size.y * 0.5))
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
## ellipsoid in its item's colour.
static func _fruit_mesh(id: String) -> Mesh:
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


func to_dict() -> Dictionary:
	var out := {}
	for uid in _taken:
		out[str(uid)] = _taken[uid]
	return out


func from_dict(d: Dictionary) -> void:
	_taken.clear()
	for k in d:
		var v = d[k]
		if v is Array and v.size() == 2:
			_taken[int(k)] = [int(v[0]), int(v[1])]
	_dirty = true
