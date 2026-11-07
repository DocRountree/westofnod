class_name GroundCover
extends Node3D
const SettingsScript := preload("res://scripts/settings.gd") # (by path: found whether or not the editor has seen its class yet)
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
## - the prairie's grass, near (to 17 m): dense, about head-high (green to
##   blonde); short where it gives way to the forest;
## - its middle (12-52 m): bigger, fewer clumps of the same (fewer, wider
##   blades);
## - its far (42-125 m): fewer blades still, straight;
## - the forest's grass: short (the ground's colour, a little lighter at
##   the tips), a few straight blades a clump, to 22 m;
## - reeds: the swamp's, 1.8-2.3 m, broad-bladed, in clumps here and there
##   (sparse patches, in the water too); to 72 m;
## - cattails among them: stalks with brown heads, a few leaves; to 66 m;
## - marram: the coast's and the beaches', half the prairie grass's height,
##   as pale as the sand (a fifth of the patches a tad greener, a fifth a tad
##   yellower), in patches: none at the water's edge, thicker and
##   taller up the beach; near (to 25 m) and middle (18-62 m);
## - ferns: the forest's, in drifts, knee-high; to 45 m.
## - black-eyed Susans (Rudbeckia hirta), fleabane (Erigeron annuus) and
##   purple coneflowers (Echinacea purpurea): the prairie's wildflowers
##   among its grass, in drifts, their heads up
## - yampah (Perideridia gairdneri): white umbels, on the prairie and in
##   the forest, knee-high there
## - swamp asters (Symphyotrichum puniceum): the swamp's, sparse
##   among the grass's tips (taller than they'd be, the grass being head-high);
##   to 38 m and 34 m.
## - common milkweed (Asclepias syriaca): the prairie's, in loose colonies,
##   a stout stem, broad leaves in pairs, drooping balls of mauve-pink
##   flowers; swamp milkweed (Asclepias incarnata): the swamp's, sparse,
##   branched, narrow leaves, flat clusters of deep pink flowers. To 28 m,
##   on a 3 m grid (their clumps' flowers many).
## The forest's brown patches are leaf litter: a texture on the terrain
## (terrain.gdshader), not geometry.
##
## A tile where its layer can't grow anything (no biome it grows in reaches
## it, as the ground blends them: WorldData.biome_bits_at; the marram, no
## beach either) isn't drawn at all: the reeds' tiles on the prairie, the
## ferns' out of the forest. Nor is an empty cell: each bake is read back
## and every tile given only its cells with a clump (out of range, or
## thinned away, counting as empty), and the tiles further off a simpler
## mesh (a layer's lods). Only the ferns' shader throws pixels away
## (ground_cover_draw.gdshaderinc): the rest come and go by growing and
## shrinking.

const LAYERS := [
	# cell (m), cells a tile side, tiles a side (odd), the mesh, uniforms
	# the prairie's grass (the forest's is its own, short and cheap, below);
	# lods: [from (m, the tile's nearest), blades, segments, width x],
	# simpler meshes for the tiles further off (the same blades, the first
	# so many of them, in fewer segments)
	{"cell": 0.25, "cells": 24, "tiles": 7, "blades": 10, "segs": 3, "radius": 0.16, "width": 0.016,
		"lods": [[6.0, 10, 2, 1.0], [11.0, 8, 2, 1.15]],
		"u": {"kind": 0, "seed": 1, "in_forest": false, "forest_height": Vector2(0.07, 0.16), "prairie_height": Vector2(1.5, 2.0),
			"fade_out": Vector2(12.0, 17.0), "thin_from": 1000.0}},
	{"cell": 0.55, "cells": 24, "tiles": 9, "blades": 11, "segs": 2, "radius": 0.32, "width": 0.027,
		"lods": [[26.0, 8, 1, 1.3]],
		"u": {"kind": 0, "seed": 2, "in_forest": false, "forest_height": Vector2(0.07, 0.16), "prairie_height": Vector2(1.5, 2.0),
			"fade_in": Vector2(12.0, 17.0), "fade_out": Vector2(40.0, 52.0), "thin_from": 28.0}},
	{"cell": 1.3, "cells": 20, "tiles": 11, "blades": 9, "segs": 1, "radius": 0.6, "width": 0.065,
		"u": {"kind": 0, "seed": 3, "in_forest": false, "prairie_height": Vector2(1.5, 2.0),
			"fade_in": Vector2(42.0, 52.0), "fade_out": Vector2(100.0, 125.0), "thin_from": 80.0}},
	# the forest's grass: short (7-16 cm), so a few straight blades a clump,
	# and only near: further off it's no more than the ground's colour
	{"cell": 0.25, "cells": 24, "tiles": 7, "blades": 5, "segs": 1, "radius": 0.16, "width": 0.02,
		"u": {"kind": 0, "seed": 17, "in_prairie": false, "trodden": true, "forest_height": Vector2(0.07, 0.16),
			"fade_out": Vector2(16.0, 22.0), "thin_from": 12.0}},
	{"cell": 1.0, "cells": 16, "tiles": 9, "blades": 11, "segs": 4, "radius": 0.4, "width": 0.068,
		"lods": [[22.0, 11, 2, 1.0], [42.0, 8, 1, 1.25]],
		"u": {"kind": 0, "seed": 5, "in_forest": false, "in_prairie": false, "in_swamp": true, "prairie_height": Vector2(1.8, 2.3),
			"prairie_green": Vector3(0.22, 0.33, 0.12), "prairie_blonde": Vector3(0.5, 0.45, 0.28),
			"fade_out": Vector2(55.0, 72.0), "thin_from": 40.0}},
	{"cell": 1.6, "cells": 12, "tiles": 7, "cattails": 4, "radius": 0.35,
		"u": {"kind": 0, "seed": 6, "in_forest": false, "in_prairie": false, "in_swamp": true, "cover": 0.45,
			"prairie_height": Vector2(1.7, 2.2), "prairie_green": Vector3(0.24, 0.33, 0.13), "prairie_blonde": Vector3(0.45, 0.42, 0.26),
			"fade_out": Vector2(50.0, 66.0), "thin_from": 40.0}},
	# marram, along the coast: half the prairie grass's height, as pale as the sand
	{"cell": 0.3, "cells": 24, "tiles": 9, "blades": 12, "segs": 3, "radius": 0.2, "width": 0.018,
		"lods": [[10.0, 12, 2, 1.0]],
		"u": {"kind": 0, "seed": 7, "in_forest": false, "in_prairie": false, "in_coast": true, "prairie_height": Vector2(0.75, 1.0),
			"prairie_green": Vector3(0.76, 0.74, 0.58), "prairie_blonde": Vector3(0.88, 0.84, 0.69), "patch_tints": Vector2(0.2, 0.2),
			"fade_out": Vector2(18.0, 25.0), "thin_from": 1000.0}},
	{"cell": 0.7, "cells": 20, "tiles": 9, "blades": 14, "segs": 2, "radius": 0.38, "width": 0.028,
		"lods": [[32.0, 10, 1, 1.2]],
		"u": {"kind": 0, "seed": 8, "in_forest": false, "in_prairie": false, "in_coast": true, "prairie_height": Vector2(0.75, 1.0),
			"prairie_green": Vector3(0.76, 0.74, 0.58), "prairie_blonde": Vector3(0.88, 0.84, 0.69), "patch_tints": Vector2(0.2, 0.2),
			"fade_in": Vector2(18.0, 25.0), "fade_out": Vector2(48.0, 62.0), "thin_from": 32.0}},
	# the prairie's flowers: black-eyed Susans in drifts, fleabane scattered more widely
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "susan", "stems": 4, "radius": 0.22,
		"u": {"kind": 2, "seed": 9, "in_forest": false, "cover": 0.85, "drift": Vector3(26.0, 0.7, 3.1),
			"forest_height": Vector2(0.35, 0.55), "prairie_height": Vector2(1.25, 1.7), # (low where the prairie gives way, as its grass)
			"prairie_green": Vector3(0.26, 0.36, 0.12), "prairie_blonde": Vector3(0.36, 0.4, 0.16),
			"petal_color": Vector3(0.96, 0.71, 0.06), "petal_base": Vector3(0.9, 0.47, 0.05), "petal_alt": Vector3(0.97, 0.6, 0.05), "petal_alt_share": 0.3,
			"disc_color": Vector3(0.17, 0.08, 0.04), "head_size": 0.07, "head_px": Vector2(3.0, 6.0),
			"fade_out": Vector2(28.0, 38.0), "thin_from": 22.0}},
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "fleabane", "stems": 4, "radius": 0.2,
		"u": {"kind": 2, "seed": 10, "in_forest": false, "cover": 0.7, "drift": Vector3(15.0, 0.6, -7.7),
			"forest_height": Vector2(0.3, 0.5), "prairie_height": Vector2(1.2, 1.5),
			"prairie_green": Vector3(0.28, 0.38, 0.14), "prairie_blonde": Vector3(0.38, 0.42, 0.18),
			"petal_color": Vector3(0.97, 0.96, 0.95), "petal_base": Vector3(0.97, 0.96, 0.95), "petal_alt": Vector3(0.8, 0.7, 0.94), "petal_mix": 1.6,
			"disc_color": Vector3(0.95, 0.78, 0.12), "head_size": 0.025, "head_px": Vector2(3.0, 6.0),
			"fade_out": Vector2(24.0, 34.0), "thin_from": 20.0}},
	# purple coneflowers, in a few drifts of their own
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "coneflower", "stems": 3, "radius": 0.2,
		"u": {"kind": 2, "seed": 11, "in_forest": false, "cover": 0.6, "drift": Vector3(22.0, 0.35, 9.3),
			"forest_height": Vector2(0.35, 0.55), "prairie_height": Vector2(1.2, 1.6),
			"prairie_green": Vector3(0.25, 0.34, 0.12), "prairie_blonde": Vector3(0.35, 0.38, 0.16),
			"petal_color": Vector3(0.78, 0.42, 0.62), "petal_base": Vector3(0.62, 0.22, 0.42), "petal_alt": Vector3(0.86, 0.6, 0.76), "petal_alt_share": 0.25,
			"disc_color": Vector3(0.42, 0.2, 0.06), "head_size": 0.09, "head_px": Vector2(3.0, 6.0),
			"fade_out": Vector2(28.0, 38.0), "thin_from": 22.0}},
	# yampah, in the prairie and in the forest's clearings: white umbels
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "yampah", "stems": 3, "radius": 0.2,
		"u": {"kind": 2, "seed": 13, "cover": 0.55, "drift": Vector3(20.0, 0.4, 5.9),
			"forest_height": Vector2(0.45, 0.75), "prairie_height": Vector2(1.05, 1.35),
			"prairie_green": Vector3(0.27, 0.37, 0.14), "prairie_blonde": Vector3(0.36, 0.4, 0.17),
			"petal_color": Vector3(0.97, 0.97, 0.94), "petal_base": Vector3(0.92, 0.93, 0.84), "petal_alt": Vector3(0.94, 0.95, 0.88), "petal_alt_share": 0.3,
			"disc_color": Vector3(0.9, 0.9, 0.78), "head_size": 0.011, "head_px": Vector2(4.0, 9.0), # (its tiny flowers green, as the stems, well before they're too small to draw: they shimmered)
			"fade_out": Vector2(10.0, 15.0), "thin_from": 8.0}}, # (only near: its tiny flowers shimmered further off)
	# the swamp's: swamp asters, sparse, here and there in loose drifts
	{"cell": 2.0, "cells": 12, "tiles": 7, "flowers": "aster", "stems": 2, "radius": 0.25,
		"u": {"kind": 2, "seed": 12, "in_forest": false, "in_prairie": false, "in_swamp": true, "swamp_clumped": false, "cover": 0.35,
			"drift": Vector3(18.0, 0.35, -4.6), "prairie_height": Vector2(0.8, 1.3),
			"prairie_green": Vector3(0.22, 0.33, 0.12), "prairie_blonde": Vector3(0.3, 0.36, 0.14),
			"petal_color": Vector3(0.6, 0.45, 0.85), "petal_base": Vector3(0.52, 0.36, 0.8), "petal_alt": Vector3(0.78, 0.68, 0.94), "petal_mix": 1.2,
			"disc_color": Vector3(0.93, 0.72, 0.12), "head_size": 0.03, "head_px": Vector2(3.0, 6.0),
			"fade_out": Vector2(26.0, 36.0), "thin_from": 20.0}},
	# common milkweed (Asclepias syriaca): the prairie's, in loose colonies
	# here and there; a stout stem, broad leaves in pairs, drooping balls of
	# small mauve-pink flowers. On a coarser grid (3 m cells): a clump's
	# flowers are many
	{"cell": 3.0, "cells": 8, "tiles": 5, "flowers": "milkweed", "stems": 1, "radius": 0.15,
		"u": {"kind": 2, "seed": 14, "in_forest": false, "cover": 0.5, "drift": Vector3(18.0, 0.3, 12.7),
			"forest_height": Vector2(0.6, 0.9), "prairie_height": Vector2(1.1, 1.5),
			"prairie_green": Vector3(0.3, 0.4, 0.22), "prairie_blonde": Vector3(0.36, 0.42, 0.24), # (blue-grey green)
			"petal_color": Vector3(0.86, 0.56, 0.66), "petal_base": Vector3(0.74, 0.42, 0.52), "petal_alt": Vector3(0.9, 0.68, 0.74), "petal_alt_share": 0.3,
			"disc_color": Vector3(0.93, 0.78, 0.82), "head_size": 0.05, "head_px": Vector2(2.0, 5.0),
			"fade_out": Vector2(20.0, 28.0), "thin_from": 16.0}},
	# swamp milkweed (Asclepias incarnata): the swamp's, sparse; branching near
	# its top into flat clusters of small deep pink flowers, narrow leaves
	{"cell": 3.0, "cells": 8, "tiles": 5, "flowers": "swamp_milkweed", "stems": 2, "radius": 0.2,
		"u": {"kind": 2, "seed": 15, "in_forest": false, "in_prairie": false, "in_swamp": true, "swamp_clumped": false, "cover": 0.4,
			"drift": Vector3(16.0, 0.35, -9.1), "prairie_height": Vector2(1.0, 1.4),
			"prairie_green": Vector3(0.24, 0.35, 0.13), "prairie_blonde": Vector3(0.3, 0.38, 0.15),
			"petal_color": Vector3(0.85, 0.3, 0.5), "petal_base": Vector3(0.72, 0.2, 0.4), "petal_alt": Vector3(0.92, 0.55, 0.68), "petal_alt_share": 0.2,
			"disc_color": Vector3(0.95, 0.8, 0.86), "head_size": 0.05, "head_px": Vector2(2.0, 5.0),
			"fade_out": Vector2(20.0, 28.0), "thin_from": 16.0}},
	# stinging nettles (Urtica dioica): the forest's, sparse, in small patches
	# here and there; upright, square stemmed, their leaves in pairs, heart
	# shaped, coarsely toothed, drooping; tassels of tiny green flowers
	# hanging from the upper leaves' axils. (Picked, they don't sting.)
	{"cell": 3.0, "cells": 8, "tiles": 5, "flowers": "nettle", "stems": 4, "radius": 0.3,
		"u": {"kind": 2, "seed": 16, "in_prairie": false, "on_litter": true, "cover": 0.4, "drift": Vector3(14.0, 0.3, -11.3),
			"forest_height": Vector2(0.75, 1.15), "prairie_height": Vector2(0.75, 1.15),
			"prairie_green": Vector3(0.17, 0.29, 0.09), "prairie_blonde": Vector3(0.21, 0.31, 0.11),
			"petal_color": Vector3(0.42, 0.48, 0.27), "petal_base": Vector3(0.36, 0.42, 0.22), "petal_alt": Vector3(0.5, 0.48, 0.3), "petal_alt_share": 0.3,
			"disc_color": Vector3(0.38, 0.44, 0.24), "head_size": 0.008, "head_px": Vector2(2.0, 5.0),
			"fade_out": Vector2(22.0, 30.0), "thin_from": 16.0}},
	{"cell": 0.5, "cells": 24, "tiles": 9, "fronds": 8, "lods": [[14.0, 8, 2, 1.0]],
		"u": {"kind": 1, "seed": 4, "in_prairie": false, "forest_height": Vector2(0.25, 0.45),
			"fade_out": Vector2(32.0, 45.0), "thin_from": 16.0}},
]
const MAX_LOGS := 256 ## logs, stumps, trunks and boulders the grass is kept out of, nearest first (ground_cover_bake.gdshader: logs[])
const MAX_GONE := 64 ## clumps picked a layer hides (ground_cover_bake.gdshader: gone[]), the nearest
const REBAKE := 5.0 ## m the camera moves before a layer's grid is worked out again (more for the layers further out: 8% of their fade_out)
const BAKES_PER_FRAME := 2 ## layers' grids worked out a frame, at most (all thirteen at once made a hitch)
const BAKE_KEYS := ["kind", "seed", "in_forest", "in_prairie", "in_swamp", "swamp_clumped", "in_coast", "forest_height", "prairie_height", "cover", "drift", "on_litter",
		"fade_in", "fade_out", "thin_from"]
const BAKE_MARGIN := 6.0 ## m past a layer's rebake distance the eye may go before a bake's distance culling shows (the bake's, the readback's lag)
const DRAW_KEYS := ["kind", "seed", "fade_in", "fade_out", "thin_from", "prairie_green", "prairie_blonde", "patch_tints",
		"petal_color", "petal_base", "petal_alt", "petal_alt_share", "disc_color", "head_size", "head_px", "petal_mix", "trodden"]

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
	for L0: Dictionary in LAYERS:
		# no more tiles than the layer's range needs: as many each side of the
		# camera's as reach its fade_out (the flowers' 7 a side, 168 m, drew
		# clumps out to 84 m and more that faded out by 15-38 m)
		var L := L0.duplicate(true)
		# (out as far as the player's grass distance, Settings: every layer's
		# fades and thinning in step, so each still hands on to the next)
		var gs := SettingsScript.grass_distance
		for key in ["fade_in", "fade_out"]:
			if L.u.has(key):
				L.u[key] = (L.u[key] as Vector2) * gs
		if L.u.has("thin_from") and float(L.u.thin_from) < 999.0:
			L.u.thin_from = float(L.u.thin_from) * gs
		var lods: Array = []
		for lo: Array in L.get("lods", []):
			lods.append([float(lo[0]) * gs, lo[1], lo[2], lo[3]])
		var reach: float = (L.u.get("fade_out", Vector2(30.0, 40.0)) as Vector2).y
		L.tiles = mini(maxi(L.tiles, ceili(L.tiles * gs)) | 1, 2 * ceili(reach / (L.cell * L.cells)) + 1)
		var grid: int = L.cells * L.tiles
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/render/ground_cover_fern.gdshader" if L.u.kind == 1 else "res://shaders/render/ground_cover.gdshader")
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
			bm.set_shader_parameter("margin", _again(L) + BAKE_MARGIN)
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
		# the simpler meshes for the tiles further off ([from, mesh], nearest first)
		var meshes: Array = [[0.0, mesh]]
		for lo: Array in lods:
			var lm: Mesh = fern_mesh(lo[1], lo[2]) if L.u.kind == 1 else grass_mesh(lo[1], lo[2], L.radius, L.width * float(lo[3]), L.u.seed)
			lm.surface_set_material(0, m)
			meshes.append([lo[0], lm])
		# what it grows in: biome bits, and whether beaches too
		var need := 0
		for pair in [["forest", L.u.get("in_forest", true)], ["prairie", L.u.get("in_prairie", true)],
				["swamp", L.u.get("in_swamp", false)], ["coast", L.u.get("in_coast", false)]]:
			var b: int = world.biome_id(pair[0])
			if pair[1] and b >= 0 and b < 31:
				need |= 1 << b
		_layers.append({"need": need, "beach": L.u.get("in_coast", false), "live": {},
				"L": L, "meshes": meshes, "size": L.cell * L.cells, "tiles": {}, "bufs": {}, "task": -1, "centre": Vector2i.MAX,
				"material": m, "vps": vps, "bakes": bakes, "shown": -1, "baking": false, "want": Vector2i.MAX, "cam": Vector3.ZERO, "baked": Vector3.INF, "walks": -1,
				"grid_shown": Vector2i.MAX, "cull_at": Vector3.INF,
				"item": item_of(L), "gone": [], "img": null})


## The terrain's leaf litter and pine needle textures (it's the terrain's material).
static func setup_terrain(terrain: ShaderMaterial) -> void:
	var t := OakTree._texture("res://data/population/textures/leaf_litter.png")
	terrain.set_shader_parameter("litter_tex", t)
	terrain.set_shader_parameter("litter_mean", _mean(t))
	var n := OakTree._texture("res://data/population/textures/needle_litter.png")
	terrain.set_shader_parameter("needle_tex", n)
	terrain.set_shader_parameter("needle_mean", _mean(n))


## The materials of the layers trodden down and muddied by the player's
## footprints (Footprints): the forest's grass.
func trodden_materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for layer in _layers:
		if layer.L.u.get("trodden", false):
			out.append(layer.material)
	return out


## Every layer's grid worked out and shown (after the first update()s).
func is_ready() -> bool:
	for layer in _layers:
		if layer.shown < 0 or layer.baking or layer.grid_shown != layer.want:
			return false
	return true


## Moves the tiles to keep round the camera, shows only those that can draw
## anything (a biome the layer grows in reaches them, and within the layer's
## range: not wholly past its fade_out, nor wholly inside its fade_in), and
## works out the grids again as needed, BAKES_PER_FRAME at most a frame (the
## grids that moved first). Call every frame.
func update(cam: Vector3) -> void:
	var due: Array = [] # [0: its grid moved, 1: worked out again; layer]
	for layer in _layers:
		var L: Dictionary = layer.L
		var size: float = layer.size
		var tiles: Dictionary = layer.tiles
		var centre := Vector2i(floori(cam.x / size), floori(cam.z / size))
		if centre != layer.centre:
			layer.centre = centre
			var half: int = L.tiles / 2
			layer.want = (centre - Vector2i(half, half)) * int(L.cells)
			layer.cam = cam # (a bake under way goes again for it)
			var wanted := {}
			for i in range(-half, half + 1):
				for j in range(-half, half + 1):
					wanted[centre + Vector2i(i, j)] = true
			var spare: Array = []
			for key in tiles.keys():
				if not wanted.has(key):
					spare.append(tiles[key])
					tiles.erase(key)
					layer.bufs.erase(key)
			for key: Vector2i in wanted:
				if tiles.has(key):
					continue
				var mi: MultiMeshInstance3D = spare.pop_back() if not spare.is_empty() else null
				if mi == null:
					mi = MultiMeshInstance3D.new()
					var mm := MultiMesh.new() # (its own: only its cells that grow anything, _fill_tiles)
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.mesh = layer.meshes[0][1]
					mi.multimesh = mm
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					add_child(mi)
				else:
					_show_cells(mi, PackedFloat32Array(), mi.multimesh.mesh) # (empty till its cells are worked out)
				mi.position = Vector3(key.x * size, 0.0, key.y * size)
				mi.custom_aabb = _box(mi.position, size)
				tiles[key] = mi
			for mi in spare:
				mi.queue_free()
			layer.cull_at = Vector3.INF
		# the tiles shown: those with anything growing, within range; each
		# with the mesh for its distance
		if cam.distance_to(layer.cull_at) > 1.0:
			layer.cull_at = cam
			for key: Vector2i in tiles:
				var mi: MultiMeshInstance3D = tiles[key]
				mi.visible = mi.multimesh.instance_count > 0 and _tile_grows(layer, key) and _tile_in_range(layer, key, cam)
				if mi.visible:
					var want := _lod_mesh(layer, _tile_near(layer, key, cam))
					if mi.multimesh.mesh != want:
						_show_cells(mi, layer.bufs.get(key, PackedFloat32Array()), want)
		# (the ground's heights are as the terrain draws them from the eye,
		# which changes as it moves: worked out again every few metres, more
		# for the layers further out; and when logs or stumps come or go)
		if layer.baking:
			continue
		var moved: bool = layer.want != layer.grid_shown
		var logs_moved: bool = population != null and population.walk_changes != layer.walks
		var again := _again(L)
		if moved or logs_moved or cam.distance_to(layer.baked) > again:
			due.append([0 if moved else 1, layer])
	due.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in mini(due.size(), BAKES_PER_FRAME):
		var layer: Dictionary = due[i][1]
		layer.cam = cam
		_bake(layer)


## m the camera goes before a layer's grid is worked out again.
static func _again(L: Dictionary) -> float:
	return maxf(REBAKE, (L.u.get("fade_out", Vector2(30.0, 40.0)) as Vector2).y * 0.08)


## How far tile key's nearest point is from cam (m, across the ground).
func _tile_near(layer: Dictionary, key: Vector2i, cam: Vector3) -> float:
	var size: float = layer.size
	var lo := Vector2(key) * size
	var c := Vector2(cam.x, cam.z)
	return c.clamp(lo, lo + Vector2(size, size)).distance_to(c)


## The layer's mesh for a tile whose nearest point is near m off.
static func _lod_mesh(layer: Dictionary, near: float) -> Mesh:
	var meshes: Array = layer.meshes
	var m: Mesh = meshes[0][1]
	for e: Array in meshes:
		if near >= float(e[0]):
			m = e[1]
	return m


## Tile mi draws the cells in buf (12 floats each, MultiMesh.buffer) with
## mesh. (The mesh changed with none to draw: changing a MultiMesh's mesh
## while it holds any reads its buffer back from the GPU.)
static func _show_cells(mi: MultiMeshInstance3D, buf: PackedFloat32Array, mesh: Mesh) -> void:
	var mm := mi.multimesh
	var n := buf.size() / 12
	if mm.mesh != mesh:
		mm.instance_count = 0
		mm.mesh = mesh
	if mm.instance_count != n:
		mm.instance_count = n
	if n > 0:
		mm.buffer = buf


## Whether any of tile key's clumps can show from cam: not all of it past
## the layer's fade_out, nor all of it nearer than its fade_in begins (m,
## across the ground, as ground_cover.gdshader measures).
func _tile_in_range(layer: Dictionary, key: Vector2i, cam: Vector3) -> bool:
	var size: float = layer.size
	var u: Dictionary = layer.L.u
	var lo := Vector2(key) * size
	var hi := lo + Vector2(size, size)
	var c := Vector2(cam.x, cam.z)
	var near := _tile_near(layer, key, cam)
	var fade_out: Vector2 = u.get("fade_out", Vector2(30.0, 40.0))
	if near > fade_out.y + 1.0:
		return false
	var fade_in: Vector2 = u.get("fade_in", Vector2.ZERO)
	if fade_in.y > 0.0:
		var far := 0.0
		for q in [lo, hi, Vector2(lo.x, hi.y), Vector2(hi.x, lo.y)]:
			far = maxf(far, (q as Vector2).distance_to(c))
		if far < fade_in.x - 1.0:
			return false
	return true


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
		# the clumps picked (Foraging), nearest first: gone till they grow again
		var gone := _gone_near(layer, cam)
		bm.set_shader_parameter("gone_count", gone.size())
		gone.resize(MAX_GONE)
		bm.set_shader_parameter("gone", gone)
		layer.vps[k].render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		# read back, and on a worker thread each tile's cells that grow
		# anything gathered (only those are drawn: an empty cell's clump
		# costs its every corner)
		var bytes: PackedByteArray = await _read_back(layer.vps[k])
		if not is_inside_tree():
			return
		var cells: int = layer.L.cells
		var grid: int = cells * int(layer.L.tiles)
		var out := {}
		layer.task = WorkerThreadPool.add_task(_compact.bind(bytes, grid, cells, int(layer.L.tiles), float(layer.L.cell), out))
		while not WorkerThreadPool.is_task_completed(layer.task):
			await get_tree().process_frame
		WorkerThreadPool.wait_for_task_completion(layer.task)
		layer.task = -1
		if not is_inside_tree():
			return
		# the grid and the tiles' cells shown together
		var m: ShaderMaterial = layer.material
		m.set_shader_parameter("data_tex", layer.vps[k].get_texture())
		m.set_shader_parameter("grid_origin", origin)
		m.set_shader_parameter("grid_size", layer.bakes[k].get_shader_parameter("grid_size"))
		m.set_shader_parameter("base_h", base_h)
		_fill_tiles(layer, origin, out)
		layer.shown = k
		layer.grid_shown = origin
		# (what grows where, for pick_near)
		layer.img = Image.create_from_data(grid * 2, grid, false, Image.FORMAT_RGBA8, bytes) if bytes.size() == grid * grid * 8 else null
		if layer.want == origin and layer.cam == cam:
			break
	layer.baking = false


func _exit_tree() -> void:
	for layer in _layers:
		if layer.task >= 0:
			WorkerThreadPool.wait_for_task_completion(layer.task)
			layer.task = -1


## A layer's grid, as baked into vp: RGBA8, its rows one after another.
## Without stalling the GPU where the renderer can (RenderingDevice's
## texture_get_data_async, Godot 4.4 on: a frame or two later); otherwise
## (the Compatibility renderer, older Godot) read straight back.
func _read_back(vp: SubViewport) -> PackedByteArray:
	var tex := vp.get_texture()
	var rd := RenderingServer.get_rendering_device()
	if rd != null and rd.has_method("texture_get_data_async"):
		var rid := RenderingServer.texture_get_rd_texture(tex.get_rid())
		if rid.is_valid():
			# (the data handed to the array's own append, no script: quitting
			# with a read under way, RenderingDevice hands it over as it shuts
			# down, after the scripts have gone, and a lambda there crashed)
			var got: Array = []
			var err: int = rd.call("texture_get_data_async", rid, 0, Callable.create(got, "append"))
			if err == OK:
				while got.is_empty():
					await get_tree().process_frame
					if not is_inside_tree():
						return PackedByteArray()
				var data: PackedByteArray = got[0]
				if data.size() == vp.size.x * vp.size.y * 4:
					return data
	var img := tex.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img.get_data()


## (On a worker thread.) Each tile's cells that grow anything (the size
## texel's blue byte not 0), as a MultiMesh buffer: 12 floats each, the
## cell's corner from the tile's. out: tile (from the grid's first) ->
## PackedFloat32Array. Read back wrong (its size), every cell.
static func _compact(bytes: PackedByteArray, grid: int, cells: int, tiles: int, cell: float, out: Dictionary) -> void:
	var row_bytes := grid * 8
	var all := bytes.size() != row_bytes * grid
	for by in tiles:
		for bx in tiles:
			var buf := PackedFloat32Array()
			buf.resize(cells * cells * 12)
			buf.fill(0.0)
			var n := 0
			for j in cells:
				var at := (by * cells + j) * row_bytes + bx * cells * 8 + 2
				for i in cells:
					if all or bytes[at + i * 8] != 0:
						var o := n * 12
						buf[o] = 1.0
						buf[o + 3] = i * cell
						buf[o + 5] = 1.0
						buf[o + 10] = 1.0
						buf[o + 11] = j * cell
						n += 1
			buf.resize(n * 12)
			out[Vector2i(bx, by)] = buf


## The layer's tiles given their cells from a grid baked at origin (out:
## _compact's); a tile the grid doesn't reach, none.
func _fill_tiles(layer: Dictionary, origin: Vector2i, out: Dictionary) -> void:
	var cells: int = layer.L.cells
	var first := Vector2i(origin.x / cells, origin.y / cells) # (origin's on the tiles' corners)
	var tiles: Dictionary = layer.tiles
	for key: Vector2i in tiles:
		var buf: PackedFloat32Array = out.get(key - first, PackedFloat32Array())
		layer.bufs[key] = buf
		var mi: MultiMeshInstance3D = tiles[key]
		_show_cells(mi, buf, mi.multimesh.mesh)
	layer.cull_at = Vector3.INF # (which to show, and their meshes, again)


## The item a layer's clumps are picked as (Foraging): its flowers', or a
## cattail; "" if they can't be.
static func item_of(L: Dictionary) -> String:
	if L.has("flowers"):
		return L.flowers
	if L.has("cattails"):
		return "cattail"
	return ""


## The clumps picked, which aren't to be drawn: item id -> the cells
## (Vector2i, of that item's layer). Each layer worked out again.
func set_gone(picked: Dictionary) -> void:
	for layer in _layers:
		var cells: Array = picked.get(layer.item, [])
		if cells != layer.gone:
			layer.gone = cells.duplicate()
			layer.baked = Vector3.INF # (worked out again at the next update)


## The layer's picked cells nearest cam, at most MAX_GONE.
func _gone_near(layer: Dictionary, cam: Vector3) -> PackedVector2Array:
	var cells: Array = layer.gone
	var out := PackedVector2Array()
	if cells.is_empty():
		return out
	var cell: float = layer.L.cell
	var c := Vector2(cam.x, cam.z) / cell
	var sorted := cells.duplicate()
	if sorted.size() > MAX_GONE:
		sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return c.distance_squared_to(Vector2(a)) < c.distance_squared_to(Vector2(b)))
		sorted.resize(MAX_GONE)
	for g: Vector2i in sorted:
		out.append(Vector2(g))
	return out


## The clump (a flower's, a cattail's) the view from eye along fwd meets
## within reach, the nearest: {item, cell, at} (the cell its layer's, at
## its foot, on the map), or {} none. Reads what grows where back from the
## layer's grid (once a bake: a small texture).
func pick_near(eye: Vector3, fwd: Vector3, reach: float) -> Dictionary:
	var best := {}
	var best_t := INF
	for layer in _layers:
		if layer.item == "" or layer.shown < 0:
			continue
		var L: Dictionary = layer.L
		var k: int = layer.shown
		var bm: ShaderMaterial = layer.bakes[k]
		if layer.img == null:
			layer.img = layer.vps[k].get_texture().get_image()
			if layer.img.get_format() != Image.FORMAT_RGBA8:
				layer.img.convert(Image.FORMAT_RGBA8)
		var img: Image = layer.img
		var origin: Vector2i = bm.get_shader_parameter("grid_origin")
		var base_h: float = bm.get_shader_parameter("base_h")
		var cell: float = L.cell
		var seed: int = L.u.seed
		var r: float = L.get("radius", 0.25) + 0.12
		var lo := Vector2i(floori((eye.x - reach) / cell) - 1, floori((eye.z - reach) / cell) - 1)
		var hi := Vector2i(floori((eye.x + reach) / cell) + 1, floori((eye.z + reach) / cell) + 1)
		for cz in range(lo.y, hi.y + 1):
			for cx in range(lo.x, hi.x + 1):
				var c := Vector2i(cx, cz)
				var t := c - origin
				if t.x < 0 or t.y < 0 or t.x * 2 >= img.get_width() or t.y >= img.get_height():
					continue
				var px := img.get_pixel(t.x * 2, t.y)
				var size := roundf(px.b * 255.0) / 255.0 * SIZE_MAX
				if size <= 0.0:
					continue
				var ground := (roundf(px.r * 255.0) * 256.0 + roundf(px.g * 255.0)) / 64.0 - 512.0 + base_h
				var at := Vector2(c) * cell + Vector2(_h2(c, 1, seed), _h2(c, 2, seed)) * cell
				# the view's nearest to the clump's upright, from its foot to its top
				var foot := Vector3(at.x, ground, at.y)
				var q := _ray_to_upright(eye, fwd, foot, size)
				if q.x < 0.0 or q.x > reach + 0.5 or q.y > r or q.x >= best_t:
					continue
				best_t = q.x
				best = {"item": layer.item, "cell": c, "at": foot}
	return best


## How far along the ray (eye, unit fwd) it comes nearest the upright from
## foot, tall h, and how near: Vector2(along, apart).
static func _ray_to_upright(eye: Vector3, fwd: Vector3, foot: Vector3, h: float) -> Vector2:
	var best := Vector2(-1.0, INF)
	for i in 9:
		var p := foot + Vector3.UP * h * (0.2 + 0.8 * i / 8.0)
		var t := (p - eye).dot(fwd)
		if t < 0.0:
			continue
		var d := (eye + fwd * t).distance_to(p)
		if d < best.y:
			best = Vector2(t, d)
	return best


const SIZE_MAX := 3.2 ## m (ground_cover.gdshaderinc: SIZE_MAX)


## ground_cover.gdshaderinc's h2(), on the CPU (its 32-bit unsigned sums).
static func _h2(c: Vector2i, k: int, seed: int) -> float:
	var d := c * 3 + Vector2i(seed * 7919 + k * 131, k * 977 - seed)
	return _gc_hash(d)


static func _mul32(a: int, b: int) -> int:
	a &= 0xFFFFFFFF
	b &= 0xFFFFFFFF
	return (a * (b & 0xFFFF) + (((a * (b >> 16)) & 0xFFFF) << 16)) & 0xFFFFFFFF


static func _gc_hash(c: Vector2i) -> float:
	var v := _mul32(c.x, 1597334677) ^ _mul32(c.y, 3812015801)
	v = (_mul32(v, 747796405) + 2891336453) & 0xFFFFFFFF
	v = _mul32((v >> ((v >> 28) + 4)) ^ v, 277803737)
	return float((v >> 22) ^ v) / 4294967295.0


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


## A clump of wildflowers ("susan": black-eyed Susans; "fleabane";
## "coneflower": purple coneflowers; "aster": swamp asters; "yampah"), in
## units of the clump's height, as grass_mesh: stems (strips, coloured as
## grass, CUSTOM0 their half width in m), a leaf or two low down, and the
## heads, solid: ray florets (UV.x 3..4, UV.y from their base out to their
## tip) round a disc (UV.x 4..5); COLOR.b the height, so a head sways with
## its stem's top; COLOR.g per stem (ground_cover.gdshader: the odd one's
## other petal colour). Susans: a head a stem, 6-7 cm across, thirteen
## golden rays drooping a little round a dark brown dome. Fleabane: a stem
## branching near its top into a few small heads, 2 cm across, a fringe
## of fine rays, white to light purple, round a yellow disc.
const TINY_RAYS := 7 ## a flower head of this many rays or fewer is drawn as a fan (flower_mesh)
const TINY_RIM := 5 ## its rim's corners


static func flower_mesh(kind: String, stems: int, radius: float, seed: int, leaves: Array = []) -> ArrayMesh:
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
		if rays <= TINY_RAYS:
			# a floret a few mm across (yampah's, the milkweeds', the
			# nettle's): a fan, its middle the rays' base colour, its rim
			# their tips', drooping; no disc. (Its rays each a quad and its
			# disc a fan, a clump of them ran to thousands of corners.)
			# The same random numbers drawn as the rays would: the clump
			# otherwise as it was
			for i in rays:
				rng.randf_range(-0.15, 0.15)
			var b0: int = base[0]
			vert.call(root, c + up * (dome / H), up, Vector2(3.25, 0.0), col)
			for i in TINY_RIM:
				var a := turn + TAU * i / TINY_RIM
				var out := u * cos(a) + v * sin(a)
				vert.call(root, c + out * (r_out / H) - up * (droop / H), (out * 0.3 + up).normalized(), Vector2(3.25, 1.0), col)
			for i in TINY_RIM:
				st.add_index(b0)
				st.add_index(b0 + 1 + i)
				st.add_index(b0 + 1 + (i + 1) % TINY_RIM)
			base[0] += TINY_RIM + 1
			return
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
		if kind == "susan" or kind == "coneflower":
			strip.call(root, [Vector3.ZERO, top * 0.5 + Vector3(lean.x, 0.0, lean.y) * 0.3, top], [0.0035, 0.003, 0.0022], side, n, shade, 0.0)
			var tilt := Vector3(lean.x, 0.0, lean.y) * 2.0 + Vector3(rng.randf_range(-0.2, 0.2), 0.0, rng.randf_range(-0.2, 0.2))
			if kind == "susan":
				head.call(root, top, tilt, 13, 0.009, 0.034, 0.008, 0.012, 0.011, g)
			else: # (the coneflower's rays hang down from its raised cone)
				head.call(root, top, tilt, 14, 0.012, 0.045, 0.009, 0.03, 0.018, g)
		elif kind == "yampah":
			# a slender stem, forking near its top into two or three
			# umbels, each a dome of small umbellets of tiny white flowers
			# on fine rays
			var fork := top * 0.78
			strip.call(root, [Vector3.ZERO, fork * 0.5, fork], [0.0035, 0.003, 0.0025], side, n, shade, 0.0)
			for u in rng.randi_range(2, 3):
				var ua := rng.randf() * TAU
				var reach := rng.randf_range(0.0, 0.05) if u == 0 else rng.randf_range(0.04, 0.09)
				var uc := fork + Vector3(cos(ua) * reach, rng.randf_range(0.12, 0.22) * tall, sin(ua) * reach)
				strip.call(root, [fork, uc], [0.0025, 0.002], side, n, shade, 0.0)
				var size := rng.randf_range(0.8, 1.2)
				for k in rng.randi_range(7, 10):
					var ka := rng.randf() * TAU
					var kr := sqrt(rng.randf()) * 0.022 * size
					var c := uc + Vector3(cos(ka) * kr / H, (0.012 - kr * 0.35) * size / H, sin(ka) * kr / H)
					strip.call(root, [uc, c], [0.0008, 0.0006], side, n, shade, 0.0)
					head.call(root, c, Vector3(cos(ka), 0.0, sin(ka)) * kr * 15.0, 7, 0.0025, 0.0055, 0.0022, 0.0, 0.0012, rng.randf())
		elif kind == "milkweed":
			# a stout, unbranched stem; broad oval leaves in pairs up it,
			# each pair square to the last; from the top and the upper
			# leaves' axils, drooping balls of small flowers on their stalks
			strip.call(root, [Vector3.ZERO, top * 0.5, top], [0.006, 0.005, 0.004], side, n, shade, 0.0)
			for k in 5:
				var at := top * (0.22 + 0.62 * k / 4.0)
				var pa := face + k * PI * 0.5
				for sd: float in [-1.0, 1.0]:
					var ld := Vector2(cos(pa), sin(pa)) * sd
					var ll := rng.randf_range(0.11, 0.15) / H
					var pts := [at, at + Vector3(ld.x * ll * 0.5, ll * 0.22, ld.y * ll * 0.5), at + Vector3(ld.x * ll, ll * 0.15, ld.y * ll)]
					strip.call(root, pts, [0.004, 0.032, 0.003], Vector3(-ld.y, 0.0, ld.x), Vector3(ld.x * 0.3, 1.0, ld.y * 0.3).normalized(), shade, 0.0)
					# (where its leaves are, if asked: a caterpillar's to sit on, a
					# monarch's to lay on: [its stem's root, its blade's middle, its
					# normal, its way out] in the mesh's space)
					leaves.append([root, pts[1], Vector3(ld.x * 0.3, 1.0, ld.y * 0.3).normalized(), ld])
			for u in rng.randi_range(2, 3):
				var ua := rng.randf() * TAU
				var ub := top * (1.0 - 0.14 * u)
				var uc := ub + Vector3(cos(ua) * 0.05, 0.03, sin(ua) * 0.05) / H
				strip.call(root, [ub, uc], [0.0025, 0.002], side, n, shade, 0.0)
				var size := rng.randf_range(0.85, 1.15)
				for f in 12:
					# a ball, drooping: its flowers more round its underside
					var fy := rng.randf_range(-0.95, 0.45)
					var fa := rng.randf() * TAU
					var ld := Vector3(cos(fa) * sqrt(1.0 - fy * fy), fy, sin(fa) * sqrt(1.0 - fy * fy))
					var fc := uc + ld * 0.032 * size / H
					strip.call(root, [uc, fc], [0.0007, 0.0006], side, n, shade, 0.0)
					head.call(root, fc, ld * 3.0, 5, 0.0022, 0.0055, 0.0028, 0.0025, 0.0018, rng.randf())
		elif kind == "nettle":
			# a square stem, upright; its leaves in pairs, each pair square
			# to the last, heart shaped, pointed, drooping, the lower bigger;
			# from the upper axils, tassels of tiny green flowers hanging
			strip.call(root, [Vector3.ZERO, top * 0.5, top], [0.0045, 0.004, 0.003], side, n, shade, 0.0)
			for k in 7:
				var f := float(k) / 6.0
				var at := top * (0.18 + 0.8 * f)
				var pa := face + k * PI * 0.5
				for sd: float in [-1.0, 1.0]:
					var ld := Vector2(cos(pa), sin(pa)) * sd
					var ll := rng.randf_range(0.09, 0.13) * lerpf(1.1, 0.55, f) / H
					var pts := [at, at + Vector3(ld.x * ll * 0.3, ll * 0.12, ld.y * ll * 0.3), at + Vector3(ld.x * ll * 0.7, ll * 0.02, ld.y * ll * 0.7), at + Vector3(ld.x * ll, -ll * 0.22, ld.y * ll)]
					strip.call(root, pts, [0.004, 0.026 * lerpf(1.0, 0.6, f), 0.018 * lerpf(1.0, 0.6, f), 0.001], Vector3(-ld.y, 0.0, ld.x), Vector3(ld.x * 0.35, 1.0, ld.y * 0.35).normalized(), shade, 0.0)
					if f > 0.35 and f < 0.95: # (its flowers' tassels, hanging from the axil)
						var td := Vector2(cos(pa + 0.6 * sd), sin(pa + 0.6 * sd)) * sd
						var t1 := at + Vector3(td.x * 0.035, 0.01, td.y * 0.035) / H
						var t2 := at + Vector3(td.x * 0.06, -0.05, td.y * 0.06) / H
						strip.call(root, [at, t1, t2], [0.0015, 0.0025, 0.0015], Vector3(-td.y, 0.0, td.x), Vector3(td.x, 0.6, td.y).normalized(), shade, 0.0)
						for q in 3:
							var c: Vector3 = t1.lerp(t2, 0.3 + 0.35 * q)
							head.call(root, c, Vector3(td.x, -0.5, td.y), 4, 0.0012, 0.0035, 0.0022, 0.001, 0.0012, rng.randf())
		elif kind == "swamp_milkweed":
			# branching near its top into a few flat clusters of small
			# flowers, upright; narrow leaves in pairs up the stem
			var fork := top * 0.8
			strip.call(root, [Vector3.ZERO, fork * 0.5, fork], [0.004, 0.0035, 0.003], side, n, shade, 0.0)
			for k in 6:
				var at := fork * (0.2 + 0.75 * k / 5.0)
				var pa := face + k * PI * 0.5
				for sd: float in [-1.0, 1.0]:
					var ld := Vector2(cos(pa), sin(pa)) * sd
					var ll := rng.randf_range(0.09, 0.13) / H
					var pts := [at, at + Vector3(ld.x * ll * 0.5, ll * 0.35, ld.y * ll * 0.5), at + Vector3(ld.x * ll, ll * 0.45, ld.y * ll)]
					strip.call(root, pts, [0.002, 0.008, 0.001], Vector3(-ld.y, 0.0, ld.x), Vector3(ld.x * 0.4, 1.0, ld.y * 0.4).normalized(), shade, 0.0)
			for cl in rng.randi_range(3, 4):
				var ba := rng.randf() * TAU
				var reach := rng.randf_range(0.03, 0.08)
				var bc := fork + Vector3(cos(ba) * reach, rng.randf_range(0.1, 0.16) * tall, sin(ba) * reach)
				strip.call(root, [fork, bc], [0.0025, 0.002], side, n, shade, 0.0)
				for f in 9:
					var fr := sqrt(rng.randf()) * 0.018
					var fa := rng.randf() * TAU
					var fc := bc + Vector3(cos(fa) * fr, 0.008 - fr * 0.3, sin(fa) * fr) / H
					strip.call(root, [bc, fc], [0.0006, 0.0005], side, n, shade, 0.0)
					head.call(root, fc, Vector3(cos(fa), 0.0, sin(fa)) * fr * 12.0, 5, 0.0016, 0.0042, 0.0022, 0.0015, 0.0012, rng.randf())
		elif kind == "aster":
			# branching from half way up into several heads, each 2.5-3 cm
			var fork := top * 0.6
			strip.call(root, [Vector3.ZERO, fork * 0.5, fork], [0.005, 0.0045, 0.004], side, n, shade, 0.0)
			for h in rng.randi_range(3, 5):
				var ha := rng.randf() * TAU
				var reach := rng.randf_range(0.04, 0.12)
				var c := fork + Vector3(cos(ha) * reach, rng.randf_range(0.15, 0.4) * tall, sin(ha) * reach)
				strip.call(root, [fork, (fork + c) * 0.5 + Vector3(0.0, 0.03, 0.0), c], [0.003, 0.0028, 0.0024], side, n, shade, 0.0)
				head.call(root, c, Vector3(cos(ha), 0.0, sin(ha)) * 0.35, 22, 0.005, 0.014, 0.0022, 0.002, 0.002, rng.randf())
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
static func fern_mesh(fronds: int, segs := 4) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)
	var base := 0
	var SEGS := segs
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
