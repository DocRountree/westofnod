extends SceneTree
## Pictures of the sandbox's organisms for the README (docs/organisms/KEY.jpg):
## each spawned in the ecology sandbox (tools/creatures/ecology_demo.tscn) and
## framed on its own bounds. Run:
##   godot --path . --script tools/creatures/organism_portraits.gd -- KEY[:stage[:male[:camera pitch]]] ...
## (the catalogue's keys: ecology_demo.gd's CATALOGUE).
var OUT := ProjectSettings.globalize_path("res://docs/organisms/")
func _init() -> void:
	var demo: Node3D = (load("res://tools/creatures/ecology_demo.tscn") as PackedScene).instantiate()
	get_root().add_child(demo)
	_go(demo)
func _aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "VisualInstance3D", true, false):
		var vi := m as VisualInstance3D
		if not vi.is_visible_in_tree() or vi is Light3D:
			continue
		var b := vi.global_transform * vi.get_aabb()
		if b.size.length() > 60.0 or b.size.length() < 1e-5:
			continue
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box
func _go(demo: Node3D) -> void:
	for i in 4: await process_frame
	demo.call("show_ui", false)
	for n in get_root().find_children("*", "Control", true, false):
		(n as Control).visible = false
	RenderingServer.render_loop_enabled = false
	var lamp: OmniLight3D = null
	var cam := Camera3D.new()
	cam.fov = 30.0
	get_root().add_child(cam)
	cam.make_current()
	for spec in OS.get_cmdline_user_args():
		var p: PackedStringArray = spec.split(":")
		var key := p[0]
		var stage := p[1] if p.size() > 1 else "adult"
		var male := p.size() > 2 and p[2] == "m"
		var pitch := float(p[3]) if p.size() > 3 else 0.46
		demo.call("clear_all")
		for i in 3: await process_frame
		var n: Node = demo.call("spawn", key, Vector3(0, 0, 0), stage, male)
		if n == null:
			print("SKIP ", key)
			continue
		if key in ["white_shrimp", "brown_shrimp", "pink_shrimp", "krill", "mollies", "chinook", "chinook_spawning", "rainbow", "steelhead", "bluefin"]:
			for q: Dictionary in demo.get("_ponds"): # (seen from above, the water: its surface drawn away)
				var nd: Array = q.nodes
				if not nd.is_empty() and nd[nd.size() - 1] is Node3D:
					(nd[nd.size() - 1] as Node3D).visible = false
		var settle := 40
		if key in ["mollies", "chinook", "rainbow", "steelhead", "krill", "bluefin"]: settle = 90
		for i in settle: await process_frame
		var box := _aabb(n)
		var c := box.get_center()
		var r := maxf(box.size.length() * 0.5, 0.004)
		var radii := {"mollies": 0.3, "chinook": 1.4, "chinook_spawning": 1.0, "rainbow": 0.7, "steelhead": 0.8, "krill": 1.6, "bluefin": 2.6,
				"white_shrimp": 0.09, "brown_shrimp": 0.09, "pink_shrimp": 0.09,
				"carpenter": 0.025, "harvester": 0.025, "june": 0.07, "lady": 0.04, "firefly": 0.06, "deer_tick": 0.02, "lone_star_tick": 0.02, "tigersnail": 0.035, "grass_snail": 0.012,
				"rattler": 0.55, "milk": 0.5, "garden_spider": 0.03, "funnel_spider": 0.06, "wasp": 0.06}
		if radii.has(key): # (a school, a colony: no box of its own; framed on its middle)
			r = radii[key]
			c = (n as Node3D).global_position
			var ps: Variant = n.get("pos")
			if ps is PackedVector3Array and not (ps as PackedVector3Array).is_empty():
				var m := Vector3.ZERO
				for v in (ps as PackedVector3Array): m += v
				c = (n as Node3D).to_global(m / float((ps as PackedVector3Array).size()))
			c += Vector3(0, 0.15 * r, 0)
		elif key in ["milkweed", "swamp_milkweed", "coneflower", "susan", "fleabane", "aster", "yampah", "nettle", "tobacco"]:
			c = box.position + Vector3(box.size.x * 0.5, box.size.y * 0.7, box.size.z * 0.5)
			r = maxf(box.size.y * 0.32, 0.08)
		var f := Vector3(0, 0, -1)
		if n is Node3D: f = -(n as Node3D).global_transform.basis.z
		f.y = 0.0
		f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
		var dist := r / tan(deg_to_rad(cam.fov * 0.5)) * 1.12
		var yaw_a := 0.75 + 0.0
		var dir := (f.rotated(Vector3.UP, yaw_a) + Vector3(0, pitch, 0)).normalized()
		if box.size.y < box.size.x * 0.3 and box.size.y < box.size.z * 0.3: # (flat things: a plant, a pond: from higher)
			dir = (f.rotated(Vector3.UP, 0.5) + Vector3(0, 0.9, 0)).normalized()
		cam.near = maxf(dist * 0.02, 0.0005)
		cam.far = 400.0
		cam.look_at_from_position(c + dir * dist, c)
		if key in ["white_shrimp", "brown_shrimp", "pink_shrimp", "krill", "mollies", "chinook", "chinook_spawning", "rainbow", "steelhead"]:
			if lamp == null:
				lamp = OmniLight3D.new()
				lamp.omni_range = 30.0
				lamp.light_energy = 2.5
				get_root().add_child(lamp)
			lamp.global_position = c + dir * dist * 0.6 + Vector3(0, 0.3 * dist, 0)
		elif lamp != null:
			lamp.queue_free()
			lamp = null
		RenderingServer.render_loop_enabled = true
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		RenderingServer.render_loop_enabled = false
		img.resize(640, 427, Image.INTERPOLATE_LANCZOS)
		var name := key + ("_" + stage if stage != "adult" else "")
		img.save_jpg(OUT + name + ".jpg", 0.86)
		print("OK ", name, " r=%.3f" % r)
	quit()
