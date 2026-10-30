class_name PropMeshes
extends RefCounted
## Procedural meshes for the scattered props. COLOR.r marks the part (0 trunk, 1
## foliage); COLOR.g is height within the prop (0..1) for wind sway.


## A broadleaf tree, ~10 m: trunk and a canopy of lumpy blobs.
static func tree(detail: int, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cylinder(st, Vector3.ZERO, 0.28, 0.16, 5.5, 6 if detail > 0 else 4)
	var blobs := 3 if detail > 0 else 1
	for b in blobs:
		var c := Vector3(rng.randf_range(-1.3, 1.3), rng.randf_range(5.8, 7.8), rng.randf_range(-1.3, 1.3))
		var r := rng.randf_range(2.4, 3.0)
		if detail == 0:
			c = Vector3(0, 6.8, 0)
			r = 3.4
		_blob(st, c, Vector3(r, r * 0.8, r), detail, rng, 1.0)
	st.index() # shared vertices: the vertex shader (which places the tree) runs once per corner
	st.generate_normals()
	return st.commit()


static func _cylinder(st: SurfaceTool, base: Vector3, r0: float, r1: float, h: float, sides: int) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p := [Vector3(cos(a0) * r0, 0, sin(a0) * r0), Vector3(cos(a1) * r0, 0, sin(a1) * r0),
				Vector3(cos(a1) * r1, h, sin(a1) * r1), Vector3(cos(a0) * r1, h, sin(a0) * r1)]
		var hv := [0.0, 0.0, 1.0, 1.0]
		for t in [[0, 2, 1], [0, 3, 2]]:
			for k in t:
				st.set_color(Color(0.0, hv[k] * 0.6, 0, 1))
				st.add_vertex(base + p[k])


## Icosphere (subdivided `sub` times), each vertex pushed in or out a little.
static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, sub: int, rng: RandomNumberGenerator, part: float) -> void:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var f := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4],
			[11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
			[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var verts: Array = []
	for p in v:
		verts.append(p.normalized())
	for s in sub:
		var cache := {}
		var nf := []
		for tri in f:
			var m := []
			for e in [[tri[0], tri[1]], [tri[1], tri[2]], [tri[2], tri[0]]]:
				var key := Vector2i(mini(e[0], e[1]), maxi(e[0], e[1]))
				if not cache.has(key):
					cache[key] = verts.size()
					verts.append((verts[e[0]] + verts[e[1]]).normalized())
				m.append(cache[key])
			nf.append_array([[tri[0], m[0], m[2]], [tri[1], m[1], m[0]], [tri[2], m[2], m[1]], [m[0], m[1], m[2]]])
		f = nf
	var bump := []
	for p in verts:
		bump.append(rng.randf_range(0.82, 1.12))
	for tri in f:
		for k in [tri[0], tri[2], tri[1]]:
			var p: Vector3 = verts[k] * r * bump[k] + c
			st.set_color(Color(part, clampf(p.y / 9.0, 0.0, 1.0), 0, 1))
			st.add_vertex(p)
