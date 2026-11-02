class_name Inventory
extends RefCounted
## What the player carries: the knapsack's SLOTS slots and one item (stack) in
## each hand. A stack is {"id": item id, "count": n}; an empty slot or hand is
## {}. Saved with the game (main.gd: to_dict / from_dict).

signal changed

const SLOTS := 10

var slots: Array[Dictionary] = []
var left := {}
var right := {}


func _init() -> void:
	slots.resize(SLOTS)
	for i in SLOTS:
		slots[i] = {}


## The places items can be, by index: the slots 0..SLOTS-1, then the left
## hand (SLOTS) and the right (SLOTS + 1).
const LEFT := SLOTS
const RIGHT := SLOTS + 1


func get_at(i: int) -> Dictionary:
	if i == LEFT:
		return left
	if i == RIGHT:
		return right
	return slots[i]


func set_at(i: int, stack: Dictionary) -> void:
	var s := {} if stack.is_empty() or int(stack.get("count", 0)) <= 0 else stack
	if i == LEFT:
		left = s
	elif i == RIGHT:
		right = s
	else:
		slots[i] = s
	changed.emit()


## Puts count of id in the knapsack (topping up stacks of it first, then the
## empty slots). Returns how many didn't fit.
func add(id: String, count: int) -> int:
	var stack := Items.stack_of(id)
	for pass_ in 2:
		for i in SLOTS:
			if count <= 0:
				break
			var s := slots[i]
			if pass_ == 0 and not s.is_empty() and s.id == id and s.count < stack:
				var n := mini(stack - int(s.count), count)
				s.count += n
				count -= n
			elif pass_ == 1 and s.is_empty():
				var n := mini(stack, count)
				slots[i] = {"id": id, "count": n}
				count -= n
	changed.emit()
	return count


func to_dict() -> Dictionary:
	return {"slots": slots.duplicate(true), "left": left.duplicate(), "right": right.duplicate()}


func from_dict(d: Dictionary) -> void:
	var s: Array = d.get("slots", [])
	for i in SLOTS:
		slots[i] = _valid(s[i] if i < s.size() else {})
	left = _valid(d.get("left", {}))
	right = _valid(d.get("right", {}))
	changed.emit()


static func _valid(v) -> Dictionary:
	if not (v is Dictionary) or not Items.exists(str(v.get("id", ""))) or int(v.get("count", 0)) <= 0:
		return {}
	return {"id": str(v.id), "count": mini(int(v.count), Items.stack_of(str(v.id)))}
