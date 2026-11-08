extends SceneTree
## Renders the desert's plants (not in the game yet), each species' variants
## in a row on sand: the Joshua tree (JoshuaTree), the San Pedro cactus
## (SanPedroCactus), the prickly pear (PricklyPear); all three, by default.
## xvfb-run godot --path . --resolution 1600x900 --script res://tools/plants/preview.gd -- <out_dir> [joshua | sanpedro | pear] [lod1 | lod2] [close]

const JOSHUA := preload("res://scripts/population/joshua_tree.gd")
const SAN_PEDRO := preload("res://scripts/population/san_pedro_cactus.gd")
const PEAR := preload("res://scripts/population/prickly_pear.gd")

var out := "user://"
var _name := "desert"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var lod := 1 if args.has("lod1") else (2 if args.has("lod2") else 0)
	OakTree.set_lod_fade(false) # (each level drawn wherever it stands)
	var rows := []
	if args.has("joshua"):
		rows = [[JOSHUA, 9.0]]
		_name = "joshua_trees"
	elif args.has("sanpedro"):
		rows = [[SAN_PEDRO, 2.5]]
		_name = "san_pedro"
	elif args.has("pear"):
		rows = [[PEAR, 2.6]]
		_name = "prickly_pears"
	else:
		rows = [[JOSHUA, 9.0], [SAN_PEDRO, 2.5], [PEAR, 2.6]]
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
	sun.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	root3.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.72, 0.62, 0.46) # (desert sand)
	gm.roughness = 1.0
	ground.material_override = gm
	root3.add_child(ground)
	var z := 0.0
	var widest := 0.0
	for r: Array in rows:
		var S: Script = r[0]
		var gap: float = r[1]
		var n: int = S.VARIANTS.size()
		for v in n:
			var mi := MeshInstance3D.new()
			mi.mesh = S.build(v) if lod == 0 else S.build_lods(v)[lod - 1]
			mi.position = Vector3((v - (n - 1) * 0.5) * gap, 0.0, z)
			root3.add_child(mi)
		widest = maxf(widest, gap * n)
		z += gap * 1.6
	var cam := Camera3D.new()
	root3.add_child(cam)
	cam.fov = 55
	if args.has("close"):
		cam.look_at_from_position(Vector3(0, 1.6, z * 0.5 + 3.0), Vector3(0, 1.0, 0))
	else:
		var d := maxf(widest, z) * 1.1 + 4.0
		cam.look_at_from_position(Vector3(0, d * 0.35, -d), Vector3(0, 2.0, z * 0.4))
	_go()


func _go() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out.path_join(_name + ".png"))
	print("saved")
	quit()
