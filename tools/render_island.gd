extends SceneTree
## Simulates (or loads) an island and renders top-down hillshaded maps.
## godot --path . -s tools/render_island.gd -- <out_dir> [preset] [seed] [cx cz span]
## Without a window (cx, cz, span) it renders the whole domain.

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out_dir := a[0] if a.size() > 0 else "user://"
	var preset := a[1] if a.size() > 1 else "test"
	var s := int(a[2]) if a.size() > 2 else 1337
	var gen := IslandGenerator.new(s, preset)
	gen.progress = func(m: String) -> void: print(m)
	var t0 := Time.get_ticks_msec()
	var d := gen.generate(preset)
	print("island ready in %d ms: %s" % [Time.get_ticks_msec() - t0, d.stats])
	var cx := float(a[3]) if a.size() > 3 else 0.0
	var cz := float(a[4]) if a.size() > 4 else 0.0
	var span := float(a[5]) if a.size() > 5 else d.domain
	var px := 900
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	var hmax := 1.0
	for v in d.heights:
		hmax = maxf(hmax, v)
	print("max height %.0f m, spawn %s" % [hmax, d.spawn])
	var light := Vector3(-0.6, 0.7, -0.4).normalized()
	var e := span / px
	for y in px:
		for x in px:
			var wx := cx - span * 0.5 + x * e
			var wz := cz - span * 0.5 + y * e
			var h := d.height_at(wx, wz)
			var nx := d.height_at(wx + e, wz) - d.height_at(wx - e, wz)
			var nz := d.height_at(wx, wz + e) - d.height_at(wx, wz - e)
			var shade := clampf(Vector3(-nx, 2.0 * e, -nz).normalized().dot(light), 0.0, 1.0)
			var g := ((Vector2(wx, wz) - d.origin) / d.cell()).round()
			var k := clampi(int(g.y), 0, d.size - 1) * d.size + clampi(int(g.x), 0, d.size - 1)
			var fl := d.material[k * 4] / 255.0
			var wet := d.material[k * 4 + 1] / 255.0
			var dep := d.material[k * 4 + 3] / 255.0
			var cover := d.wattr[k * 4] / 255.0
			var c: Color
			if h < 0.0 and cover < 0.5:
				c = Color(0.08, 0.2, 0.42).lerp(Color(0.25, 0.55, 0.65), clampf(1.0 + h / 30.0, 0.0, 1.0))
			else:
				var t := clampf(h / hmax, 0.0, 1.0)
				c = Color(0.36, 0.52, 0.24).lerp(Color(0.55, 0.5, 0.43), t).lerp(Color(0.9, 0.9, 0.9), smoothstep(0.8, 1.0, t))
				c = c.lerp(Color(0.3, 0.55, 0.22), fl * 0.5)
				c = c.lerp(Color(0.25, 0.35, 0.22), wet * 0.6)
				c = c.lerp(Color(0.7, 0.65, 0.5), dep * 0.6)
				if h < 1.5 and fl < 0.2:
					c = Color(0.84, 0.79, 0.6)
				c = c * (0.35 + 0.8 * shade)
				c = c.lerp(Color(0.15, 0.35, 0.7), cover)
			img.set_pixel(x, y, c)
	var name := "island_%s_%d_%d_%d_%d.png" % [preset, s, int(cx), int(cz), int(span)]
	img.save_png(out_dir.path_join(name))
	print("wrote ", name)
	quit()
