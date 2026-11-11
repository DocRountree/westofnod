extends SceneTree
## Renders a butterfly or a moth (or its caterpillar, its pupa) in the
## ecology toolkit's plain (tools/creatures/ecology_demo), doing one of its
## ways, and saves a shot a few seconds in (or several, a second apart).
## xvfb-run godot --path . --resolution 1280x720 --script res://tools/creatures/butterfly_preview.gd -- <out_dir> <key> [adult|young|pupa] [act|rest|spread|hatch] [secs] [side|top|near|low] [shots]
## key: the toolkit's (cloak, cecropia, polyphemus, luna, monarch...); act
## one of the toolkit's (eat, lay, alarm, ...); "rest": set down at once,
## wings shut; "spread": set down at once, wings open; "hatch": the pupa's
## adult out (2).

var out := "user://"
var demo: Node3D
var _key := "cloak"
var _stage := "adult"
var _act := "spread"
var _secs := 3.0
var _view := "top"
var _shots := 1


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: _key = a[1]
	if a.size() > 2: _stage = a[2]
	if a.size() > 3: _act = a[3]
	if a.size() > 4: _secs = float(a[4])
	if a.size() > 5: _view = a[5]
	if a.size() > 6: _shots = int(a[6])
	demo = (load("res://tools/creatures/ecology_demo.tscn") as PackedScene).instantiate()
	get_root().add_child(demo)
	_go()


func _go() -> void:
	for i in 3:
		await process_frame
	demo.call("show_ui", false)
	demo.set("_grass_on", false)
	var o: Node3D = demo.call("spawn", _key, Vector3.ZERO, _stage, false)
	await process_frame
	if _stage == "adult" and _act in ["rest", "spread", "alarm", "display"]:
		if o.has_method("bask"):
			o.call("bask", Vector3.ZERO, Vector3.UP)
		o.call("land", Vector3(0.0, 0.0, 0.0), Vector3.UP)
		o.set("_open", 1.0 if _act == "spread" else 0.0)
		o.set("_open_now", 1.0 if _act == "spread" else 0.0)
		if _act in ["alarm", "display"]:
			for i in 20:
				await process_frame
			demo.call("_do", o, _act)
	elif _act == "hatch":
		o.call("eclose")
	elif _act not in ["rest", "spread", "none"]:
		demo.call("_do", o, _act)
	for s in _shots:
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < (_secs if s == 0 else 1.0) * 1000.0:
			await process_frame
			_aim(o)
		await RenderingServer.frame_post_draw
		var name := "%s_%s_%s_%s%s" % [_key, _stage, _act, _view, "" if _shots == 1 else "_%d" % s]
		get_root().get_texture().get_image().save_png(out.path_join(name + ".png"))
		print("saved ", name, " mode ", o.get("_mode") if is_instance_valid(o) else "-")
	quit()


func _aim(o: Node3D) -> void:
	if not is_instance_valid(o):
		return
	var p := o.global_position
	var d := 0.45 if _key in ["cecropia", "polyphemus"] else 0.32
	if _stage != "adult":
		d *= 0.7
	var c: Vector3
	match _view:
		"side": c = p + Vector3(d, d * 0.25, 0.0)
		"near": c = p + Vector3(d * 0.6, d * 0.5, d * 0.6)
		"low": c = p + Vector3(d * 0.8, 0.03, d * 0.5)
		_: c = p + Vector3(0.0, d * 1.3, 0.02)
	var off := c - p
	var dist := off.length()
	demo.set("_focus", p)
	demo.set("_dist", dist)
	demo.set("_pitch", -asin(clampf(off.y / dist, -1.0, 1.0)))
	demo.set("_yaw", atan2(off.x, off.z))
