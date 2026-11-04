class_name HummingbirdMoth
extends Lepidoptera
## A hummingbird clearwing (Hemaris thysbe), at twice life size (about 5 cm
## long, its wings 9 cm across): a stout, furry body, olive-yellow on the
## thorax, a band of burgundy across the abdomen, a black fan of a tail
## tuft; clubbed black antennae; clear, glassy wings, their veins and broad
## border reddish brown, beating too fast to see (a blur, ~40 a second); a
## long proboscis. It never settles: it feeds hovering, like a hummingbird.
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
var _tuft: MeshInstance3D


func _init() -> void:
	body_len = 25.0
	wing_len = 22.0
	wing_w = 9.0
	hind_len = 12.0
	hind_w = 8.0
	beat_hz = 40.0
	stroke = Vector2(-0.5, 1.2)
	max_speed = 2.2
	accel = 11.0
	proboscis = 24.0
	pattern = 1
	_head_at = Vector3(0.0, -0.8, -12.0)


func _build() -> void:
	var olive := Color(0.5, 0.48, 0.2)
	var burgundy := Color(0.36, 0.1, 0.09)
	var dark := Color(0.08, 0.07, 0.05)
	# thorax, head (big dark eyes), abdomen in three: olive, the burgundy
	# band, olive; all furry (rough)
	_part(Vector3(0.0, 0.5, -2.5), Vector3(7.0, 6.5, 8.0), olive, 0.95)
	_part(Vector3(0.0, 0.3, -8.0), Vector3(5.0, 4.6, 4.2), olive.darkened(0.15), 0.95)
	for side in [-1.0, 1.0]:
		_part(Vector3(1.9 * side, 0.6, -8.8), Vector3(2.2, 2.8, 2.6), dark, 0.25)
	_part(Vector3(0.0, 0.0, 3.4), Vector3(6.4, 5.8, 5.0), olive, 0.95)
	_part(Vector3(0.0, -0.2, 7.0), Vector3(5.6, 5.0, 4.0), burgundy, 0.9)
	_part(Vector3(0.0, -0.4, 10.0), Vector3(4.4, 4.0, 3.6), olive.darkened(0.1), 0.95)
	_tuft = _part(Vector3(0.0, -0.4, 12.4), Vector3(4.5, 1.2, 3.0), dark, 0.9)
	_antennae(Vector3(1.0, 1.6, -9.5), 8.0, 0.8, dark)
	_legs_at(Vector3(0.0, -2.6, -2.5), 4.0, olive.darkened(0.3))


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
		_tuft.scale = Vector3(4.5 * spread, 1.2, 3.0)
