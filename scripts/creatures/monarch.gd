class_name Monarch
extends "res://scripts/creatures/lepidoptera.gd" # (by path: found whether or not the editor has seen the class yet)
## A monarch (Danaus plexippus), at twice life size (its wings 20 cm
## across): tawny orange wings veined black, a black border with two rows
## of white dots, the forewings' tips black crossed by orange and white
## spots; beneath paler, the forewings' tips buff, the hindwings pale buff,
## their veins black edged white (the wings: bake_lepidoptera_wings.py). The
## body black, slender, dotted white along the thorax and the abdomen's
## sides, white spots by the big eyes, palps white beneath; long, slender,
## gradually clubbed antennae; only four legs to walk on (a brush-foot: its
## forelegs small, folded up under the chest). Not yet in the game
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
	fore_wing = "monarch_fore"
	hind_wing = "monarch_hind"
	fore_hinge = Vector3(1.1, 1.5, -4.6)
	hind_hinge = Vector3(1.1, 1.3, -1.6)
	_head_at = Vector3(0.0, -0.8, -8.8)


func _build() -> void:
	var black := Color(0.03, 0.025, 0.025)
	var white := Color(0.92, 0.9, 0.86)
	var eye := Color(0.13, 0.11, 0.09)
	# the thorax: stout, furred black, spotted white on its sides and over
	# its shoulders
	_part(Vector3(0.0, 0.5, -3.0), Vector3(4.6, 4.4, 7.6), black, 0.85, null, 0.25)
	_part(Vector3(0.0, -0.4, -2.6), Vector3(4.0, 3.2, 6.4), black, 0.85, null, 0.2) # (its chest, under)
	# the head: black, two big eyes, white dots round them and on the brow
	_part(Vector3(0.0, 0.2, -7.6), Vector3(3.6, 3.3, 3.0), black, 0.75, null, 0.15)
	for side in [-1.0, 1.0]:
		_part(Vector3(1.45 * side, 0.45, -7.9), Vector3(1.7, 2.4, 2.3), eye, 0.22)
		_part(Vector3(0.55 * side, 1.55, -8.4), Vector3.ONE * 0.55, white, 0.6)
		_part(Vector3(1.55 * side, -0.85, -7.2), Vector3.ONE * 0.5, white, 0.6)
		# the palps: two short, upturned scaly prongs under the face, white
		# beneath
		var palp := _part(Vector3(0.5 * side, -1.0, -9.2), Vector3(0.75, 0.85, 2.4), black, 0.7)
		palp.rotation.x = 0.5
		_part(Vector3(0.5 * side, -1.35, -9.0), Vector3(0.5, 0.4, 1.6), white, 0.7)
		# the thorax's white spots: a row along each side, a pair at the
		# collar, a few under
		for k in 4:
			_part(Vector3(2.15 * side, 0.9 - k * 0.55, -5.4 + k * 1.5), Vector3(0.55, 0.6, 0.65), white, 0.6)
		_part(Vector3(0.9 * side, 2.4, -5.9), Vector3(0.6, 0.45, 0.6), white, 0.6)
		_part(Vector3(1.2 * side, -1.8, -4.0), Vector3(0.6, 0.45, 0.7), white, 0.6)
		_part(Vector3(1.0 * side, -1.9, -1.4), Vector3(0.6, 0.45, 0.7), white, 0.6)
	# the abdomen: slender, in segments tapering to its tip, black, a row
	# of fine white dots low down each side
	var segs := [[1.2, 3.3], [3.8, 3.4], [6.4, 3.3], [9.0, 3.1], [11.6, 2.8], [14.2, 2.4], [16.6, 1.9], [18.6, 1.3]]
	for i in segs.size():
		var z: float = segs[i][0]
		var wd: float = segs[i][1]
		var y := -0.3 - 0.0025 * z * z # (drooping a little toward its tip)
		_part(Vector3(0.0, y, z), Vector3(wd, wd * 0.95, 3.1), black, 0.8, null, 0.12)
		if i < segs.size() - 1:
			for side in [-1.0, 1.0]:
				_part(Vector3(wd * 0.44 * side, y - wd * 0.18, z), Vector3(0.38, 0.38, 0.5), white, 0.6)
	# long slender antennae, gradually clubbed
	_antennae(Vector3(0.6, 1.4, -8.8), 16.0, 1.0, black, 0.17, 0.25)
	# its forelegs small and folded under the chest; the walking four long
	_legs_at(Vector3(0.0, -1.8, -3.0), 7.5, black, true)


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
