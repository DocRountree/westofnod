class_name LunaMoth
extends "res://scripts/creatures/monarch.gd" # (by path: found whether or not the editor has seen the class yet)
## A luna moth (Actias luna), at twice life size (its wings 22 cm across,
## its tails 15 cm long): pale green wings, the forewing's costa a broad
## band of purplish maroon, an eyespot on each wing (an oval clear window,
## ringed yellow, black and, outside, maroon), the margins edged yellow and
## pink, the hindwings drawn out into long, curving tails (the wings:
## bake_lepidoptera_wings.py). Its body stout and furred white; a little
## white head; its antennae feathered (broad, a male's), yellowish tan;
## its legs furred purplish pink; no mouthparts to speak of: the adults
## never eat, living only a week to mate and lay.
##
## Its ways: it flies at night, slowly, flapping and gliding (the
## monarch's motor, slower); rests (rest(at, normal)) its wings spread,
## the hindwings' tails hanging; mates; lays its eggs (lay) a few to a
## leaf on its trees (walnut, hickory, sweetgum, birch); feeds never. Its
## caterpillar (Larva: luna) big, lime green, a pale line low along each
## side, magenta warts across its back; its cocoon (Pupa: luna) thin and
## papery, wrapped in leaves in the litter.


func _init() -> void:
	super()
	body_len = 30.0
	wing_len = 56.0
	wing_w = 30.0
	hind_len = 72.0
	hind_w = 40.0
	beat_hz = 4.5
	stroke = Vector2(-0.55, 1.15)
	max_speed = 0.9
	accel = 2.5
	proboscis = 0.5
	stand = 5.0
	pattern = 3
	fore_wing = "luna_fore"
	hind_wing = "luna_hind"
	fore_hinge = Vector3(1.8, 1.9, -4.6)
	hind_hinge = Vector3(1.8, 1.6, -1.4)
	_head_at = Vector3(0.0, -0.6, -8.2)
	abdomen_at = Vector3(0.0, -0.3, 0.0)
	abdomen_tip = Vector3(0.0, -0.8, 17.0)
	egg_kind = "luna"


func _ready() -> void:
	super()
	# (no proboscis: it never feeds)
	if _tongue_node:
		_tongue_node.visible = false
	if _coil:
		_coil.visible = false


func _build() -> void:
	var white := Color(0.93, 0.93, 0.86)
	var cream := Color(0.85, 0.87, 0.7)
	var pink := Color(0.55, 0.25, 0.32)
	var tan := Color(0.8, 0.68, 0.38)
	var eye := Color(0.12, 0.1, 0.08)
	# the thorax: stout, densely furred white, a maroon collar across its
	# front (the costa's colour carried over)
	_loft_part([[-6.8, 0.0, 1.6, 1.5], [-6.0, 0.15, 2.6, 2.5], [-4.0, 0.2, 3.1, 3.0], [-1.8, 0.15, 3.05, 2.95], [0.0, 0.0, 2.5, 2.5], [0.9, -0.1, 1.5, 1.5]], white, 0.95, null, 0.7)
	_part(Vector3(0.0, 1.4, -6.2), Vector3(4.8, 1.4, 1.6), pink, 0.9, null, 0.5) # (the collar)
	# the head: small, white, the eyes dark
	_part(Vector3(0.0, 0.0, -7.6), Vector3(3.2, 2.9, 2.6), white, 0.9, null, 0.5)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.3 * side, 0.2, -7.9), Vector3(1.4, 1.9, 1.8), eye, 0.25)
	# the abdomen: stout, furred white, cream beneath
	_loft_part([[-0.6, 0.1, 2.0, 1.9], [1.0, 0.05, 2.5, 2.4], [5.0, -0.1, 2.6, 2.5], [10.0, -0.35, 2.3, 2.2], [14.0, -0.6, 1.7, 1.6], [16.5, -0.75, 1.0, 0.95], [17.6, -0.8, 0.2, 0.2]],
			white, 0.95, _abdomen, 0.6, Vector2(1.0, 3.0))
	_loft_part([[0.5, -1.4, 1.6, 0.6], [6.0, -1.6, 1.9, 0.7], [13.0, -1.6, 1.3, 0.5], [15.5, -1.5, 0.5, 0.2]], cream, 0.95, _abdomen, 0.4)
	# its antennae: feathered, each a shaft with fine branches out both
	# sides, broad in the middle (a male's), yellowish tan
	for side: float in [-1.0, 1.0]:
		var base := Vector3(0.7 * side, 1.3, -8.4)
		var d := Vector3(0.45 * side, 0.6, -0.66).normalized()
		var across := d.cross(Vector3.UP).normalized() * side
		const N := 14
		var p := base
		for k in N:
			var t := float(k + 1) / N
			var q := p + d * 9.0 / N
			_stick(p, q, 0.13, tan)
			var bl := 1.9 * sin(PI * clampf(t * 1.05, 0.0, 1.0)) + 0.25 # (the branches: longest in the middle)
			for s2: float in [-1.0, 1.0]:
				var b := q + (across * s2 * 0.85 + d * 0.35 + Vector3.UP * 0.12).normalized() * bl
				_stick(q, b, 0.05, tan)
			p = q
			d = (d + Vector3(0.0, -0.02, 0.03)).normalized()
	# its legs: furred, purplish pink
	_legs_at(Vector3(0.0, -2.2, -3.0), 8.5, pink, false)


## Its behaviours (pilot.gd): fly {centre, radius}, rest {at, normal} (its
## wings spread), lay {spots, normals}, mate. It never feeds.
func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["fly", "rest", "mate"]) if male else PackedStringArray(["fly", "rest", "lay", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"feed":
			return false # (no mouthparts)
		"rest":
			if not args.has("at"):
				return false
			rest(args.at, args.get("normal", Vector3.UP))
			return true
	return super(name, args)


## Down onto a surface (a trunk, a leaf: at, facing normal), to rest the
## day out, its wings spread, the tails hanging.
func rest(at: Vector3, normal := Vector3.UP) -> void:
	bask(at, normal)


func feed(_florets: Array) -> void:
	rest(_pos * Vector3(1.0, 0.0, 1.0), Vector3.UP) # (it never eats: down to rest instead)


## Resting: its wings spread (as basking, but still: it doesn't close and
## open them).
func _think(dt: float) -> void:
	super(dt)
	if _mode == "bask" and not flying:
		_open = 1.0
		_wait = 10.0
