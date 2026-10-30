extends SceneTree
## Headless-ish preview: renders generator output to hillshaded PNGs.
## godot --path . -s tools/heightmap_preview.gd -- <out_dir> [spacing] [tiles] [cx] [cz]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://"
	var s := float(args[1]) if args.size() > 1 else 8.0
	var tiles := int(args[2]) if args.size() > 2 else 4
	var cx := float(args[3]) if args.size() > 3 else 0.0
	var cz := float(args[4]) if args.size() > 4 else 0.0
	var n := 64
	var gen := TerrainGenerator.new()
	gen.start()
	var size := tiles * n
	var span := size * s
	var heights := PackedFloat32Array()
	heights.resize((size + 1) * (size + 1))
	var allu := PackedFloat32Array()
	allu.resize(heights.size())
	var water := PackedFloat32Array()
	water.resize(heights.size())
	var t0 := Time.get_ticks_msec()
	for tj in tiles:
		for ti in tiles:
			gen.request({"kind": 1, "key": Vector2i(ti, tj), "origin": Vector2(cx - span / 2 + ti * n * s, cz - span / 2 + tj * n * s), "spacing": s, "n": n})
	var got := 0
	while got < tiles * tiles:
		OS.delay_msec(20)
		for r in gen.poll():
			got += 1
			var k: Vector2i = r.key
			var d: PackedFloat32Array = r.data
			var on: int = n + 3
			for j in n + 1:
				for i in n + 1:
					var gi := k.x * n + i
					var gj := k.y * n + j
					var o := ((j + 1) * on + i + 1) * TerrainGenerator.OUT_STRIDE
					heights[gj * (size + 1) + gi] = d[o]
					allu[gj * (size + 1) + gi] = d[o + 1]
					water[gj * (size + 1) + gi] = d[o + 5] if d[o + 4] > d[o] else 0.0
	print("generated %d tiles in %d ms" % [tiles * tiles, Time.get_ticks_msec() - t0])
	gen.stop()
	var img := Image.create(size + 1, size + 1, false, Image.FORMAT_RGB8)
	var hmin := 1e9
	var hmax := -1e9
	for j in size + 1:
		for i in size + 1:
			var h := heights[j * (size + 1) + i]
			hmin = minf(hmin, h)
			hmax = maxf(hmax, h)
			var hx := heights[j * (size + 1) + mini(i + 1, size)] - heights[j * (size + 1) + maxi(i - 1, 0)]
			var hz := heights[mini(j + 1, size) * (size + 1) + i] - heights[maxi(j - 1, 0) * (size + 1) + i]
			var nrm := Vector3(-hx, 2.0 * s, -hz).normalized()
			var shade := clampf(nrm.dot(Vector3(-0.6, 0.7, -0.4).normalized()), 0.0, 1.0)
			var c: Color
			if h < 0.0:
				c = Color(0.1, 0.25, 0.5).lerp(Color(0.2, 0.55, 0.7), clampf(1.0 + h / 30.0, 0.0, 1.0))
			elif h < 1.2 and allu[j * (size + 1) + i] < 0.2:
				c = Color(0.85, 0.8, 0.6)
			else:
				c = Color(0.35, 0.55, 0.25).lerp(Color(0.55, 0.5, 0.45), clampf(h / 150.0, 0.0, 1.0))
				c = c.lerp(Color(0.25, 0.6, 0.2), clampf(allu[j * (size + 1) + i], 0.0, 1.0) * 0.6)
				c = c * (0.35 + 0.75 * shade)
				if water[j * (size + 1) + i] > 1.5:
					c = Color(0.2, 0.45, 0.85)
				elif water[j * (size + 1) + i] > 0.5:
					c = Color(0.15, 0.35, 0.8)
			img.set_pixel(i, j, c)
	print("height range %.1f .. %.1f" % [hmin, hmax])
	img.save_png(out_dir.path_join("preview_s%d_%d_%d.png" % [int(s), int(cx), int(cz)]))
	quit()
