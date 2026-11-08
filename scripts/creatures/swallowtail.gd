class_name Swallowtail
extends "res://scripts/creatures/monarch.gd" # (by path: found whether or not the editor has seen the class yet)
## An Old World swallowtail (Papilio machaon; in North America in the north
## and the west, the black swallowtail's close kin), at twice life size (its
## wings 15 cm across): pale creamy yellow wings barred and banded black
## (the forewing's base black dusted yellow, three black bars from its
## costa, a broad black outer band with a row of yellow spots), the
## hindwing's black band blue scaled within, yellow crescents in its
## scallops, a black tail edged yellow and, by the body, a red eyespot
## ringed black, blue above (the wings: bake_lepidoptera_wings.py). The body
## black above, a yellow stripe along each side, the thorax furred black
## with yellow at its sides and over its shoulders, grey hairs at the
## wings' roots; the head black, a yellow brow; black antennae with a
## stout club; six walking legs, black (a swallowtail's forelegs whole).
##
## Its ways, the monarch's (fly, bask, feed, lay, mate), with its own: it
## feeds with its wings fluttering, never still (as swallowtails do at a
## flower), and lays its eggs, one to a leaf, on the carrot family's plants
## (in the sandbox: yampah); its caterpillar (Larva: swallowtail) green,
## banded black, spotted orange, with its forked orange osmeterium; its
## chrysalis (Pupa: swallowtail) girdled upright.


func _init() -> void:
	super()
	body_len = 30.0
	wing_len = 43.0
	wing_w = 21.0
	hind_len = 40.0
	hind_w = 30.0
	beat_hz = 8.0
	stroke = Vector2(-0.6, 1.2)
	max_speed = 1.6
	accel = 4.0
	proboscis = 16.0
	stand = 4.2
	pattern = 2
	fore_wing = "swallowtail_fore"
	hind_wing = "swallowtail_hind"
	fore_hinge = Vector3(1.2, 1.5, -4.4)
	hind_hinge = Vector3(1.2, 1.3, -1.4)
	_head_at = Vector3(0.0, -0.8, -8.8)
	abdomen_at = Vector3(0.0, -0.3, 0.0)
	abdomen_tip = Vector3(0.0, -0.9, 18.6)
	egg_kind = "swallowtail"


func _build() -> void:
	var black := Color(0.035, 0.03, 0.025)
	var yellow := Color(0.92, 0.82, 0.42)
	var grey := Color(0.55, 0.53, 0.46)
	var eye := Color(0.1, 0.09, 0.07)
	# the thorax: furred black, yellow along its sides, grey hairs at the
	# wings' roots
	_loft_part([[-6.6, 0.0, 1.3, 1.2], [-5.8, 0.1, 2.1, 2.0], [-4.0, 0.15, 2.5, 2.45], [-1.8, 0.1, 2.45, 2.4], [0.0, -0.05, 1.9, 1.95], [0.8, -0.1, 1.2, 1.2]], black, 0.9, null, 0.35)
	for side: float in [-1.0, 1.0]:
		var st := _part(Vector3(2.0 * side, -0.3, -3.0), Vector3(0.9, 1.6, 6.4), yellow, 0.9, null, 0.3)
		st.rotation.x = 0.05
		_part(Vector3(1.5 * side, 1.6, -3.6), Vector3(1.6, 1.1, 3.6), grey, 0.95, null, 0.6) # (the hairs over the wings' roots)
		_part(Vector3(1.3 * side, 1.4, -1.0), Vector3(1.6, 1.0, 2.6), grey, 0.95, null, 0.6)
	# the head: black, a yellow brow, the big eyes
	_part(Vector3(0.0, 0.2, -7.6), Vector3(3.5, 3.2, 3.0), black, 0.8, null, 0.15)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.45 * side, 0.45, -7.9), Vector3(1.7, 2.4, 2.3), eye, 0.22)
		_part(Vector3(0.6 * side, 1.5, -8.4), Vector3(0.9, 0.5, 0.7), yellow, 0.7)
		var palp := _part(Vector3(0.5 * side, -1.0, -9.2), Vector3(0.75, 0.85, 2.4), yellow.darkened(0.2), 0.7)
		palp.rotation.x = 0.5
	# the abdomen: black above, a yellow stripe along each side, paler
	# beneath; its segments' joints faint creases
	_loft_part([[-0.6, 0.1, 1.45, 1.4], [1.0, 0.05, 1.75, 1.65], [4.5, -0.05, 1.8, 1.7], [9.0, -0.25, 1.62, 1.55], [13.5, -0.5, 1.3, 1.22], [16.5, -0.72, 0.9, 0.85], [18.2, -0.86, 0.5, 0.46], [19.0, -0.9, 0.1, 0.1]],
			black, 0.8, _abdomen, 0.15, Vector2(1.2, 2.5))
	for side: float in [-1.0, 1.0]:
		_loft_part([[0.6, -0.35, 0.3, 0.45], [2.0, -0.35, 0.45, 0.6], [9.0, -0.5, 0.42, 0.55], [15.0, -0.9, 0.3, 0.42], [17.6, -1.0, 0.15, 0.2]],
				yellow, 0.8, _abdomen, 0.1).position = Vector3(1.45 * side, 0.0, 0.0)
	# black antennae, a stout club
	_antennae(Vector3(0.6, 1.4, -8.8), 14.0, 1.4, black, 0.18, 0.3)
	# six walking legs, black
	_legs_at(Vector3(0.0, -1.8, -3.0), 8.0, black, false)


## Feeding: as the monarch's, but its wings never still, fluttering over
## its back the while.
func _think(dt: float) -> void:
	super(dt)
	if _mode == "feed" and not flying:
		_open = 0.28 + 0.24 * sin(_t * 16.0)
