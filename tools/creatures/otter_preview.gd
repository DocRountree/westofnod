extends SceneTree
## Renders the otters (RiverOtter, SeaOtter) in the ecology toolkit's plain
## (tools/creatures/ecology_demo), doing one of their ways, and saves a
## shot, a few seconds in (or several, a second apart).
## xvfb-run godot --path . --resolution 1600x900 --script res://tools/creatures/otter_preview.gd -- <out_dir> <river|sea|both> [act] [secs] [near|side|top|low|face] [shots]
## act: one of the toolkit's (wander, eat, hunt, forage, groom, sleep, alarm,
## display, play, sit, lay, nurse, mark), or "land" (put on the bank, still)
## or "water" (in its water, still)

var out := "user://"
var demo: Node3D
var _who := "river"
var _act := "land"
var _secs := 3.0
var _view := "side"
var _shots := 1
var _otters: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		_who = args[1]
	if args.size() > 2:
		_act = args[2]
	if args.size() > 3:
		_secs = float(args[3])
	if args.size() > 4:
		_view = args[4]
	if args.size() > 5:
		_shots = int(args[5])
	demo = (load("res://tools/creatures/ecology_demo.tscn") as PackedScene).instantiate()
	get_root().add_child(demo)
	_go()


func _go() -> void:
	for i in 3:
		await process_frame
	demo.call("show_ui", false)
	var ui: CanvasLayer = demo.get("_ui_layer")
	if ui:
		ui.visible = false
	var kinds := []
	if _who in ["river", "both"]:
		kinds.append("river_otter")
	if _who in ["sea", "both"]:
		kinds.append("sea_otter")
	var x := 0.0
	for k: String in kinds:
		var o: Node3D = demo.call("spawn", k, Vector3(x, 0.0, 0.0), "young" if _act == "young" else "adult", false)
		_otters.append(o)
		x += 6.0
	await process_frame
	var o0: Node3D = _otters[0]
	if _act == "water":
		var q: Dictionary = demo.call("_pond_near", o0.get("_pos"), 3.0)
		o0.call("place", (q.c as Vector3), 0.6)
		o0.call("swim", q.c, 0.01)
	elif _act == "land":
		var q: Dictionary = demo.call("_pond_near", o0.get("_pos"), 3.0)
		if not q.is_empty():
			o0.call("place", (q.c as Vector3) + Vector3(0.0, 0.0, float(q.hd) + 0.8), 0.6)
		o0.call("sit", 0.0)
		o0.call("wander", o0.get("_pos"), 0.0)
		o0.set("_wait", 999.0)
		o0.set("_target", o0.get("_pos"))
	elif _act != "young":
		for o: Node3D in _otters:
			demo.call("_do", o, _act)
	for s in _shots:
		var t0 := Time.get_ticks_msec()
		var wait := _secs if s == 0 else 1.0
		while Time.get_ticks_msec() - t0 < wait * 1000.0:
			await process_frame
			_aim(o0)
		await RenderingServer.frame_post_draw
		var name := "%s_%s_%s%s" % [_who, _act, _view, "" if _shots == 1 else "_%d" % s]
		get_root().get_texture().get_image().save_png(out.path_join(name + ".png"))
		print("saved ", name, " mode ", o0.get("_mode"), " stage ", o0.get("_stage"), " at ", o0.get("_pos"), " target ", o0.get("_target"), " speed ", o0.get("_speed"), " water ", o0.get("_in_water"), " lie ", o0.get("_lie"), " sit ", o0.get("_sit"), " st ", o0.get("_st"), " born ", o0.get("_born_left"), " young ", (o0.get("young_ones") as Array).size())
	quit()


func _aim(o: Node3D) -> void:
	var p := o.global_position
	var yaw := float(o.get("_yaw"))
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var d := 1.6 if _who != "sea" else 2.0
	match _view:
		"near":
			_put(p + right * d * 0.5 + fwd * d * 0.4 + Vector3.UP * 0.25, p)
		"face":
			_put(p + fwd * 0.9 + right * 0.15 + Vector3.UP * 0.08, p + fwd * 0.3)
		"top":
			_put(p + Vector3.UP * d * 1.3 + right * 0.01, p)
		"low":
			_put(p + right * d + Vector3.UP * 0.06, p)
		"back":
			_put(p - right * d * 0.8 - fwd * d * 0.5 + Vector3.UP * 0.4, p)
		_:
			_put(p + right * d + Vector3.UP * 0.35, p)


## (The toolkit's camera, from c looking at f: its own focus, turn, tilt and
## distance, which it places itself by each frame.)
func _put(c: Vector3, f: Vector3) -> void:
	var off := c - f
	var dist := off.length()
	demo.set("_focus", f)
	demo.set("_dist", dist)
	demo.set("_pitch", -asin(clampf(off.y / dist, -1.0, 1.0)))
	demo.set("_yaw", atan2(off.x, off.z))
