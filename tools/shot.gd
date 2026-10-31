extends Node
## Test driver: loads the game, waits for the island, and saves screenshots
## from the ground, low and high around the spawn, at the sea and far out.
## godot --path . tools/shot.tscn -- <out_dir> [--climb]  (--climb: only the climbing test)

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
