class_name LadyBeetles
extends "res://scripts/creatures/beetles.gd" # (by path: found whether or not the editor has seen the class yet)
## Convergent lady beetles (Hippodamia convergens), drawn at twice life
## size (about 12 mm long): an oval, rather long for a lady beetle, highly
## domed and glossy; the wing cases orange-red with thirteen black spots
## (six on each, one shared behind the scutellum: some smaller, some
## missing in life; these have all thirteen); the pronotum black, edged
## white, two short white dashes on it converging toward the back (the
## name's); the head black with white patches; short clubbed antennae;
## short black legs. Flying, the elytra raised high and spread, the hind
## wings a whirring blur under them, the legs tucked. Not yet in the game (tools/creatures/beetle_demo.tscn,
## wasp_demo.tscn). Beetles: how they're made and moved; "eating" at a
## leaf, for them, is hunting it over for aphids.

# the spots on each wing case: (x out from the middle line, z), radius (mm)
const SPOTS := [
	[Vector2(0.45, -0.75), 0.2], [Vector2(1.3, -0.3), 0.26], [Vector2(0.55, 0.45), 0.28],
	[Vector2(1.55, 1.05), 0.27], [Vector2(0.75, 1.7), 0.3], [Vector2(0.85, 2.6), 0.24],
]


func _init() -> void:
	body_h = 1.15
	top_speed = 0.035
	reach = 2.8
	fly_speed = 0.45
	fly_pitch = 0.45
	apart = 7.0
	pronotum_part = 17
	colors = {
		"black": Color(0.025, 0.025, 0.03),
		"leg_color": Color(0.03, 0.03, 0.035),
		"shell_a": Color(0.86, 0.24, 0.05),
		"shell_b": Color(0.95, 0.45, 0.14),
		"iridescence": 0.35,
		"shell_metal": 0.0,
		"shell_gloss": 1.0,
		"mark_a": Color(0.02, 0.02, 0.025),
		"mark_b": Color(0.93, 0.92, 0.88),
		"stride_hz": 6.0,
		"sweep": 0.5,
		# flying: the elytra raised high and spread, the legs tucked, the
		# wings a pale smoky brown
		"elytra_open": Vector3(1.05, -0.4, 0.35),
		"fly_tuck": Vector2(0.9, 0.6),
		"fly_hz": 24.0,
		"wing_color": Color(0.6, 0.5, 0.4),
	}
	shape = {
		"under": [Vector3(0.0, -0.4, 0.4), Vector3(3.3, 1.1, 4.8)],
		"pronotum": [Vector3(0.0, 0.25, -1.45), Vector3(3.1, 1.3, 1.6)],
		"elytra": [Vector3(0.0, 0.3, 0.95), Vector3(3.9, 2.4, 4.6)],
		"scutellum": [Vector3(0.0, 0.6, -1.2), Vector3(0.3, 0.2, 0.3)],
		"neck": Vector3(0.0, -0.1, -2.0),
		"head": [Vector3(0.0, -0.05, -0.3), Vector3(1.5, 1.0, 0.9)],
		"clypeus": [Vector3(0.0, -0.3, -0.7), Vector3(1.0, 0.4, 0.4)],
		"eye": [Vector3(0.6, 0.05, -0.35), Vector3(0.38, 0.55, 0.5)],
		"antenna": "clubbed",
		"antenna_at": Vector3(0.45, 0.05, -0.6),
		"antenna_len": 1.4,
		"legs": [
			{"hip": Vector3(0.45, -0.65, -1.2), "f": 0.95, "t": 0.9, "s": 0.65, "home": Vector2(1.75, -2.0)},
			{"hip": Vector3(0.65, -0.7, -0.1), "f": 1.0, "t": 1.0, "s": 0.7, "home": Vector2(2.2, 0.2)},
			{"hip": Vector3(0.8, -0.7, 0.8), "f": 1.1, "t": 1.05, "s": 0.75, "home": Vector2(2.05, 2.05)},
		],
		"leg_r": 0.13,
		"hind_wing": 1.4,
	}


func _marks(ball: Callable) -> void:
	var c: Vector3 = shape.elytra[0]
	var size: Vector3 = shape.elytra[1]
	var pc: Vector3 = shape.pronotum[0]
	var ps: Vector3 = shape.pronotum[1]
	for side: float in [-1.0, 1.0]:
		# the thirteen spots (the shared one: half on each elytron, meeting
		# at the middle line), riding on the elytra
		var m := _el_mark(side)
		for sp: Array in SPOTS:
			var at: Vector2 = sp[0]
			var r: float = sp[1]
			_spot(ball, c, size, at.x * side, c.z + at.y, Vector2(r, r * 1.1), m)
		_spot(ball, c, size, 0.13 * side, -0.6, Vector2(0.13, 0.24), m)
		# the pronotum's white: its side margins, the front edge's corner,
		# and the dash converging toward the back
		_spot(ball, pc, ps, 1.22 * side, pc.z + 0.1, Vector2(0.28, 0.62), 18)
		_spot(ball, pc, ps, 0.75 * side, pc.z - 0.6, Vector2(0.45, 0.15), 18)
		_spot(ball, pc, ps, 0.42 * side, pc.z + 0.15, Vector2(0.11, 0.42), 18, 0.3 * side)
		# the head's white patches, on its front
		var h: Vector3 = shape.neck + (shape.head[0] as Vector3)
		var hs: Vector3 = shape.head[1]
		ball.call(h + Vector3(0.3 * side, 0.12, -hs.z * 0.45), Vector3(0.42, 0.1, 0.3), 20, Basis(Vector3.RIGHT, Vector3(0.0, 0.0, -1.0), Vector3.UP))
