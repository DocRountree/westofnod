class_name GroundCover
extends Node3D
## Grass and ferns: too many to place one by one (Population), so a grid of
## cells follows the camera and works out what grows in each from where
## the cell is: the same clump in the same place every time, nothing stored.
##
## Each layer is a MultiMesh of one cell per instance, shared by a square
## of tiles round the camera (a tile is a MultiMeshInstance3D, so Godot
## culls the ones out of view; as the camera moves, the tiles left behind
## jump ahead). When a layer's tiles move, a SubViewport works out every
## cell of its new grid once (ground_cover_bake.gdshader: what grows, how
## tall, its height on the ground, the ground's colour) into a small
## texture (and again every few metres the camera moves: the heights are
## the ground's as the terrain draws it from there, coarser further off),
## which the drawing shader (ground_cover.gdshader) reads: each
## vertex reads two texels instead of working the terrain out again. Two
## viewports take turns, so the shader switches to a new grid only once
## it's ready.
##
## Layers:
## - grass, near (to 17 m): dense; short in the forest (the ground's colour,
##   a little lighter at the tips), about head-high on the prairie (green
##   to blonde);
## - grass, middle (12-52 m): bigger, fewer clumps of the same (fewer,
##   wider blades);
## - grass, far (42-125 m): the prairie's only (fewer blades still, straight);
## - reeds: the swamp's, 1.8-2.3 m, broad-bladed, in clumps here and there
##   (sparse patches, in the water too); to 72 m;
## - cattails among them: stalks with brown heads, a few leaves; to 66 m;
## - marram: the coast's and the beaches', half the prairie grass's height,
##   as pale as the sand (a fifth of the patches a tad greener, a fifth a tad
##   yellower), in patches: none at the water's edge, thicker and
##   taller up the beach; near (to 25 m) and middle (18-62 m);
## - ferns: the forest's, in drifts, knee-high; to 45 m.
## - black-eyed Susans (Rudbeckia hirta) and fleabane (Erigeron annuus): the
##   prairie's wildflowers among its grass, in drifts, their heads up
##   among the grass's tips (taller than they'd be, the grass being head-high);
##   to 38 m and 34 m.
## The forest's brown patches are leaf litter: a texture on the terrain
## (terrain.gdshader), not geometry.
##
## A tile where its layer can't grow anything (no biome it grows in reaches
## it, as the ground blends them: WorldData.biome_bits_at; the marram, no
## beach either) isn't drawn at all: the reeds' tiles on the prairie, the
## ferns' out of the forest. Every empty cell of a drawn tile still costs
## its clump's every corner.

const LAYERS := [
	# cell (m), cells a tile side, tiles a side (odd), the mesh, uniforms
	{"cell": 0.25, "cells": 24, "tiles": 7, "blades": 10, "segs": 3, "radius": 0.16, "width": 0.016,
		"u": {"kind": 0, "seed": 1, "forest_height": Vector2(0.07, 0.16), "prairie_height": Vector2(1.5, 2.0),
			"fade_out": Vector2(12.0, 17.0), "thin_from": 1000.0}},
	{"cell": 0.55, "cells": 24, "tiles": 9, "blades": 11, "segs": 2, "radius": 0.32, "width": 0.027,
		"u": {"kind": 0, "seed": 2, "forest_height": Vector2(0.07, 0.16), "prairie_height": Vector2(1.5, 2.0),
			"fade_in": Vector2(12.0, 17.0), "fade_out": Vector2(40.0, 52.0), "thin_from": 28.0}},
	{"cell": 1.3, "cells": 20, "tiles": 11, "blades": 9, "segs": 1, "radius": 0.6, "width": 0.065,
		"u": {"kind": 0, "seed": 3, "in_forest": false, "prairie_height": Vector2(1.5, 2.0),
			"fade_in": Vector2(42.0, 52.0), "fade_out": Vector2(100.0, 125.0), "thin_from": 80.0}},
	{"cell": 1.0, "cells": 16, "tiles": 9, "blades": 11, "segs": 4, "radius": 0.4, "width": 0.068,
		"u": {"kind": 0, "seed": 5, "in_forest": false, "in_prairie": false, "in_swamp": true, "prairie_height": Vector2(1.8, 2.3),
			"prairie_green": Vector3(0.22, 0.33, 0.12), "prairie_blonde": Vector3(0.5, 0.45, 0.28),
			"fade_out": Vector2(55.0, 72.0), "thin_from": 40.0}},
	{"cell": 1.6, "cells": 12, "tiles": 7, "cattails": 4, "radius": 0.35,
		"u": {"kind": 0, "seed": 6, "in_forest": false, "in_prairie": false, "in_swamp": true, "cover": 0.45,
			"prairie_height": Vector2(1.7, 2.2), "prairie_green": Vector3(0.24, 0.33, 0.13), "prairie_blonde": Vector3(0.45, 0.42, 0.26),
			"fade_out": Vector2(50.0, 66.0), "thin_from": 40.0}},
	# marram, along the coast: half the prairie grass's height, as pale as the sand
	{"cell": 0.3, "cells": 24, "tiles": 9, "blades": 12, "segs": 3, "radius": 0.2, "width": 0.018,
		"u": {"kind": 0, "seed": 7, "in_forest": false, "in_prairie": false, "in_coast": true, "prairie_height": Vector2(0.75, 1.0),
			"prairie_green": Vector3(0.76, 0.74, 0.58), "prairie_blonde": Vector3(0.88, 0.84, 0.69), "patch_tints": Vector2(0.2, 0.2),
			"fade_out": Vector2(18.0, 25.0), "thin_from": 1000.0}},
	{"cell": 0.7, "cells": 20, "tiles": 9, "blades": 14, "segs": 2, "radius": 0.38, "width": 0.028,
		"u": {"kind": 0, "seed": 8, "in_forest": false, "in_prairie": false, "in_coast": true, "prairie_height": Vector2(0.75, 1.0),
			"prairie_green": Vector3(0.76, 0.74, 0.58), "prairie_blonde": Vector3(0.88, 0.84, 0.69), "patch_tints": Vector2(0.2, 0.2),
			"fade_in": Vector2(18.0, 25.0), "fade_out": Vector2(48.0, 62.0), "thin_from": 32.0}},
	# the prairie's flowers: black-eyed Susans in drifts, fleabane scattered more widely
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "susan", "stems": 3, "radius": 0.22,
		"u": {"kind": 2, "seed": 9, "in_forest": false, "cover": 0.65, "drift": Vector3(26.0, 0.6, 3.1),
			"forest_height": Vector2(1.25, 1.7), "prairie_height": Vector2(1.25, 1.7),
			"prairie_green": Vector3(0.26, 0.36, 0.12), "prairie_blonde": Vector3(0.36, 0.4, 0.16),
			"petal_color": Vector3(0.96, 0.71, 0.06), "petal_base": Vector3(0.9, 0.47, 0.05), "petal_alt": Vector3(0.97, 0.6, 0.05), "petal_alt_share": 0.3,
			"disc_color": Vector3(0.17, 0.08, 0.04), "head_size": 0.07, "head_px": Vector2(3.0, 6.0),
			"fade_out": Vector2(28.0, 38.0), "thin_from": 22.0}},
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "fleabane", "stems": 3, "radius": 0.2,
		"u": {"kind": 2, "seed": 10, "in_forest": false, "cover": 0.45, "drift": Vector3(15.0, 0.5, -7.7),
			"forest_height": Vector2(1.2, 1.5), "prairie_height": Vector2(1.2, 1.5),
			"prairie_green": Vector3(0.28, 0.38, 0.14), "prairie_blonde": Vector3(0.38, 0.42, 0.18),
			"petal_color": Vector3(0.97, 0.96, 0.95), "petal_base": Vector3(0.97, 0.96, 0.95), "petal_alt": Vector3(0.8, 0.7, 0.94), "petal_mix": 1.6,
			"disc_color": Vector3(0.95, 0.78, 0.12), "head_size": 0.025, "head_px": Vector2(3.0, 6.0),
			"fade_out": Vector2(24.0, 34.0), "thin_from": 20.0}},
	{"cell": 0.5, "cells": 24, "tiles": 9, "fronds": 8,
		"u": {"kind": 1, "seed": 4, "in_prairie": false, "forest_height": Vector2(0.25, 0.45),
			"fade_out": Vector2(32.0, 45.0), "thin_from": 16.0}},
]
const MAX_LOGS := 256 ## logs, stumps, trunks and boulders the grass is kept out of, nearest first (ground_cover_bake.gdshader: logs[])
const REBAKE := 5.0 ## m the camera moves before a layer's grid is worked out again
const BAKE_KEYS := ["kind", "seed", "in_forest", "in_prairie", "in_swamp", "in_coast", "forest_height", "prairie_height", "cover", "drift"]
const DRAW_KEYS := ["kind", "seed", "fade_in", "fade_out", "thin_from", "prairie_green", "prairie_blonde", "patch_tints",
		"petal_color", "petal_base", "petal_alt", "petal_alt_share", "disc_color", "head_size", "head_px", "petal_mix"]

var world: WorldData
var population: Population ## (optional) its logs and stumps keep the grass off
var materials: Array[ShaderMaterial] = []
var _layers: Array[Dictionary] = []
const BITS_CELL := 32.0 ## m: the grid the biomes' reach is read on (_bits)
const BITS_MARGIN := 48.0 ## m round a tile also looked at (between the grid's points, the borders' wander)
var _bits := {} # Vector2i (a BITS_CELL grid point) -> biome bits there (WorldData.biome_bits_at)
var _low := {} # the same -> true where the ground's within a few metres of the sea (beaches: the marram)
# the logs and trunks near the camera, found once for every layer
# (Population.walk_near, out to the furthest any layer needs, nearest first)
var _logs_at := Vector3.INF
var _logs_changes := -1
var _logs_xs := PackedVector4Array()
var _logs_rs := PackedFloat32Array()
var _logs_ds := PackedFloat32Array()


func setup(w: WorldData) -> void:
	world = w
	var frond := load("res://data/population/textures/fern_frond.png") as Texture2D
	for L in LAYERS:
		var grid: int = L.cells * L.tiles
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/ground_cover.gdshader")
		m.set_shader_parameter("cell", L.cell)
		if L.u.kind == 1:
			m.set_shader_parameter("frond_tex", OakTree._texture("res://data/population/textures/fern_frond.png"))
			m.set_shader_parameter("frond_mean", _mean_linear(frond))
		for k in L.u:
			if k in DRAW_KEYS:
				m.set_shader_parameter(k, L.u[k])
		materials.append(m)
		# the two viewports that work out the grid, in turn
		var vps: Array[SubViewport] = []
		var bakes: Array[ShaderMaterial] = []
		for n in 2:
			var vp := SubViewport.new()
			vp.size = Vector2i(grid * 2, grid)
			vp.disable_3d = true
			vp.transparent_bg = true
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
			vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
			var bm := ShaderMaterial.new()
			bm.shader = load("res://shaders/render/ground_cover_bake.gdshader")
			bm.set_shader_parameter("height_tex", world.height_tex)
			bm.set_shader_parameter("map_size", float(world.size))
			bm.set_shader_parameter("map_domain", world.domain)
			bm.set_shader_parameter("map_origin", world.origin)
			bm.set_shader_parameter("mask_tex", world.mask_tex)
			if world.biome_tex:
				bm.set_shader_parameter("biome_tex", world.biome_tex)
				bm.set_shader_parameter("swamp_biome", world.biome_names.find("swamp"))
			bm.set_shader_parameter("cell", L.cell)
			bm.set_shader_parameter("grid_size", Vector2i(grid, grid))
			bm.set_shader_parameter("clear", L.get("radius", 0.25) + 0.05)
			bm.set_shader_parameter("cd_leaf", Cdlod.GRID * world.cell() / 8.0)
			bm.set_shader_parameter("cd_range_factor", Cdlod.RANGE_FACTOR)
			bm.set_shader_parameter("cd_morph_start", Cdlod.MORPH_START)
			for k in L.u:
				if k in BAKE_KEYS:
					bm.set_shader_parameter(k, L.u[k])
			var rect := ColorRect.new()
			rect.size = Vector2(vp.size)
			rect.material = bm
			vp.add_child(rect)
			add_child(vp)
			vps.append(vp)
			bakes.append(bm)
		var mesh: Mesh
		if L.u.kind == 1:
			mesh = fern_mesh(L.fronds)
		elif L.has("flowers"):
			mesh = flower_mesh(L.flowers, L.stems, L.radius, L.u.seed)
		elif L.has("cattails"):
			mesh = cattail_mesh(L.cattails, L.radius, L.u.seed)
		else:
			mesh = grass_mesh(L.blades, L.segs, L.radius, L.width, L.u.seed)
		mesh.surface_set_material(0, m)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = L.cells * L.cells
		for i in L.cells:
			for j in L.cells:
				mm.set_instance_transform(i * L.cells + j, Transform3D(Basis(), Vector3(i * L.cell, 0.0, j * L.cell)))
		# what it grows in: biome bits, and whether beaches too
		var need := 0
		for pair in [["forest", L.u.get("in_forest", true)], ["prairie", L.u.get("in_prairie", true)],
				["swamp", L.u.get("in_swamp", false)], ["coast", L.u.get("in_coast", false)]]:
			var b: int = world.biome_id(pair[0])
			if pair[1] and b >= 0 and b < 31:
				need |= 1 << b
		_layers.append({"need": need, "beach": L.u.get("in_coast", false), "live": {},
				"L": L, "mm": mm, "size": L.cell * L.cells, "tiles": {}, "centre": Vector2i.MAX,
				"material": m, "vps": vps, "bakes": bakes, "shown": -1, "baking": false, "want": Vector2i.MAX, "cam": Vector3.ZERO, "baked": Vector3.INF, "walks": -1})


## The terrain's leaf litter texture (it's the terrain's material).
static func setup_terrain(terrain: ShaderMaterial) -> void:
	var t := OakTree._texture("res://data/population/textures/leaf_litter.png")
	terrain.set_shader_parameter("litter_tex", t)
	terrain.set_shader_parameter("litter_mean", _mean(t))


## Every layer's grid worked out and shown (after the first update()s).
func is_ready() -> bool:
	for layer in _layers:
		if layer.shown < 0 or layer.baking:
			return false
	return true


## Moves the tiles to keep round the camera. Call every frame.
func update(cam: Vector3) -> void:
	for layer in _layers:
		var L: Dictionary = layer.L
		var size: float = layer.size
		var tiles: Dictionary = layer.tiles
		var centre := Vector2i(floori(cam.x / size), floori(cam.z / size))
		if centre == layer.centre:
			# (the ground's heights are as the terrain draws them from the
			# eye, which changes as it moves: worked out again every few metres)
			# (and when logs or stumps come or go)
			var logs_moved: bool = population != null and population.walk_changes != layer.walks
			if not layer.baking and (cam.distance_to(layer.baked) > REBAKE or logs_moved):
				layer.cam = cam
				_bake(layer)
			continue
		layer.centre = centre
		var half: int = L.tiles / 2
		layer.want = (centre - Vector2i(half, half)) * int(L.cells)
		layer.cam = cam
		if not layer.baking:
			_bake(layer)
		var wanted := {}
		for i in range(-half, half + 1):
			for j in range(-half, half + 1):
				wanted[centre + Vector2i(i, j)] = true
		var spare: Array = []
		for key in tiles.keys():
			if not wanted.has(key):
				spare.append(tiles[key])
				tiles.erase(key)
		for key: Vector2i in wanted:
			if tiles.has(key):
				continue
			var mi: MultiMeshInstance3D = spare.pop_back() if not spare.is_empty() else null
			if mi == null:
				mi = MultiMeshInstance3D.new()
				mi.multimesh = layer.mm
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(mi)
			mi.position = Vector3(key.x * size, 0.0, key.y * size)
			mi.custom_aabb = _box(mi.position, size)
			mi.visible = _tile_grows(layer, key)
			tiles[key] = mi
		for mi in spare:
			mi.queue_free()


## Whether anything of the layer can grow in tile key: a biome it grows in
## reaching it (or near it), or for the marram a beach.
func _tile_grows(layer: Dictionary, key: Vector2i) -> bool:
	var live: Dictionary = layer.live
	if live.has(key):
		return live[key]
	if live.size() > 4096:
		live.clear()
	var size: float = layer.size
	var lo := Vector2(key) * size - Vector2(BITS_MARGIN, BITS_MARGIN)
	var hi := Vector2(key + Vector2i.ONE) * size + Vector2(BITS_MARGIN, BITS_MARGIN)
	var g0 := Vector2i(floori(lo.x / BITS_CELL), floori(lo.y / BITS_CELL))
	var g1 := Vector2i(ceili(hi.x / BITS_CELL), ceili(hi.y / BITS_CELL))
	var grows := false
	for gz in range(g0.y, g1.y + 1):
		for gx in range(g0.x, g1.x + 1):
			var g := Vector2i(gx, gz)
			if not _bits.has(g):
				if _bits.size() > 65536:
					_bits.clear()
					_low.clear()
				_bits[g] = world.biome_bits_at(gx * BITS_CELL, gz * BITS_CELL)
				_low[g] = world.base_height(gx * BITS_CELL, gz * BITS_CELL) < 12.0
			if (_bits[g] & layer.need) != 0 or (layer.beach and _low[g]):
				grows = true
				break
		if grows:
			break
	live[key] = grows
	return grows


## The logs and trunks within r of cam, nearest first (at most MAX_LOGS):
## found once out to the furthest any layer reaches, again only when the
## camera's gone a couple of metres or the logs have changed.
func _logs_near(cam: Vector3, r: float, xs: PackedVector4Array, rs: PackedFloat32Array) -> void:
	var changes := population.walk_changes
	if cam.distance_to(_logs_at) > 2.0 or changes != _logs_changes:
		_logs_at = cam
		_logs_changes = changes
		_logs_xs.clear()
		_logs_rs.clear()
		_logs_ds.clear()
		var far := 0.0
		for layer in _layers:
			far = maxf(far, layer.size * (layer.L.tiles / 2 + 1) * 1.42)
		population.walk_near(cam, far + 2.0, MAX_LOGS, _logs_xs, _logs_rs, _logs_ds)
	for i in _logs_xs.size():
		if _logs_ds[i] > r + 2.0:
			break
		xs.append(_logs_xs[i])
		rs.append(_logs_rs[i])


## Works out the layer's grid where it's wanted, in the viewport not shown;
## once drawn, shows it. (Until then the new tiles at the far edge, beyond
## the old grid, are empty.)
func _bake(layer: Dictionary) -> void:
	layer.baking = true
	while true:
		var origin: Vector2i = layer.want
		var cam: Vector3 = layer.cam
		layer.baked = cam
		layer.walks = population.walk_changes if population else 0
		var k: int = 1 - maxi(layer.shown, 0)
		var bm: ShaderMaterial = layer.bakes[k]
		var base_h := roundf(cam.y)
		bm.set_shader_parameter("grid_origin", origin)
		bm.set_shader_parameter("base_h", base_h)
		bm.set_shader_parameter("eye", cam)
		bm.set_shader_parameter("view_pos", cam)
		# the logs, stumps, trunks and boulders about, which nothing grows through
		var xs := PackedVector4Array()
		var rs := PackedFloat32Array()
		if population:
			_logs_near(cam, layer.size * (layer.L.tiles / 2 + 1) * 1.42, xs, rs)
		bm.set_shader_parameter("log_count", xs.size())
		xs.resize(MAX_LOGS)
		rs.resize(MAX_LOGS)
		bm.set_shader_parameter("logs", xs)
		bm.set_shader_parameter("log_r", rs)
		layer.vps[k].render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var m: ShaderMaterial = layer.material
		m.set_shader_parameter("data_tex", layer.vps[k].get_texture())
		m.set_shader_parameter("grid_origin", origin)
		m.set_shader_parameter("grid_size", layer.bakes[k].get_shader_parameter("grid_size"))
		m.set_shader_parameter("base_h", base_h)
		layer.shown = k
		if layer.want == origin and layer.cam == cam:
			break
	layer.baking = false


## A box round a tile: its ground's lowest to highest, and the tallest grass.
func _box(at: Vector3, size: float) -> AABB:
	var lo := INF
	var hi := -INF
	for i in 3:
		for j in 3:
			var h := world.height_at(at.x + size * i * 0.5, at.z + size * j * 0.5)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	var r := 4.0 + (hi - lo) * 0.3 # (the relief between the samples)
	return AABB(Vector3(-2.0, lo - r, -2.0), Vector3(size + 4.0, hi - lo + 2.0 * r + 3.0, size + 4.0))


## A clump of grass blades: each a tapering, curving strip, its middle line
## in units of the clump's height, its width (m) either side in CUSTOM0, its
## root's place in UV2.
static func grass_mesh(blades: int, segs: int, radius: float, width: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7 + 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	var base := 0
	var SEGS := segs
	for b in blades:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var root := Vector2(cos(a), sin(a)) * r
		var face := rng.randf() * TAU # which way the blade faces
		var lean_dir := Vector2(cos(a), sin(a)) if r > radius * 0.2 else Vector2(cos(face), sin(face))
		var lean := rng.randf_range(0.1, 0.45) # (outward, curving more toward the tip)
		var tall := rng.randf_range(0.6, 1.0)
		var w := width * rng.randf_range(0.7, 1.3)
		var side := Vector3(cos(face + PI * 0.5), 0.0, sin(face + PI * 0.5))
		var shade := rng.randf_range(0.85, 1.15)
		var blond := rng.randf()
		for s in SEGS + 1:
			var t := float(s) / SEGS
			var off := lean_dir * lean * t * t * tall
			var c := Vector3(off.x, tall * t * (1.0 - 0.25 * lean * t), off.y)
			var half := w * 0.5 * (1.0 - t * 0.85)
			var n := Vector3(lean_dir.x, 0.6, lean_dir.y).normalized()
			for k in 2:
				st.set_color(Color(shade, blond, t))
				st.set_uv(Vector2(float(k), t))
				st.set_uv2(root)
				st.set_normal(n)
				var e := side * (half if k == 1 else -half)
				st.set_custom(0, Color(e.x, e.y, e.z))
				st.add_vertex(c)
		for s in SEGS:
			var i := base + s * 2
			for q in [i, i + 1, i + 3, i, i + 3, i + 2]:
				st.add_index(q)
		base += (SEGS + 1) * 2
	return st.commit()


## A clump of cattails (bulrush, Typha): stalks, each with its brown head
## (a cylinder with rounded ends, solid: UV.x 2..3 marks it for the shader)
## a little below the top and a thin spike above, and a few long leaves
## round them; in units of the clump's height, as grass_mesh. COLOR.b is
## the height (not how far along each strip), so stalk, head and spike sway
## as one.
static func cattail_mesh(stalks: int, radius: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 13 + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	var base := [0]
	var strip := func(root: Vector2, pts: Array, halfs: Array, side: Vector3, n: Vector3, shade: float, u0: float) -> void:
		for s in pts.size():
			var t: float = (pts[s] as Vector3).y
			for k in 2:
				st.set_color(Color(shade, 0.3, t))
				st.set_uv(Vector2(u0 + float(k), t))
				st.set_uv2(root)
				st.set_normal(n)
				var e: Vector3 = side * (halfs[s] if k == 1 else -halfs[s])
				st.set_custom(0, Color(e.x, e.y, e.z))
				st.add_vertex(pts[s])
		for s in pts.size() - 1:
			var i: int = base[0] + s * 2
			for q in [i, i + 1, i + 3, i, i + 3, i + 2]:
				st.add_index(q)
		base[0] += pts.size() * 2
	for b in stalks:
		var a := rng.randf() * TAU
		var root := Vector2(cos(a), sin(a)) * sqrt(rng.randf()) * radius
		var tall := rng.randf_range(0.8, 1.0)
		var lean := Vector2(cos(a), sin(a)) * rng.randf_range(0.0, 0.06)
		var face := rng.randf() * TAU
		var side := Vector3(cos(face), 0.0, sin(face))
		var n := Vector3(-side.z, 0.3, side.x).normalized()
		var top := Vector3(lean.x, tall, lean.y)
		var head0 := top * 0.74
		var head1 := top * 0.9
		# the stalk, to the head: round, ~1.4 cm across at its foot
		_tube(st, base, root, [Vector3.ZERO, head0 * 0.5, head0], [0.0072 / 1.95, 0.0064 / 1.95, 0.006 / 1.95], rng.randf_range(0.85, 1.1))
		# the head: a cylinder, rounded at both ends, ~2.4 cm across (in
		# clump heights: the clumps are about 1.95 m)
		_capsule(st, base, root, head0, head1, 0.012 / 1.95, rng.randf_range(0.85, 1.1))
		# the spike above it
		strip.call(root, [head1, top], [0.003, 0.0015], side, n, 1.0, 0.0)
		# leaves: long, flat, arching a little
		for l in rng.randi_range(2, 3):
			var la := rng.randf() * TAU
			var dir := Vector2(cos(la), sin(la))
			var lt := rng.randf_range(0.7, 0.95) * tall
			var lside := Vector3(-dir.y, 0.0, dir.x)
			var pts := []
			var halfs := []
			for s in 5:
				var t := s / 4.0
				var off := dir * 0.12 * t * t
				pts.append(Vector3(off.x, lt * t, off.y))
				halfs.append(0.009 * (1.0 - t * 0.8))
			strip.call(root, pts, halfs, lside, Vector3(dir.x, 0.6, dir.y).normalized(), rng.randf_range(0.85, 1.15), 0.0)
	return st.commit()


## A clump of wildflowers ("susan": black-eyed Susans; "fleabane"), in
## units of the clump's height, as grass_mesh: stems (strips, coloured as
## grass, CUSTOM0 their half width in m), a leaf or two low down, and the
## heads, solid: ray florets (UV.x 3..4, UV.y from their base out to their
## tip) round a disc (UV.x 4..5); COLOR.b the height, so a head sways with
## its stem's top; COLOR.g per stem (ground_cover.gdshader: the odd one's
## other petal colour). Susans: a head a stem, 6-7 cm across, thirteen
## golden rays drooping a little round a dark brown dome. Fleabane: a stem
## branching near its top into a few small heads, 2 cm across, a fringe
## of fine rays, white to light purple, round a yellow disc.
static func flower_mesh(kind: String, stems: int, radius: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 17 + 3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	var base := [0]
	const H := 1.5 # m: about a clump's height (the heads' sizes in it)
	var vert := func(root: Vector2, p: Vector3, n: Vector3, uv: Vector2, col: Color, e := Vector3.ZERO) -> void:
		st.set_color(col)
		st.set_uv(uv)
		st.set_uv2(root)
		st.set_normal(n)
		st.set_custom(0, Color(e.x, e.y, e.z))
		st.add_vertex(p)
	# a strip (a stem, a leaf) through pts, half widths halfs (m)
	var strip := func(root: Vector2, pts: Array, halfs: Array, side: Vector3, n: Vector3, shade: float, g: float) -> void:
		for s in pts.size():
			var t: float = (pts[s] as Vector3).y
			for k in 2:
				vert.call(root, pts[s], n, Vector2(float(k), t), Color(shade, g, t), side * (halfs[s] if k == 1 else -halfs[s]))
		for s in pts.size() - 1:
			var i: int = base[0] + s * 2
			for q in [i, i + 1, i + 3, i, i + 3, i + 2]:
				st.add_index(q)
		base[0] += pts.size() * 2
	# a head at c, facing up (tipped a little by tilt): rays from r_in to
	# r_out (m), drooping by droop at their tips; a disc of radius r_in,
	# raised by dome
	var head := func(root: Vector2, c: Vector3, tilt: Vector3, rays: int, r_in: float, r_out: float, ray_w: float, droop: float, dome: float, g: float) -> void:
		var up := (Vector3.UP + tilt).normalized()
		var u := up.cross(Vector3.FORWARD).normalized()
		var v := up.cross(u)
		var col := Color(rng.randf_range(0.9, 1.1), g, c.y)
		var turn := rng.randf() * TAU
		for i in rays:
			var a := turn + TAU * (i + rng.randf_range(-0.15, 0.15)) / rays
			var out := u * cos(a) + v * sin(a)
			var side := (u * -sin(a) + v * cos(a)) * (ray_w * 0.5 / H)
			var p0 := c + out * (r_in * 0.8 / H)
			var p1 := c + out * (r_out / H) - up * (droop / H)
			var n := up
			var b: int = base[0]
			vert.call(root, p0 - side * 0.6, n, Vector2(3.25, 0.0), col)
			vert.call(root, p0 + side * 0.6, n, Vector2(3.25, 0.0), col)
			vert.call(root, p1 - side, n, Vector2(3.25, 1.0), col)
			vert.call(root, p1 + side, n, Vector2(3.25, 1.0), col)
			for q in [b, b + 1, b + 3, b, b + 3, b + 2]:
				st.add_index(q)
			base[0] += 4
		const RIM := 6
		var b0: int = base[0]
		vert.call(root, c + up * (dome / H), up, Vector2(4.5, 0.0), col)
		for i in RIM:
			var a := TAU * i / RIM
			var out := u * cos(a) + v * sin(a)
			vert.call(root, c + out * (r_in / H), (out + up).normalized(), Vector2(4.5, 1.0), col)
		for i in RIM:
			st.add_index(b0)
			st.add_index(b0 + 1 + i)
			st.add_index(b0 + 1 + (i + 1) % RIM)
		base[0] += RIM + 1
	for b in stems:
		var a := rng.randf() * TAU
		var root := Vector2(cos(a), sin(a)) * sqrt(rng.randf()) * radius
		var tall := rng.randf_range(0.8, 1.0)
		var lean := Vector2(cos(a), sin(a)) * rng.randf_range(0.0, 0.05)
		var face := rng.randf() * TAU
		var side := Vector3(cos(face), 0.0, sin(face))
		var n := Vector3(-side.z, 0.4, side.x).normalized()
		var g := rng.randf()
		var shade := rng.randf_range(0.85, 1.1)
		var top := Vector3(lean.x, tall, lean.y)
		# a leaf low down
		var la := rng.randf() * TAU
		var dir := Vector2(cos(la), sin(la))
		var lt := rng.randf_range(0.15, 0.3)
		strip.call(root, [Vector3(0.0, lt * 0.5, 0.0), Vector3(dir.x * 0.05, lt, dir.y * 0.05), Vector3(dir.x * 0.1, lt * 1.15, dir.y * 0.1)],
				[0.004, 0.009, 0.001], Vector3(-dir.y, 0.0, dir.x), Vector3(dir.x, 0.6, dir.y).normalized(), shade, 0.0)
		if kind == "susan":
			strip.call(root, [Vector3.ZERO, top * 0.5 + Vector3(lean.x, 0.0, lean.y) * 0.3, top], [0.0035, 0.003, 0.0022], side, n, shade, 0.0)
			head.call(root, top, Vector3(lean.x, 0.0, lean.y) * 2.0 + Vector3(rng.randf_range(-0.2, 0.2), 0.0, rng.randf_range(-0.2, 0.2)),
					13, 0.009, 0.034, 0.008, 0.012, 0.011, g)
		else:
			var fork := top * 0.82
			strip.call(root, [Vector3.ZERO, fork * 0.5, fork], [0.0055, 0.005, 0.0042], side, n, shade, 0.0)
			var heads := rng.randi_range(2, 3)
			for h in heads:
				var ha := rng.randf() * TAU
				var reach := rng.randf_range(0.02, 0.06)
				var c := fork + Vector3(cos(ha) * reach, rng.randf_range(0.08, 0.18) * tall, sin(ha) * reach)
				strip.call(root, [fork, c], [0.0035, 0.003], side, n, shade, 0.0)
				# (a fringe of fine rays, each its own colour: rng.randf())
				head.call(root, c, Vector3(cos(ha), 0.0, sin(ha)) * 0.3, 16, 0.0035, 0.0115, 0.0024, 0.0012, 0.0015, rng.randf())
	return st.commit()


## A round stalk through pts (radii r, in clump heights) into st: rings of
## six round it; solid (CUSTOM0 zero), UV.x 1.25 (lit as round, coloured as
## a blade: ground_cover.gdshader).
static func _tube(st: SurfaceTool, base: Array, root: Vector2, pts: Array, r: Array, shade: float) -> void:
	const SIDES := 6
	for s in pts.size():
		var p: Vector3 = pts[s]
		var axis: Vector3 = ((pts[mini(s + 1, pts.size() - 1)] as Vector3) - (pts[maxi(s - 1, 0)] as Vector3)).normalized()
		var u := axis.cross(Vector3.RIGHT if absf(axis.x) < 0.9 else Vector3.FORWARD).normalized()
		var v := axis.cross(u)
		for i in SIDES:
			var ang := TAU * i / SIDES
			var out := u * cos(ang) + v * sin(ang)
			st.set_color(Color(shade, 0.3, p.y))
			st.set_uv(Vector2(1.25, p.y))
			st.set_uv2(root)
			st.set_normal(out)
			st.set_custom(0, Color(0, 0, 0))
			st.add_vertex(p + out * float(r[s]))
	for s in pts.size() - 1:
		for i in SIDES:
			var i0: int = base[0] + s * SIDES + i
			var i1: int = base[0] + s * SIDES + (i + 1) % SIDES
			for q in [i0, i1 + SIDES, i1, i0, i0 + SIDES, i1 + SIDES]:
				st.add_index(q)
	base[0] += pts.size() * SIDES


## A capsule from a to b (radius r) into st: rings round the axis, the ends
## hemispheres; solid (CUSTOM0 zero), UV.x 2.5 (a cattail's head).
static func _capsule(st: SurfaceTool, base: Array, root: Vector2, a: Vector3, b: Vector3, r: float, shade: float) -> void:
	const SIDES := 8
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.RIGHT if absf(axis.x) < 0.9 else Vector3.FORWARD).normalized()
	var v := axis.cross(u)
	var rings := [] # [centre of its sphere or the axis point, along (m), ring radius]
	for k in 4: # the bottom end, pole up to the equator
		var th := PI * 0.5 * k / 3.0
		rings.append([a, a - axis * r * cos(th), r * sin(th)])
	for k in 4: # the top end, equator up to the pole
		var th := PI * 0.5 * (3 - k) / 3.0
		rings.append([b, b + axis * r * cos(th), r * sin(th)])
	for ring in rings:
		for i in SIDES:
			var ang := TAU * i / SIDES
			var out := u * cos(ang) + v * sin(ang)
			var p: Vector3 = ring[1] + out * float(ring[2])
			var nrm := (p - (ring[0] as Vector3)).normalized() if p.distance_to(ring[0]) > 1e-6 else out
			st.set_color(Color(shade, 0.3, p.y))
			st.set_uv(Vector2(2.5, 0.0))
			st.set_uv2(root)
			st.set_normal(nrm)
			st.set_custom(0, Color(0, 0, 0))
			st.add_vertex(p)
	for k in rings.size() - 1:
		for i in SIDES:
			var i0: int = base[0] + k * SIDES + i
			var i1: int = base[0] + k * SIDES + (i + 1) % SIDES
			for q in [i0, i1, i1 + SIDES, i0, i1 + SIDES, i0 + SIDES]:
				st.add_index(q)
	base[0] += rings.size() * SIDES


## A fern: fronds arching out and down from the middle, each a bent strip
## carrying fern_frond.png, in units of the frond's length.
static func fern_mesh(fronds: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	var base := 0
	const SEGS := 4
	for f in fronds:
		var a := TAU * (f + rng.randf_range(-0.3, 0.3)) / fronds
		var dir := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-dir.z, 0.0, dir.x)
		var rise := rng.randf_range(1.8, 3.2) # how steeply it sets off
		var length := rng.randf_range(0.8, 1.0)
		var shade := rng.randf_range(0.62, 0.85) # (deep green, toward the ground's olive)
		var p := Vector3.ZERO
		var heading := Vector2(1.0, rise).normalized() # (out, up)
		var pts: Array[Vector3] = []
		for s in SEGS + 1:
			pts.append(p)
			heading = heading.rotated(-0.75 / SEGS) # arching over
			var step := heading * length / SEGS
			p += dir * step.x + Vector3.UP * step.y
		for s in SEGS + 1:
			var t := float(s) / SEGS
			var along := (pts[mini(s + 1, SEGS)] - pts[maxi(s - 1, 0)]).normalized()
			var n := side.cross(along).normalized()
			if n.y < 0.0:
				n = -n
			var tilt := side.rotated(along, 0.25) # (the frond's blade tipped a little)
			for k in 2:
				st.set_color(Color(shade, 0.0, t))
				st.set_uv(Vector2(float(k), 1.0 - t))
				st.set_uv2(Vector2.ZERO)
				st.set_custom(0, Color(0, 0, 0))
				st.set_normal(n)
				st.add_vertex(pts[s] + tilt * length * 0.13 * (1.0 if k == 1 else -1.0))
		for s in SEGS:
			var i := base + s * 2
			for q in [i, i + 1, i + 3, i, i + 3, i + 2]:
				st.add_index(q)
		base += (SEGS + 1) * 2
	return st.commit()


static func _mean(t: Texture2D) -> Vector3:
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	img = img.duplicate()
	img.clear_mipmaps()
	img.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	var c := img.get_pixel(0, 0)
	return Vector3(c.r, c.g, c.b)


## The mean of a frond texture's covered pixels, linear.
static func _mean_linear(t: Texture2D) -> Vector3:
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	var sum := Vector3.ZERO
	var n := 0.0
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				var l := c.srgb_to_linear()
				sum += Vector3(l.r, l.g, l.b)
				n += 1.0
	return sum / maxf(n, 1.0)
