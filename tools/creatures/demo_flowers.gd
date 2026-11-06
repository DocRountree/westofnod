class_name DemoFlowers
## The game's own flowers for the creature demos (tools/creatures/): clumps
## of GroundCover's flower layers (their meshes and colours), built ready
## placed on the CPU and drawn by demo_flower.gdshader (not by the ground
## cover's grid), and where their flowers are.


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
## yampah), standing at `near`, `tall` m; still. Its
## florets' tops (points, the parent's space).
static func clump(parent: Node3D, flowers: String, near: Vector2, tall: float, ground: Color) -> Array:
	var out := []
	for h in build(parent, flowers, near, tall, ground, 0.0).heads:
		out.append(h[0])
	return out


## The same, swaying in the wind by sway_k (the ground cover's grass_sway,
## m per m of the wind at the top, times the clump's size: 0 still):
## {heads: [the disc's top, the way it faces, how far up its stem (the
## sway's share)] each, size: the clump's (m), leaves: [a blade's middle,
## its normal, its way out] each (a milkweed's)}.
##
## The mesh is GroundCover.flower_mesh's, placed, turned and sized here
## on the CPU as ground_cover.gdshader would place a cell's clump, at
## `near`, coloured with
## the layer's own colours (its petals, its discs; its stems from the
## ground's colour at the root to the prairie's green at the top), drawn
## by demo_flower.gdshader: nothing of the game's ground cover grid needed.
static func build(parent: Node3D, flowers: String, near: Vector2, tall: float, ground: Color, sway_k: float) -> Dictionary:
	var L: Dictionary
	for l in GroundCover.LAYERS:
		if l.get("flowers", "") == flowers:
			L = l
	var u: Dictionary = L.u
	# standing exactly at `near`, its own plants (a seed from where it
	# stands), turned some way
	var seed: int = u.seed + (absi(int(near.x * 1000.0) * 31 + int(near.y * 1000.0) * 7) % 997) * 101
	var pos := near
	var spin := fposmod(sin(near.x * 12.9898 + near.y * 78.233) * 43758.5453, 1.0) * TAU
	var pick0 := fposmod(spin * 3.7, 1.0)
	var size := tall
	var leaf_at := []
	var src := GroundCover.flower_mesh(L.flowers, L.stems, L.radius, seed, leaf_at)
	var a := src.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var cols: PackedColorArray = a[Mesh.ARRAY_COLOR]
	var cu: Variant = a[Mesh.ARRAY_CUSTOM0]
	var across: PackedFloat32Array = cu.to_float32_array() if cu is PackedByteArray else cu
	# the layer's colours (sRGB), or the shader's defaults
	var green: Vector3 = u.get("prairie_green", Vector3(0.27, 0.43, 0.12))
	var blonde: Vector3 = u.get("prairie_blonde", Vector3(0.74, 0.64, 0.38))
	var petal: Vector3 = u.get("petal_color", Vector3.ONE)
	var petal_base: Vector3 = u.get("petal_base", Vector3.ONE)
	var petal_alt: Vector3 = u.get("petal_alt", Vector3.ONE)
	var alt_share: float = u.get("petal_alt_share", 0.0)
	var petal_mix: float = u.get("petal_mix", 0.0)
	var disc: Vector3 = u.get("disc_color", Vector3(0.5, 0.5, 0.5))
	var root_col := Vector3(ground.r, ground.g, ground.b)
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	var out_f := PackedVector2Array()
	out_v.resize(vs.size())
	out_n.resize(vs.size())
	out_c.resize(vs.size())
	out_f.resize(vs.size())
	var heads := []
	for i in vs.size():
		var root := _turn(uv2s[i], spin)
		var v := _turn(Vector2(vs[i].x, vs[i].z), spin)
		var ac := _turn(Vector2(across[i * 3], across[i * 3 + 2]), spin)
		var w := Vector3(pos.x + root.x + v.x * size + ac.x, vs[i].y * size + across[i * 3 + 1], pos.y + root.y + v.y * size + ac.y)
		var n2 := _turn(Vector2(ns[i].x, ns[i].z), spin)
		var nrm := Vector3(n2.x, ns[i].y, n2.y).normalized()
		var frac := cols[i].b
		var col: Vector3
		var ux := uvs[i].x
		if ux > 4.0: # (a disc)
			col = disc * cols[i].r
			if uvs[i].y < 0.01:
				heads.append([w, nrm, frac])
		elif ux > 3.0: # (a ray)
			var pick := fposmod(cols[i].g + pick0, 1.0)
			if petal_mix > 0.0:
				col = petal.lerp(petal_alt, pow(pick, petal_mix))
			elif pick < alt_share:
				col = petal_alt
			else:
				col = petal_base.lerp(petal, smoothstep(0.0, 0.45, clampf(uvs[i].y, 0.0, 1.0)))
			col *= cols[i].r
		else: # (a stem, a leaf)
			var tip := green.lerp(blonde, clampf(0.47 + cols[i].g * 0.5 - 0.25, 0.0, 1.0)) * 0.85 * cols[i].r
			col = root_col.lerp(tip, smoothstep(0.0, 0.7, frac)) * lerpf(0.75, 1.0, frac)
		out_v[i] = w
		out_n[i] = nrm
		out_c[i] = Color(col.x, col.y, col.z)
		out_f[i] = Vector2(frac, 0.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = out_v
	arrays[Mesh.ARRAY_NORMAL] = out_n
	arrays[Mesh.ARRAY_COLOR] = out_c
	arrays[Mesh.ARRAY_TEX_UV2] = out_f
	arrays[Mesh.ARRAY_INDEX] = a[Mesh.ARRAY_INDEX]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m := ShaderMaterial.new()
	m.shader = load("res://tools/creatures/demo_flower.gdshader")
	m.set_shader_parameter("sway_k", sway_k)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	parent.add_child(mi)
	# its leaves (a milkweed's), placed as its mesh is: [the blade's middle,
	# its normal, its way out (level)], the parent's space
	var leaves := []
	for l: Array in leaf_at:
		var r := _turn(l[0], spin)
		var lm: Vector3 = l[1]
		var mv := _turn(Vector2(lm.x, lm.z), spin)
		var n: Vector3 = l[2]
		var nv := _turn(Vector2(n.x, n.z), spin)
		var dv := _turn(l[3], spin)
		leaves.append([Vector3(pos.x + r.x + mv.x * size, lm.y * size, pos.y + r.y + mv.y * size), Vector3(nv.x, n.y, nv.y).normalized(), Vector3(dv.x, 0.0, dv.y).normalized()])
	return {"heads": heads, "size": size, "leaves": leaves}


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
