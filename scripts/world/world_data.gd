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


## A biome for something placed at (x, z) (Population: its trees, stumps,
## rocks), picked among the biomes there by their shares, as the ground
## blends them (ground.gdshaderinc: biome_grid, biome_texel; the borders
## wandering and the sixteen nearest texels by a cubic B-spline): across a
## border, about 200 m, the one thins out as the other comes in, and each
## reaches into the other here and there. u: 0..1, the pick (a hash of the
## place, so the same each time). -1 where none.
func biome_blend_at(x: float, z: float, u: float) -> int:
	if _biome_size == 0:
		return -1
	var jx := (vnoise(x / 1400.0 + 3.3, z / 1400.0 + 3.3) - 0.5) * 1100.0 + (vnoise(x / 90.0, z / 90.0) - 0.5) * 180.0 + (vnoise(x / 23.0 + 5.1, z / 23.0 + 5.1) - 0.5) * 50.0
	var jz := (vnoise(x / 1400.0 - 12.9, z / 1400.0 - 12.9) - 0.5) * 1100.0 + (vnoise(x / 90.0 + 31.7, z / 90.0 + 31.7) - 0.5) * 180.0 + (vnoise(x / 23.0 - 8.3, z / 23.0 - 8.3) - 0.5) * 50.0
	var g := (Vector2(x + jx, z + jz) - origin) / (domain + cell()) * _biome_size - Vector2(0.5, 0.5)
	var i0 := floori(g.x) - 1
	var j0 := floori(g.y) - 1
	var wx := _bspline(g.x - floorf(g.x))
	var wz := _bspline(g.y - floorf(g.y))
	var n := _biome_size - 1
	var acc := 0.0
	var b := 255
	for j in 4:
		for i in 4:
			acc += wx[i] * wz[j]
			b = _biome_bytes[clampi(j0 + j, 0, n) * _biome_size + clampi(i0 + i, 0, n)]
			if u < acc:
				return b if b < biome_names.size() else -1
	return b if b < biome_names.size() else -1


## Every biome with any share at (x, z) as the ground blends them
## (biome_blend_at: the sixteen texels round the wandering point), as bits
## (1 << biome index; none: no bit). GroundCover: which of its tiles can
## grow anything.
func biome_bits_at(x: float, z: float) -> int:
	if _biome_size == 0:
		return 0
	var jx := (vnoise(x / 1400.0 + 3.3, z / 1400.0 + 3.3) - 0.5) * 1100.0 + (vnoise(x / 90.0, z / 90.0) - 0.5) * 180.0 + (vnoise(x / 23.0 + 5.1, z / 23.0 + 5.1) - 0.5) * 50.0
	var jz := (vnoise(x / 1400.0 - 12.9, z / 1400.0 - 12.9) - 0.5) * 1100.0 + (vnoise(x / 90.0 + 31.7, z / 90.0 + 31.7) - 0.5) * 180.0 + (vnoise(x / 23.0 - 8.3, z / 23.0 - 8.3) - 0.5) * 50.0
	var g := (Vector2(x + jx, z + jz) - origin) / (domain + cell()) * _biome_size - Vector2(0.5, 0.5)
	var i0 := floori(g.x) - 1
	var j0 := floori(g.y) - 1
	var n := _biome_size - 1
	var bits := 0
	for j in 4:
		for i in 4:
			var b := _biome_bytes[clampi(j0 + j, 0, n) * _biome_size + clampi(i0 + i, 0, n)]
			if b < 31:
				bits |= 1 << b
	return bits


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


## How far into the swamp (x, z) is: 0 at its edge (or out of it), 1 some
## 700 m or more in: the share of the swamp round it on two rings (300 m
## and 700 m), half of it at the edge.
func swamp_depth(x: float, z: float) -> float:
	if swamp < 0:
		return 0.0
	var n := 0
	for r in [300.0, 700.0]:
		for k in 10:
			var a := TAU * (k + (0.5 if r > 400.0 else 0.0)) / 10.0
			if biome_index_at(x + cos(a) * r, z + sin(a) * r) == swamp:
				n += 1
	return smoothstep(0.5, 1.0, n / 20.0)


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


## The ground's height and normal at (x, z) at once: Vector4(height, the
## normal's x, y, z). The height is height_at()'s, to the last bit; the
## normal from the slope worked out alongside it (the B-spline's and the
## relief's derivatives, the swamp's smoothing taken as level), not by
## differences: one evaluation where height_at() and normal_at() took five.
## (The player and actors move by it; Population still places by
## normal_at(), so the trees stand where they always have.)
func surface_at(x: float, z: float) -> Vector4:
	var c := cell()
	var gx := (x - origin.x) / c
	var gz := (z - origin.y) / c
	var i := floori(gx)
	var j := floori(gz)
	var w := _bspline(gx - i)
	var v := _bspline(gz - j)
	var dw := _dbspline(gx - i)
	var dv := _dbspline(gz - j)
	var b := 0.0
	var bx := 0.0
	var bz := 0.0
	var inside := i >= 1 and j >= 1 and i + 2 < size and j + 2 < size
	for r in 4:
		var s0: float
		var s1: float
		var s2: float
		var s3: float
		if inside:
			var k := (j - 1 + r) * size + i - 1
			s0 = heights[k]
			s1 = heights[k + 1]
			s2 = heights[k + 2]
			s3 = heights[k + 3]
		else:
			s0 = _sample(i - 1, j - 1 + r)
			s1 = _sample(i, j - 1 + r)
			s2 = _sample(i + 1, j - 1 + r)
			s3 = _sample(i + 2, j - 1 + r)
		var row := s0 * w.x + s1 * w.y + s2 * w.z + s3 * w.w
		b += row * v[r]
		bx += (s0 * dw.x + s1 * dw.y + s2 * dw.z + s3 * dw.w) * v[r]
		bz += row * dv[r]
	var g := Vector2(bx, bz) / c
	var h := b
	var lr := (b - 0.5) / 3.0
	var land := clampf(lr, 0.0, 1.0)
	if land > 0.0:
		var dry := 1.0 - swampiness(x, z)
		if dry > 0.0:
			var d := 0.0
			var dg := Vector2.ZERO
			for k in DETAIL.size():
				var o: Vector2 = DETAIL[k]
				var n := _vnoise_grad(x / o.x + 17.0 * k, z / o.x - 9.0 * k)
				d += (n.x - 0.5) * 2.0 * o.y
				dg += Vector2(n.y, n.z) / o.x * 2.0 * o.y
			h = b + d * land * dry
			var gb := g
			g += dg * land * dry
			if lr < 1.0:
				g += gb * d * dry / 3.0 # (the relief coming in up the shore)
	var nrm := Vector3(-g.x, 1.0, -g.y).normalized()
	return Vector4(h, nrm.x, nrm.y, nrm.z)


## The B-spline's weights' derivatives (_bspline(), d/dt).
static func _dbspline(t: float) -> Vector4:
	var s := 1.0 - t
	return Vector4(-0.5 * s * s, 1.5 * t * t - 2.0 * t, -1.5 * t * t + t + 0.5, 0.5 * t * t)


## vnoise() (its value, to the bit) and its slope: Vector3(value, d/dx, d/dz).
static func _vnoise_grad(x: float, z: float) -> Vector3:
	var i := floori(x)
	var j := floori(z)
	var fx := x - i
	var fz := z - j
	var ux := fx * fx * fx * (fx * (fx * 6.0 - 15.0) + 10.0)
	var uz := fz * fz * fz * (fz * (fz * 6.0 - 15.0) + 10.0)
	var dux := 30.0 * fx * fx * (fx * (fx - 2.0) + 1.0)
	var duz := 30.0 * fz * fz * (fz * (fz - 2.0) + 1.0)
	var a := _hash(i, j)
	var b := _hash(i + 1, j)
	var c := _hash(i, j + 1)
	var d := _hash(i + 1, j + 1)
	var value := lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uz)
	var k3 := a - b - c + d
	return Vector3(value, dux * (b - a + k3 * uz), duz * (c - a + k3 * ux))


## Surface normal at (x, z).
func normal_at(x: float, z: float) -> Vector3:
	var e := 1.0
	return Vector3(height_at(x - e, z) - height_at(x + e, z), 2.0 * e,
			height_at(x, z - e) - height_at(x, z + e)).normalized()


## Water surface over (x, z): Vector3(level, flow x, flow z). Only the sea
## (level 0, still) for now.
func water_at(_x: float, _z: float) -> Vector3:
	return Vector3.ZERO
