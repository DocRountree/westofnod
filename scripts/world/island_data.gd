class_name IslandData
extends RefCounted
## The finished island: full-resolution maps over a square domain, plus the
## textures the renderer samples. Cached to disk by IslandGenerator.
##
##   heights   terrain height (m)
##   water     water surface level where there is inland water (m)
##   material  RGBA8: floodplain, wetness, river bed, fan/delta deposits
##   wattr     RGBA8: water coverage, flow x, flow z (0.5 = still), kind / 2

const VERSION := 1

var size: int # cells per side
var domain: float # metres per side
var origin: Vector2 # world xz of cell (0, 0)
var heights := PackedFloat32Array()
var water := PackedFloat32Array()
var material := PackedByteArray()
var wattr := PackedByteArray()
var spawn := Vector3.INF
var stats := {}

var height_tex: ImageTexture
var water_tex: ImageTexture
var material_tex: ImageTexture
var wattr_tex: ImageTexture


func cell() -> float:
	return domain / (size - 1)


## Builds the textures (with mipmaps, so distant ground and water average
## instead of aliasing). Call on the main thread.
func make_textures() -> void:
	var hi := Image.create_from_data(size, size, false, Image.FORMAT_RF, heights.to_byte_array())
	hi.generate_mipmaps()
	height_tex = ImageTexture.create_from_image(hi)
	var wi := Image.create_from_data(size, size, false, Image.FORMAT_RF, water.to_byte_array())
	wi.generate_mipmaps()
	water_tex = ImageTexture.create_from_image(wi)
	var mi := Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, material)
	mi.generate_mipmaps()
	material_tex = ImageTexture.create_from_image(mi)
	var ai := Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, wattr)
	ai.generate_mipmaps()
	wattr_tex = ImageTexture.create_from_image(ai)


func _grid(x: float, z: float) -> Vector2:
	return (Vector2(x, z) - origin) / cell()


## Terrain height, bilinear (matches the renderer's finest level). Sea floor
## depth outside the domain.
func height_at(x: float, z: float) -> float:
	var g := _grid(x, z)
	if g.x < 0.0 or g.y < 0.0 or g.x > size - 1 or g.y > size - 1:
		return IslandGenerator.OCEAN_FLOOR
	var i := mini(floori(g.x), size - 2)
	var j := mini(floori(g.y), size - 2)
	var fx := g.x - i
	var fz := g.y - j
	var k := j * size + i
	return lerpf(lerpf(heights[k], heights[k + 1], fx), lerpf(heights[k + size], heights[k + size + 1], fx), fz)


## Water surface over (x, z): Vector3(level, flow x, flow z). The sea (level 0)
## unless an inland water surface stands higher here.
func water_at(x: float, z: float) -> Vector3:
	var g := _grid(x, z)
	if g.x < 0.0 or g.y < 0.0 or g.x > size - 1 or g.y > size - 1:
		return Vector3.ZERO
	var k := roundi(g.y) * size + roundi(g.x)
	if wattr[k * 4] > 127 and water[k] > 0.0:
		return Vector3(water[k], (wattr[k * 4 + 1] - 127.5) / 127.5, (wattr[k * 4 + 2] - 127.5) / 127.5)
	return Vector3.ZERO


func save(path: String) -> void:
	var f := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return
	f.store_32(VERSION)
	f.store_32(size)
	f.store_float(domain)
	f.store_var([origin, spawn, stats])
	f.store_buffer(heights.to_byte_array())
	f.store_buffer(water.to_byte_array())
	f.store_buffer(material)
	f.store_buffer(wattr)


static func load_from(path: String) -> IslandData:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null or f.get_32() != VERSION:
		return null
	var d := IslandData.new()
	d.size = f.get_32()
	d.domain = f.get_float()
	var meta: Array = f.get_var()
	d.origin = meta[0]
	d.spawn = meta[1]
	d.stats = meta[2]
	var nn := d.size * d.size
	d.heights = f.get_buffer(nn * 4).to_float32_array()
	d.water = f.get_buffer(nn * 4).to_float32_array()
	d.material = f.get_buffer(nn * 4)
	d.wattr = f.get_buffer(nn * 4)
	return d
