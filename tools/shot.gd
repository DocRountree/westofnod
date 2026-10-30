extends Node
## Test driver: loads the game, waits for spawn, exercises dig/place, and saves
## screenshots. godot --path . tools/shot.tscn -- <out_dir>

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


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	while main.player.frozen:
		await _wait(0.5)
		if Time.get_ticks_msec() - t0 > 240000:
			print("TIMEOUT waiting for spawn")
			get_tree().quit()
			return
	print("spawned after %d ms at %s" % [Time.get_ticks_msec() - t0, main.player.global_position])
	var p: Player = main.player
	# let the near ring fill in
	await _wait(25.0)
	await _shot("01_spawn")
	p.camera.rotation.x = -0.35
	for i in 3:
		p.rotate_y(PI / 2)
		await _wait(1.0)
		await _shot("02_look_%d" % i)
	# dig a few times + place blocks
	p.camera.rotation.x = -1.0
	for i in 4:
		p._break()
	p._select(6)
	p.camera.rotation.x = -0.6
	p._place()
	p.rotate_y(0.3)
	p._place()
	p.camera.rotation.x = -0.9
	await _wait(1.0)
	await _shot("03_dig_place")
	print("inventory ", p.inventory)
	# fly up for an overview
	p.flying = true
	p.global_position += Vector3(0, 140, 0)
	p.camera.rotation.x = -0.45
	await _wait(8.0)
	await _shot("04_aerial")
	p.rotate_y(PI)
	await _wait(4.0)
	await _shot("05_aerial_back")
	get_tree().quit()
