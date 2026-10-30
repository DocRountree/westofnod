class_name WorldData
extends RefCounted
## The vertical slice's baked data (tools/dem/bake_slice.py, from real elevation
## data): height map, material masks and river centrelines, plus the textures
## the renderer samples and the queries gameplay needs.

const DIR := "res://data/slice/"
const OCEAN_FLOOR := -60.0

var size: int
var domain: float
var origin: Vector2
var heights := PackedFloat32Array()
var rivers: Array = [] # {pts: PackedVector2Array, level, width: PackedFloat32Array}
var height_tex: ImageTexture
var mask_tex: ImageTexture
var spawn := Vector3.ZERO

var _water_cell := 8.0
var _water_n := 0
var _water := PackedFloat32Array() # river level per 8 m cell, or -INF
var _flow := PackedVector2Array()


func load_slice() -> WorldData:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "slice.json"))
	size = int(meta.size)
	domain = float(meta.cell) * (size - 1)
	origin = Vector2(meta.origin[0], meta.origin[1])
	var h_min: float = meta.h_min
	var h_scale: float = meta.h_scale
	var img := Image.load_from_file(DIR + "heights.png")
	img.convert(Image.FORMAT_LA8)
	var raw := img.get_data() # 16 bits as (high, low) bytes
	heights.resize(size * size)
	for k in size * size:
		heights[k] = h_min + ((raw[k * 2] << 8) | raw[k * 2 + 1]) * h_scale
	var hi := Image.create_from_data(size, size, false, Image.FORMAT_RF, heights.to_byte_array())
	hi.generate_mipmaps()
	height_tex = ImageTexture.create_from_image(hi)
	var mi := Image.load_from_file(DIR + "masks.png")
	mi.generate_mipmaps()
	mask_tex = ImageTexture.create_from_image(mi)
	for r in JSON.parse_string(FileAccess.get_file_as_string(DIR + "rivers.json")):
		var pts := PackedVector2Array()
		for p in r.pts:
			pts.append(Vector2(p[0], p[1]))
		rivers.append({"pts": pts, "level": PackedFloat32Array(r.level), "width": PackedFloat32Array(r.width)})
	_rasterise_water()
	_pick_spawn()
	return self


func cell() -> float:
	return domain / (size - 1)


## Terrain height, bilinear (as the finest rendered level).
func height_at(x: float, z: float) -> float:
	var g := (Vector2(x, z) - origin) / cell()
	if g.x < 0.0 or g.y < 0.0 or g.x > size - 1 or g.y > size - 1:
		return OCEAN_FLOOR
	var i := mini(floori(g.x), size - 2)
	var j := mini(floori(g.y), size - 2)
	var fx := g.x - i
	var fz := g.y - j
	var k := j * size + i
	return lerpf(lerpf(heights[k], heights[k + 1], fx), lerpf(heights[k + size], heights[k + size + 1], fx), fz)


## Water surface over (x, z): Vector3(level, flow x, flow z); the sea (0) unless
## a river stands higher here.
func water_at(x: float, z: float) -> Vector3:
	var g := ((Vector2(x, z) - origin) / _water_cell).floor()
	if g.x < 0 or g.y < 0 or g.x >= _water_n or g.y >= _water_n:
		return Vector3.ZERO
	var k := int(g.y) * _water_n + int(g.x)
	if _water[k] > 0.0:
		return Vector3(_water[k], _flow[k].x, _flow[k].y)
	return Vector3.ZERO


func _rasterise_water() -> void:
	_water_n = ceili(domain / _water_cell) + 1
	_water.resize(_water_n * _water_n)
	_water.fill(-INF)
	_flow.resize(_water_n * _water_n)
	for r in rivers:
		var pts: PackedVector2Array = r.pts
		for i in pts.size():
			var hw: float = r.width[i] * 0.5
			var dir := (pts[maxi(i - 1, 0)] - pts[mini(i + 1, pts.size() - 1)]).normalized() # downstream
			var c := ((pts[i] - origin) / _water_cell).floor()
			var k := ceili(hw / _water_cell)
			for dj in range(-k, k + 1):
				for di in range(-k, k + 1):
					var gi := int(c.x) + di
					var gj := int(c.y) + dj
					if gi < 0 or gj < 0 or gi >= _water_n or gj >= _water_n:
						continue
					var q := origin + (Vector2(gi, gj) + Vector2(0.5, 0.5)) * _water_cell
					if q.distance_to(pts[i]) <= hw + _water_cell * 0.5:
						var kk := gj * _water_n + gi
						if r.level[i] > _water[kk]:
							_water[kk] = r.level[i]
							_flow[kk] = dir


## On the valley floor, beside the largest river, a little way inland.
func _pick_spawn() -> void:
	var best: Dictionary = rivers[0]
	for r in rivers:
		if r.pts.size() > best.pts.size() and r.width[0] > best.width[0] * 0.8:
			best = r
	var pts: PackedVector2Array = best.pts
	for i in range(pts.size() / 6, pts.size()):
		if best.level[i] > 3.0:
			var t := (pts[mini(i + 1, pts.size() - 1)] - pts[i]).normalized()
			var p: Vector2 = pts[i] + Vector2(-t.y, t.x) * (best.width[i] * 0.5 + 12.0)
			spawn = Vector3(p.x, height_at(p.x, p.y) + 1.0, p.y)
			return
