extends SceneTree
## Simulates islands and renders their coarse grids with rivers and lakes.
## godot --path . -s tools/island_preview.gd -- <out_dir> [cx] [cz] [scale]
## Renders every island whose domain contains (cx, cz).

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://"
	var cx := float(args[1]) if args.size() > 1 else 3000.0
	var cz := float(args[2]) if args.size() > 2 else 3000.0
	var px := int(args[3]) if args.size() > 3 else 3
	var rd := RenderingServer.create_local_rendering_device()
	var sim := IslandSim.new(rd)
	var arch := Archipelago.new(1337)
	var list := arch.islands_in(Rect2(cx - 15000, cz - 15000, 30000, 30000))
	list.sort_custom(func(a, b): return a.r > b.r)
	for d in list:
		print("  candidate r=%.0f at %s" % [d.r, d.center])
	var pick := int(args[4]) if args.size() > 4 else 0
	for desc in list.slice(pick, pick + 1):
		var t0 := Time.get_ticks_msec()
		var isl := Island.new(desc).build(sim)
		print("island r=%.0f  %s  total %d ms" % [isl.radius, isl.stats, Time.get_ticks_msec() - t0])
		var kinds := [0, 0, 0, 0]
		for i in range(0, isl.segs.size(), Island.SEG_STRIDE):
			kinds[int(isl.segs[i + 11])] += 1
		print("  segments floor/river/oxbow/scar: ", kinds)
		for i in range(0, isl.segs.size(), Island.SEG_STRIDE):
			if int(isl.segs[i + 11]) == Island.KIND_OXBOW:
				print("  first oxbow at ", Vector2(isl.segs[i], isl.segs[i + 1]))
				break
		_render(isl, px).save_png(out_dir.path_join("island_%d.png" % absi(isl.id % 100000)))
	sim.free_rids()
	quit()


func _render(isl: Island, px: int) -> Image:
	var n := isl.n
	var size := n * px
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var hmax := 1.0
	for k in n * n:
		hmax = maxf(hmax, isl.h[k])
	print("  max height %.0f m" % hmax)
	var light := Vector3(-0.6, 0.7, -0.4).normalized()
	for y in size:
		for x in size:
			var p := isl.origin + Vector2(x, y) * isl.dx / px
			var hh := isl.sample(isl.h, p)
			var e := isl.dx / px
			var nx := isl.sample(isl.h, p + Vector2(e, 0)) - isl.sample(isl.h, p - Vector2(e, 0))
			var nz := isl.sample(isl.h, p + Vector2(0, e)) - isl.sample(isl.h, p - Vector2(0, e))
			var nrm := Vector3(-nx, 2.0 * e, -nz).normalized()
			var shade := clampf(nrm.dot(light), 0.0, 1.0)
			var s := isl.sample(isl.sd, p)
			var c: Color
			if s < 0.0:
				c = Color(0.1, 0.25, 0.5).lerp(Color(0.25, 0.55, 0.7), clampf(1.0 + s / 300.0, 0.0, 1.0))
			else:
				var t := clampf(hh / hmax, 0.0, 1.0)
				c = Color(0.3, 0.5, 0.2).lerp(Color(0.55, 0.5, 0.42), t).lerp(Color(0.95, 0.95, 0.95), smoothstep(0.75, 1.0, t))
				c = c * (0.3 + 0.85 * shade)
				var k := isl._idx(p)
				if isl.lake[k] >= 0:
					c = Color(0.15, 0.35, 0.75)
			img.set_pixel(x, y, c)
	var cols := [Color(0.7, 0.85, 0.5), Color(0.1, 0.3, 0.9), Color(0.2, 0.75, 0.9), Color(0.55, 0.5, 0.3)]
	var sg := isl.segs
	for kind in [0, 3, 2, 1]:
		for i in range(0, sg.size(), Island.SEG_STRIDE):
			if int(sg[i + 11]) != kind:
				continue
			var a := (Vector2(sg[i], sg[i + 1]) - isl.origin) / isl.dx * px
			var b := (Vector2(sg[i + 2], sg[i + 3]) - isl.origin) / isl.dx * px
			var steps := ceili(a.distance_to(b)) + 1
			var wpx := maxf(sg[i + 6] * 2.0 / isl.dx * px, 1.0) if kind != 0 else 1.0
			for t in steps + 1:
				var q := a.lerp(b, float(t) / steps)
				for oy in range(-int(wpx / 2), int(wpx / 2) + 1):
					for ox in range(-int(wpx / 2), int(wpx / 2) + 1):
						var xi := int(q.x) + ox
						var yi := int(q.y) + oy
						if xi >= 0 and yi >= 0 and xi < size and yi < size:
							if kind == 0:
								if (xi + yi) % 3 == 0:
									img.set_pixel(xi, yi, cols[0])
							else:
								img.set_pixel(xi, yi, cols[kind])
	return img
