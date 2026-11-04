class_name HummingbirdMoth
extends "res://scripts/creatures/lepidoptera.gd" # (by path: found whether or not the editor has seen the class yet)
## A hummingbird clearwing (Hemaris thysbe), at twice life size (about 5 cm
## long, its wings 9 cm across): a stout, densely furred body, olive above,
## cream beneath the thorax and the head, two burgundy segments across the
## abdomen, a fan of a tail tuft, dark with yellowish edges; big dark eyes;
## stout black antennae thickening to a hooked tip; pale legs; clear,
## glassy wings, their veins, a dark bar closing the cell and a broad
## border toothed along the veins reddish brown, the bases olive and furred
## (bake_lepidoptera_wings.py), beating too fast to see (a blur, ~40 a
## second); a long proboscis. It never settles: it feeds hovering, like a hummingbird.
## Not yet in the game (tools/creatures/lepidoptera_demo.tscn).
##
## - search(centre, radius, flowers): darting about from hover to hover,
##   quick and straight, now and then hovering a moment in front of one of
##   the flowers (their heads, its parent's space) to look it over
## - feed(florets): hovering in front of a flower's florets one after
##   another, body tipped up, the proboscis in each (its parent's space),
##   holding there, the tail tuft fanned to steady it; on to another floret
##   every second or two

var _mode := ""
var _centre := Vector3.ZERO
var _radius := 0.5
var _flowers: Array = []
var _florets: Array = []
var _wait := 0.0
var _at := -1 # the floret it's at
var _tuft: Node3D


func _init() -> void:
	body_len = 25.0
	wing_len = 23.0
	wing_w = 9.0
	hind_len = 12.0
	hind_w = 8.0
	beat_hz = 40.0
	stroke = Vector2(-0.5, 1.2)
	max_speed = 2.2
	accel = 11.0
	proboscis = 24.0
	pattern = 1
	fore_wing = "hemaris_fore"
	hind_wing = "hemaris_hind"
	fore_hinge = Vector3(2.0, 2.2, -4.6)
	hind_hinge = Vector3(1.9, 1.9, -1.2)
	_head_at = Vector3(0.0, -0.8, -12.0)


func _build() -> void:
	var olive := Color(0.46, 0.46, 0.19)
	var olive_hi := Color(0.6, 0.57, 0.26) # (the fur's paler tips, over the shoulders)
	var cream := Color(0.86, 0.8, 0.52)
	var burgundy := Color(0.33, 0.08, 0.08)
	var dark := Color(0.07, 0.055, 0.045)
	# the thorax: big and round, densely furred olive above, cream beneath;
	# the shoulder flaps (tegulae) a paler olive
	_part(Vector3(0.0, 0.7, -3.0), Vector3(7.2, 6.6, 8.4), olive, 0.95, null, 0.6)
	_part(Vector3(0.0, -1.2, -3.0), Vector3(6.0, 4.2, 7.6), cream, 0.95, null, 0.5)
	for side in [-1.0, 1.0]:
		var teg := _part(Vector3(2.4 * side, 2.0, -3.8), Vector3(2.6, 2.2, 5.4), olive_hi, 0.95, null, 0.6)
		teg.rotation.z = -0.4 * side
	# the head: olive, the big dark eyes; cream palps under the face, the
	# coiled proboscis between
	_part(Vector3(0.0, 0.4, -8.0), Vector3(5.0, 4.4, 4.0), olive, 0.95, null, 0.5)
	for side in [-1.0, 1.0]:
		_part(Vector3(1.95 * side, 0.6, -8.6), Vector3(2.3, 3.1, 2.9), dark, 0.2)
	_part(Vector3(0.0, -1.5, -9.4), Vector3(3.2, 1.9, 2.4), cream, 0.95, null, 0.5)
	# the abdomen: stout, tapering, in segments: olive, then the two
	# burgundy ones, then olive-yellow; beneath, cream forward, dark
	# burgundy behind
	var segs := [[1.6, 6.6, olive], [4.0, 6.5, olive], [6.3, 6.1, burgundy], [8.5, 5.5, burgundy], [10.5, 4.6, olive_hi]]
	for i in segs.size():
		var z: float = segs[i][0]
		var wd: float = segs[i][1]
		var y := -0.1 - 0.02 * z
		_part(Vector3(0.0, y, z), Vector3(wd, wd * 0.92, 3.0), segs[i][2], 0.95, null, 0.5)
		_part(Vector3(0.0, y - wd * 0.22, z), Vector3(wd * 0.8, wd * 0.5, 2.7), cream if i < 2 else burgundy.darkened(0.3), 0.95, null, 0.4)
	# the tail fan: dark in the middle, yellowish at its edges, spread from
	# the tip (fanned wider to steady it, hovering: _think)
	_tuft = Node3D.new()
	_tuft.position = Vector3(0.0, -0.4, 11.8)
	_body.add_child(_tuft)
	for k in 5:
		var a := (k - 2) * 0.32
		var col := dark if absi(k - 2) < 2 else olive_hi.darkened(0.15)
		var hair := _part(Vector3(sin(a) * 1.4, 0.0, cos(a) * 1.4), Vector3(1.3, 0.8, 3.2), col, 0.95, _tuft, 0.5)
		hair.rotation.y = a
	# stout black antennae, thickening along their length to a hooked tip
	_antennae(Vector3(1.0, 1.9, -9.4), 8.5, 0.8, dark, 0.3, 0.55, true)
	# pale legs
	_legs_at(Vector3(0.0, -2.8, -2.6), 4.5, cream.darkened(0.15))


## Darting about round centre (within radius), now and then hovering in
## front of one of `flowers` (their heads: points, its parent's space).
func search(centre: Vector3, radius: float, flowers := []) -> void:
	_mode = "search"
	_centre = centre
	_radius = radius
	_flowers = flowers
	_wait = 0.0
	_tongue = 0.0
	_tongue_at = Vector3.INF


## Feeding at florets (points, its parent's space), one after another.
func feed(florets: Array) -> void:
	_mode = "feed"
	_florets = florets
	_at = -1
	_wait = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_jitter = 0.0015
	var hovering := (_target - _pos).length() < 0.02
	if _mode == "search":
		_tongue = 0.0
		if hovering and _wait <= 0.0:
			if not _flowers.is_empty() and rng.randf() < 0.45:
				# up to a flower, a few cm in front of it, facing it
				var f: Vector3 = _flowers[rng.randi() % _flowers.size()]
				var away := _flat(f, _pos)
				if away == Vector3.ZERO:
					away = Vector3.BACK
				_target = f + away * 0.07 + Vector3.UP * 0.01
				_look = -away
				_wait = rng.randf_range(0.5, 1.1)
			else:
				_target = _somewhere(_centre, _radius, 0.15, 0.9)
				_look = Vector3.ZERO
				_wait = rng.randf_range(0.3, 1.0)
		# darting: tipped forward going fast; hovering, tipped up, the tail down
		var speed := _vel.length()
		_pitch = lerpf(0.45, -0.25, clampf(speed / max_speed, 0.0, 1.0))
	elif _mode == "feed":
		if _florets.is_empty():
			return
		if _at < 0 or _wait <= 0.0:
			# on to another floret: one near the last, mostly
			var next := rng.randi() % _florets.size()
			if _at >= 0:
				var here: Vector3 = _florets[_at]
				for tries in 6:
					var c := rng.randi() % _florets.size()
					if c != _at and (_florets[c] as Vector3).distance_to(here) < 0.06:
						next = c
						break
			_at = next
			_wait = rng.randf_range(1.0, 2.4)
			_tongue = 0.0 # (out of the old one, into the next)
		var p: Vector3 = _florets[_at]
		# hovering in front of it, the head just over a proboscis' length off,
		# a little above, tipped up
		var away := _flat(p, _pos)
		if away == Vector3.ZERO:
			away = Vector3.BACK
		var off := (proboscis * 0.75 + 11.0) * MM
		_target = p + away * off + Vector3.UP * 0.012
		_look = -away
		_pitch = 0.5
		var there := (_target - _pos).length() < 0.01
		_tongue = 1.0 if there else 0.0
		_tongue_at = p
	# the tail tuft fanned out to steady it, holding still
	if _tuft:
		var spread := 1.0 + 0.6 * clampf(1.0 - _vel.length() / 0.4, 0.0, 1.0)
		_tuft.scale = Vector3(spread, 1.0, 1.0)
