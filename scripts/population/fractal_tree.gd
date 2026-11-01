class_name FractalTree
## One recipe for a tree, drawn two ways, to compare them:
##
## - raymarched: shaders/render/fractal_tree.gdshader evaluates the tree's
##   distance function per pixel inside a box, so every instance can differ
##   (its seed is its position) and branches and leaf clusters cost no memory;
## - as a mesh: build_mesh() walks the same recipe on the CPU into triangles,
##   with simpler versions for further off (build_lods()).
##
## The prop kind (data/population/props/fractal_tree.tres) is the same trees
## in the same places either way; set_raymarched() switches it (T in game).
##
## The recipe is an IFS: a trunk; at its top the space is mirrored in x (two
## children), tilted outward by TILT, twisted round the axis by TWIST and
## shrunk by LEN_RATIO; repeat LEVELS times; a lumpy leaf cluster at each tip
## (2^LEVELS of them). Keep these numbers in step with the shader's uniforms,
## and BOX_MIN / BOX_MAX round bounds().

const TRUNK_LEN := 4.2 ## m
const TRUNK_R := 0.34 ## m at the base
const LEVELS := 7
const LEN_RATIO := 0.76 ## each level's branches this much shorter...
const RAD_RATIO := 0.64 ## ...and this much thinner
const TILT := 0.52 ## rad, a child off its parent
const TWIST := 2.4 ## rad round the parent's axis between levels
const LEAF_R := 1.25 ## m, a leaf cluster's radius
const LEAF_AMP := 0.32 ## m, how lumpy the clusters are


## The leaf clusters' lumps (the shader's leaf_noise(), the same numbers).
static func leaf_noise(p: Vector3) -> float:
	var a := sin(p.x * 2.1 + 1.3) * sin(p.y * 2.3 + 0.7) * sin(p.z * 1.9 + 2.1)
	var q := Vector3(0.8 * p.y + 0.6 * p.z, -0.8 * p.x + 0.36 * p.y - 0.48 * p.z, -0.6 * p.x - 0.48 * p.y + 0.64 * p.z) * 4.3
	var b := sin(q.x + 0.5) * sin(q.y + 1.7) * sin(q.z + 2.9)
	return a * 0.75 + b * 0.25


## A child's frame in its parent's (side: +1, or -1 for the mirrored one):
## the inverse of the shader's step (translate, fold, tilt, twist, scale).
static func _child(side: float, tilt: float, twist: float) -> Transform3D:
	var ct := cos(tilt)
	var st := sin(tilt)
	var cw := cos(twist)
	var sw := sin(twist)
	var cols: Array[Vector3] = []
	for e: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		var v := e * LEN_RATIO
		# un-twist (shader: x' = c x - s z, z' = s x + c z)
		v = Vector3(cw * v.x + sw * v.z, v.y, -sw * v.x + cw * v.z)
		# un-tilt (shader: x' = c x - s y, y' = s x + c y)
		v = Vector3(ct * v.x + st * v.y, -st * v.x + ct * v.y, v.z)
		v.x *= side
		cols.append(v)
	return Transform3D(Basis(cols[0], cols[1], cols[2]), Vector3(0.0, TRUNK_LEN, 0.0))


## The raymarched tree's box (tree space, m): round bounds(), with room for
## the shader's per-instance variation.
const BOX_MIN := Vector3(-11.5, 0.0, -11.5)
const BOX_MAX := Vector3(11.5, 18.5, 11.5)
const TRAD_LOD_DISTANCES := [80.0, 250.0]

static var _ray_mesh: BoxMesh
static var _ray_material: ShaderMaterial
static var _trad_mesh: Mesh
static var _trad_lods: Array[Mesh] = []


## The mesh prop's mesh (PropKind.mesh_script): the whole tree, ~12k triangles.
static func build() -> Mesh:
	if _trad_mesh == null:
		_trad_mesh = build_mesh()
	return _trad_mesh


## The raymarching material (one for every tree; its uniforms tune them all).
static func ray_material() -> ShaderMaterial:
	if _ray_material == null:
		_ray_material = ShaderMaterial.new()
		_ray_material.shader = load("res://shaders/render/fractal_tree.gdshader")
		_ray_material.set_shader_parameter("box_min", BOX_MIN)
		_ray_material.set_shader_parameter("box_max", BOX_MAX)
	return _ray_material


## Switch a kind of these trees between the two techniques, in place (then
## Population.rebuild()): raymarched at every distance (a box each, the
## shader simplifying with distance), or meshes, simpler further off (lods).
## Its lod_material is the meshes' material.
static func set_raymarched(kind: PropKind, on: bool) -> void:
	if on:
		if _ray_mesh == null:
			_ray_mesh = BoxMesh.new()
			_ray_mesh.size = BOX_MAX - BOX_MIN
			_ray_mesh.custom_aabb = AABB(BOX_MIN, BOX_MAX - BOX_MIN)
		kind.mesh = _ray_mesh
		kind.material = ray_material()
		kind.lods = []
		kind.lod_distances = PackedFloat32Array()
	else:
		kind.mesh = build()
		kind.material = kind.lod_material
		kind.lods = build_lods()
		kind.lod_distances = PackedFloat32Array(TRAD_LOD_DISTANCES)


## Simpler versions for further off (PropKind.lods): branches cut after 3
## levels (~700 triangles) and after 2 (~110), each cut branch's subtree one
## leaf cluster, as the raymarched tree does with distance.
static func build_lods() -> Array[Mesh]:
	if _trad_lods.is_empty():
		_trad_lods = [build_mesh(3, 5, 1), build_mesh(2, 4, 0)]
	return _trad_lods


## The tree as triangles: bark (vertex alpha 0) and leaves (alpha 1).
## cut: levels of branches drawn (the rest become clusters); sides: segments
## round a branch; leaf_subdiv: of each cluster's sphere.
static func build_mesh(cut := LEVELS, sides := 7, leaf_subdiv := 1) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ico := _icosphere(leaf_subdiv)
	_grow(st, Transform3D.IDENTITY, 0, TRUNK_R, cut, sides, ico)
	st.index()
	st.generate_normals()
	return st.commit()


static func _grow(st: SurfaceTool, xf: Transform3D, level: int, r_local: float, cut: int, sides: int, ico: Array) -> void:
	var sc := pow(LEN_RATIO, level) # metres per local unit
	if level >= mini(cut, LEVELS):
		# one cluster for the rest of the subtree (the shader's tree(), the same)
		var m := LEVELS - level
		var hm := TRUNK_LEN * (1.0 - pow(LEN_RATIO, m)) / (1.0 - LEN_RATIO)
		var rl := LEAF_R / sc
		_leaf(st, xf, Vector3(0.0, 0.45 * hm + rl * 0.6, 0.0), 0.5 * hm + rl, sc, ico)
		return
	var r_top := r_local * RAD_RATIO / LEN_RATIO
	_branch(st, xf, r_local, r_top, sides)
	for side in [1.0, -1.0]:
		_grow(st, xf * _child(side, TILT, TWIST), level + 1, r_top, cut, sides, ico)


static func _branch(st: SurfaceTool, xf: Transform3D, r0: float, r1: float, sides: int) -> void:
	var flip := xf.basis.determinant() < 0.0
	var bark := Color(0.3, 0.22, 0.15, 0.0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var q := [xf * (d0 * r0), xf * (d1 * r0), xf * (d1 * r1 + Vector3(0, TRUNK_LEN, 0)), xf * (d0 * r1 + Vector3(0, TRUNK_LEN, 0))]
		var tris := [[0, 1, 2], [0, 2, 3]] if not flip else [[0, 2, 1], [0, 3, 2]]
		for t in tris:
			for k in t:
				st.set_color(bark)
				st.add_vertex(q[k])


static func _leaf(st: SurfaceTool, xf: Transform3D, c: Vector3, r: float, sc: float, ico: Array) -> void:
	var flip := xf.basis.determinant() < 0.0
	var verts: PackedVector3Array = ico[0]
	var idx: PackedInt32Array = ico[1]
	var placed := PackedVector3Array()
	for v in verts:
		var p := xf * (c + v * r) # tree space (m)
		# the lumps, along the sphere's normal, as in the shader
		var n := (xf.basis * v).normalized()
		placed.append(p - n * LEAF_AMP * leaf_noise(p))
	var shade := 0.85 + 0.3 * fposmod(sin(placed[0].x * 12.9 + placed[0].z * 78.2) * 43758.5, 1.0)
	var leaf := Color(0.16 * shade, 0.3 * shade, 0.09 * shade, 1.0)
	for i in range(0, idx.size(), 3):
		var t := [idx[i], idx[i + 1], idx[i + 2]] if not flip else [idx[i], idx[i + 2], idx[i + 1]]
		for k in t:
			st.set_color(leaf)
			st.add_vertex(placed[k])


## A unit icosphere: [vertices, indices] (counter-clockwise from outside).
static func _icosphere(subdiv: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = []
	for p in [[-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1]]:
		v.append(Vector3(p[0], p[1], p[2]).normalized())
	var f := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
			[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for s in subdiv:
		var mid := {}
		var nf := []
		for tri in f:
			var m := []
			for e in 3:
				var a: int = tri[e]
				var b: int = tri[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not mid.has(key):
					mid[key] = v.size()
					v.append(((v[a] + v[b]) * 0.5).normalized())
				m.append(mid[key])
			nf.append([tri[0], m[0], m[2]])
			nf.append([tri[1], m[1], m[0]])
			nf.append([tri[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		f = nf
	var idx := PackedInt32Array()
	for tri in f:
		# Godot's front faces are clockwise: reverse the CCW ones
		idx.append_array([tri[0], tri[2], tri[1]])
	return [PackedVector3Array(v), idx]


## The tree's extent (m): [min, max] over branch ends and leaf clusters.
static func bounds() -> AABB:
	var box := AABB(Vector3(-TRUNK_R, 0, -TRUNK_R), Vector3(TRUNK_R * 2, TRUNK_LEN, TRUNK_R * 2))
	var stack := [[Transform3D.IDENTITY, 0]]
	while not stack.is_empty():
		var e: Array = stack.pop_back()
		var xf: Transform3D = e[0]
		var level: int = e[1]
		var sc := pow(LEN_RATIO, level)
		if level == LEVELS:
			var r := LEAF_R / sc
			var c := xf * Vector3(0, r * 0.6, 0)
			box = box.merge(AABB(c - Vector3.ONE * (LEAF_R + LEAF_AMP), Vector3.ONE * 2.0 * (LEAF_R + LEAF_AMP)))
			continue
		box = box.expand(xf * Vector3(0, TRUNK_LEN, 0))
		for side in [1.0, -1.0]:
			stack.append([xf * _child(side, TILT, TWIST), level + 1])
	return box
