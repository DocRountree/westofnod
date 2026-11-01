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
## texture, which the drawing shader (ground_cover.gdshader) reads: each
## vertex reads two texels instead of working the terrain out again. Two
## viewports take turns, so the shader switches to a new grid only once
## it's ready.
##
## Layers:
## - grass, near (to 21 m): dense; short in the forest (the ground's colour,
##   a little lighter at the tips), about head-high on the prairie (green
##   to blonde);
## - grass, middle (15-52 m): bigger, fewer clumps of the same;
## - grass, far (42-125 m): the prairie's only;
## - ferns: the forest's, in drifts, knee-high; to 45 m.
## The forest's brown patches are leaf litter: a texture on the terrain
## (terrain.gdshader), not geometry.

const LAYERS := [
	# cell (m), cells a tile side, tiles a side (odd), the mesh, uniforms
	{"cell": 0.25, "cells": 24, "tiles": 9, "blades": 10, "segs": 3, "radius": 0.16, "width": 0.016,
		"u": {"kind": 0, "seed": 1, "forest_height": Vector2(0.07, 0.16), "prairie_height": Vector2(1.7, 2.2),
			"fade_out": Vector2(15.0, 21.0), "thin_from": 1000.0}},
	{"cell": 0.55, "cells": 24, "tiles": 9, "blades": 14, "segs": 2, "radius": 0.32, "width": 0.024,
		"u": {"kind": 0, "seed": 2, "forest_height": Vector2(0.07, 0.16), "prairie_height": Vector2(1.7, 2.2),
			"fade_in": Vector2(15.0, 21.0), "fade_out": Vector2(40.0, 52.0), "thin_from": 28.0}},
	{"cell": 1.3, "cells": 20, "tiles": 11, "blades": 14, "segs": 2, "radius": 0.6, "width": 0.05,
		"u": {"kind": 0, "seed": 3, "in_forest": false, "prairie_height": Vector2(1.7, 2.2),
			"fade_in": Vector2(42.0, 52.0), "fade_out": Vector2(100.0, 125.0), "thin_from": 80.0}},
	{"cell": 0.5, "cells": 24, "tiles": 9, "fronds": 8,
		"u": {"kind": 1, "seed": 4, "in_prairie": false, "forest_height": Vector2(0.25, 0.45),
			"fade_out": Vector2(32.0, 45.0), "thin_from": 16.0}},
]
const BAKE_KEYS := ["kind", "seed", "in_forest", "in_prairie", "forest_height", "prairie_height", "cover"]
const DRAW_KEYS := ["kind", "seed", "fade_in", "fade_out", "thin_from"]

var world: WorldData
var materials: Array[ShaderMaterial] = []
var _layers: Array[Dictionary] = []


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
		var mesh: Mesh = fern_mesh(L.fronds) if L.u.kind == 1 else grass_mesh(L.blades, L.segs, L.radius, L.width, L.u.seed)
		mesh.surface_set_material(0, m)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = L.cells * L.cells
		for i in L.cells:
			for j in L.cells:
				mm.set_instance_transform(i * L.cells + j, Transform3D(Basis(), Vector3(i * L.cell, 0.0, j * L.cell)))
		_layers.append({"L": L, "mm": mm, "size": L.cell * L.cells, "tiles": {}, "centre": Vector2i.MAX,
				"material": m, "vps": vps, "bakes": bakes, "shown": -1, "baking": false, "want": Vector2i.MAX, "cam": Vector3.ZERO})


## The terrain's leaf litter texture (it's the terrain's material).
static func setup_terrain(terrain: ShaderMaterial) -> void:
	var t := OakTree._texture("res://data/population/textures/leaf_litter.png")
	terrain.set_shader_parameter("litter_tex", t)
	terrain.set_shader_parameter("litter_mean", _mean(t))


## Moves the tiles to keep round the camera. Call every frame.
func update(cam: Vector3) -> void:
	for layer in _layers:
		var L: Dictionary = layer.L
		var size: float = layer.size
		var tiles: Dictionary = layer.tiles
		var centre := Vector2i(floori(cam.x / size), floori(cam.z / size))
		if centre == layer.centre:
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
			tiles[key] = mi
		for mi in spare:
			mi.queue_free()


## Works out the layer's grid where it's wanted, in the viewport not shown;
## once drawn, shows it. (Until then the new tiles at the far edge, beyond
## the old grid, are empty.)
func _bake(layer: Dictionary) -> void:
	layer.baking = true
	while true:
		var origin: Vector2i = layer.want
		var cam: Vector3 = layer.cam
		var k: int = 1 - maxi(layer.shown, 0)
		var bm: ShaderMaterial = layer.bakes[k]
		var base_h := roundf(cam.y)
		bm.set_shader_parameter("grid_origin", origin)
		bm.set_shader_parameter("base_h", base_h)
		bm.set_shader_parameter("eye", cam)
		bm.set_shader_parameter("view_pos", cam)
		layer.vps[k].render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var m: ShaderMaterial = layer.material
		m.set_shader_parameter("data_tex", layer.vps[k].get_texture())
		m.set_shader_parameter("grid_origin", origin)
		m.set_shader_parameter("grid_size", layer.bakes[k].get_shader_parameter("grid_size"))
		m.set_shader_parameter("base_h", base_h)
		layer.shown = k
		if layer.want == origin:
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
