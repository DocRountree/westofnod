extends SceneTree
## Renders a species' variants in a row on a plain, for looking at the
## models (the oak's; or with maple, sycamore, lodgepole, cypress, pawpaw or
## crabapple, theirs: MapleTree, SycamoreTree, LodgepolePine, BaldCypress,
## PawpawTree, CrabappleTree; or walnut, WalnutTree; tulip, TulipTree; cherry,
## raspberry, blueberry: BlackCherryTree, RaspberryBush, BlueberryBush).
## xvfb-run godot --path . --resolution 1600x900 --script res://tools/trees/preview.gd -- <out_dir> [maple | sycamore | lodgepole | cypress | pawpaw | crabapple | walnut | tulip] [lod] [side | pair | pair2 | close | bark | leaves | dead | snag | saplings]

var out := "user://"
var _name := "oaks"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var lod := args.has("lod")
	var S: Script = OakTree
	var species := "oaks"
	if args.has("maple"):
		S = MapleTree
		species = "maples"
	elif args.has("sycamore"):
		S = SycamoreTree
		species = "sycamores"
	elif args.has("lodgepole"):
		S = LodgepolePine
		species = "lodgepoles"
	elif args.has("cypress"):
		S = BaldCypress
		species = "cypresses"
	elif args.has("pawpaw"):
		S = PawpawTree
		species = "pawpaws"
	elif args.has("crabapple"):
		S = CrabappleTree
		species = "crabapples"
	elif args.has("walnut"):
		S = WalnutTree
		species = "walnuts"
	elif args.has("tulip"):
		S = TulipTree
		species = "tulip trees"
	elif args.has("cherry"):
		S = BlackCherryTree
		species = "black cherries"
	elif args.has("raspberry"):
		S = RaspberryBush
		species = "raspberries"
	elif args.has("blueberry"):
		S = BlueberryBush
		species = "blueberries"
	_name = species
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
	var at := [Vector3(-55, 0, 0), Vector3(-27.5, 0, 0), Vector3(0, 0, 0), Vector3(27.5, 0, 0), Vector3(48, 0, 12), Vector3(48, 0, -2), Vector3(62, 0, 0), Vector3(40, 0, 2), Vector3(54, 0, 6), Vector3(14, 0, 14), Vector3(20, 0, 16), Vector3(78, 0, -8), Vector3(92, 0, 6)]
	var spread := 1.25 if S == SycamoreTree else 1.0 # (the sycamores are bigger)
	if S == LodgepolePine:
		spread = 0.6 # (slim)
	elif S == PawpawTree or S == CrabappleTree:
		spread = 0.35 # (small trees)
	elif S == RaspberryBush or S == BlueberryBush:
		spread = 0.06 # (bushes)
	for i in at.size():
		at[i] *= spread
	S.build(0)
	for v in S.VARIANTS.size():
		var mi := MeshInstance3D.new()
		mi.mesh = S.build_lods(v)[0] if lod else S.build(v)
		mi.position = at[v]
		var shadow: Mesh = S.build_shadow(v)
		var casts: bool = shadow == null and S.variant_props(v).get("shadows", true)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root3.add_child(mi)
		# its fruit, if it bears any (as Foraging hangs them: every spot)
		if S.has_method("fruit_of") and S.fruit_of(v) != "":
			var spots: PackedVector3Array = S.fruit_spots(v)
			for i in mini(spots.size(), Foraging.MOST):
				var f := Items.model(S.fruit_of(v))
				f.position = mi.position + spots[i]
				root3.add_child(f)
		var near: Array = S.near_multimesh(v)
		if not near.is_empty():
			var smi := MultiMeshInstance3D.new()
			# (those on its thick moss, as Population picks them out)
			var mat: ShaderMaterial = near[1]
			var out := []
			Population._sporophytes_on_moss((near[0] as MultiMesh).buffer, Transform3D(Basis(), mi.position),
					Population.moss_of(mat), out)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.use_custom_data = true
			mm.mesh = (near[0] as MultiMesh).mesh
			mm.instance_count = out[1]
			if out[1] > 0:
				mm.buffer = out[0]
			smi.multimesh = mm
			smi.custom_aabb = (near[0] as MultiMesh).get_aabb().grow(0.05)
			smi.material_override = near[1]
			smi.position = mi.position
			smi.set_instance_shader_parameter("tree_at", mi.position)
			root3.add_child(smi)
		if shadow:
			var sh := MeshInstance3D.new()
			sh.mesh = shadow
			sh.position = mi.position
			sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			root3.add_child(sh)
	var cam := Camera3D.new()
	root3.add_child(cam)
	if args.has("saplings"):
		cam.look_at_from_position(Vector3(17, 2.2, 25), Vector3(17, 1.8, 15))
		cam.fov = 60
	elif args.has("snag"):
		cam.look_at_from_position(Vector3(62, 6, 26), Vector3(62, 5, 0))
		cam.fov = 60
	elif args.has("leaves"):
		# a sprig low on the open-grown oak, from a metre and a half
		var tb: TreeBuilder = OakTree.grow(0) if S == OakTree else S.species().grow(0)
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
		cam.look_at_from_position(Vector3(44, 3.5, 19), Vector3(47, 0.4, 5))
		cam.fov = 60
	elif args.has("side"):
		cam.look_at_from_position(Vector3(-27.5, 8, 30), Vector3(-27.5, 7, 0))
		cam.fov = 60
	elif args.has("bark"): # an arm's length from a dead oak's trunk (the lichen)
		cam.look_at_from_position(Vector3(62 + 0.3, 1.5, 1.2), Vector3(62, 1.3, 0))
		cam.fov = 55
	elif args.has("moss"): # close over the stump's top (its moss and sporophytes)
		cam.look_at_from_position(Vector3(48 + 0.45, 1.3, 12 + 0.45), Vector3(48, 0.85, 12))
		OakTree.set_player(Vector3(48 + 0.45, 0.0, 12 + 0.45))
		cam.fov = 50
	elif args.has("pair"): # the first two standing trees, nearer
		var hy := 9.0 * clampf(spread * 1.5, 0.4, 1.0) # (lower for the small trees)
		cam.look_at_from_position(Vector3(-41.25 * spread, hy, 40 * spread), Vector3(-41.25 * spread, hy * 0.85, 0))
		cam.fov = 55
	elif args.has("pair2"): # the other two
		var hy := 11.0 * clampf(spread * 1.5, 0.35, 1.0)
		cam.look_at_from_position(Vector3(13.75 * spread, hy, 45 * spread), Vector3(13.75 * spread, hy * 0.85, 0))
		cam.fov = 55
	elif args.has("close"):
		cam.look_at_from_position(Vector3(-55 + 4.0, 1.7, 6.0), Vector3(-55, 5.0, 0))
		cam.fov = 65
	else:
		cam.look_at_from_position(Vector3(0, 10, 95) * Vector3(1, 1, spread), Vector3(0, 9, 0))
		cam.fov = 60
	OakTree.set_lod_fade(false) # (no chunks here: show each level wherever it is)
	_go()


func _go() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out.path_join(_name + ".png"))
	print("saved")
	quit()
