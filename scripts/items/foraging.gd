class_name Foraging
extends Node
## Picking fruit (right-click with a hand empty): from a fruiting tree in
## reach (Population.fruit_near: a pawpaw's crown, a few metres from its
## trunk, in front of you), a few of its fruit (Items) into the empty hand,
## any it can't hold into the knapsack; a tree once picked bears again the
## next day. Saved with the game (to_dict).

const REACH := 2.8 ## m from the trunk: under its crown
const MOST := 3 ## fruit a tree gives at a picking, at most

var main: Node
var _picked := {} # tree uid -> the day it was picked


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return
	var p: Player = main.player
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or p.typing or p.frozen:
		return
	var inv: Inventory = main.inventory
	var hand := Inventory.RIGHT if inv.right.is_empty() else (Inventory.LEFT if inv.left.is_empty() else -1)
	if hand < 0:
		return # (both hands full: nothing to pick with)
	get_viewport().set_input_as_handled()
	var tree: Dictionary = main.population.fruit_near(Origin.map(p.camera.global_position), -p.camera.global_basis.z, REACH)
	if tree.is_empty():
		return
	var day: int = main.clock.day
	var uid: int = tree.uid
	var name := Items.name_of(tree.fruit).to_lower()
	if _picked.get(uid, -1000) == day:
		main.chat.say("Nothing left on it to pick today.", Color(0.85, 0.85, 0.8))
		return
	# (how many: the tree's and the day's own, 1..MOST)
	var n := 1 + int(fposmod(sin(float(uid % 100003) * 12.9898 + day * 78.233) * 43758.5453, 1.0) * MOST)
	# into the empty hand, as many as it holds; the rest into the knapsack
	var in_hand := mini(n, Items.stack_of(tree.fruit))
	inv.set_at(hand, {"id": tree.fruit, "count": in_hand})
	var left: int = inv.add(tree.fruit, n - in_hand) if n > in_hand else 0
	_picked[uid] = day
	var got := n - left
	main.chat.say("Picked %d %s%s." % [got, name, "" if got == 1 else "s"], Color(0.8, 1.0, 0.75))


func to_dict() -> Dictionary:
	var out := {}
	for uid in _picked:
		out[str(uid)] = _picked[uid]
	return out


func from_dict(d: Dictionary) -> void:
	_picked.clear()
	for k in d:
		_picked[int(k)] = int(d[k])
