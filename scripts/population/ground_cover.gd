class_name GroundCover
extends Node3D
## Grass and ferns: too many to place one by one (Population), so a grid of
## cells follows the camera and the shader (ground_cover.gdshader) works out
## what grows in each from where the cell is: the same clump in the same
## place every time, nothing stored.
##
## Layers, each a MultiMesh of one cell per instance, shared by a square of
## tiles round the camera (a tile is a MultiMeshInstance3D, so Godot culls
## the ones out of view; as the camera moves, the tiles left behind jump
## ahead):
## - grass, near: short blades in the forest (the ground's colour, a little
##   lighter at the tips), longer in the prairie (green to blonde); thinning
##   from 12 m, gone by 45 m in the forest;
## - grass, far: the prairie's only, bigger clumps, from 35 m to 130 m;
## - ferns: the forest's, in drifts, short; gone by 50 m.
## The forest's brown patches are leaf litter: a texture on the terrain
## (terrain.gdshader), not geometry.

const LAYERS := [
	# name, mesh, cell (m), cells a tile side, tiles a side, uniforms
	{"name": "grass", "cell": 0.4, "cells": 32, "tiles": 7, "blades": 14, "radius": 0.2, "width": 0.02,
		"u": {"kind": 0, "seed": 1, "forest_height": Vector2(0.07, 0.15), "prairie_height": Vector2(0.4, 0.8),
			"fade_out": Vector2(30.0, 42.0), "thin_from": 12.0}},
	{"name": "prairie_far", "cell": 1.2, "cells": 24, "tiles": 9, "blades": 12, "radius": 0.45, "width": 0.04,
		"u": {"kind": 0, "seed": 2, "in_forest": false, "prairie_height": Vector2(0.45, 0.8),
			"fade_in": Vector2(32.0, 42.0), "fade_out": Vector2(100.0, 130.0), "thin_from": 60.0}},
	{"name": "fern", "cell": 1.1, "cells": 20, "tiles": 5, "fronds": 9,
		"u": {"kind": 1, "seed": 3, "in_prairie": false, "forest_height": Vector2(0.55, 0.95),
			"fade_out": Vector2(36.0, 50.0), "thin_from": 18.0, "cover": 0.9}},
]

var world: WorldData
var materials: Array[ShaderMaterial] = []
var _layers: Array = [] # [layer, multimesh, tile size, {Vector2i: MultiMeshInstance3D}, centre]


func setup(w: WorldData) -> void:
	world = w
	var frond := load("res://data/population/textures/fern_frond.png") as Texture2D
	for L in LAYERS:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/ground_cover.gdshader")
		m.set_shader_parameter("height_tex", world.height_tex)
		m.set_shader_parameter("map_size", float(world.size))
		m.set_shader_parameter("map_domain", world.domain)
		m.set_shader_parameter("map_origin", world.origin)
		m.set_shader_parameter("mask_tex", world.mask_tex)
		if world.biome_tex:
			m.set_shader_parameter("biome_tex", world.biome_tex)
			m.set_shader_parameter("swamp_biome", world.biome_names.find("swamp"))
		m.set_shader_parameter("cell", L.cell)
		if L.u.kind == 1:
			m.set_shader_parameter("frond_tex", OakTree._texture("res://data/population/textures/fern_frond.png"))
			m.set_shader_parameter("frond_mean", _mean_linear(frond))
		for k in L.u:
			m.set_shader_parameter(k, L.u[k])
		materials.append(m)
		var mesh: Mesh = fern_mesh(L.fronds) if L.u.kind == 1 else grass_mesh(L.blades, L.radius, L.width, L.u.seed)
		mesh.surface_set_material(0, m)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = L.cells * L.cells
		for i in L.cells:
			for j in L.cells:
				mm.set_instance_transform(i * L.cells + j, Transform3D(Basis(), Vector3(i * L.cell, 0.0, j * L.cell)))
		_layers.append([L, mm, L.cell * L.cells, {}, Vector2i.MAX])


## The terrain's leaf litter texture (it's the terrain's material).
static func setup_terrain(terrain: ShaderMaterial) -> void:
	var t := OakTree._texture("res://data/population/textures/leaf_litter.png")
	terrain.set_shader_parameter("litter_tex", t)
	terrain.set_shader_parameter("litter_mean", _mean(t))


## Moves the tiles to keep round the camera. Call every frame.
func update(cam: Vector3) -> void:
	for m in materials:
		m.set_shader_parameter("view_pos", cam)
	for layer in _layers:
		var L: Dictionary = layer[0]
		var size: float = layer[2]
		var tiles: Dictionary = layer[3]
		var centre := Vector2i(floori(cam.x / size), floori(cam.z / size))
		if centre == layer[4]:
			continue
		layer[4] = centre
		var half: int = L.tiles / 2
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
				mi.multimesh = layer[1]
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(mi)
			mi.position = Vector3(key.x * size, 0.0, key.y * size)
			mi.custom_aabb = _box(mi.position, size)
			tiles[key] = mi
		for mi in spare:
			mi.queue_free()


## A box round a tile: its ground's lowest to highest, and a metre of grass.
func _box(at: Vector3, size: float) -> AABB:
	var lo := INF
	var hi := -INF
	for i in 3:
		for j in 3:
			var h := world.height_at(at.x + size * i * 0.5, at.z + size * j * 0.5)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	var r := 4.0 + (hi - lo) * 0.3 # (the relief between the samples)
	return AABB(Vector3(-1.0, lo - r, -1.0), Vector3(size + 2.0, hi - lo + 2.0 * r + 1.5, size + 2.0))


## A clump of grass blades: each a tapering, curving strip, its middle line
## in units of the clump's height, its width (m) either side in CUSTOM0, its
## root's place in UV2.
static func grass_mesh(blades: int, radius: float, width: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7 + 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	var base := 0
	const SEGS := 3
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
				st.set_color(Color(shade, blond, 0.0))
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
	const SEGS := 6
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
				st.set_color(Color(shade, 0.0, 0.0))
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
