extends SceneTree
## Renders the oak variants in a row on a plain, for looking at the models.
## xvfb-run godot --path . --resolution 1600x900 --script res://tools/trees/preview.gd -- <out_dir> [lod] [close]

var out := "user://"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var lod := args.has("lod")
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root3.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	root3.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.32, 0.4, 0.2)
	ground.material_override = gm
	root3.add_child(ground)
	var at := [Vector3(-55, 0, 0), Vector3(-27.5, 0, 0), Vector3(0, 0, 0), Vector3(27.5, 0, 0), Vector3(48, 0, 12), Vector3(48, 0, -2), Vector3(62, 0, 0)]
	for v in OakTree.VARIANTS.size():
		var mi := MeshInstance3D.new()
		mi.mesh = OakTree.build_lods(v)[0] if lod else OakTree.build(v)
		mi.position = at[v]
		var shadow := OakTree.build_shadow(v)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root3.add_child(mi)
		if shadow:
			var sh := MeshInstance3D.new()
			sh.mesh = shadow
			sh.position = mi.position
			sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			root3.add_child(sh)
	var cam := Camera3D.new()
	root3.add_child(cam)
	if args.has("snag"):
		cam.look_at_from_position(Vector3(62, 6, 26), Vector3(62, 5, 0))
		cam.fov = 60
	elif args.has("leaves"):
		# a sprig low on the open-grown oak, from a metre and a half
		var tb := OakTree.grow(0)
		var best := Vector3.ZERO
		var best_out := Vector3.ZERO
		for sp in tb.sprigs:
			var q: Vector3 = tb.pos[sp[0]]
			if q.y > 3.0 and (best == Vector3.ZERO or q.y < best.y):
				best = q
				best_out = Vector3(q.x, 0, q.z).normalized()
		best += at[0]
		cam.look_at_from_position(best + best_out * 1.6 + Vector3(0, 0.3, 0), best + Vector3(0, 0.15, 0))
		cam.fov = 60
	elif args.has("dead"):
		cam.look_at_from_position(Vector3(45.5, 2.0, 16.5), Vector3(48, 0.6, 11))
		cam.fov = 60
	elif args.has("side"):
		cam.look_at_from_position(Vector3(-27.5, 8, 30), Vector3(-27.5, 7, 0))
		cam.fov = 60
	elif args.has("close"):
		cam.look_at_from_position(Vector3(-55 + 4.0, 1.7, 6.0), Vector3(-55, 5.0, 0))
		cam.fov = 65
	else:
		cam.look_at_from_position(Vector3(0, 10, 95), Vector3(0, 9, 0))
		cam.fov = 60
	_go()


func _go() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out.path_join("oaks.png"))
	print("saved")
	quit()
