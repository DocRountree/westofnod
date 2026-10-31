extends Node
## Test driver: loads the game, waits for the island, and saves screenshots
## from the ground, low and high around the spawn, at the sea and far out.
## godot --path . tools/shot.tscn -- <out_dir> [--climb | --sea | --sky]  (only the climbing / water tests)

var out_dir := "user://"
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_run()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("shot ", name, " at ", main.player.global_position)


func _view(pos: Vector3, yaw: float, pitch: float, settle: float = 2.0) -> void:
	var p: Player = main.player
	p.flying = true
	p.global_position = pos
	p.rotation.y = yaw
	p.head.rotation.x = pitch
	p.velocity = Vector3.ZERO
	await _wait(settle)


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	while main.player.frozen:
		await _wait(0.5)
		if Time.get_ticks_msec() - t0 > 900000:
			print("TIMEOUT waiting for the world")
			get_tree().quit()
			return
	print("world after %d ms" % (Time.get_ticks_msec() - t0))
	var p: Player = main.player
	var isl: WorldData = main.world
	var s := p.global_position
	await _wait(3.0)
	if OS.get_cmdline_user_args().has("--sky"):
		await _sky_shots(s)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--sea"):
		await _sea_shots(s)
		get_tree().quit()
		return
	if not OS.get_cmdline_user_args().has("--climb"):
		await _shot("01_spawn")
	# Third person, walking.
	p.set_third_person(true)
	Input.action_press("move_forward")
	await _wait(1.5)
	await _shot("01b_third_person_walk")
	Input.action_release("move_forward")
	# Climb: find steep rock near by, grip it, climb for a few seconds.
	var rock := Vector3.INF
	for r in range(20, 4000, 10):
		for i in 36:
			var a := TAU * i / 36.0
			var q := s + Vector3(cos(a), 0, sin(a)) * r
			if isl.normal_at(q.x, q.z).y < 0.6:
				rock = q
				break
		if rock != Vector3.INF:
			break
	if rock != Vector3.INF:
		var nrm := isl.normal_at(rock.x, rock.z)
		var base := rock + Vector3(nrm.x, 0, nrm.z).normalized() * 0.8
		p.flying = false
		p.global_position = Vector3(base.x, isl.height_at(base.x, base.z) + 0.1, base.z)
		p.rotation.y = atan2(nrm.x, nrm.z) # face the rock
		p.head.rotation.x = -0.2
		await _wait(0.5)
		p.set_climbing(true)
		print("climbing: ", p.climbing, " at ", p.global_position)
		Input.action_press("move_forward")
		await _wait(3.0)
		await _shot("01c_climb")
		p.rotate_y(0.8)
		await _wait(1.5)
		await _shot("01d_climb_side")
		Input.action_release("move_forward")
		print("climbed to ", p.global_position, "  hand/foot gaps to the rock (m): ", p.avatar.contact_gaps())
		p.set_climbing(false)
		p.set_third_person(false)
	if OS.get_cmdline_user_args().has("--climb"):
		get_tree().quit()
		return
	p.rotate_y(PI * 0.5)
	await _wait(1.0)
	await _shot("02_spawn_side")
	await _view(s + Vector3(0, 30, 0), 0.0, -0.5)
	await _shot("03_river_low")
	await _view(s + Vector3(0, 150, 0), 0.0, -0.45)
	await _shot("04_aerial")
	await _view(s + Vector3(0, 150, 0), PI, -0.3)
	await _shot("05_aerial_back")
	await _view(s + Vector3(0, 700, 0), PI * 0.5, -0.25) # west, toward Isabela
	await _shot("06_high")
	await _view(s + Vector3(0, 4000, 0), PI * 0.5, -0.5)
	await _shot("06a_very_high")
	await _view(s + Vector3(0, 8, 0), PI * 0.3, -0.05)
	await _shot("06b_valley")
	# The coast at sea level, looking along the shore.
	var best := Vector3.INF
	for i in 400:
		var a := TAU * i / 400.0
		for r in range(50, 4000, 20):
			var q := s + Vector3(cos(a) * r, 0.0, sin(a) * r)
			if isl.height_at(q.x, q.z) < -1.5:
				if best == Vector3.INF or q.distance_to(s) < best.distance_to(s):
					best = q
				break
	if best != Vector3.INF:
		var toward := atan2(-best.x, -best.z)
		await _view(Vector3(best.x, 2.0, best.z), toward + PI, -0.08, 4.0)
		await _shot("07_sea")
		# Swim: fall into the sea, then hold jump.
		p.flying = false
		p.global_position = Vector3(best.x, 0.5, best.z)
		await _wait(2.0)
		print("swim: sinking y=%.2f" % p.global_position.y)
		Input.action_press("jump")
		await _wait(1.5)
		Input.action_release("jump")
		print("swim: after jump y=%.2f" % p.global_position.y)
	get_tree().quit()


## The water: the nearest coast low and from above, the open sea all round.
func _sea_shots(s: Vector3) -> void:
	var isl: WorldData = main.world
	var best := Vector3.INF
	for i in 200:
		var a := TAU * i / 200.0
		for r in range(50, 6000, 20):
			var q := s + Vector3(cos(a) * r, 0.0, sin(a) * r)
			if isl.height_at(q.x, q.z) < -1.0:
				if best == Vector3.INF or q.distance_to(s) < best.distance_to(s):
					best = q
				break
	var toward := atan2(-(best.x - s.x), -(best.z - s.z)) # facing away from land
	await _view(Vector3(best.x, 3.0, best.z), toward + PI, -0.12, 3.0)
	await _shot("sea_1_shore")
	await _view(Vector3(best.x, 40.0, best.z), toward + PI, -0.6, 3.0)
	await _shot("sea_2_shore_above")
	var out := best + Vector3(sin(toward), 0, cos(toward)) * -3000.0
	for k in 4:
		await _view(Vector3(out.x, 6.0, out.z), k * PI * 0.5, -0.08, 2.0)
		await _shot("sea_3_open_%d" % k)
	await _view(Vector3(out.x, 400.0, out.z), toward, -0.25, 3.0)
	await _shot("sea_4_high")


## The sky through the day, an aurora night up north, and the wraps.
func _sky_shots(s: Vector3) -> void:
	var clk: GameClock = main.clock
	clk.day_minutes = 0.0 # hold the time for each shot
	for t in [[12.0, "noon"], [17.6, "sunset"], [18.3, "dusk"], [22.0, "night"]]:
		clk.time_of_day = t[0]
		await _view(s + Vector3(0, 300, 0), PI * 0.5, -0.05, 4.0) # west, toward Isabela
		await _shot("sky_%s" % t[1])
	# far north, an aurora night, looking north
	var north := Vector3(s.x, 400.0, main.world.origin.y + 8000.0)
	main.aurora.set_forced(true)
	clk.time_of_day = 23.0
	await _view(north, 0.0, 0.15, 4.0)
	print("latitude %.1f, aurora from %.1f, visible %s" % [WorldConfig.current().latitude, main.aurora.min_latitude, main.aurora.visible])
	await _shot("sky_aurora_north")
	await _view(Vector3(s.x, 400.0, s.z), 0.0, 0.15, 4.0)
	print("latitude %.1f, aurora visible %s" % [WorldConfig.current().latitude, main.aurora.visible])
	await _shot("sky_no_aurora_south")
	main.aurora.set_forced(false)
	# wraps: east off the map, and over the north pole
	clk.time_of_day = 12.0
	var w: float = main.world.domain
	var x1: float = main.world.origin.x + w
	await _view(Vector3(x1 - 5.0, 50.0, s.z), -PI * 0.5, 0.0, 1.0) # facing east
	var day0: int = clk.day
	main.player.velocity = Vector3.ZERO
	main.player.global_position.x = x1 + 3.0
	await _wait(0.5)
	print("east wrap: x %.0f (expect near %.0f), day %d -> %d" % [main.player.global_position.x, main.world.origin.x, day0, clk.day])
	var zt: float = main.world.origin.y
	await _view(Vector3(s.x, 50.0, zt + 5.0), 0.0, 0.0, 1.0) # facing north
	var t0 := clk.time_of_day
	main.player.global_position.z = zt - 3.0
	await _wait(0.5)
	var f: Vector3 = -main.player.global_basis.z
	print("pole wrap: pos %s, facing %s (expect +z), time %.1f -> %.1f" % [main.player.global_position, f, t0, clk.time_of_day])
