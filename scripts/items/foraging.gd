class_name Foraging
extends Node
## Picking fruit (F: the "pick" action): from a fruiting tree in reach
## (Population.fruit_near: a pawpaw's crown, a few metres from its trunk, in
## front of you), a few of its fruit (Items) into the knapsack; a tree once
## picked bears again the next day. Saved with the game (to_dict).

const REACH := 2.8 ## m from the trunk: under its crown
const MOST := 3 ## fruit a tree gives at a picking, at most

var main: Node
var _picked := {} # tree uid -> the day it was picked


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pick") or event.is_echo():
		return
	var p: Player = main.player
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or p.typing or p.frozen:
		return
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
	var left: int = main.inventory.add(tree.fruit, n)
	if left >= n:
		main.chat.say("Your knapsack is full.", Color(1.0, 0.7, 0.5))
		return
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
