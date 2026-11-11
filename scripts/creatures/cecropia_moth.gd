class_name CecropiaMoth
extends "res://scripts/creatures/luna_moth.gd" # (by path: found whether or not the editor has seen the class yet)
## A cecropia moth (Hyalophora cecropia), the biggest moth here, at twice
## life size (its wings 30 cm across): frosted, dark brown dusted grey all
## over; the wings' bases red; a white band across both wings, red-orange
## on its outer side; a white crescent edged red at each wing's middle;
## beyond the band a pale tan zone to the margin, a dark wavy line through
## it; the forewing's tip lilac, a black eyespot in it with a blue-white
## crescent, a white zigzag (the wings: bake_lepidoptera_wings.py). Its
## body red-orange, furred: a white collar, the abdomen banded white; its
## legs red-orange; its antennae broadly feathered, dark (a male's
## broadest); no mouthparts: it never eats, living a week or two.
##
## Its ways (the luna's): flies at night, slow, heavy, flapping and
## gliding; rests by day its wings spread flat; mates (the female calling
## at night, the male finding her by her scent from far off); lays its eggs
## (lay) in twos and threes on leaves of its trees (maple, cherry, birch,
## willow). Its caterpillar (Larva: cecropia) huge, pale bluish green,
## its knobs red on its thorax, yellow along its back, blue down its sides,
## each bristling black; its cocoon (Pupa: cecropia) big, baggy, brown, a
## spindle of tough silk.


func _init() -> void:
	super()
	body_len = 40.0
	wing_len = 65.0
	wing_w = 33.0
	hind_len = 44.0
	hind_w = 42.0
	beat_hz = 4.0
	stroke = Vector2(-0.5, 1.1)
	max_speed = 0.8
	accel = 2.2
	stand = 6.5
	fore_wing = "cecropia_fore"
	hind_wing = "cecropia_hind"
	fore_hinge = Vector3(2.4, 2.4, -5.8)
	hind_hinge = Vector3(2.4, 2.0, -1.8)
	_head_at = Vector3(0.0, -0.6, -10.0)
	abdomen_at = Vector3(0.0, -0.4, 0.0)
	abdomen_tip = Vector3(0.0, -1.0, 22.0)
	egg_kind = "cecropia"
	fore_forward = 0.2 # (at rest, its forewings drawn a little forward, the hindwings showing)


func _build() -> void:
	var red := Color(0.78, 0.3, 0.14)
	var white := Color(0.94, 0.92, 0.88)
	var brown := Color(0.25, 0.18, 0.14)
	var eye := Color(0.1, 0.08, 0.07)
	# the thorax: stout, densely furred red-orange, a white collar across its front
	_loft_part([[-8.4, 0.0, 2.2, 2.0], [-7.4, 0.2, 3.4, 3.2], [-5.0, 0.3, 4.0, 3.9], [-2.2, 0.2, 3.9, 3.8], [0.0, 0.0, 3.2, 3.2], [1.1, -0.1, 2.0, 2.0]], red, 0.95, null, 0.7)
	_part(Vector3(0.0, 1.6, -7.8), Vector3(6.4, 1.8, 1.8), white, 0.9, null, 0.6)
	for side: float in [-1.0, 1.0]: # (the white edges of its shoulder flaps)
		_part(Vector3(2.6 * side, 2.0, -4.0), Vector3(1.0, 1.0, 5.0), white, 0.9, null, 0.6)
	# the head: red, a white band across it, the eyes dark
	_part(Vector3(0.0, 0.0, -9.4), Vector3(4.0, 3.6, 3.2), red, 0.9, null, 0.6)
	_part(Vector3(0.0, 1.2, -9.6), Vector3(3.6, 1.0, 2.6), white, 0.9, null, 0.5)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.6 * side, 0.1, -9.8), Vector3(1.6, 2.2, 2.0), eye, 0.25)
	# the abdomen: stout, red-orange, banded white
	_loft_part([[-0.8, 0.1, 2.6, 2.5], [1.2, 0.05, 3.2, 3.1], [6.5, -0.1, 3.4, 3.3], [12.5, -0.4, 3.0, 2.9], [17.5, -0.75, 2.2, 2.1], [21.0, -0.95, 1.2, 1.1], [22.4, -1.0, 0.25, 0.25]],
			red, 0.95, _abdomen, 0.6, Vector2(1.0, 3.6))
	for k in 5:
		var z := 2.6 + 3.6 * k
		var wd := 3.3 - 0.004 * z * z
		_part(Vector3(0.0, -0.1 - 0.0016 * z * z, z), Vector3(wd * 2.04, wd * 2.0, 0.9), white, 0.9, _abdomen, 0.5)
	# antennae broadly feathered, dark brown
	_feathered(Vector3(0.9, 1.6, -10.2), 11.0, 2.4, brown)
	# its legs: furred, red-orange
	_legs_at(Vector3(0.0, -2.8, -3.6), 10.5, red, false)
