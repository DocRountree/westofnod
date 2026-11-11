extends SceneTree
## The figure on a plain, to look at (as tools/trees/preview.gd the trees):
##   xvfb-run godot --path . --resolution 1600x900 --script res://tools/character/preview.gd -- <out_dir> [name] [key=value ...] [face | back | side | row | walk]
## key=value: a look's fields (CharacterLook.FIELDS: hair_style=braids, skin=#7b4e31, ...); row: six figures, by chance.
var out := "user://"
var _name := "figure"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var words := []
	var set_ := {}
	for a in args.slice(1):
		if a.contains("="):
			var kv := a.split("=")
			var f := CharacterLook.field(kv[0])
			set_[kv[0]] = Color.html(kv[1]) if not f.is_empty() and f.type == "color" else kv[1]
		elif a in ["face", "back", "side", "row", "walk", "hands", "chest", "head"]:
			words.append(a)
		else:
			_name = a
	var root3 := Node3D.new()
	root.add_child(root3)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	root3.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-38), deg_to_rad(35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 12.0
	root3.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.42, 0.44, 0.36)
	ground.material_override = gm
	root3.add_child(ground)
	var figures: Array[Avatar] = []
	var n := 6 if words.has("row") else 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var av := Avatar.new()
		av.look = CharacterLook.random(rng, set_) if n > 1 else CharacterLook.new()
		if n == 1:
			for k in set_:
				av.look.put(k, set_[k])
		av.position = Vector3((i - (n - 1) * 0.5) * 0.85, 0.0, 0.0)
		av.rotation.y = PI # (facing the camera, at +z... the figure's front is -z)
		root3.add_child(av)
		figures.append(av)
	var cam := Camera3D.new()
	root3.add_child(cam)
	cam.fov = 35
	if words.has("face"):
		cam.look_at_from_position(Vector3(0.12, 1.68, 0.62), Vector3(0, 1.66, 0))
	elif words.has("chest"):
		cam.look_at_from_position(Vector3(0.25, 1.35, 1.75), Vector3(0, 1.28, 0))
	elif words.has("head"):
		cam.look_at_from_position(Vector3(0.45, 1.66, 1.25), Vector3(0, 1.6, 0))
	elif words.has("hands"):
		cam.look_at_from_position(Vector3(0.5, 0.85, 0.5), Vector3(0.27, 0.78, 0))
	elif words.has("back"):
		cam.look_at_from_position(Vector3(0.9, 1.35, -3.2), Vector3(0, 0.95, 0))
	elif words.has("side"):
		cam.look_at_from_position(Vector3(3.3, 1.3, 0.3), Vector3(0, 0.95, 0))
	elif n > 1:
		cam.look_at_from_position(Vector3(0.6, 1.5, 5.6), Vector3(0, 0.92, 0))
	else:
		cam.look_at_from_position(Vector3(0.9, 1.35, 3.2), Vector3(0, 0.95, 0))
	_go(figures, 2.6 if words.has("walk") else 0.0)

func _go(figures: Array[Avatar], speed: float) -> void:
	await process_frame # (the figures in the scene: their bones made)
	for i in 24:
		for av in figures:
			av.walk(1.0 / 30.0, speed, true)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(_name + ".png"))
	print("saved ", _name)
	quit()
