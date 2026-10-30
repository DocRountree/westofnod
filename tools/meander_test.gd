extends SceneTree
## Runs Meander.migrate on a straight valley and draws the result.
## godot --path . -s tools/meander_test.gd -- <out.png> [width] [length] [belt]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var w := float(args[1]) if args.size() > 1 else 10.0
	var length := float(args[2]) if args.size() > 2 else 3000.0
	var bw := float(args[3]) if args.size() > 3 else 8.0 * w
	var belt := PackedFloat32Array()
	for i in int(length / 20.0) + 2:
		belt.append(bw)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var t0 := Time.get_ticks_msec()
	var res := Meander.migrate(length, w, belt, 20.0, rng)
	print("meander: %d pts, %d oxbows, %d ms" % [res.pts.size(), res.oxbows.size(), Time.get_ticks_msec() - t0])
	var sc := 1200.0 / length
	var img := Image.create(1200, int(bw * 2.6 * sc) + 20, false, Image.FORMAT_RGB8)
	img.fill(Color(0.3, 0.5, 0.25))
	var cy := img.get_height() / 2
	for x in 1200:
		img.set_pixel(x, cy - int(bw * sc), Color.BLACK)
		img.set_pixel(x, cy + int(bw * sc), Color.BLACK)
	for ox in res.oxbows:
		for p in ox.pts:
			img.set_pixel(clampi(int(p.x * sc), 0, 1199), clampi(cy + int(p.y * sc), 0, img.get_height() - 1),
					Color(0.2, 0.8, 0.9) if ox.age < 0.55 else Color(0.6, 0.5, 0.3))
	for p in res.pts:
		img.set_pixel(clampi(int(p.x * sc), 0, 1199), clampi(cy + int(p.y * sc), 0, img.get_height() - 1), Color(0.1, 0.2, 1.0))
	img.save_png(args[0])
	quit()
