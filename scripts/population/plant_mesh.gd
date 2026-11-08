class_name PlantMesh
extends RefCounted
## Geometry for the plants built whole, not grown by TreeBuilder (the
## desert's: JoshuaTree, SanPedroCactus, PricklyPear): swept tubes (ribbed,
## for a cactus's stem), tapering blades (a yucca's leaves, a spine),
## ellipsoids, flat lenses; each vertex its own colour, into a SurfaceTool
## (begun with begin()); finish() commits each into one mesh with its
## material. All in metres.


static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	# (the front face Godot's way round, clockwise seen from where the
	# normals point: swapped if it's given the other way)
	if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
		var tc := cb
		cb = cc
		cc = tc
	if not st.has_meta("used"):
		st.set_meta("used", true)
	st.set_color(ca)
	st.set_normal(na)
	st.add_vertex(a)
	st.set_color(cb)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_color(cc)
	st.set_normal(nc)
	st.add_vertex(c)


## A frame (right, up) square to dir, carried on from the last (so a swept
## tube doesn't twist).
static func _carry(prev_right: Vector3, dir: Vector3) -> Vector3:
	var r := prev_right - dir * prev_right.dot(dir)
	if r.length() < 1e-4:
		r = dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT)
	return r.normalized()


## A tube swept along pts (radii each), `sides` round; ribs: {n: how many,
## depth: a share of the radius the grooves go in, sharp: the crests'
## breadth (0.3 broad .. 1 pointed)}; colour: Callable (point index, the
## angle round, how deep in a groove 0..1) -> Color; capped: its end
## rounded shut (dome: how far back the rounding starts, m). uv: each
## vertex's UV (x: the way round, in ribs (a crest at each whole number), or
## turns with none; y: m along) and UV2 (its radius there, m; the ribs); for
## a shader to paint by (SanPedroCactus's skin). Its rings ([its sides + 1
## vertices: [point, normal, colour, ...]]) and how far along each is (m).
static func tube(st: SurfaceTool, pts: Array, radii: Array, sides: int, colour: Callable, ribs := {}, dome := 0.0, uv := false) -> Array:
	var n := pts.size()
	if n < 2:
		return [[], []]
	var rn := int(ribs.get("n", 0))
	var depth := float(ribs.get("depth", 0.0))
	var sharp := float(ribs.get("sharp", 0.5))
	var rings := []
	var right := Vector3.ZERO
	var total := 0.0
	var along := [0.0]
	for i in range(1, n):
		total += (pts[i] as Vector3).distance_to(pts[i - 1])
		along.append(total)
	for i in n:
		var p: Vector3 = pts[i]
		var dir: Vector3 = ((pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		right = _carry(right if i > 0 else Vector3.ZERO, dir)
		var up := dir.cross(right).normalized()
		var R: float = radii[i]
		if dome > 0.0: # (the end rounded over)
			var left := total - float(along[i])
			if left < dome:
				R *= sqrt(maxf(1.0 - pow(1.0 - left / dome, 2.0), 0.0))
		var ring := []
		for k in sides + 1:
			var a := TAU * float(k) / sides
			var groove := 0.0
			if rn > 0:
				groove = 1.0 - pow(absf(cos(a * rn * 0.5)), sharp)
			var r := R * (1.0 - depth * groove)
			var off := right * cos(a) + up * sin(a)
			var nrm := off
			if rn > 0: # (the normal tipped across the rib's slope)
				var dg := float(rn) * 0.5 * sin(a * rn * 0.5) * signf(cos(a * rn * 0.5)) * depth * 2.0
				nrm = (off - (right * -sin(a) + up * cos(a)) * dg).normalized()
			ring.append([p + off * r, nrm, colour.call(i, a, groove), Vector2(float(k) / sides * maxi(rn, 1), along[i]), Vector2(R, maxi(rn, 1))])
		rings.append(ring)
	for i in n - 1:
		var A: Array = rings[i]
		var B: Array = rings[i + 1]
		for k in sides:
			var a0: Array = A[k]
			var a1: Array = A[k + 1]
			var b0: Array = B[k]
			var b1: Array = B[k + 1]
			if uv:
				_tri_uv(st, a0, b0, b1)
				_tri_uv(st, a0, b1, a1)
			else:
				_tri(st, a0[0], b0[0], b1[0], a0[1], b0[1], b1[1], a0[2], b0[2], b1[2])
				_tri(st, a0[0], b1[0], a1[0], a0[1], b1[1], a1[1], a0[2], b1[2], a1[2])
	return [rings, along]


## (_tri, each vertex [point, normal, colour, uv, uv2])
static func _tri_uv(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	if (b[0] - a[0]).cross(c[0] - a[0]).dot(a[1] + b[1] + c[1]) > 0.0:
		var t := b
		b = c
		c = t
	if not st.has_meta("used"):
		st.set_meta("used", true)
	for v: Array in [a, b, c]:
		st.set_color(v[2])
		st.set_normal(v[1])
		st.set_uv(v[3])
		st.set_uv2(v[4])
		st.add_vertex(v[0])


## A blade (a leaf, a spine) from base along dir, length long, width wide
## at its base, thick; narrowing to a point; flat across `flat` (square to
## dir: its broad face's normal); base and tip colours.
static func blade(st: SurfaceTool, base: Vector3, dir: Vector3, flat: Vector3, length: float, width: float, thick: float, c0: Color, c1: Color, keel := true) -> void:
	var d := dir.normalized()
	var f := (flat - d * flat.dot(d)).normalized()
	if f.length() < 1e-4:
		f = d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var s := d.cross(f).normalized() # (across its breadth)
	var tip := base + d * length
	var mid := base + d * length * 0.35
	var w := width * 0.5
	var cm := c0.lerp(c1, 0.35)
	# (a diamond in section at its broadest, a third up: the faces meet at
	# the edges and the keel, so it reads stiff, not a card)
	var e1 := mid + s * w
	var e2 := mid - s * w
	var t1 := mid + f * thick * 0.5
	var t2 := mid - f * thick * (0.5 if keel else 0.2)
	var b1 := base + s * w * 0.55
	var b2 := base - s * w * 0.55
	for face: Array in [[t1, e1, f + s], [e1, t2, -f + s], [t2, e2, -f - s], [e2, t1, f - s]]:
		var p: Vector3 = face[0]
		var q: Vector3 = face[1]
		var nn: Vector3 = (face[2] as Vector3).normalized()
		_tri(st, p, tip, q, nn, nn, nn, cm, c1, cm)
	for face: Array in [[b1, e1, t1, f], [b2, t1, e2, f], [b1, t2, e1, -f], [b2, e2, t2, -f]]:
		var nn: Vector3 = face[3]
		_tri(st, face[0], face[1], face[2], nn, nn, nn, c0, cm, cm)


## A spine: a thin three-sided needle from base along dir.
static func spine(st: SurfaceTool, base: Vector3, dir: Vector3, length: float, r: float, c0: Color, c1: Color) -> void:
	var d := dir.normalized()
	var a := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var b := d.cross(a)
	var tip := base + d * length
	var ps := []
	for k in 3:
		var ang := TAU * k / 3.0
		ps.append(base + (a * cos(ang) + b * sin(ang)) * r)
	for k in 3:
		var p: Vector3 = ps[k]
		var q: Vector3 = ps[(k + 1) % 3]
		var nn := ((p + q) * 0.5 - base).normalized()
		_tri(st, p, q, tip, nn, nn, d, c0, c0, c1)


## An ellipsoid: centre, its axes (each its half length and way: basis
## columns), sides round, rings up; colour by the unit point on it.
static func ellipsoid(st: SurfaceTool, c: Vector3, axes: Basis, sides: int, rings: int, colour: Callable) -> void:
	var inv_t := axes.inverse().transposed()
	var pt := func(i: int, k: int) -> Array:
		var th := PI * float(i) / rings
		var ph := TAU * float(k) / sides
		var u := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
		return [c + axes * u, (inv_t * u).normalized(), colour.call(u)]
	for i in rings:
		for k in sides:
			var a: Array = pt.call(i, k)
			var b: Array = pt.call(i + 1, k)
			var e: Array = pt.call(i + 1, k + 1)
			var d: Array = pt.call(i, k + 1)
			_tri(st, a[0], d[0], e[0], a[1], d[1], e[1], a[2], d[2], e[2])
			_tri(st, a[0], e[0], b[0], a[1], e[1], b[1], a[2], e[2], b[2])


## The one-colour ellipsoid.
static func blob(st: SurfaceTool, c: Vector3, axes: Basis, col: Color, sides := 8, rings := 5) -> void:
	ellipsoid(st, c, axes, sides, rings, func(_u: Vector3) -> Color: return col)


## Commits each SurfaceTool (with its material) into one mesh, as a
## surface of it.
static func finish(parts: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for p: Array in parts:
		var st: SurfaceTool = p[0]
		if not st.has_meta("used"): # (nothing in it: this level has none)
			continue
		st.index()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, p[1])
	return mesh


## A material painted by the vertices' colours.
static func painted(rough := 0.7, sheen := 0.0, cull := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	if sheen > 0.0:
		m.rim_enabled = true
		m.rim = sheen
		m.rim_tint = 0.3
	if not cull:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## A random point's noise: -1 .. 1 (cheap; repeatable).
static func noise(p: Vector3, f := 1.0) -> float:
	var q := p * f
	return fposmod(sin(q.x * 12.9898 + q.y * 78.233 + q.z * 37.719) * 43758.5453, 1.0) * 2.0 - 1.0


# ---- levels of detail ---------------------------------------------------------

static var _lod_mats := {} # [rough, rim, cull, begin, end] -> ShaderMaterial


## A plant's levels as Population draws them: raw its three meshes (whole,
## simpler, simplest); lod the distances (m) where the next takes over
## (lod[0], lod[1]) and where its far card does (lod[2]), the card out to
## view (m, its PropKind's: brought to the player's tree distance as
## Population brings it). Each mesh drawn over its span only, stippled into
## the next (plant_painted.gdshaderinc); the card a photograph of the
## simplest, eight ways round (OakTree._impostor, ImpostorBaker), as a
## tree's. [the whole one (PropKind.mesh), [the rest] (PropKind.lods)]
static func levels(raw: Array, lod: Array, view: float, species: String, variant: int) -> Array:
	var whole := _lodded(raw[0], 0.0, lod[0])
	var lods: Array[Mesh] = [_lodded(raw[1], lod[0], lod[1]), _lodded(raw[2], lod[1], lod[2])]
	var card := OakTree._impostor(variant, raw[2], species) # (photographed from the plain one: no levels)
	var m := card.surface_get_material(0) as ShaderMaterial
	m.set_meta("view_base", view)
	m.set_shader_parameter("lod_range", Vector3(lod[2], reach(view, lod[2]), _fade()))
	lods.append(card)
	return [whole, lods]


## How far its far cards reach (m): as Population's view_distance for it.
static func reach(view: float, last: float) -> float:
	return maxf(view * OakTree.view() / OakTree.VIEW, last + 20.0)


static func _fade() -> float:
	return Population.LOD_FADE if OakTree.lod_fade_on else 0.0


## A copy of mesh, its materials (painted()) made the level's: drawn from
## begin to end (m) only.
static func _lodded(mesh: ArrayMesh, begin: float, end: float) -> ArrayMesh:
	var out := ArrayMesh.new()
	for i in mesh.get_surface_count():
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(i))
		var own := mesh.surface_get_material(i)
		if own is ShaderMaterial: # (its own shader, with lod_fade.gdshaderinc: a copy given the span)
			var okey := [own.get_instance_id(), begin, end]
			if not _lod_mats.has(okey):
				var c := (own as ShaderMaterial).duplicate() as ShaderMaterial
				c.set_shader_parameter("lod_range", Vector3(begin, end, _fade()))
				_lod_mats[okey] = c
				OakTree._leaf_mats[["plant"] + okey] = c
			out.surface_set_material(i, _lod_mats[okey])
			continue
		var src := own as StandardMaterial3D
		var rough := src.roughness if src else 0.7
		var rim := src.rim if src and src.rim_enabled else 0.0
		var cull := src == null or src.cull_mode != BaseMaterial3D.CULL_DISABLED
		var key := [rough, rim, cull, begin, end]
		if not _lod_mats.has(key):
			var m := ShaderMaterial.new()
			m.shader = load("res://shaders/render/plant_painted.gdshader" if cull else "res://shaders/render/plant_painted_two_sided.gdshader")
			m.set_shader_parameter("roughness_v", rough)
			m.set_shader_parameter("rim_v", rim)
			m.set_shader_parameter("lod_range", Vector3(begin, end, _fade()))
			_lod_mats[key] = m
			OakTree._leaf_mats[["plant"] + key] = m # (its fade turned off with the trees': OakTree.set_lod_fade)
		out.surface_set_material(i, _lod_mats[key])
	return out
