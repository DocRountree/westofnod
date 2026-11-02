class_name OakTree
## The English oak (Quercus robur): four hand-set standing trees, a stump,
## three dead standing trees, three fallen logs and two saplings (variants 0-12), grown into a
## TreeBuilder skeleton and dressed with data/population/textures/oak_*.png
## (tools/trees/bake_oak_textures.py). The prop (data/population/props/
## oak.tres) has variants = 13 and this as its mesh_script.
##
## What makes it read as an oak: a short, stout trunk with flared roots that
## runs on into the crown, giving off a few heavy limbs one after another; limbs that spread wide, nearly level,
## and go crooked, changing direction at every node; side branches that
## leave at wide angles and turn up at their ends; leaves crowded in
## clusters at the shoot tips; a broad, rounded crown, often wider than tall.
##
## Levels: 0 trunk, 1 limbs, 2 branches, 3 twigs (the twigs carry the sprigs).
## The crown is an ellipsoid ("crown": horizontal radius, top, bottom, m):
## branches that reach it stop there and leaf out, so the leaves pack into
## a dome as an oak's do.

const VARIANTS := [
	# open-grown: short trunk, limbs spreading wide, a broad dome
	{"trunk_h": 2.8, "leader_h": 4.0, "trunk_r": 0.5, "limbs": 6, "limb_angle": 55.0, "limb_len": 8.0, "branch_len": 3.6, "twig_len": 1.2, "lean": 0.0, "droop": 0.0, "seed": 11, "crown": [7.5, 15.5, 3.5]},
	# young: slimmer, upright, a strong leader
	{"trunk_h": 3.2, "leader_h": 6.5, "trunk_r": 0.28, "limbs": 6, "limb_angle": 42.0, "limb_len": 5.0, "branch_len": 2.6, "twig_len": 1.1, "lean": 0.0, "droop": 0.0, "seed": 23, "crown": [5.0, 14.5, 3.5]},
	# leaning: grown toward the light, the crown heavier on one side
	{"trunk_h": 3.0, "leader_h": 4.5, "trunk_r": 0.42, "limbs": 5, "limb_angle": 50.0, "limb_len": 7.0, "branch_len": 3.3, "twig_len": 1.15, "lean": 9.0, "droop": 0.02, "seed": 41, "crown": [6.8, 14.5, 3.5]},
	# forest-grown: a tall clean bole, a small high crown
	{"trunk_h": 6.5, "leader_h": 5.5, "trunk_r": 0.45, "limbs": 5, "limb_angle": 40.0, "limb_len": 5.2, "branch_len": 2.8, "twig_len": 1.1, "lean": 0.0, "droop": 0.0, "seed": 53, "crown": [5.0, 19.0, 7.5]},
	# a stump, sawn off, the roots flaring
	{"kind": "stump", "seed": 61},
	# a fallen trunk, snapped at both ends, the stubs of its limbs
	{"kind": "log", "seed": 67},
	# a dead oak still standing: an open-grown oak's skeleton, bare, broken
	{"kind": "dead", "like": 0, "seed": 71, "limb_angle": 40.0, "limb_len": 7.0, "branch_len": 3.0, "crown": [6.0, 13.5, 3.0]},
	# a long, slender fallen stem, bristling with snapped limbs
	{"kind": "log", "seed": 73, "length": Vector2(8.0, 9.5), "r0": 0.32, "r1": 0.17, "bow": 0.45, "stubs": Vector2i(4, 6)},
	# a short, heavy section of a big trunk
	{"kind": "log", "seed": 79, "length": Vector2(2.8, 3.6), "r0": 0.58, "r1": 0.52, "bow": 0.06, "stubs": Vector2i(0, 1)},
	# saplings, 3-4 m: a whip with a small crown, and a bushier one forking low
	{"kind": "sapling", "trunk_h": 0.9, "leader_h": 2.0, "trunk_r": 0.045, "limbs": 4, "limb_angle": 40.0, "limb_len": 1.5, "branch_len": 0.8, "twig_len": 0.5, "lean": 0.0, "droop": 0.0, "seed": 83, "crown": [1.3, 3.8, 0.9]},
	{"kind": "sapling", "trunk_h": 0.4, "leader_h": 1.6, "trunk_r": 0.05, "limbs": 5, "limb_angle": 52.0, "limb_len": 1.6, "branch_len": 0.8, "twig_len": 0.5, "lean": 4.0, "droop": 0.0, "seed": 89, "crown": [1.6, 3.2, 0.5]},
	# two more dead oaks: a young one, slender, its few limbs steep; and a
	# forest-grown one, a tall clean bole, a small broken crown, leaning
	{"kind": "dead", "like": 1, "seed": 97, "limb_angle": 34.0, "limb_len": 4.6, "branch_len": 2.2, "crown": [4.2, 13.0, 3.5]},
	{"kind": "dead", "like": 3, "seed": 103, "lean": 6.0, "limb_angle": 46.0, "limb_len": 4.8, "branch_len": 2.4, "crown": [4.6, 17.5, 7.5]},
]

## How a variant differs as a prop (Population applies these to its kind):
## weight is its share of the oaks; the stump and the dead oak are half as
## common as each standing tree (the three dead ones together), the three logs together three quarters,
## each sapling half; the logs lie along the ground (out into a swamp's
## edge, too: standing on one lifts you out of the mud), can be stood on
## and cast no shadow, the stumps jumped onto; dead oaks stand in the swamp too, as many as all the
## standing oaks (live, saplings and dead; not the logs or stumps) on the
## prairie, down into its shallows, gathered there in irregular clumps (no
## two closer than 7.5 m: their trunks clear, limbs may interlace).
const PROPS := {
	"tree": {"standing": true, "foot": 0.75, "shadowless_in": ["swamp"]},
	"stump": {"weight": 0.5, "shadowless_in": ["swamp"], "radius": 0.0, "foot": 0.6, "align_to_ground": 0.3, "sink": 0.12, "scale_range": Vector2(0.8, 1.1)},
	"log": {"weight": 0.25, "radius": 0.0, "align_to_ground": 0.9, "sink": 0.12, "scale_range": Vector2(0.8, 1.15), "shadows": false},
	"dead": {"weight": 0.5 / 3.0, "standing": true, "density_like": {"swamp": "prairie"}, "like_group": "standing", "height_range": Vector2(-0.5, 1900.0), "foot": 0.65,
		"clump": {"swamp": 1.0}, "clump_size": 34.0, "min_spacing": 7.5, "shadowless_in": ["swamp"]},
	"sapling": {"weight": 0.5, "standing": true, "radius": 0.1, "foot": 0.08, "scale_range": Vector2(0.75, 1.25), "shadowless_in": ["swamp"]},
}

# per level (0 trunk .. 3 twigs)
const SEG := [0.5, 0.65, 0.45, 0.35] ## m between nodes
const CROOK := [0.05, 0.15, 0.28, 0.32] ## rad, random turn at each node
const UP := [0.0, 0.012, 0.06, 0.1] ## turn toward the sky at each node
const CHILD_ANGLE := [0.0, 0.9, 0.85, 0.8] ## rad off the parent
const TIP_R := 0.006 ## m, the thinnest twig

## Levels of detail: where each simpler one takes over (m), and the last's
## end. Each level has its own materials, which know its span (lod_range)
## for the stippled hand-over (lod_fade.gdshaderinc).
const LOD := [40.0, 120.0, 300.0]
const VIEW := 600.0

static var _bark_mats := {} # [level, cover] -> ShaderMaterial

## How much lichen (its share of the bark), moss, moss up the sides from
## the ground, and moss on a cut end's face (lichen.gdshaderinc) each kind
## carries: none on saplings; dead oaks and logs the same everywhere (not
## by biome: LICHEN_ANY), as much as a dead oak in a swamp would otherwise
## have, less 20% (save dead oaks in the swamp: all of it); the stumps mossiest (their tops almost
## covered and spilling over here and there, patches up from the ground),
## the logs some on top. On the prairie very little lichen and no moss, in
## the swamp the most lichen (lichen.gdshaderinc growth_at; main.gd tells
## the materials where they are: set_growth_map).
const COVER := {
	"tree": [0.11, 0.0, 0.0, 0.0], "sapling": [0.0, 0.0, 0.0, 0.0], "dead": [0.245, 0.0, 0.0, 0.0],
	"stump": [0.15, 0.92, 1.0, 1.0], "log": [0.245, 0.6, 0.25, 0.4],
	"fresh_stump": [0.11, 0.0, 0.0, 0.0], # (an axed tree's: its bark as the tree's, its top clean)
}
static var _growth := {} # the biome map's parameters (set_growth_map)
const LICHEN_ANY := ["dead", "log", "stump"] ## Their lichen doesn't go by the biome (the prairie's dry air thins it on the living trees only).
const MOSS_ANY := ["log", "stump"] ## Their moss grows on the prairie too (on the ground, damp underneath).
static var _leaf_mats := {}
static var _cache := {} # variant -> [mesh, lods, near_multimesh]


static func bark_material(level := 0, kind := "tree") -> ShaderMaterial:
	var cover: Array = COVER.get(kind, COVER.tree)
	var key := [level, cover, kind == "fresh_stump"]
	if not _bark_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/bark.gdshader")
		m.set_shader_parameter("fresh_end", kind == "fresh_stump")
		m.set_shader_parameter("bark_tex", _texture("res://data/population/textures/oak_bark.png"))
		m.set_shader_parameter("lichen_amount", cover[0])
		m.set_shader_parameter("moss_amount", cover[1])
		m.set_shader_parameter("moss_low", cover[2])
		m.set_shader_parameter("lichen_any_biome", kind in LICHEN_ANY)
		m.set_shader_parameter("moss_any_biome", kind in MOSS_ANY)
		m.set_shader_parameter("lichen_swamp", 1.25 if kind == "dead" else 1.0) # (in the swamp as before: 0.306)
		m.set_shader_parameter("moss_end", cover[3])
		m.set_shader_parameter("lichen_tex", _texture("res://data/population/textures/lichen.png"))
		m.set_shader_parameter("moss_tex", _texture("res://data/population/textures/moss.png"))
		if kind == "stump":
			m.set_shader_parameter("moss_spill", _stump_top())
		for p in _growth:
			m.set_shader_parameter(p, _growth[p])
		_lod_span(m, level)
		_bark_mats[key] = m
	return _bark_mats[key]


## The moss's sporophytes, for a kind with moss (sporophytes.gdshader): its
## moss's settings, the same as its bark's.
static func sporophyte_material(kind: String) -> ShaderMaterial:
	var cover: Array = COVER.get(kind, COVER.tree)
	var key := ["sporophytes", cover]
	if not _bark_mats.has(key):
		var bark := bark_material(0, kind)
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/sporophytes.gdshader")
		for p in ["moss_amount", "moss_low", "moss_end", "moss_spill", "moss_any_biome", "moss_tex"]:
			m.set_shader_parameter(p, bark.get_shader_parameter(p))
		for p in _growth:
			m.set_shader_parameter(p, _growth[p])
		_bark_mats[key] = m # (with the bark's: told the night and the biomes too)
	return _bark_mats[key]


const SPOROPHYTES := 3000.0 ## a m², on what faces up (fewer down the sides); shown where the moss is thick
const SPOROPHYTES_MOST := 40000


## Where the player is (main.gd, each frame): the sporophytes stand only
## within a couple of metres of them.
static func set_player(pos: Vector3) -> void:
	for key in _bark_mats:
		if key[0] is String:
			_bark_mats[key].set_shader_parameter("player", pos)


## One sporophyte's corners (UV, as sporophytes.gdshader reads them): the
## stalk, three sides, rings at its foot, middle and top; the capsule,
## three rings of five between two poles. And its triangles.
static var _spo_uv := PackedVector2Array()
static var _spo_idx := PackedInt32Array()


static func _sporophyte_template() -> void:
	if not _spo_uv.is_empty():
		return
	const SIDES := 3
	for ring in 3:
		for k in SIDES:
			_spo_uv.append(Vector2(float(k) / SIDES, ring * 0.5))
	for ring in 2:
		for k in SIDES:
			var a := ring * SIDES + k
			var b := ring * SIDES + (k + 1) % SIDES
			_spo_idx.append_array([a, b, b + SIDES, a, b + SIDES, a + SIDES])
	const ROUND := 5
	var bottom := _spo_uv.size()
	_spo_uv.append(Vector2(0.0, 2.0))
	for ring in 3:
		for k in ROUND:
			_spo_uv.append(Vector2(float(k) / ROUND, 2.25 + ring * 0.25))
	_spo_uv.append(Vector2(0.0, 3.0))
	var top := bottom + 3 * ROUND + 1
	for k in ROUND:
		var a := bottom + 1 + k
		var b := bottom + 1 + (k + 1) % ROUND
		_spo_idx.append_array([bottom, b, a])
		for ring in 2:
			var c := a + ring * ROUND
			var d := b + ring * ROUND
			_spo_idx.append_array([c, d, d + ROUND, c, d + ROUND, c + ROUND])
		_spo_idx.append_array([top, a + 2 * ROUND, b + 2 * ROUND])


## The template every sporophyte is drawn from (sporophytes.gdshader builds
## the shape): every corner at the origin, told apart by its UV.
static var _spo_mesh: ArrayMesh


## The moss's sporophytes on the bark of mesh (its first surface), as a
## MultiMesh in the tree's own space, one instance each: its origin the
## foot, basis x the bark's normal there, y the stalk (1-2.2 cm, standing
## straight up); its colour the bark's UV there (r, g); custom the foot
## (xyz) and 2 on a cut end + a rank 0..1 (w).
## All over what faces up or sideways (the shader shows those where the moss
## is). Drawn only for the logs and stumps near the player (Population,
## near_multimesh), so a log can carry all it should.
static func _sporophyte_multimesh(mesh: ArrayMesh, seed: int) -> MultiMesh:
	_sporophyte_template()
	if _spo_mesh == null:
		var t := []
		t.resize(Mesh.ARRAY_MAX)
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		v.resize(_spo_uv.size())
		n.resize(_spo_uv.size())
		n.fill(Vector3.UP)
		t[Mesh.ARRAY_VERTEX] = v
		t[Mesh.ARRAY_NORMAL] = n
		t[Mesh.ARRAY_TEX_UV] = _spo_uv
		t[Mesh.ARRAY_INDEX] = _spo_idx
		_spo_mesh = ArrayMesh.new()
		_spo_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, t)
		_spo_mesh.custom_aabb = AABB(Vector3(-0.01, -0.01, -0.01), Vector3(0.02, 0.04, 0.02))
	var a := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uv2: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 31 + 7
	var xfs: Array[Transform3D] = []
	var customs: Array[Color] = []
	var colors: Array[Color] = []
	for i in range(0, idx.size(), 3):
		var p0 := verts[idx[i]]
		var e1 := verts[idx[i + 1]] - p0
		var e2 := verts[idx[i + 2]] - p0
		var n := (normals[idx[i]] + normals[idx[i + 1]] + normals[idx[i + 2]]).normalized()
		if n.y < -0.3:
			continue # (underneath)
		var k := 0.5 * e1.cross(e2).length() * SPOROPHYTES * (0.3 + 0.7 * smoothstep(-0.35, 0.7, n.y))
		var many := int(k) + (1 if rng.randf() < k - int(k) else 0)
		var end := 2.0 if uv2.size() > idx[i] and uv2[idx[i]].x > 0.5 else 0.0
		for _j in many:
			if xfs.size() >= SPOROPHYTES_MOST:
				break
			var r1 := rng.randf()
			var r2 := rng.randf()
			if r1 + r2 > 1.0:
				r1 = 1.0 - r1
				r2 = 1.0 - r2
			var foot := p0 + e1 * r1 + e2 * r2
			var stalk := (Vector3.UP + Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)) * 0.06).normalized() * rng.randf_range(0.01, 0.022)
			var side := n.cross(stalk)
			if side.length_squared() < 1e-10:
				side = Vector3.RIGHT.cross(stalk)
			xfs.append(Transform3D(Basis(n, stalk, side.normalized()), foot))
			# the bark's UV at the foot (the instance's colour: the shader
			# reads the moss texture there, as the bark does, to stand only
			# on green moss)
			var uv := uvs[idx[i]] + (uvs[idx[i + 1]] - uvs[idx[i]]) * r1 + (uvs[idx[i + 2]] - uvs[idx[i]]) * r2
			colors.append(Color(uv.x, uv.y, 0.0, 1.0))
			customs.append(Color(foot.x, foot.y, foot.z, end + rng.randf()))
	if xfs.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.use_colors = true
	mm.mesh = _spo_mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_custom_data(i, customs[i])
		mm.set_instance_color(i, colors[i])
	return mm


## A variant's sporophytes: [MultiMesh (in the tree's own space), material],
## or [] for one without moss. Population draws them on the logs and stumps
## near the player.
static func near_multimesh(variant := 0) -> Array:
	return _models(variant)[2]


## The stump's top (m, its own space): where its moss spills over.
static func _stump_top() -> float:
	for v in VARIANTS.size():
		if _kind(v) == "stump":
			return build_walk(v)[4]
	return 0.0


## 0 day .. 1 night: the lichen and the leaves dim at night (main.gd).
static func set_night(n: float) -> void:
	for key in _bark_mats:
		_bark_mats[key].set_shader_parameter("night", n)
	for key in _leaf_mats:
		_leaf_mats[key].set_shader_parameter("night", n)


## Where lichen and moss grow how much (sparse on the prairie, thick in the
## swamp), from the world's biome map (for every bark material, made or to
## be made).
static func set_growth_map(world: WorldData) -> void:
	if world.biome_tex == null:
		return
	_growth = {"growth_biomes": world.biome_tex, "growth_origin": world.origin,
			"growth_domain": world.domain, "prairie_biome": world.biome_names.find("prairie"),
			"swamp_biome_": world.biome_names.find("swamp")}
	for key in _bark_mats:
		for p in _growth:
			_bark_mats[key].set_shader_parameter(p, _growth[p])


static func leaf_material(level := 0) -> ShaderMaterial:
	if not _leaf_mats.has(level):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/leaves.gdshader")
		m.set_shader_parameter("leaf_tex", _texture("res://data/population/textures/oak_leaves.png"))
		_lod_span(m, level)
		_leaf_mats[level] = m
	return _leaf_mats[level]


static var _textures := {}


## A texture with its mipmaps, whatever it was imported with (.import files
## aren't kept in the repository, and Godot's default leaves them out for a
## texture only scripts use): without them the leaves' cut-outs and the bark
## alias, sparkling and crawling as the camera moves.
static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		var t: Texture2D = load(path)
		var img := t.get_image()
		if not img.has_mipmaps():
			if img.is_compressed():
				img.decompress()
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
		_textures[path] = t
	return _textures[path]


static func _lod_span(m: ShaderMaterial, level: int) -> void:
	var begin: float = 0.0 if level == 0 else LOD[level - 1]
	var end: float = VIEW if level == LOD.size() else LOD[level]
	m.set_shader_parameter("lod_range", Vector3(begin, end, Population.LOD_FADE))


## Off: every level drawn wherever it is (e.g. to look at one level alone).
static func set_lod_fade(on: bool) -> void:
	for mats in [_bark_mats, _leaf_mats]:
		for key in mats:
			var r: Vector3 = mats[key].get_shader_parameter("lod_range")
			r.z = Population.LOD_FADE if on else 0.0
			mats[key].set_shader_parameter("lod_range", r)


static var _shadow: Mesh
static var _sapling_shadow: Mesh


## Whether variant v can be felled (an axe: Felling): the standing ones.
static func choppable(v: int) -> bool:
	return _kind(v) in ["tree", "dead", "sapling"]


## The trunk's radius at the foot (m, at scale 1) of a standing variant.
static func trunk_radius(v: int) -> float:
	var P: Dictionary = VARIANTS[posmod(v, VARIANTS.size())]
	if P.has("trunk_r"):
		return P.trunk_r
	if P.has("like"):
		return VARIANTS[P.like].get("trunk_r", 0.4)
	return 0.4


## The trunk's radius (m, at scale 1) at height h of a standing variant, as
## its mesh has it: the mean distance from the trunk's middle of where its
## bark crosses the plane y = h (Felling: the rings' scale on a cut).
static var _radius_at := {}


static func trunk_radius_at(v: int, h: float) -> float:
	var key := [posmod(v, VARIANTS.size()), snappedf(h, 0.01)]
	if not _radius_at.has(key):
		var arrays := build(v).surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var mid := Vector2.ZERO
		var near: Array[Vector2] = []
		# where the triangles' edges cross the plane y = h, near the trunk
		for i in range(0, idx.size(), 3):
			for e in 3:
				var a := verts[idx[i + e]]
				var b := verts[idx[i + (e + 1) % 3]]
				if (a.y - h) * (b.y - h) < 0.0:
					var p := a.lerp(b, (h - a.y) / (b.y - a.y))
					if Vector2(p.x, p.z).length() < trunk_radius(v) * 2.5:
						near.append(Vector2(p.x, p.z))
						mid += Vector2(p.x, p.z)
		var r := trunk_radius(v)
		if near.size() > 4:
			mid /= near.size()
			r = 0.0
			for q in near:
				r += q.distance_to(mid)
			r /= near.size()
		_radius_at[key] = r
	return _radius_at[key]


static func _kind(v: int) -> String:
	return VARIANTS[posmod(v, VARIANTS.size())].get("kind", "tree")


## Population: how variant v differs as a prop.
static func variant_props(v: int) -> Dictionary:
	var p: Dictionary = PROPS[_kind(v)].duplicate()
	p.lod_distances = PackedFloat32Array(LOD)
	p.view_distance = VIEW
	return p


## The whole tree (PropKind.mesh_script).
static func build(variant := 0) -> Mesh:
	return _models(variant)[0]


## The shadow every standing oak casts, whatever its variant: a lumpy dome
## on a stalk (PropKind.shadow_mesh; the trees themselves cast none). The
## stump and the log cast their own (null).
static func build_shadow(variant := 0) -> Mesh:
	match _kind(variant):
		"tree":
			if _shadow == null:
				_shadow = TreeBuilder.shadow_proxy(7.5, 4.0, 14.0, 0.45, 23)
			return _shadow
		"sapling": # (the same, small)
			if _sapling_shadow == null:
				_sapling_shadow = TreeBuilder.shadow_proxy(1.3, 1.0, 3.6, 0.05, 29)
			return _sapling_shadow
	return null


## Simpler versions for further off: branches and clump cards to 40-120 m,
## limbs and fewer, bigger clumps to 300 m, the stem and a few big clumps
## beyond.
## The stump an axe leaves (Felling): the stump's shape, but sawn flat
## across (no splinters), its top fresh, pale wood, no moss or lichen on it
## yet. [mesh, lods] (its levels of detail as the stump's).
static var _fresh_stump := []


static func fresh_stump() -> Array:
	if _fresh_stump.is_empty():
		var b := [bark_material(0, "fresh_stump"), bark_material(1, "fresh_stump"), bark_material(2, "fresh_stump"), bark_material(3, "fresh_stump")]
		var l := [leaf_material(0), leaf_material(1), leaf_material(2), leaf_material(3)]
		var tb := grow_stump(VARIANTS[4])
		tb.splinter = false
		tb.caps[tb.caps.size() - 1][2] = 0.0 # (sawn flat across)
		var lods: Array[Mesh] = [tb.lod(b[1], l[1], 0, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
		_fresh_stump = [tb.build(b[0], l[0], 12.0), lods]
	return _fresh_stump


## The cut variant of a variant's meshes (its levels of detail: [mesh,
## lods]): their bark in bark.gdshader compiled with BARK_CUT, both faces
## drawn, so a notch (Population.set_notch) is a real hollow and a felled
## tree's foot (Felling: cut_below) a cut face. For the trees being felled
## (Population: their chunk's nearest level) and the felled.
static var _cut_meshes := {}
static var _cut_shader: Shader


static func cut_meshes(variant := 0) -> Array:
	variant = posmod(variant, VARIANTS.size())
	if not _cut_meshes.has(variant):
		if _cut_shader == null:
			var src: Shader = load("res://shaders/render/bark.gdshader")
			_cut_shader = Shader.new()
			_cut_shader.code = src.code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode cull_disabled;\n#define BARK_CUT")
		var out := []
		for m: Mesh in [build(variant)] + build_lods(variant):
			var c := m.duplicate() as ArrayMesh
			for si in c.get_surface_count():
				var mat := c.surface_get_material(si) as ShaderMaterial
				if mat and mat.shader and mat.shader.resource_path == "res://shaders/render/bark.gdshader":
					c.surface_set_material(si, _cut_material(mat))
			out.append(c)
		_cut_meshes[variant] = [out[0], out.slice(1)]
	return _cut_meshes[variant]


static func _cut_material(mat: ShaderMaterial) -> ShaderMaterial:
	var key := ["cut", mat]
	if not _bark_mats.has(key):
		var c := mat.duplicate() as ShaderMaterial
		c.shader = _cut_shader
		_bark_mats[key] = c # (with the bark's: told the night and the biomes too)
	return _bark_mats[key]


static func build_lods(variant := 0) -> Array[Mesh]:
	return _models(variant)[1]


static func _models(variant: int) -> Array:
	variant = posmod(variant, VARIANTS.size())
	if not _cache.has(variant):
		var k := _kind(variant)
		var b := [bark_material(0, k), bark_material(1, k), bark_material(2, k), bark_material(3, k)]
		var l := [leaf_material(0), leaf_material(1), leaf_material(2), leaf_material(3)]
		var tb: TreeBuilder
		var lods: Array[Mesh]
		match _kind(variant):
			"stump":
				tb = grow_stump(VARIANTS[variant])
				lods = [tb.lod(b[1], l[1], 0, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			"log":
				tb = grow_log(VARIANTS[variant])
				lods = [tb.lod(b[1], l[1], 1, 2, 0, 1.0), tb.lod(b[2], l[2], 0, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			"dead":
				tb = grow_dead(VARIANTS[variant])
				lods = [tb.lod(b[1], l[1], 2, 2, 0, 1.0), tb.lod(b[2], l[2], 1, 3, 0, 1.0), tb.lod(b[3], l[3], 0, 4, 0, 1.0)]
			_:
				tb = grow(variant)
				lods = [tb.lod(b[1], l[1], 2, 2, 4, 1.0, LOD[0]), tb.lod(b[2], l[2], 1, 3, 12, 2.0, LOD[1]), tb.lod(b[3], l[3], 0, 4, 36, 3.2, LOD[2])]
		var mesh := tb.build(b[0], l[0], 12.0)
		var near := []
		if (COVER.get(k, COVER.tree) as Array)[1] > 0.0:
			var mm := _sporophyte_multimesh(mesh, VARIANTS[variant].get("seed", variant))
			if mm:
				near = [mm, sporophyte_material(k)]
		_cache[variant] = [mesh, lods, near]
	return _cache[variant]


## Population: what can be stood on (PropKind.walk): a log's trunk, a
## segment between each pair of its nodes (not the stubs of its limbs); a
## stump, a post to the bottom of its splinters (solid all round, too); an
## oak's limbs.
static func build_walk(variant := 0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	variant = posmod(variant, VARIANTS.size())
	if _kind(variant) == "stump":
		var st := grow_stump(VARIANTS[variant])
		var h := st.pos[st.branches[0][-1]].y
		out.append_array([0.0, 0.0, 0.0, 0.0, h, 0.0, 0.55, 0.55])
		return out
	if _kind(variant) in ["tree", "dead"]:
		# the limbs, all of them, as far as they're climbable; marked by a
		# negative first radius (high in the air: Population.walk_near
		# leaves them out; never a post however steep)
		var lines := _climb_lines(variant)
		for li in range(1, lines.size()):
			var l := lines[li]
			for k in range(4, l.size(), 4):
				out.append_array([l[k - 4], l[k - 3], l[k - 2], l[k], l[k + 1], l[k + 2], -l[k - 1], l[k + 3]])
		return out
	if _kind(variant) != "log":
		return out
	var tb := grow_log(VARIANTS[variant])
	var b := tb.branches[0]
	for i in b.size() - 1:
		var a := tb.pos[b[i]]
		var e := tb.pos[b[i + 1]]
		out.append_array([a.x, a.y, a.z, e.x, e.y, e.z, tb.radius[b[i]], tb.radius[b[i + 1]]])
	return out


## Population: what can be climbed (PropKind.climb): a standing or dead
## oak's trunk, on up into the crown, and its limbs (the first branching),
## each as far as it's stout enough to hold you (5 cm); saplings are too
## slender, stumps and logs are stood on instead. Each line: its node count,
## then x, y, z, radius a node, from where it starts.
static func build_climb(variant := 0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for line in _climb_lines(variant):
		out.append(line.size() / 4)
		out.append_array(line)
	return out


static var _climb_cache := {}


## The trunk (first) and the limbs that can be climbed, x, y, z, r a node.
static func _climb_lines(variant: int) -> Array[PackedFloat32Array]:
	variant = posmod(variant, VARIANTS.size())
	if _climb_cache.has(variant):
		return _climb_cache[variant]
	var lines: Array[PackedFloat32Array] = []
	var tb: TreeBuilder
	match _kind(variant):
		"tree":
			tb = grow(variant)
		"dead":
			tb = grow_dead(VARIANTS[variant])
	if tb:
		tb.fit_radii() # (as drawn)
		# the trunk: the branch from the root; then the limbs off it
		var order: Array[PackedInt32Array] = []
		for br in tb.branches:
			if br.size() > 1 and br[0] == 0:
				order.push_front(br)
			elif br.size() > 1 and tb.level[br[1]] == 1:
				order.append(br)
		for br in order:
			var line := PackedFloat32Array()
			for i in br:
				if tb.radius[i] < 0.05 and line.size() >= 8:
					break # (too thin to bear you)
				var p := tb.pos[i]
				line.append_array([p.x, p.y, p.z, tb.radius[i]])
			if line.size() >= 8:
				lines.append(line)
	_climb_cache[variant] = lines
	return lines


## A stump: snapped off 0.75-1.1 m up (low enough to jump onto), splinters standing up round a
## broken, sunken middle; the roots flaring into buttresses.
static func grow_stump(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	tb.rng.seed = P.seed
	tb.flare = 0.5
	tb.bark_tint = Color(0.92, 0.9, 0.86)
	tb.splinter = true
	var h := tb.rng.randf_range(0.75, 1.1)
	var nodes := PackedInt32Array([tb.add_node(Vector3.ZERO, -1, 0)])
	for i in 3:
		var y := h * (i + 1) / 3.0
		nodes.append(tb.add_node(Vector3(0.0, y, 0.0), nodes[i], 0))
	for n in nodes:
		tb.set_radius(n, 0.5 - 0.04 * tb.pos[n].y)
	tb.add_branch(nodes, false, true, 0.45)
	return tb


## A fallen trunk: 5-7 m, lying along x, a little bowed, broken at both
## ends, with the snapped stubs of a few limbs; the bark greyer and greener.
static func grow_log(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	var rng := tb.rng
	rng.seed = P.seed
	tb.flare = 0.0
	tb.splinter = true # (snapped, not sawn)
	tb.bark_tint = Color(0.78, 0.82, 0.7)
	var len_range: Vector2 = P.get("length", Vector2(5.0, 7.0))
	var length := rng.randf_range(len_range.x, len_range.y)
	var r0: float = P.get("r0", 0.42)
	var r1: float = P.get("r1", 0.3)
	var bow: float = P.get("bow", 0.25)
	var n := maxi(int(length / 0.65), 6)
	var nodes := PackedInt32Array()
	for i in n:
		var t := float(i) / (n - 1)
		var r := lerpf(r0, r1, t)
		var p := Vector3((t - 0.5) * length, r * 0.85 - 0.05 * sin(PI * t), bow * sin(PI * t * 1.3))
		nodes.append(tb.add_node(p, nodes[i - 1] if i > 0 else -1, 0))
		tb.set_radius(nodes[i], r)
	tb.add_branch(nodes, true, true, r0 * 0.7)
	# stubs of the limbs that broke off as it fell
	var stubs: Vector2i = P.get("stubs", Vector2i(2, 4))
	for k in rng.randi_range(stubs.x, stubs.y):
		var at := nodes[rng.randi_range(2, n - 2)]
		var around := rng.randf_range(-1.2, 1.2) + (PI if rng.randf() < 0.3 else 0.0)
		var d := Vector3(rng.randf_range(-0.4, 0.6), cos(around), sin(around)).normalized()
		if d.y < -0.2:
			d.y = -d.y # (not into the ground)
		var len := rng.randf_range(0.35, 1.1)
		var r := rng.randf_range(0.07, 0.12) * r0 / 0.42
		var stub := PackedInt32Array([at])
		for i in 2:
			stub.append(tb.add_node(tb.pos[at] + d * len * (i + 1) / 2.0, stub[i], 1))
			tb.set_radius(stub[i + 1], r * (1.0 - 0.25 * i))
		tb.add_branch(stub, false, true, r * 0.9)
	return tb


## A dead oak, still standing: the skeleton of the standing variant it's
## "like", with its own seed and spread, then stripped: the twigs and leaves gone,
## most branches and some limbs snapped off (end grain at the breaks), the
## bark weathered silver-grey. It casts its own shadow.
static func grow_dead(D: Dictionary) -> TreeBuilder:
	var P: Dictionary = VARIANTS[D.like].duplicate()
	for key in D:
		if key != "kind" and key != "like":
			P[key] = D[key] # (its own seed, and a narrower spread)
	var tb := _grow_tree(P)
	var rng := tb.rng
	tb.sprigs.clear()
	tb.bark_tint = Color(0.74, 0.72, 0.68)
	tb.sways = false
	# parents before children, so a branch knows whether its parent still
	# reaches the node it grows from
	var order := range(tb.branches.size())
	order.sort_custom(func(a: int, b: int) -> bool: return tb.level[tb.branches[a][1]] < tb.level[tb.branches[b][1]])
	var gone := {}
	var keep: Array[PackedInt32Array] = []
	var caps: Array = []
	for i in order:
		var b: PackedInt32Array = tb.branches[i]
		var lv := tb.level[b[1]]
		if gone.has(b[0]) or lv >= 3:
			for n in b:
				gone[n] = true
			continue
		var cut := b.size()
		if lv == 2 and rng.randf() < 0.75:
			cut = maxi(2, int(b.size() * rng.randf_range(0.2, 0.7)))
		elif lv == 1 and rng.randf() < 0.5:
			cut = maxi(3, int(b.size() * rng.randf_range(0.45, 0.85)))
		if cut < b.size():
			for j in range(cut, b.size()):
				gone[b[j]] = true
			keep.append(b.slice(0, cut))
			caps.append([false, true, tb.radius[b[cut - 1]] * rng.randf_range(0.8, 1.6)])
		else:
			keep.append(b)
			caps.append(tb.caps[i])
	tb.branches = keep
	tb.caps = caps
	return tb


## The skeleton of variant v (a standing tree).
static func grow(v: int) -> TreeBuilder:
	return _grow_tree(VARIANTS[v])


static func _grow_tree(P: Dictionary) -> TreeBuilder:
	var tb := TreeBuilder.new()
	tb.rng.seed = P.seed
	var rng := tb.rng
	tb.flare = 0.45 + P.trunk_r * 0.3
	var lean_az := rng.randf() * TAU
	var lean_dir := Vector3(cos(lean_az), 0.0, sin(lean_az))
	var c: Array = P.crown
	P = P.duplicate()
	P.env_centre = Vector3(0.0, (c[1] + c[2]) * 0.5, 0.0) + lean_dir * (P.lean / 11.0) * 2.0
	P.env_radii = Vector3(c[0], (c[1] - c[2]) * 0.5, c[0])
	# The stem: a clear bole, then on up into the crown as a leader that
	# the limbs leave one by one; it thins as each takes its share (the pipe
	# model), and its top carries on as the highest limb. Leaning if it does,
	# a little crooked.
	var d := (Vector3.UP + lean_dir * tan(deg_to_rad(P.lean))).normalized()
	var root := tb.add_node(Vector3.ZERO, -1, 0)
	var stem := PackedInt32Array([root])
	var total_h: float = P.trunk_h + P.leader_h
	var steps := maxi(ceili(total_h / SEG[0]), 3)
	var p := Vector3.ZERO
	var dirs: Array[Vector3] = [d]
	for i in steps:
		d = _turn(rng, d, CROOK[0] * (1.0 if p.y < P.trunk_h else 2.5))
		d = (d + Vector3.UP * 0.04).normalized()
		p += d * total_h / steps
		stem.append(tb.add_node(p, stem[stem.size() - 1], 0))
		dirs.append(d)
	# the limbs, up the leader in a spiral (137 degrees apart): the lowest
	# longest and flattest, the highest short and steep
	var first := 1
	while first < stem.size() - 1 and tb.pos[stem[first]].y < P.trunk_h:
		first += 1
	var n_limbs: int = P.limbs
	var az := rng.randf() * TAU
	for k in n_limbs:
		var f := float(k) / maxf(n_limbs - 1, 1)
		var at := clampi(first + roundi(f * (stem.size() - 1 - first)), 1, stem.size() - 1)
		az += deg_to_rad(137.5) + rng.randf_range(-0.3, 0.3)
		var tilt := deg_to_rad(lerpf(P.limb_angle, P.limb_angle * 0.55, f) + rng.randf_range(-6.0, 6.0))
		var dir := Vector3(sin(tilt) * cos(az), cos(tilt), sin(tilt) * sin(az))
		var len: float = P.limb_len * lerpf(1.0, 0.65, f) * rng.randf_range(0.85, 1.1)
		if P.lean > 0.0:
			var toward := Vector2(dir.x, dir.z).normalized().dot(Vector2(lean_dir.x, lean_dir.z))
			len *= 1.0 + 0.25 * toward # the crown heavier toward the lean
		_branch(tb, P, stem[at], dir, len, 1, dirs[at])
	# the leader's top, on as a limb
	_branch(tb, P, stem[stem.size() - 1], _turn(rng, dirs[dirs.size() - 1], 0.2), P.limb_len * 0.5, 1, dirs[dirs.size() - 1])
	tb.add_branch(stem)
	tb.compute_radii(P.trunk_r, TIP_R)
	return tb


## A branch at level lv from node `from`, heading dir, length m long: it
## leaves its parent nearly along the parent's way (parent_dir) and bends
## out to its own over its first few nodes, as wood grows; crooked, turning
## up, with side branches (or sprigs on the twigs) at its nodes.
static func _branch(tb: TreeBuilder, P: Dictionary, from: int, dir: Vector3, length: float, lv: int, parent_dir := Vector3.ZERO) -> void:
	var rng := tb.rng
	var steps := maxi(ceili(length / SEG[lv]), 2)
	var nodes := PackedInt32Array([from])
	var p := tb.pos[from]
	var target := dir
	var d := dir if parent_dir == Vector3.ZERO else parent_dir.slerp(dir, 0.3).normalized()
	var spiral := rng.randf() * TAU
	for i in steps:
		var t := float(i + 1) / steps
		if i < 4:
			d = d.slerp(target, 0.4).normalized() # (easing out of the parent)
		d = _turn(rng, d, CROOK[lv])
		# up toward the light; heavy limbs droop first, then sweep up
		var up: float = UP[lv] - (P.droop * (1.0 - t) if lv == 1 else 0.0)
		if p.y < P.trunk_h * 0.5:
			up = maxf(up, 0.25) # (never down into the ground)
		d = (d + Vector3.UP * up).normalized()
		target = (target + Vector3.UP * up * 0.5).normalized()
		var q := p + d * length / steps
		var e: Vector3 = (q - P.env_centre) / P.env_radii
		if e.y < 0.0:
			e.y *= 0.35 # (below its middle the crown is a broad, open bowl)
		if e.length() > (1.08 if lv == 1 else 1.0) and i > 0:
			break # reached the edge of the crown
		p = q
		var node := tb.add_node(p, nodes[nodes.size() - 1], lv)
		nodes.append(node)
		if lv < 3:
			# side branches, alternating round the branch, none near its base
			var start := 0.3 if lv == 1 else 0.15
			if t > start:
				for c in 2:
					spiral += 2.4 + rng.randf_range(-0.3, 0.3)
					var cd := _side(d, spiral, CHILD_ANGLE[lv + 1] + rng.randf_range(-0.2, 0.2))
					cd = _outward(cd, p, 0.35)
					if cd.y < -0.25: # (branches don't hang straight down)
						cd = Vector3(cd.x, -0.25, cd.z).normalized()
					var cl: float = (P.branch_len if lv == 1 else P.twig_len) * (1.0 - 0.45 * t) * rng.randf_range(0.75, 1.2)
					if rng.randf() < (0.8 if lv == 1 else 0.7):
						_branch(tb, P, node, cd, cl, lv + 1, d)
			# a few sprigs on the outer half of the branches too
			if lv == 2 and t > 0.4 and rng.randf() < 0.5:
				tb.add_sprig(node, _outward(_side(d, rng.randf() * TAU, 0.8), p, 0.4))
		elif t > 0.25 and rng.randf() < 0.7:
			tb.add_sprig(node, _outward(_side(d, rng.randf() * TAU, rng.randf_range(0.5, 1.1)), p, 0.3))
	if lv >= 2:
		tb.add_sprig(nodes[nodes.size() - 1], _outward(_turn(rng, d, 0.5), p, 0.3))
	tb.add_branch(nodes)


## d turned by up to `amount` rad in a random direction.
static func _turn(rng: RandomNumberGenerator, d: Vector3, amount: float) -> Vector3:
	return _side(d, rng.randf() * TAU, rng.randf() * amount)


## d tilted by angle toward the side at `around` rad round it.
static func _side(d: Vector3, around: float, angle: float) -> Vector3:
	var u := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
	var w := d.cross(u)
	var s := u * cos(around) + w * sin(around)
	return (d * cos(angle) + s * sin(angle)).normalized()


## d bent away from the trunk's axis (horizontally), by k.
static func _outward(d: Vector3, p: Vector3, k: float) -> Vector3:
	var o := Vector3(p.x, 0.0, p.z)
	if o.length() < 0.01:
		return d
	return (d + o.normalized() * k).normalized()
