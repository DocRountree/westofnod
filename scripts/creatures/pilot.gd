extends RefCounted
## The steering every creature shares, for a state machine (or anything)
## to drive it by: each creature (Wasp, Lepidoptera's, Hexapod's, Snake,
## Larva; a colony's members: AntColony.member(i)) has the same calls,
## passed on to its pilot:
##
## - go(direction, speed := -1, seconds := -1): travel that way (level),
##   at speed (m/s; -1 its own pace) for seconds (-1: till told otherwise)
## - go_to(point, speed := -1): travel to point (its parent's space), done
##   there
## - face(direction): turn to face that way (a snake, which can't turn on
##   the spot, curving round to it), done facing it
## - stop(): stop where it is; whatever it was doing ends, not done
## - act(name, args := {}): start one of its behaviours (behaviours() lists
##   its own: "eat", "lay", "hop", "strike", ...; args by name: at, prey,
##   seconds, ...); false if it hasn't that one. "mate" {partner (its kind,
##   the other sex; a colony's: the partner's index), seconds}: everyone's
##   that mates (not ants: their workers don't), A behaviour that would go
##   on and on (eating, grooming, basking) ends after args.seconds (each
##   has its own default)
## - is_busy(): whether it's doing one of these
## - signal action_finished(name, ok): one of them ended: done (ok), or cut
##   short (stop(), another started, or it couldn't: not ok)
## - height: a Callable (x, z) -> the ground's y there, for those that walk
##   or crawl (none: level ground where it was put)
## Whatever it was doing of its own accord (wandering, stalking, searching)
## it stops while piloted; once an order's done it holds still (hovering,
## a flyer that can) till the next. Its own wandering again: its own call
## (wander(), stalk(), ...).
##
## The creature gives its pilot (duck-typed; a colony's take its member's
## index first): _p_here() -> Vector3, _p_heading() -> Vector3,
## _p_steer(point, speed), _p_hold(), _p_act(name, args) -> bool,
## _p_act_done(name) -> bool, _p_act_secs(name) -> float (-1: till done),
## _p_behaviours() -> PackedStringArray, _p_mobile() -> bool, _p_speed() ->
## float (its own pace, m/s), _p_reach() -> float (m: near enough).

var creature: Object
var index := -1 # (a colony's member)
var finished: Callable # (name, ok): the creature's signal
var kind := "" # "", "go", "go_to", "face", "act"
var _dir := Vector3.FORWARD
var _speed := -1.0
var _left := -1.0
var _point := Vector3.ZERO
var _act := ""
var _secs := -1.0
var _t := 0.0


func _init(c: Object, i := -1) -> void:
	creature = c
	index = i


func _call(m: String, args := []) -> Variant:
	return creature.callv(m, ([index] + args) if index >= 0 else args)


func busy() -> bool:
	return kind != ""


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_cancel()
	var d := Vector3(direction.x, 0.0, direction.z)
	if d.length() < 1e-5 or not _call("_p_mobile"):
		_finish("go", false)
		return
	kind = "go"
	_dir = d.normalized()
	_speed = speed
	_left = seconds
	_t = 0.0


func go_to(point: Vector3, speed := -1.0) -> void:
	_cancel()
	if not _call("_p_mobile"):
		_finish("go_to", false)
		return
	kind = "go_to"
	_point = point
	_speed = speed
	_t = 0.0


func face(direction: Vector3) -> void:
	_cancel()
	var d := Vector3(direction.x, 0.0, direction.z)
	if d.length() < 1e-5 or not _call("_p_mobile"):
		_finish("face", false)
		return
	kind = "face"
	_dir = d.normalized()
	_t = 0.0


func stop() -> void:
	_cancel()
	_call("_p_hold")


## Its behaviours that eat: given no target, the nearest real food of its
## diet (Diet.find) is found for them; none, the act fails (false): nothing
## is ever made for it to eat.
const FEEDING := ["eat", "hunt", "strike", "catch", "fish", "browse", "feed", "feed_on_insect", "forage", "visit_flowers", "feed_on_flower"]
const TARGETS := ["prey", "food", "seed", "stick", "bush", "school", "heads", "florets", "at", "centre", "carcass"]


func _has_target(args: Dictionary) -> bool:
	for k: String in TARGETS:
		if args.has(k):
			return true
	return false


# (args with its food in them, under every name a creature might read it by;
# {} if there's none. What it eats from under it (grass, leaves, the
# litter): args as they were.)
func _with_food(args: Dictionary, act := "eat") -> Dictionary:
	if not (creature is Node3D) or Diet.of(creature).is_empty():
		return args
	var kinds := Diet.for_act(creature, act) # (hunting: its prey; eating: any of its food)
	if kinds.is_empty():
		return {}
	var f := Diet.find_one(creature as Node3D, 30.0, kinds)
	if f == null:
		return {}
	if f == creature:
		return args
	f.set_meta("hunted", creature)
	var out := args.duplicate()
	var at: Vector3 = Diet._at(f as Node3D)
	for k: String in ["prey", "food", "seed", "stick", "bush", "school", "carcass"]:
		out[k] = f
	out["at"] = at
	out["centre"] = at
	out["heads"] = f.get_meta("heads", [])
	out["florets"] = f.get_meta("florets", [])
	return out


func act(name: String, args := {}) -> bool:
	if name == "mate": # (everyone's that mates: mate(partner, seconds) -> bool, is_mating())
		if not creature.has_method("mate") or args.get("partner") == null:
			return false
		_cancel()
		if not _call("mate", [args.get("partner"), float(args.get("seconds", -1.0))]):
			_finish(name, false)
			return false
		kind = "act"
		_act = name
		_secs = -1.0
		_t = 0.0
		return true
	if not (_call("_p_behaviours") as PackedStringArray).has(name):
		return false
	if name in FEEDING and not _has_target(args): # (eating: what's really there, never made for it)
		args = _with_food(args, name)
		if args.is_empty():
			return false
	_cancel()
	if not _call("_p_act", [name, args]):
		_finish(name, false)
		return false
	kind = "act"
	_act = name
	_secs = float(args.get("seconds", _call("_p_act_secs", [name])))
	_t = 0.0
	return true


## Each frame (the creature calls it, before its own thinking).
func tick(dt: float) -> void:
	if kind == "":
		return
	_t += dt
	match kind:
		"go":
			var here: Vector3 = _call("_p_here")
			var pace := _speed if _speed > 0.0 else float(_call("_p_speed"))
			var look := maxf(float(_call("_p_reach")) * 6.0, pace * 1.5)
			var to := here + _dir * look
			to.y = here.y
			_call("_p_steer", [to, _speed])
			if _left >= 0.0:
				_left -= dt
				if _left <= 0.0:
					_done(true)
		"go_to":
			_call("_p_steer", [_point, _speed])
			var here: Vector3 = _call("_p_here")
			if Vector2(here.x - _point.x, here.z - _point.z).length() < float(_call("_p_reach")):
				_done(true)
			elif _t > 120.0:
				_done(false)
		"face":
			var here: Vector3 = _call("_p_here")
			var h: Vector3 = _call("_p_heading")
			h.y = 0.0
			if h.length() > 1e-5 and h.normalized().angle_to(_dir) < 0.2:
				_done(true)
			elif _t > 8.0:
				_done(false)
			else:
				_call("_p_steer", [here + _dir * float(_call("_p_reach")) * 4.0, -1.0])
		"act":
			if _act == "mate":
				if not _call("is_mating"):
					_done(true)
			elif _call("_p_act_done", [_act]) or (_secs >= 0.0 and _t >= _secs):
				_done(true)


## (The current order ended: held still, told.)
func _done(ok: bool) -> void:
	var k := _act if kind == "act" else kind
	kind = ""
	_call("_p_hold")
	_finish(k, ok)


## (A new order cuts the last one short.)
func _cancel() -> void:
	if kind != "":
		var k := _act if kind == "act" else kind
		kind = ""
		_finish(k, false)


func _finish(name: String, ok: bool) -> void:
	if finished.is_valid():
		finished.call(name, ok)
