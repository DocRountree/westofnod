class_name WorldData
extends RefCounted
## The world's baked data (tools/dem/bake_galapagos.py: the Galapagos
## archipelago from real elevation data): the height map and material masks,
## the textures the renderer samples, and the queries gameplay needs.
##
## The ground's height is the same function here and in the shaders
## (height_map.gdshaderinc: terrain_height): a smooth cubic B-spline through
## the 34 m samples, plus procedural relief below them (three octaves of value
## noise, 40 / 15 / 6 m), so collision matches what is drawn.

const DIR := "res://data/world/"
const OCEAN_FLOOR := -80.0
const DETAIL := [Vector2(40.0, 3.0), Vector2(15.0, 1.1), Vector2(6.0, 0.4)] # wavelength m, amplitude m

var size: int
var domain: float
var origin: Vector2
var heights := PackedFloat32Array()
var rivers: Array = [] # (none in the Galapagos: porous lava)
var height_tex: ImageTexture
var mask_tex: ImageTexture
var spawn := Vector3.ZERO
var big_island_north_z := 0.0 ## The northern tip of the biggest island (world z).
var meta := {}
## Biomes (tools/map/bake_biomes.py): one byte a pixel over the whole map, the
## biome's index into biome_names (255: none).
var biome_tex: Texture2D
var biome_names: Array = []
var _biome_bytes := PackedByteArray()
var _biome_size := 0
var _swamp := -1 # the swamp's biome index


func load_world() -> WorldData:
	meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "world.json"))
	size = int(meta.size)
	domain = float(meta.cell) * (size - 1)
	origin = Vector2(meta.origin[0], meta.origin[1])
	var raw := FileAccess.get_file_as_bytes(DIR + "heights.f16.gz").decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var img := Image.create_from_data(size, size, false, Image.FORMAT_RH, raw)
	var cpu := img.duplicate() as Image
	cpu.convert(Image.FORMAT_RF)
	heights = cpu.get_data().to_float32_array()
	img.generate_mipmaps()
	height_tex = ImageTexture.create_from_image(img)
	var mi := Image.load_from_file(DIR + "masks.png")
	mi.generate_mipmaps()
	mask_tex = ImageTexture.create_from_image(mi)
	big_island_north_z = float(meta.get("big_island_north_z", origin.y))
	if meta.has("biomes"):
		var bimg := Image.load_from_file(DIR + str(meta.biomes.file))
		bimg.convert(Image.FORMAT_R8)
		biome_tex = ImageTexture.create_from_image(bimg)
		biome_names = meta.biomes.names
		_biome_size = bimg.get_width()
		_biome_bytes = bimg.get_data()
		_swamp = biome_names.find("swamp")
	var s: Array = meta.spawn
	spawn = Vector3(s[0], height_at(s[0], s[1]) + 3.0, s[1])
	return self


## The biome's name at (x, z) ("" where none).
func biome_at(x: float, z: float) -> String:
	if _biome_size == 0:
		return ""
	var i := clampi(int((x - origin.x) / domain * _biome_size), 0, _biome_size - 1)
	var j := clampi(int((z - origin.y) / domain * _biome_size), 0, _biome_size - 1)
	var b := _biome_bytes[j * _biome_size + i]
	return biome_names[b] if b < biome_names.size() else ""


func cell() -> float:
	return domain / (size - 1)


func _sample(i: int, j: int) -> float:
	if i < 0 or j < 0 or i >= size or j >= size:
		return OCEAN_FLOOR
	return heights[j * size + i]


## The data's smooth surface: a uniform cubic B-spline through the samples.
func base_height(x: float, z: float) -> float:
	var g := (Vector2(x, z) - origin) / cell()
	var i := floori(g.x)
	var j := floori(g.y)
	var fx := g.x - i
	var fz := g.y - j
	var wx := _bspline(fx)
	var wz := _bspline(fz)
	var h := 0.0
	for b in 4:
		var row := 0.0
		for a in 4:
			row += _sample(i - 1 + a, j - 1 + b) * wx[a]
		h += row * wz[b]
	return h


static func _bspline(t: float) -> PackedFloat32Array:
	var t2 := t * t
	var t3 := t2 * t
	return PackedFloat32Array([(1.0 - t) * (1.0 - t) * (1.0 - t) / 6.0, (3.0 * t3 - 6.0 * t2 + 4.0) / 6.0,
			(-3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0) / 6.0, t3 / 6.0])


## Ground height (as drawn, at full detail).
func height_at(x: float, z: float) -> float:
	var b := base_height(x, z)
	return b + detail(x, z) * clampf((b - 0.5) / 3.0, 0.0, 1.0) * (1.0 - swampiness(x, z))


## How much of a swamp (x, z) is in, 0..1: the four nearest biome texels
## blended, as in height_map.gdshaderinc (no fine relief there).
func swampiness(x: float, z: float) -> float:
	if _biome_size == 0 or _swamp < 0:
		return 0.0
	var g := (Vector2(x, z) - origin) / (domain + cell()) * _biome_size - Vector2(0.5, 0.5)
	var i := floori(g.x)
	var j := floori(g.y)
	var f := g - Vector2(i, j)
	var v := func(a: int, b: int) -> float:
		var ca := clampi(a, 0, _biome_size - 1)
		var cb := clampi(b, 0, _biome_size - 1)
		return 1.0 if _biome_bytes[cb * _biome_size + ca] == _swamp else 0.0
	return lerpf(lerpf(v.call(i, j), v.call(i + 1, j), f.x), lerpf(v.call(i, j + 1), v.call(i + 1, j + 1), f.x), f.y)


## Procedural relief below the data's resolution (as terrain_height in the shader).
static func detail(x: float, z: float) -> float:
	var d := 0.0
	for k in DETAIL.size():
		var o: Vector2 = DETAIL[k]
		d += (vnoise(x / o.x + 17.0 * k, z / o.x - 9.0 * k) - 0.5) * 2.0 * o.y
	return d


## Value noise in [0, 1] with quintic interpolation; same hash as the shader.
static func vnoise(x: float, z: float) -> float:
	var i := floori(x)
	var j := floori(z)
	var fx := x - i
	var fz := z - j
	var ux := fx * fx * fx * (fx * (fx * 6.0 - 15.0) + 10.0)
	var uz := fz * fz * fz * (fz * (fz * 6.0 - 15.0) + 10.0)
	return lerpf(lerpf(_hash(i, j), _hash(i + 1, j), ux), lerpf(_hash(i, j + 1), _hash(i + 1, j + 1), ux), uz)


static func _hash(i: int, j: int) -> float:
	const M := 0xFFFFFFFF
	var v := (((i & M) * 1597334677) & M) ^ (((j & M) * 3812015801) & M)
	v = (v * 747796405 + 2891336453) & M
	v = (((v >> ((v >> 28) + 4)) ^ v) * 277803737) & M
	return float((v >> 22) ^ v) / 4294967295.0


## Surface normal at (x, z).
func normal_at(x: float, z: float) -> Vector3:
	var e := 1.0
	return Vector3(height_at(x - e, z) - height_at(x + e, z), 2.0 * e,
			height_at(x, z - e) - height_at(x, z + e)).normalized()


## Water surface over (x, z): Vector3(level, flow x, flow z). Only the sea here.
func water_at(_x: float, _z: float) -> Vector3:
	return Vector3.ZERO
