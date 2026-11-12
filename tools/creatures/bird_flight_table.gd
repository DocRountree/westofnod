extends SceneTree
## Prints what BirdFlight makes of the five birds the plan (docs/birds.md)
## is sized by: godot --headless --script tools/creatures/bird_flight_table.gd
## (their weights, spans and wing areas: field guide figures, the areas
## estimated; no bird is made).

const BIRDS := [
	# name, kg, span m, wing area m2, its own beat (0: the law's)
	["ruby-throated hummingbird", 0.0032, 0.11, 0.0012, 53.0],
	["house finch", 0.021, 0.24, 0.0090, 0.0],
	["American robin", 0.077, 0.36, 0.020, 0.0],
	["red-tailed hawk", 1.10, 1.25, 0.21, 0.0],
	["wild turkey", 6.0, 1.35, 0.40, 0.0],
]


func _init() -> void:
	var F := BirdFlight
	print("%-26s %7s %5s %5s %6s %6s %6s %5s %6s %7s %7s %6s" % ["bird", "N/m2", "AR", "Hz", "stall", "glide", "L/D", "sink", "r30", "heave", "roll/s", "J"])
	for bd: Array in BIRDS:
		var m: float = bd[1]
		var b: float = bd[2]
		var s: float = bd[3]
		var hz: float = bd[4] if float(bd[4]) > 0.0 else F.wingbeat_hz(m, b, s)
		var vg := F.best_glide_speed(m, b, s)
		var vs := F.min_sink_speed(m, b, s, deg_to_rad(30.0))
		print("%-26s %7.1f %5.1f %5.1f %6.1f %6.1f %6.1f %5.2f %6.1f %6.1fmm %7.0f %6.2f" % [bd[0], F.wing_loading(m, s), F.aspect_ratio(b, s), hz,
				F.stall_speed(m, s), vg, F.glide_ratio(m, b, s), F.sink_rate(m, b, s, vs, deg_to_rad(30.0)), F.turn_radius(vs, deg_to_rad(30.0)),
				F.heave(hz) * 1000.0, rad_to_deg(F.roll_rate(vg, b)), F.advance_ratio(vg, hz, b)])
	print("a finch's bound, 0.25 s shut after 0.35 s flapping: drops %.0f mm, climbs at %.1f m/s2 flapping" % [BirdFlight.bound_drop(0.25) * 1000.0, BirdFlight.bound_climb(0.35, 0.25)])
	quit()
