class_name SwarmBody
extends "res://scripts/creatures/creature.gd"
## A swarm as one animal, for FaunaSim: a colony of ants, a band of beetles
## or snails, a cloud of fireflies, ticks in the grass, a pool of krill, a
## school of mollies. Its record is the swarm; its body this, the swarm's
## own node under it (made when it's near, as any body). It isn't steered:
## the swarm does as it does (an ant colony finds its own food:
## auto_forage); its brain only keeps its record.
## spec: [its script (scripts/creatures/), how many, how far about its
## middle (m)] (Species' "swarm").

var spec: Array = ["ant_colony.gd", 160, 0.4]
var swarm: Node3D
var height: Callable ## (x, z) -> the ground's y (its parent's space)
var young := false
var _lo := Vector3.INF
var _hi := Vector3.INF


func _init(young_ := false) -> void:
	young = young_


## Its water (its parent's space): the bottom's corner, the surface's.
func set_water(lo: Vector3, hi: Vector3) -> void:
	_lo = lo
	_hi = hi


func place(at: Vector3, _yaw := 0.0) -> void:
	position = at
	if swarm != null:
		return
	var sc: GDScript = load("res://scripts/creatures/" + String(spec[0]))
	swarm = sc.new()
	var n := int(spec[1])
	var r := float(spec[2])
	if "height" in swarm and height.is_valid(): # (the ground under them, in their own space)
		var here := at
		var h := height
		swarm.set("height", func(x: float, z: float) -> float: return float(h.call(x + here.x, z + here.z)) - here.y)
	if "tank_min" in swarm and _lo != Vector3.INF:
		swarm.set("tank_min", _lo - at)
		swarm.set("tank_max", _hi - at)
	add_child(swarm)
	var mid := Vector3.ZERO
	if "tank_min" in swarm and _lo != Vector3.INF:
		mid = Vector3(0.0, (_lo.y + _hi.y) * 0.5 - at.y, 0.0)
	if swarm.has_method("setup"):
		swarm.call("setup", n, mid, r)
	elif swarm.has_method("add"):
		swarm.call("add", n, mid, r)
	if "auto_forage" in swarm:
		swarm.set("auto_forage", true)
	swarm.set_meta("swarm_reach", r)


func where() -> Vector3:
	return position


func _p_mobile() -> bool:
	return false
