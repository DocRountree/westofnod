class_name Drops
extends Node
## Things put down on the ground. Q (the "drop" action) drops what's in the
## right hand (else the left), the whole stack, just before you: it lies
## there (its model as held, turned to lie on its longest side, a stack's
## few spread a little), on the ground or a log or stump. Left-click one
## (looking at it, within REACH of your eye) with a hand free (or holding
## the same, with room) to take it up again, as much of it as the hand holds.
## Saved with the game (to_list, from_list: main.gd), on the map (Origin).

const REACH := 2.4 ## m from the eye
const AIM := 0.22 ## m from the line looked along
const SHOWN := 5 ## the most of a stack drawn lying there

var main: Node
var _drops: Array = [] # {id, count, at (map), yaw, node}


func _unhandled_input(event: InputEvent) -> void:
	var p: Player = main.player
	if p == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or p.typing or p.frozen:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.is_action("drop"):
		if drop_held():
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _take():
			get_viewport().set_input_as_handled()


## The right hand's stack (else the left's) down before you. Whether there was one.
func drop_held() -> bool:
	var inv: Inventory = main.inventory
	var hand := Inventory.RIGHT if not inv.get_at(Inventory.RIGHT).is_empty() else Inventory.LEFT
	var held: Dictionary = inv.get_at(hand)
	if held.is_empty():
		return false
	var p: Player = main.player
	var here := Origin.map(p.global_position)
	var fwd := -p.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var side := fwd.cross(Vector3.UP)
	var spot := here + fwd * 0.55 + side * (0.18 if hand == Inventory.RIGHT else -0.18)
	inv.set_at(hand, {})
	put(str(held.id), int(held.count), Vector3(spot.x, _ground(spot, here.y), spot.z), atan2(fwd.x, fwd.z) + randf_range(-0.6, 0.6))
	return true


func _ground(spot: Vector3, eye_y: float) -> float:
	var g: float = main.world.height_at(spot.x, spot.z)
	if main.population:
		g = maxf(g, main.population.deck_at(spot, eye_y + 0.6, 0.1)) # (on a log or a stump)
	return g


## A stack lying at `at` (the map's), turned yaw.
func put(id: String, count: int, at: Vector3, yaw: float) -> void:
	var d := {"id": id, "count": count, "at": at, "yaw": yaw, "node": null}
	d.node = _model(id, count, at, yaw)
	_drops.append(d)


## Its model (as held) laid down: turned onto its longest side, its
## bottom on the ground; a stack's first few spread a little.
func _model(id: String, count: int, at: Vector3, yaw: float) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(at)
	for k in mini(count, SHOWN):
		var m := Items.model(id)
		var box := _aabb(m, Transform3D())
		var lie := Basis()
		if box.size.y > maxf(box.size.x, box.size.z) * 1.3: # (tall as held: on its side)
			lie = Basis(Vector3.RIGHT, PI * 0.5)
		var turned := _aabb(m, Transform3D(lie, Vector3.ZERO))
		var holder := Node3D.new()
		var spread := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)) * minf(maxf(box.size.x, box.size.z) * 1.2 + 0.02, 0.06) * (0.0 if k == 0 else 1.0)
		holder.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(-0.5, 0.5) * (0.0 if k == 0 else 1.0)) * lie, spread + Vector3(0.0, -turned.position.y + turned.size.y * 0.9 * float(k > 0 and box.size.y > 0.3), 0.0))
		holder.add_child(m)
		root.add_child(holder)
	root.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	Origin.root.add_child(root)
	return root


## The bounds of n's meshes (in the space xf puts n in).
static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf * ((n as Node3D).transform if n is Node3D else Transform3D())
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _aabb(c, t)
		if b.size == Vector3.ZERO:
			continue
		out = b if first else out.merge(b)
		first = false
	return out


## The drop looked at, taken up into a hand with room. Whether one was.
func _take() -> bool:
	var p: Player = main.player
	var eye := Origin.map(p.camera.global_position)
	var fwd := -p.camera.global_basis.z
	var best := -1
	var best_d := AIM
	for i in _drops.size():
		var c: Vector3 = (_drops[i].at as Vector3) + Vector3(0.0, 0.04, 0.0)
		var v := c - eye
		var t := v.dot(fwd)
		if t < 0.0 or t > REACH:
			continue
		var d := (v - fwd * t).length()
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		return false
	var e: Dictionary = _drops[best]
	var inv: Inventory = main.inventory
	var id := str(e.id)
	var left := int(e.count)
	for h: int in [Inventory.LEFT, Inventory.RIGHT]:
		var held: Dictionary = inv.get_at(h)
		if left <= 0 or not Foraging._room(held, id):
			continue
		var have := int(held.get("count", 0))
		var n := mini(left, Items.stack_of(id) - have)
		inv.set_at(h, {"id": id, "count": have + n})
		left -= n
	if left == int(e.count):
		main.chat.say("Your hands are full.", Color(0.85, 0.85, 0.8))
		return true
	(e.node as Node3D).queue_free()
	if left > 0: # (what the hands couldn't hold left lying)
		e.count = left
		e.node = _model(id, left, e.at, e.yaw)
	else:
		_drops.remove_at(best)
	return true


func to_list() -> Array:
	var out := []
	for e in _drops:
		var a: Vector3 = e.at
		out.append({"id": e.id, "count": e.count, "at": [a.x, a.y, a.z], "yaw": e.yaw})
	return out


func from_list(list: Array) -> void:
	for e in list:
		if e is Dictionary and Items.exists(str(e.get("id", ""))) and (e.get("at", []) as Array).size() == 3:
			var a: Array = e.at
			put(str(e.id), int(e.get("count", 1)), Vector3(a[0], a[1], a[2]), float(e.get("yaw", 0.0)))
