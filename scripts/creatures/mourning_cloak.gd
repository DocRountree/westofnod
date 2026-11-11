class_name MourningCloak
extends "res://scripts/creatures/monarch.gd" # (by path: found whether or not the editor has seen the class yet)
## A mourning cloak (Nymphalis antiopa), at twice life size (its wings 15 cm
## across): above, a deep maroon, browner and furred at the base; a broad
## cream border, speckled dark, its edge ragged; inside it a black band
## carrying a row of violet-blue spots; two cream marks on the forewing's
## costa near its tip; the forewing's tip squared off, the hindwing's margin
## drawn into a blunt point. Beneath, bark: near black, finely striated
## grey, its border a dull pale grey (the wings: bake_lepidoptera_wings.py).
## Its body dark, furred maroon brown; its antennae black, their clubs
## tipped pale; only four legs to walk on (a brush-foot, as the monarch).
##
## Its ways (the monarch's: fly, bask, feed, lay, mate), with its own:
## - feed(spots): not at flowers but at sap oozing from a tree, or rotting
##   fruit on the ground: its wings closed over its back the while, the
##   bark of their undersides showing, its proboscis down in it
## - bask(at, normal): spread flat to the sun on a trunk, a stone, bare
##   ground (the first butterfly out in spring: it winters as an adult)
## - rest(at, normal): its wings shut, on bark: gone, its undersides the
##   bark's own
## - startle(): disturbed, its wings flicked open and shut, sharply, a few
##   times (they click), and off
## - lay(spots, normals): its eggs in a cluster, a ring round a twig (on a
##   willow, an elm, a birch); its caterpillars (Larva: cloak) together,
##   black, flecked white, red spots along the back, branched spines; its
##   chrysalis (Pupa: cloak) hanging, grey brown, knobbed and pointed

var _rest := false
var _flick := 0.0 # (s of its startle left)


func _init() -> void:
	super()
	body_len = 26.0
	wing_len = 38.0
	wing_w = 24.0
	hind_len = 32.0
	hind_w = 30.0
	beat_hz = 8.5
	stroke = Vector2(-0.55, 1.25)
	max_speed = 1.6
	accel = 4.0
	proboscis = 12.0
	stand = 3.8
	pattern = 0
	fore_wing = "cloak_fore"
	hind_wing = "cloak_hind"
	fore_hinge = Vector3(1.1, 1.4, -4.2)
	hind_hinge = Vector3(1.1, 1.2, -1.4)
	_head_at = Vector3(0.0, -0.8, -8.4)
	abdomen_at = Vector3(0.0, -0.3, 0.0)
	abdomen_tip = Vector3(0.0, -0.9, 16.4)
	egg_kind = "cloak"


func _build() -> void:
	var fur := Color(0.22, 0.11, 0.08)
	var dark := Color(0.08, 0.06, 0.05)
	var eye := Color(0.12, 0.1, 0.08)
	var pale := Color(0.86, 0.8, 0.62)
	# the thorax: stout, densely furred dark maroon brown
	_loft_part([[-6.4, 0.0, 1.3, 1.2], [-5.6, 0.1, 2.1, 2.0], [-3.8, 0.15, 2.5, 2.45], [-1.6, 0.1, 2.45, 2.4], [0.0, -0.05, 1.9, 1.95], [0.8, -0.1, 1.2, 1.2]], fur, 0.95, null, 0.7)
	# the head: dark, the eyes big, hairy palps
	_part(Vector3(0.0, 0.2, -7.3), Vector3(3.3, 3.0, 2.8), fur, 0.9, null, 0.6)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.4 * side, 0.4, -7.6), Vector3(1.6, 2.3, 2.2), eye, 0.22)
		var palp := _part(Vector3(0.5 * side, -1.0, -8.9), Vector3(0.8, 0.9, 2.6), fur, 0.9, null, 0.6)
		palp.rotation.x = 0.5
	# the abdomen: dark, furred, tapering
	_loft_part([[-0.6, 0.1, 1.4, 1.35], [1.0, 0.05, 1.7, 1.6], [4.5, -0.05, 1.72, 1.62], [9.0, -0.25, 1.5, 1.42], [13.0, -0.5, 1.15, 1.1], [15.6, -0.75, 0.7, 0.66], [16.8, -0.88, 0.15, 0.15]],
			fur.darkened(0.2), 0.9, _abdomen, 0.5, Vector2(1.2, 2.4))
	# antennae black, the clubs tipped pale
	_antennae(Vector3(0.6, 1.4, -8.4), 13.0, 1.3, dark, 0.17, 0.25)
	for side: float in [-1.0, 1.0]:
		var d := Vector3(0.38 * side, 0.55, -0.74).normalized()
		var tip := Vector3(0.6 * side, 1.4, -8.4)
		for k in 10:
			tip += d * 1.3
			d = (d + Vector3(0.0, 0.035, 0.03)).normalized()
		_part(tip, Vector3.ONE * 1.0, pale, 0.5)
	# four walking legs, the forelegs small, folded
	_legs_at(Vector3(0.0, -1.8, -3.0), 7.0, fur, true)


## Its behaviours (pilot.gd): the monarch's, and rest {at, normal}, startle.
func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["rest", "startle"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"rest":
			if not args.has("at"):
				return false
			rest(args.at, args.get("normal", Vector3.UP))
			return true
		"startle":
			startle()
			return true
	return super(name, args)


func rest(at: Vector3, normal := Vector3.UP) -> void:
	bask(at, normal)
	_rest = true


func bask(at: Vector3, normal: Vector3) -> void:
	_rest = false
	super(at, normal)


func fly(centre: Vector3, radius: float) -> void:
	_rest = false
	super(centre, radius)


func startle() -> void:
	if flying:
		return
	_flick = 1.6


func _think(dt: float) -> void:
	super(dt)
	if flying:
		_flick = 0.0
		return
	if _flick > 0.0: # (flicked open and shut, sharply: click, click)
		_flick -= dt
		_open = 1.0 if fmod(_flick, 0.4) > 0.2 else 0.0
		if _flick <= 0.0:
			fly(_pos, 0.6)
		return
	if _mode == "bask" and _rest: # (shut: the bark of its undersides)
		_open = 0.0
		_wait = 10.0
