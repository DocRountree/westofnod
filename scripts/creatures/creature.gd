class_name Creature
extends Node3D
## The base of every animal with a body of its own (Hexapod's and so the
## mammals', Bird's, Snake, Turtle, Frog, Bat, Wasp, Lepidoptera, Larva,
## Dragonfly, Cetacean, GreatWhiteShark, SeaUrchin). What they all share,
## for whatever drives them (a state machine, the sandbox) and for the
## world's bookkeeping (Fauna):
##
## - tick(dt): its frame (what was each one's _process). Called from here
##   every frame, or every tick_every-th with the time since its last (a
##   body far off or out of sight, slowed by Fauna.pace(): its thinking and
##   its moving at a few a second). set_process(false) still stops it.
##   seen: false while it's out of sight (Fauna.pace()): what's only for
##   the eye may be left out of its frame (a walker's legs' pose).
## - fauna_id: its number among everything Fauna knows (Fauna.body(id)):
##   what another creature, or a record of it with no body, names it by.
## - Steering (pilot.gd): go, go_to, face, stop, act, behaviours, is_busy,
##   action_finished; order() and take_order(): what it's been told, as
##   data, to give to another body of the same animal.
## - piloted(): whether it's being steered (its own wandering set aside).
## - where(): where it is on the ground (its parent's space).
## - Fauna.report(): what it does that changes the world's numbers ("died",
##   "born", "laid", "ate", "killed"): told to whoever's listening.
## A species overrides the _p_* calls its pilot uses (see pilot.gd).

signal action_finished(name: String, ok: bool)
const _PilotScript := preload("res://scripts/creatures/pilot.gd")

var fauna_id := 0
var tick_every := 1 ## frames between its ticks (1: every frame)
var seen := true ## whether it can be seen now (Fauna.pace()): unseen, a species may leave out what's only for the eye (its legs' pose)
var _tick_acc := 0.0
var _pilot: _PilotScript
var _fauna_cell := Vector2i.MAX # (Fauna's: the cell of its space it's filed in)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			Fauna.join(self)
		NOTIFICATION_EXIT_TREE:
			Fauna.leave(self)


func _process(dt: float) -> void:
	if tick_every > 1:
		_tick_acc += dt
		if (Engine.get_process_frames() + fauna_id) % tick_every != 0:
			return
		dt = _tick_acc
		_tick_acc = 0.0
	tick(dt)
	if not Fauna._spaces.is_empty():
		Fauna.moved(self)


## Its frame: the species' own.
func tick(_dt: float) -> void:
	pass


## Where it is, on the ground (its parent's space).
func where() -> Vector3:
	var q: Variant = get("_pos")
	return q if q is Vector3 else position


# --- steering: a state machine's (pilot.gd) ---------------------------------------

func _pl() -> _PilotScript:
	if _pilot == null:
		_pilot = _PilotScript.new(self)
		_pilot.finished = action_finished.emit
	return _pilot


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_pl().go(direction, speed, seconds)


func go_to(point: Vector3, speed := -1.0) -> void:
	_pl().go_to(point, speed)


func face(direction: Vector3) -> void:
	_pl().face(direction)


func stop() -> void:
	_pl().stop()


func act(name: String, args := {}) -> bool:
	return _pl().act(name, args)


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func is_busy() -> bool:
	return _pilot != null and _pilot.busy()


## Whether it's being steered: it has had an order, and hasn't been sent
## back to its own doings since (release()).
func piloted() -> bool:
	return _pilot != null and _pilot.driving


## Its own doings again (the species': whatever it does left to itself).
func release() -> void:
	if _pilot:
		_pilot.stop()
		_pilot.driving = false


## What it's been told to do, as data ({} if nothing): for another body of
## the same animal to take up (take_order), or to be kept while it has none.
func order() -> Dictionary:
	return _pilot.order() if _pilot else {}


func take_order(o: Dictionary) -> void:
	if not o.is_empty():
		_pl().take_order(o)


func _p_here() -> Vector3:
	return where()


func _p_heading() -> Vector3:
	return -global_transform.basis.z


func _p_steer(_point: Vector3, _speed: float) -> void:
	pass


func _p_hold() -> void:
	pass


func _p_mobile() -> bool:
	return false


func _p_speed() -> float:
	return 1.0


func _p_reach() -> float:
	return 0.1


func _p_behaviours() -> PackedStringArray:
	return PackedStringArray()


func _p_act(_name: String, _args: Dictionary) -> bool:
	return false


func _p_act_done(_name: String) -> bool:
	return true


func _p_act_secs(_name: String) -> float:
	return -1.0
