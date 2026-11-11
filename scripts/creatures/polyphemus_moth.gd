class_name PolyphemusMoth
extends "res://scripts/creatures/luna_moth.gd" # (by path: found whether or not the editor has seen the class yet)
## A polyphemus moth (Antheraea polyphemus), at twice life size (its wings
## 26 cm across): tawny orange-brown; the forewing's costa dusted grey, a
## pink-white line near its base edged red, a small round eyespot (a clear
## window ringed yellow and black), a pink-white line beyond edged dark;
## the hindwing's great eyespot (named for the Cyclops): a clear window, a
## yellow ring, black with a blue arc over it, a black blotch round it,
## rimmed pink; a dark band beyond and a pink line (the wings:
## bake_lepidoptera_wings.py). Its body furred tawny, a pale collar; its
## antennae broadly feathered, tan; no mouthparts: it never eats.
##
## Its ways (the luna's), with its own:
## - rest(at, normal): by day, its wings shut up over its back, the great
##   eyes hidden (a dead leaf)
## - startle(): disturbed, its wings flung open and pumped, the hindwings'
##   eyes staring out (an owl's face), a while; then shut again
## - lay(spots, normals): its eggs singly and in twos on leaves of its trees
##   (oak, maple, birch, willow). Its caterpillar (Larva: polyphemus) big,
##   bright green, plump, slanting yellow lines down its sides, small
##   orange-red knobs flecked silver; its cocoon (Pupa: polyphemus) a tough
##   oval, wrapped in a leaf, dropped to the litter

var _flash := 0.0 # (s of its startle left)


func _init() -> void:
	super()
	body_len = 34.0
	wing_len = 58.0
	wing_w = 30.0
	hind_len = 40.0
	hind_w = 38.0
	beat_hz = 4.5
	stroke = Vector2(-0.55, 1.15)
	max_speed = 0.9
	accel = 2.4
	stand = 5.6
	fore_wing = "polyphemus_fore"
	hind_wing = "polyphemus_hind"
	fore_hinge = Vector3(2.0, 2.1, -5.0)
	hind_hinge = Vector3(2.0, 1.8, -1.5)
	_head_at = Vector3(0.0, -0.6, -8.8)
	abdomen_at = Vector3(0.0, -0.3, 0.0)
	abdomen_tip = Vector3(0.0, -0.9, 18.6)
	egg_kind = "polyphemus"


func _build() -> void:
	var tawny := Color(0.66, 0.42, 0.24)
	var pale := Color(0.84, 0.74, 0.62)
	var tan := Color(0.62, 0.48, 0.3)
	var eye := Color(0.1, 0.08, 0.07)
	_loft_part([[-7.4, 0.0, 1.9, 1.8], [-6.5, 0.15, 3.0, 2.9], [-4.4, 0.25, 3.5, 3.4], [-2.0, 0.15, 3.45, 3.35], [0.0, 0.0, 2.8, 2.8], [1.0, -0.1, 1.7, 1.7]], tawny, 0.95, null, 0.75)
	_part(Vector3(0.0, 1.5, -6.8), Vector3(5.4, 1.5, 1.6), pale, 0.9, null, 0.6) # (the collar)
	_part(Vector3(0.0, 0.0, -8.2), Vector3(3.5, 3.2, 2.8), tawny, 0.9, null, 0.6)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.4 * side, 0.2, -8.5), Vector3(1.5, 2.0, 1.9), eye, 0.25)
	_loft_part([[-0.6, 0.1, 2.3, 2.2], [1.0, 0.05, 2.8, 2.7], [5.5, -0.1, 3.0, 2.9], [11.0, -0.35, 2.6, 2.5], [15.5, -0.65, 1.9, 1.8], [18.2, -0.85, 1.0, 0.95], [19.2, -0.9, 0.2, 0.2]],
			tawny, 0.95, _abdomen, 0.6, Vector2(1.0, 3.0))
	_feathered(Vector3(0.8, 1.4, -9.0), 10.0, 2.2, tan)
	_legs_at(Vector3(0.0, -2.4, -3.2), 9.0, tawny.darkened(0.15), false)


func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append("startle")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	if name == "startle":
		startle()
		return true
	return super(name, args)


## (Its wings flung open, the great eyes staring, pumped a while.)
func startle() -> void:
	if not flying:
		_flash = 4.0


func fly(centre: Vector3, radius: float) -> void:
	_flash = 0.0
	super(centre, radius)


## Resting: its wings shut over its back (but startled: flung open,
## pumping, the hindwings' eyes showing).
func _think(dt: float) -> void:
	super(dt)
	if flying or _mode != "bask":
		return
	if _flash > 0.0: # (its forewings drawn up off the hindwings: the eyes)
		_flash -= dt
		_open = 0.75 + 0.25 * sin(_t * 9.0) if _flash < 3.6 else 1.0
		fore_forward = 0.55
	else:
		_open = 0.0
		fore_forward = 0.0
	_wait = 10.0
