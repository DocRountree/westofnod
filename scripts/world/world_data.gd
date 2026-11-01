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
var height_tex: ImageTexture
var mask_tex: ImageTexture
var spawn := Vector3.ZERO
var meta := {}
## Biomes (tools/map/bake_biomes.py): one byte a pixel over the whole map, the
## biome's index into biome_names (255: none).
var biome_tex: Texture2D
var biome_names: Array = []
var _biome_bytes := PackedByteArray()
var _biome_size := 0
var swamp := -1 ## The swamp's biome index.


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
	if meta.has("biomes"):
		var bimg := Image.load_from_file(DIR + str(meta.biomes.file))
		bimg.convert(Image.FORMAT_R8)
		biome_tex = ImageTexture.create_from_image(bimg)
		biome_names = meta.biomes.names
		_biome_size = bimg.get_width()
		_biome_bytes = bimg.get_data()
		swamp = biome_names.find("swamp")
	var s: Array = meta.spawn
	spawn = Vector3(s[0], height_at(s[0], s[1]) + 3.0, s[1])
	return self


## The biome's index into biome_names at (x, z) (-1 where none). Safe to call
## from worker threads (all of WorldData's queries are: it is read-only once loaded).
func biome_index_at(x: float, z: float) -> int:
	if _biome_size == 0:
		return -1
	var i := clampi(int((x - origin.x) / domain * _biome_size), 0, _biome_size - 1)
	var j := clampi(int((z - origin.y) / domain * _biome_size), 0, _biome_size - 1)
	var b := _biome_bytes[j * _biome_size + i]
	return b if b < biome_names.size() else -1


## The biome's name at (x, z) ("" where none).
func biome_at(x: float, z: float) -> String:
	var b := biome_index_at(x, z)
	return biome_names[b] if b >= 0 else ""


## The biome's index for a name (-1 if there is no such biome).
func biome_id(name: String) -> int:
	return biome_names.find(name)


func cell() -> float:
	return domain / (size - 1)


func _sample(i: int, j: int) -> float:
	if i < 0 or j < 0 or i >= size or j >= size:
		return OCEAN_FLOOR
	return heights[j * size + i]


## The data's smooth surface: a uniform cubic B-spline through the samples.
func base_height(x: float, z: float) -> float:
	var c := cell()
	var gx := (x - origin.x) / c
	var gz := (z - origin.y) / c
	var i := floori(gx)
	var j := floori(gz)
	var w := _bspline(gx - i)
	var v := _bspline(gz - j)
	var h := 0.0
	if i >= 1 and j >= 1 and i + 2 < size and j + 2 < size:
		# inside: read the rows directly (the common case)
		var k := (j - 1) * size + i - 1
		for b in 4:
			h += (heights[k] * w.x + heights[k + 1] * w.y + heights[k + 2] * w.z + heights[k + 3] * w.w) * v[b]
			k += size
		return h
	for b in 4:
		var row := 0.0
		for a in 4:
			row += _sample(i - 1 + a, j - 1 + b) * w[a]
		h += row * v[b]
	return h


static func _bspline(t: float) -> Vector4:
	var t2 := t * t
	var t3 := t2 * t
	var s := 1.0 - t
	return Vector4(s * s * s, 3.0 * t3 - 6.0 * t2 + 4.0, -3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0, t3) / 6.0


## Ground height (as drawn, at full detail).
func height_at(x: float, z: float) -> float:
	var b := base_height(x, z)
	var land := clampf((b - 0.5) / 3.0, 0.0, 1.0)
	if land <= 0.0:
		return b # the sea floor: no relief (most of the map)
	var dry := 1.0 - swampiness(x, z)
	if dry <= 0.0:
		return b
	return b + detail(x, z) * land * dry


## How much of a swamp (x, z) is in, 0..1: the four nearest biome texels
## blended, as in height_map.gdshaderinc (no fine relief there).
func swampiness(x: float, z: float) -> float:
	if _biome_size == 0 or swamp < 0:
		return 0.0
	var g := (Vector2(x, z) - origin) / (domain + cell()) * _biome_size - Vector2(0.5, 0.5)
	var i := floori(g.x)
	var j := floori(g.y)
	var fx := g.x - i
	var fz := g.y - j
	var n := _biome_size - 1
	var i0 := clampi(i, 0, n)
	var i1 := clampi(i + 1, 0, n)
	var r0 := clampi(j, 0, n) * _biome_size
	var r1 := clampi(j + 1, 0, n) * _biome_size
	var a := 1.0 if _biome_bytes[r0 + i0] == swamp else 0.0
	var b := 1.0 if _biome_bytes[r0 + i1] == swamp else 0.0
	var c := 1.0 if _biome_bytes[r1 + i0] == swamp else 0.0
	var d := 1.0 if _biome_bytes[r1 + i1] == swamp else 0.0
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz)


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


## Water surface over (x, z): Vector3(level, flow x, flow z). Only the sea
## (level 0, still) for now.
func water_at(_x: float, _z: float) -> Vector3:
	return Vector3.ZERO
