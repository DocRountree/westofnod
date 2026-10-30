extends Node
## Test driver: loads the game, waits for spawn, exercises digging, and saves
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
	p.head.rotation.x = -0.35
	for i in 3:
		p.rotate_y(PI / 2)
		await _wait(1.0)
		await _shot("02_look_%d" % i)
	# dig a few times
	p.head.rotation.x = -1.0
	for i in 4:
		p._dig()
	p.head.rotation.x = -0.9
	await _wait(1.0)
	await _shot("03_dig")
	p.flying = true
	# river close-up from low altitude
	p.global_position += Vector3(0, 25, 0)
	p.head.rotation.x = -0.6
	await _wait(3.0)
	await _shot("03b_river_low")
	# Gerstner ocean at sea level, near the closest coast
	var world: TerrainWorld = main.terrain
	var start := p.global_position
	var best := Vector3.INF
	for k in world._far:
		var mi: MeshInstance3D = world._far[k]
		var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for v in verts:
			if v.y > -3.0 and v.y < -1.0:
				var wp := mi.position + Vector3(v.x, 0, v.z)
				if best == Vector3.INF or wp.distance_to(start) < best.distance_to(start):
					best = wp
	if best != Vector3.INF:
		p.global_position = Vector3(best.x, 2.2, best.z)
		p.head.rotation.x = -0.12
		await _wait(12.0)
		for i in 2:
			await _shot("03c_sea_%d" % i)
			p.rotate_y(PI * 0.6)
			await _wait(6.0)
		p.global_position = start
	# fly up for an overview
	p.global_position += Vector3(0, 140, 0)
	p.head.rotation.x = -0.45
	await _wait(8.0)
	await _shot("04_aerial")
	p.rotate_y(PI)
	await _wait(4.0)
	await _shot("05_aerial_back")
	if OS.get_cmdline_user_args().has("--isolate"):
		var tw: TerrainWorld = main.terrain
		for k in tw._far:
			tw._far[k].visible = false
		await _wait(1.0)
		await _shot("06_no_far")
		for k in tw._far:
			tw._far[k].visible = true
		for k in tw._near:
			tw._near[k].node.visible = false
		await _wait(1.0)
		await _shot("07_no_near")
		for k in tw._near:
			tw._near[k].node.visible = true
		for k in tw._far:
			tw._far[k].visible = false
		p.global_position.y = 600.0
		p.head.rotation.x = -PI / 2
		await _wait(1.0)
		await _shot("08_topdown")
	get_tree().quit()
