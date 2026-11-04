class_name Monarch
extends "res://scripts/creatures/lepidoptera.gd" # (by path: found whether or not the editor has seen the class yet)
## A monarch (Danaus plexippus), at twice life size (its wings 20 cm
## across): orange wings veined black, a black border with two rows of
## white dots, the forewings' tips black with orange and white spots;
## beneath paler, the hindwings yellowish with bolder veins; the body black,
## dotted white; clubbed black antennae. Not yet in the game
## (tools/creatures/lepidoptera_demo.tscn).
##
## - fly(centre, radius): flap and glide: a few strong, slow beats, then a
##   glide on its wings held in a shallow V, sinking a little; wandering
##   round centre, banking into its turns, bobbing as it beats
## - bask(at, normal): down onto a surface (a stone, a leaf: at, facing
##   normal, its parent's space), its wings spread flat to the sun, held
##   there; closing them part way now and then and opening them again
## - feed(florets): onto a flower's florets (its parent's space), its wings
##   closed upright over its back, showing their undersides, opening them a
##   little now and then; the proboscis down into a floret; stepping to
##   another every few seconds

var _mode := ""
var _centre := Vector3.ZERO
var _radius := 1.0
var _florets: Array = []
var _at := -1
var _wait := 0.0
var _beats_left := 0.0 # flying: beats till the next glide (or, < 0, s gliding)
var _land_at := Vector3.INF
var _land_n := Vector3.UP


func _init() -> void:
	body_len = 28.0
	wing_len = 48.0
	wing_w = 26.0
	hind_len = 36.0
	hind_w = 30.0
	beat_hz = 7.0
	stroke = Vector2(-0.55, 1.25)
	max_speed = 1.4
	accel = 3.5
	proboscis = 14.0
	stand = 4.0
	pattern = 0
	_head_at = Vector3(0.0, -0.6, -9.5)


func _build() -> void:
	var black := Color(0.03, 0.025, 0.025)
	var white := Color(0.9, 0.88, 0.85)
	_part(Vector3(0.0, 0.5, -3.0), Vector3(4.4, 4.2, 7.5), black, 0.8) # (the thorax)
	_part(Vector3(0.0, 0.2, -8.0), Vector3(3.6, 3.4, 3.2), black, 0.8) # (the head)
	for side in [-1.0, 1.0]:
		_part(Vector3(1.4 * side, 0.4, -8.6), Vector3(1.6, 2.0, 1.9), Color(0.1, 0.09, 0.08), 0.3) # (its eyes)
		for k in 3: # (white dots on the thorax and the head)
			_part(Vector3(1.6 * side, 0.9 - k * 0.8, -5.0 + k * 1.6), Vector3.ONE * 0.6, white, 0.6)
		_part(Vector3(1.2 * side, -0.6, -8.0), Vector3.ONE * 0.5, white, 0.6)
	_part(Vector3(0.0, -0.3, 6.0), Vector3(3.2, 3.0, 13.0), black, 0.8) # (the abdomen)
	_antennae(Vector3(0.7, 1.4, -9.2), 14.0, 0.8, black)
	_legs_at(Vector3(0.0, -1.8, -3.0), 6.0, black)


## Flap and glide, wandering round centre (within radius).
func fly(centre: Vector3, radius: float) -> void:
	_mode = "fly"
	_centre = centre
	_radius = radius
	_land_at = Vector3.INF
	_tongue = 0.0
	_tongue_at = Vector3.INF
	take_off()
	_target = _somewhere(_centre, _radius, 0.5, 1.8)


## Down onto a surface (at, facing normal), to bask, its wings spread.
func bask(at: Vector3, normal: Vector3) -> void:
	_mode = "bask"
	_land_at = at
	_land_n = normal.normalized()
	_tongue = 0.0
	_tongue_at = Vector3.INF
	take_off()
	_wait = 0.0


## Onto a flower's florets, to feed.
func feed(florets: Array) -> void:
	_mode = "feed"
	_florets = florets
	_at = -1
	_wait = 0.0
	_land_at = Vector3.INF
	take_off()


func _think(dt: float) -> void:
	_wait -= dt
	_jitter = 0.0
	if flying:
		_flap_and_glide(dt)
	if _mode == "fly":
		if (_target - _pos).length() < 0.15:
			_target = _somewhere(_centre, _radius, 0.5, 1.8)
		_pitch = 0.15
	elif _mode == "bask":
		if flying:
			_come_down(dt)
		else:
			# spread flat to the sun; now and then closing part way, and open again
			if _wait <= 0.0:
				_open = rng.randf_range(0.35, 0.6) if _open > 0.9 else 1.0
				_wait = rng.randf_range(0.6, 1.2) if _open < 0.9 else rng.randf_range(3.0, 8.0)
			_pitch = 0.0
	elif _mode == "feed":
		if _florets.is_empty():
			return
		if _at < 0:
			_at = _top_floret()
			_land_at = _florets[_at]
			_land_n = Vector3.UP
		if flying:
			_come_down(dt)
			return
		# wings closed over its back, opening a little now and then
		if _wait <= 0.0:
			if _open > 0.05:
				_open = 0.0
				_wait = rng.randf_range(2.0, 5.0)
			else:
				_open = rng.randf_range(0.15, 0.35)
				_wait = rng.randf_range(0.5, 1.0)
			# and every so often a step to another floret near
			if rng.randf() < 0.35:
				var here: Vector3 = _florets[_at]
				for tries in 8:
					var c := rng.randi() % _florets.size()
					if c != _at and (_florets[c] as Vector3).distance_to(here) < 0.04:
						_at = c
						land(_florets[c], Vector3.UP)
						_heading = _heading.rotated(Vector3.UP, rng.randf_range(-0.8, 0.8))
						break
		_tongue = 1.0
		_tongue_at = _florets[_at]
		_pitch = 0.0


## In flight: some strong beats, then a glide on its wings held in a V,
## sinking a little; and so on.
func _flap_and_glide(dt: float) -> void:
	if _beats_left > 0.0:
		_flap = 1.0
		_beats_left -= beat_hz * dt
		if _beats_left <= 0.0:
			_beats_left = -rng.randf_range(0.3, 0.9) # (s to glide)
	else:
		_flap = 0.0
		_glide = 0.32
		_vel.y -= 0.25 * dt # (sinking as it glides)
		_beats_left += dt
		if _beats_left >= 0.0:
			_beats_left = float(rng.randi_range(3, 6))


## Flying down to _land_at: over it, then down onto it, and landing.
func _come_down(_dt: float) -> void:
	if _land_at == Vector3.INF:
		return
	var over := _land_at + _land_n * 0.05
	if _pos.distance_to(over) > 0.04 and _pos.y > _land_at.y + 0.02:
		_target = over
		_pitch = 0.2
	else:
		_target = _land_at + _land_n * stand * MM
		_flap = 1.0 # (beating down onto it)
		if _pos.distance_to(_target) < 0.015:
			land(_land_at, _land_n)
			_open = 1.0 if _mode == "bask" else 0.0
			_wait = rng.randf_range(2.0, 5.0)


## The floret highest up (the top of the flower), to land on first.
func _top_floret() -> int:
	var best := 0
	for i in _florets.size():
		if (_florets[i] as Vector3).y > (_florets[best] as Vector3).y:
			best = i
	return best
