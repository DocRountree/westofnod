extends SceneTree
## Renders the water lilies (LilyPad; not in the game yet), its six variants
## in two rows on still water, or one close; or what's held (Items.model).
## xvfb-run godot --path . --resolution 1600x900 --script res://tools/plants/lily_preview.gd -- <out_dir> [0..5 | held] [lod1 | lod2] [low]

var out := "user://"
var _name := "lilies"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var lod := 1 if args.has("lod1") else (2 if args.has("lod2") else 0)
	OakTree.set_lod_fade(false) # (each level drawn wherever it stands)
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root3.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 10.0
	root3.add_child(sun)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	water.mesh = pm
	water.position.y = -0.0005
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.06, 0.09, 0.07) # (a pond: dark, glassy)
	wm.roughness = 0.08
	wm.metallic_specular = 0.6
	water.material_override = wm
	root3.add_child(water)
	var cam := Camera3D.new()
	root3.add_child(cam)
	cam.fov = 40
	var one := -1
	for a in args:
		if a.is_valid_int():
			one = int(a)
	if args.has("held"):
		_name = "lily_held"
		water.visible = false
		var ids := ["lily_pad", "water_lily", "spatterdock"]
		for i in ids.size():
			var m := Items.model(ids[i])
			m.position = Vector3((i - 1) * 0.28, 1.0, 0.0)
			root3.add_child(m)
			var hand := MeshInstance3D.new() # (where it's gripped)
			var sm := SphereMesh.new()
			sm.radius = 0.008
			sm.height = 0.016
			hand.mesh = sm
			hand.position = m.position
			root3.add_child(hand)
		cam.look_at_from_position(Vector3(0.0, 1.12, 0.75), Vector3(0.0, 1.06, 0.0))
	elif one >= 0:
		_name = "lily_%d%s" % [one, "" if lod == 0 else "_lod%d" % lod]
		var mi := MeshInstance3D.new()
		mi.mesh = LilyPad.build(one) if lod == 0 else LilyPad.build_lods(one)[lod - 1]
		root3.add_child(mi)
		if args.has("low"):
			cam.look_at_from_position(Vector3(0.0, 0.12, 0.55), Vector3(0.0, 0.03, 0.0))
		else:
			cam.look_at_from_position(Vector3(0.0, 0.45, 0.5), Vector3(0.0, 0.0, 0.0))
	else:
		_name = "lilies" + ("" if lod == 0 else "_lod%d" % lod)
		for v in LilyPad.VARIANTS:
			var mi := MeshInstance3D.new()
			mi.mesh = LilyPad.build(v) if lod == 0 else LilyPad.build_lods(v)[lod - 1]
			mi.position = Vector3((v % 3 - 1) * 0.6, 0.0, (v / 3) * 0.6 - 0.3)
			root3.add_child(mi)
		if args.has("low"):
			cam.look_at_from_position(Vector3(0.0, 0.35, 1.9), Vector3(0.0, 0.0, 0.0))
		else:
			cam.look_at_from_position(Vector3(0.0, 1.5, 1.4), Vector3(0.0, 0.0, 0.0))
	_go()


func _go() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out.path_join(_name + ".png"))
	print("saved")
	quit()
