class_name DemoFlowers
## The game's own flowers for the creature demos (tools/creatures/): a clump
## of one of GroundCover's flower layers, still (no wind, so the CPU knows
## where its flowers are), and where its flowers are.


## The flowers' middles, one a flower ball or cluster (the florets' mean,
## grouped), for the moth to look in at as it searches.
static func heads(florets: Array) -> Array:
	var out := []
	for p: Vector3 in florets:
		var near := false
		for q: Vector3 in out:
			if q.distance_to(p) < 0.08:
				near = true
				break
		if not near:
			out.append(p)
	return out


## A clump of one of the game's flowers (GroundCover's layer with that
## `flowers`: milkweed, swamp_milkweed, coneflower, susan, fleabane, aster,
## yampah), standing at `near` (within a few cm), as a cell of its layer: the cell's data (ground_cover_bake's
## two texels) made up here, the ground at 0, the clump `tall` m; no wind.
## Its florets' tops, as the shader places them (the map's = the parent's,
## at the origin).
static func clump(parent: Node3D, flowers: String, near: Vector2, tall: float, ground: Color) -> Array:
	var L: Dictionary
	for l in GroundCover.LAYERS:
		if l.get("flowers", "") == flowers:
			L = l
	var cell: float = L.cell
	# a cell (and a seed: the hash's) whose clump stands at `near`, near
	# enough (every clump of a kind can then stand where it's wanted; each
	# its own plants, the mesh drawn from that seed)
	var seed: int = L.u.seed
	var at_cell := Vector2i.ZERO
	var best := INF
	for s in 600:
		var sd: int = L.u.seed + s * 101
		for cz in range(-2, 2):
			for cx in range(-2, 2):
				var c := Vector2i(cx, cz)
				var at := Vector2(c) * cell + Vector2(GroundCover._h2(c, 1, sd), GroundCover._h2(c, 2, sd)) * cell
				var d := at.distance_to(near)
				if d < best:
					best = d
					at_cell = c
					seed = sd
		if best < 0.03:
			break
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/ground_cover.gdshader")
	m.set_shader_parameter("cell", cell)
	for k in L.u:
		if k in GroundCover.DRAW_KEYS:
			m.set_shader_parameter(k, L.u[k])
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("grass_sway", 0.0) # (still: the insects go by where the flowers are)
	m.set_shader_parameter("fade_out", Vector2(1000.0, 1001.0))
	m.set_shader_parameter("thin_from", 1000.0)
	var size_b := roundf(tall / GroundCover.SIZE_MAX * 255.0)
	var img := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color8(128, 0, int(size_b), 120)) # (the ground at 0: 512 m over base_h, in 1/64 m; the size; how blonde)
	img.set_pixel(1, 0, Color(ground.r, ground.g, ground.b, 1.0))
	m.set_shader_parameter("data_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter("grid_origin", at_cell)
	m.set_shader_parameter("grid_size", Vector2i(1, 1))
	m.set_shader_parameter("base_h", 0.0)
	var mesh := GroundCover.flower_mesh(L.flowers, L.stems, L.radius, seed)
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 1
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(at_cell.x * cell, 0.0, at_cell.y * cell)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.custom_aabb = AABB(Vector3(-1, -1, -1), Vector3(cell + 2, 4, cell + 2))
	parent.add_child(mi)
	# the florets' tops (a head's disc's top: UV 4.5, 0), as the shader puts
	# them: the clump at the cell's spot, turned, sized
	var pos := Vector2(at_cell) * cell + Vector2(GroundCover._h2(at_cell, 1, seed), GroundCover._h2(at_cell, 2, seed)) * cell
	var spin := GroundCover._h2(at_cell, 8, seed) * TAU
	var size := size_b / 255.0 * GroundCover.SIZE_MAX
	var a := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var out := []
	for i in vs.size():
		if absf(uvs[i].x - 4.5) < 0.01 and uvs[i].y < 0.01:
			var root := _turn(uv2s[i], spin)
			var v := _turn(Vector2(vs[i].x, vs[i].z), spin)
			out.append(Vector3(pos.x + root.x + v.x * size, vs[i].y * size, pos.y + root.y + v.y * size))
	return out


## v turned by a (as ground_cover.gdshader turns a clump: mat2(cos, sin; -sin, cos)).
static func _turn(v: Vector2, a: float) -> Vector2:
	return Vector2(cos(a) * v.x - sin(a) * v.y, sin(a) * v.x + cos(a) * v.y)


## A patch of the prairie's flowers round `centre` (xz): its milkweeds and
## the others among them, each kind's clumps at its own spots (offsets
## from centre, m). Returns {flowers: florets} for each kind (the milkweeds'
## clumps' florets kept apart: "milkweed", "milkweed2", ...).
static func patch(parent: Node3D, centre: Vector2, ground: Color) -> Dictionary:
	var out := {}
	var plan := [
		["milkweed", Vector2(0.0, 0.0), 1.3], ["milkweed", Vector2(0.55, 0.35), 1.15], ["milkweed", Vector2(-0.35, 0.5), 1.25],
		["swamp_milkweed", Vector2(-0.6, -0.35), 1.2],
		["coneflower", Vector2(0.45, -0.45), 0.95], ["coneflower", Vector2(-0.9, 0.2), 0.9],
		["susan", Vector2(0.95, 0.0), 0.8], ["susan", Vector2(0.15, 0.85), 0.75],
		["fleabane", Vector2(-0.2, -0.75), 0.7], ["aster", Vector2(0.9, 0.8), 0.95], ["yampah", Vector2(-0.95, -0.7), 0.95]]
	for p: Array in plan:
		var key: String = p[0]
		var n := 2
		while out.has(key):
			key = "%s%d" % [p[0], n]
			n += 1
		out[key] = clump(parent, p[0], centre + (p[1] as Vector2), p[2], ground)
	return out
