extends Node
## Test driver: loads the game, waits for the island, and saves screenshots
## from the ground, low and high over the rivers, at the sea and far out.
## godot --path . tools/shot.tscn -- <out_dir>

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
	await _shot("01_spawn")
	p.rotate_y(PI * 0.5)
	await _wait(1.0)
	await _shot("02_spawn_side")
	await _view(s + Vector3(0, 30, 0), 0.0, -0.5)
	await _shot("03_river_low")
	await _view(s + Vector3(0, 150, 0), 0.0, -0.45)
	await _shot("04_aerial")
	await _view(s + Vector3(0, 150, 0), PI, -0.3)
	await _shot("05_aerial_back")
	await _view(Vector3(0, 700, 2500), 0.0, -0.35)
	await _shot("06_high")
	await _view(Vector3(0, 300, 1500), 0.0, -0.22)
	await _shot("06a_forest_band")
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
