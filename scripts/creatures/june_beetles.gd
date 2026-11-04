class_name JuneBeetles
extends "res://scripts/creatures/beetles.gd" # (by path: found whether or not the editor has seen the class yet)
## June beetles (Phyllophaga, "June bugs"), drawn at twice life size (about
## 40 mm long): a stout, oblong, convex body; the wing cases and pronotum a
## glossy reddish brown (lacquered, not metallic), the wing cases with
## faint ridges along them; the head small and darker, a broad clypeus
## before it; antennae short, ending in a club of three long plates
## fanned a little (lamellate); long, sturdy legs, reddish brown, the
## tibiae spurred, the tarsi in segments with paired claws. Slow and
## clumsy on the ground. Not yet in the game (tools/creatures/
## beetle_demo.tscn, wasp_demo.tscn). Beetles: how they're made and moved.


func _init() -> void:
	body_h = 4.9
	top_speed = 0.04 # (2 cm/s, twice life size)
	reach = 9.4
	apart = 26.0
	colors = {
		"black": Color(0.24, 0.13, 0.06), # (the head, the underside)
		"leg_color": Color(0.38, 0.19, 0.08),
		"shell_a": Color(0.42, 0.2, 0.07), # (facing you)
		"shell_b": Color(0.68, 0.4, 0.16), # (the gloss at a glance)
		"iridescence": 0.55,
		"shell_metal": 0.0,
		"shell_gloss": 0.85,
		"mark_a": Color(0.3, 0.13, 0.05), # (the ridges, a shade darker)
		"stride_hz": 3.5,
		"sweep": 0.2,
	}
	shape = {
		"under": [Vector3(0.0, -1.7, 1.4), Vector3(8.4, 3.6, 15.0)],
		"pronotum": [Vector3(0.0, 0.8, -3.7), Vector3(8.6, 4.6, 5.6)],
		"elytron": [Vector3(2.0, 1.0, 3.4), Vector3(5.0, 6.6, 13.4)],
		"scutellum": [Vector3(0.0, 2.4, -0.9), Vector3(1.8, 0.8, 1.6)],
		"neck": Vector3(0.0, -0.3, -6.2),
		"head": [Vector3(0.0, 0.1, -0.9), Vector3(4.6, 3.0, 3.2)],
		"clypeus": [Vector3(0.0, -0.3, -2.4), Vector3(3.8, 1.1, 1.4)],
		"eye": [Vector3(2.0, 0.2, -0.8), Vector3(1.3, 1.7, 1.7)],
		"antenna": "lamellate",
		"antenna_at": Vector3(1.5, -0.3, -2.1),
		"antenna_len": 4.2,
		"legs": [
			{"hip": Vector3(1.3, -2.0, -4.2), "f": 4.4, "t": 4.2, "s": 3.8, "home": Vector2(7.2, -8.6)},
			{"hip": Vector3(2.0, -2.3, -0.6), "f": 4.6, "t": 4.6, "s": 3.8, "home": Vector2(8.8, 0.4)},
			{"hip": Vector3(2.4, -2.3, 1.8), "f": 5.4, "t": 5.6, "s": 4.6, "home": Vector2(8.4, 8.0)},
		],
		"leg_r": 0.5,
		"spines": true,
	}


## Faint ridges along the wing cases.
func _marks(ball: Callable) -> void:
	var c: Vector3 = shape.elytron[0]
	var size: Vector3 = shape.elytron[1]
	for side: float in [-1.0, 1.0]:
		var e := Vector3(c.x * side, c.y, c.z)
		for x in [0.6, 1.7, 2.9]:
			_spot(ball, e, size, x * side, c.z + 0.3, Vector2(0.16, 4.6 - x * 0.5), 17)
