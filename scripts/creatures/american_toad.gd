class_name AmericanToad
extends "res://scripts/creatures/frog.gd" # (by path: found whether or not the editor has seen the class yet)
## An American toad (Anaxyrus americanus), drawn at twice life size, on the
## leopard frog's make and ways (Frog) but its own: squat and broad, its
## snout short and blunt, its legs short (it walks, and hops a little way,
## not leaps); its skin dry and warty all over, brown, reddish or olive, a
## faint pale line down its back, big dark spots each round a wart or two;
## a kidney-shaped parotoid gland behind each eye, the bony crests between
## and behind its eyes; no dorsolateral folds, no lip stripe; its iris
## copper gold; its belly cream, speckled dark. A male's call a long
## musical trill, his one round vocal sac under his chin swelling out
## before it, shimmering; a female's eggs laid in two long strings of
## jelly, tangled in the weed on the bottom. Its tadpoles black, small.

const TOAD_BODY := [[-30.0, 0.8, 11.0, 8.4], [-28.6, 5.2, 13.8, 7.0], [-24.5, 10.8, 17.4, 5.2], [-18.5, 14.8, 20.0, 3.6], [-10.0, 17.0, 22.4, 2.0], [-1.0, 18.2, 25.0, 0.4], [8.0, 18.8, 27.0, -0.4], [16.0, 17.4, 27.4, 0.2], [22.0, 14.2, 25.0, 2.2], [26.5, 9.4, 21.4, 4.6], [29.5, 4.2, 17.0, 7.0], [30.6, 0.6, 14.0, 9.4]] # (squat and rotund: its back a high dome, its belly full)


func _sections() -> Array:
	return TOAD_BODY


func _has_folds() -> bool:
	return false


func _skin_opts() -> Dictionary:
	return {"backs": [Color(0.42, 0.33, 0.22), Color(0.5, 0.35, 0.23), Color(0.39, 0.35, 0.24), Color(0.45, 0.38, 0.27)],
		"folds": 0.0, "lip": 0.0, "warts": 1.0, "stripe": 0.45, "belly_spots": 1.0, "spot_size": 1.45,
		"spot": Color(0.16, 0.11, 0.07), "halo": Color(0.64, 0.56, 0.42), "belly": Color(0.86, 0.82, 0.7)}


func _eye_y() -> float:
	return 18.4


func _leg_k() -> float:
	return 0.72


func _leap_max() -> float:
	return 0.13


func _iris() -> Color:
	return Color(0.74, 0.48, 0.2)


func _single_sac() -> bool:
	return true


func _egg_strings() -> bool:
	return true


func _web_k() -> float:
	return 0.45


func _tad_cols() -> Array: # (black, a little bronze speckled)
	return [Color(0.06, 0.055, 0.05), Color(0.3, 0.26, 0.16), Color(0.16, 0.15, 0.14)]


## Its parotoid glands (kidney shaped, swollen, warty, behind each eye) and
## the bony crests: along the inside of each eye, and behind it, down to
## the gland.
func _build_extra() -> void:
	for side: float in [-1.0, 1.0]:
		var g := _part(Vector3(11.0 * side, 18.4, -8.0), Vector3(8.5, 6.0, 15.0), _skin, _frog)
		g.rotation = Vector3(0.12, -0.3 * side, -0.35 * side)
		var c1 := _part(Vector3(4.8 * side, 20.2, -19.5), Vector3(2.4, 2.6, 11.0), _skin, _frog) # (inside its eye)
		c1.rotation.y = 0.12 * side
		var c2 := _part(Vector3(7.8 * side, 19.8, -13.2), Vector3(6.5, 2.4, 2.6), _skin, _frog) # (behind it)
		c2.rotation.z = -0.3 * side


## (His call: a long musical trill, his sac swelling round under his chin,
## shimmering as he sings; a while, then another.)
func _think(dt: float) -> void:
	if _mode == "call":
		_float_at(_pos)
		var bout := fmod(_st, 16.0)
		_sac = (0.88 + 0.12 * sin(_t * 70.0)) if bout < 11.0 else move_toward(_sac, 0.0, dt * 2.0)
		_throat = 0.4
		if _st > 34.0:
			_sac = 0.0
			wander(_pos, 0.25)
		return
	super(dt)
