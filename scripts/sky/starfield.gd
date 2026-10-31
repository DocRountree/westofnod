@tool
class_name Starfield
extends MultiMeshInstance3D
## The fixed sky as one instanced draw: stars (white points) and Messier
## objects (grey smudges at their true angular size and orientation). The
## planets wander, so they live on their own layer (PlanetLayer).
##
## Everything sits on a big sphere around the camera in equatorial coordinates;
## Atmosphere rotates the node into the local sky for the date and time.
## Per instance: COLOR.rgb = colour; CUSTOM = (brightness, kind, size px, 0)
## with kind 0 star, 2 deep-sky object (ellipse in the instance basis).

const RADIUS := 100000.0        ## Beyond the farthest land, inside the camera's far plane.
const STAR_SIZE_PX := 2.7       ## Stars are points: every star the same size.
const FAINT_PATH := "res://data/faint_stars.f32" ## Telescopic stars (see _build).
## Messier numbers by kind (the catalogue's deep-sky list is M1..M110 in order).
const OPEN_CLUSTERS := [6, 7, 11, 18, 21, 23, 25, 26, 29, 34, 35, 36, 37, 38, 39, 41, 44, 45, 46, 47, 48, 50, 52, 67, 93, 103]
const GLOBULARS := [2, 3, 4, 5, 9, 10, 12, 13, 14, 15, 19, 22, 28, 30, 53, 54, 55, 56, 62, 68, 69, 70, 71, 72, 75, 79, 80, 92, 107]
const NEBULAE := [1, 8, 16, 17, 20, 27, 42, 43, 57, 76, 78, 97]
# (Globular clusters only resolve in bigger telescopes than 8x: they stay glows.)

@export var catalog: StarCatalog
## Uniform boost over real brightness: a magnitude-1 star draws at this level
## (1 = screen white). Brighter stars bloom; magnitude 6 is a faint dot.
@export var brightness := 2.4


func _ready() -> void:
	_build()


func _build() -> void:
	if catalog == null:
		return
	var stars := catalog.star_count()
	var dsos := catalog.deep_sky_count()
	var faint := _load_faint()
	var extra := _galaxy_nuclei()
	var n := stars + dsos + faint.size() / 4 + extra.size()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = QuadMesh.new()
	mm.instance_count = n
	var buf := PackedFloat32Array()
	buf.resize(n * 20)   # 12 transform + 4 colour + 4 custom
	var s := catalog.stars
	for i in stars:
		_write(buf, i, Basis(), _unit(s[i * 3], s[i * 3 + 1]), Color.WHITE,
				brightness * _flux(s[i * 3 + 2]), 0.0, STAR_SIZE_PX)
	var d := catalog.deep_sky
	for j in dsos:
		var o := j * 6
		var ra := d[o]
		var dec := d[o + 1]
		var pa := deg_to_rad(d[o + 5])
		# sky-plane axes at the object: north (toward the pole) and east
		var north := Vector3(-sin(dec) * cos(ra), -sin(dec) * sin(ra), cos(dec))
		var east := Vector3(-sin(ra), cos(ra), 0.0)
		var major := north * cos(pa) + east * sin(pa)
		var minor := east * cos(pa) - north * sin(pa)
		# the quad spans twice the object's diameter so its soft edge can fade out
		var arcmin := deg_to_rad(1.0 / 60.0) * RADIUS * 2.0
		var basis := Basis(major * d[o + 3] * arcmin, minor * d[o + 4] * arcmin, _unit(ra, dec))
		_write(buf, stars + j, basis, _unit(ra, dec), Color.WHITE,
				brightness * _deep_sky_glow(d[o + 2], d[o + 3], d[o + 4]), 2.0, 0.0,
				1.0 if (j + 1) in OPEN_CLUSTERS else 0.0)
	# Stars too faint for the eye (V 6.5 to 10.5, from HYG/Hipparcos: see
	# tools/build_faint_stars.py), seen through a telescope: the real ones, so
	# magnified clusters split into their real stars.
	for k in faint.size() / 4:
		_write(buf, stars + dsos + k, Basis(), _unit(faint[k * 4], faint[k * 4 + 1]), _bv_colour(faint[k * 4 + 3]),
				brightness * _flux(faint[k * 4 + 2]), 0.0, STAR_SIZE_PX)
	var e := stars + dsos + faint.size() / 4
	for x: Array in extra:
		_write(buf, e, x[0], x[1], x[2], x[3], x[4], x[5])
		e += 1
	mm.buffer = buf
	mm.custom_aabb = AABB(Vector3.ONE * -RADIUS, Vector3.ONE * RADIUS * 2.0)
	multimesh = mm
	custom_aabb = mm.custom_aabb


## Place the sky: basis maps equatorial coordinates into the world; visibility 0..1.
func update_sky(equatorial_to_world: Basis, visibility: float) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam:
		global_transform = Transform3D(equatorial_to_world, cam.global_position)
		var mat := material_override as ShaderMaterial
		mat.set_shader_parameter("visibility", visibility)
		mat.set_shader_parameter("pixel_angle", deg_to_rad(cam.fov) / maxf(get_viewport().get_visible_rect().size.y, 1.0))
		# magnification (from the field of view) squared: a telescope's light grasp
		var zoom := tan(deg_to_rad(75.0) * 0.5) / tan(deg_to_rad(cam.fov) * 0.5)
		mat.set_shader_parameter("gain", maxf(zoom * zoom, 1.0))
		for c in get_children():
			if c is MilkyWay:
				c.update_sky(visibility, deg_to_rad(cam.fov) / maxf(get_viewport().get_visible_rect().size.y, 1.0), maxf(zoom * zoom, 1.0))
	visible = visibility > 0.0


func _write(buf: PackedFloat32Array, i: int, basis: Basis, dir: Vector3, colour: Color,
		bright: float, kind: float, size_px: float, resolves := 0.0) -> void:
	var p := dir * RADIUS
	var o := i * 20
	buf[o] = basis.x.x      # rows of the 3x4 transform
	buf[o + 1] = basis.y.x
	buf[o + 2] = basis.z.x
	buf[o + 3] = p.x
	buf[o + 4] = basis.x.y
	buf[o + 5] = basis.y.y
	buf[o + 6] = basis.z.y
	buf[o + 7] = p.y
	buf[o + 8] = basis.x.z
	buf[o + 9] = basis.y.z
	buf[o + 10] = basis.z.z
	buf[o + 11] = p.z
	buf[o + 12] = colour.r
	buf[o + 13] = colour.g
	buf[o + 14] = colour.b
	buf[o + 15] = 1.0
	buf[o + 16] = bright
	buf[o + 17] = kind
	buf[o + 18] = size_px
	buf[o + 19] = resolves


func _load_faint() -> PackedFloat32Array:
	var f := FileAccess.open(FAINT_PATH, FileAccess.READ)
	if f == null:
		return PackedFloat32Array()
	return f.get_buffer(f.get_length()).to_float32_array()


## The galaxies' bright nuclei (small and star-like in M31, M32, M81...): a
## compact glow at the centre of each, a few arcminutes across, that a
## telescope brings out of the faint disc. Each: [basis, dir, colour,
## brightness, kind, size px].
func _galaxy_nuclei() -> Array:
	var out := []
	var d := catalog.deep_sky
	var arcmin := deg_to_rad(1.0 / 60.0) * RADIUS * 2.0
	for j in catalog.deep_sky_count():
		var m := j + 1
		if m in OPEN_CLUSTERS or m in GLOBULARS or m in NEBULAE or m == 40 or m == 73:
			continue # (M40 and M73 are star groupings)
		var o := j * 6
		var ra := d[o]
		var dec := d[o + 1]
		var c := _unit(ra, dec)
		var north := Vector3(-sin(dec) * cos(ra), -sin(dec) * sin(ra), cos(dec))
		var east := Vector3(-sin(ra), cos(ra), 0.0)
		var size := clampf(d[o + 3] * 0.04, 0.5, 3.0) * arcmin
		out.append([Basis(east * size, north * size, c), c, Color(1.0, 0.95, 0.85),
				brightness * _deep_sky_glow(d[o + 2], d[o + 3], d[o + 4]) * 2.5, 2.0, 0.0])
	return out


## Star colour from the B-V index: blue-white (-0.3) through white and yellow
## to orange-red (2), gently, as the eye sees it.
static func _bv_colour(bv: float) -> Color:
	var t := clampf((bv + 0.3) / 2.3, 0.0, 1.0)
	var c := Color(0.75, 0.84, 1.0).lerp(Color(1.0, 0.97, 0.92), smoothstep(0.0, 0.35, t))
	return c.lerp(Color(1.0, 0.72, 0.48), smoothstep(0.35, 1.0, t))


static func _unit(ra: float, dec: float) -> Vector3:
	return Vector3(cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec))


# True relative brightness from magnitude (2.512x per magnitude), 1 at magnitude 1.
# The only boost is the uniform `brightness` multiplier on every object.
static func _flux(magnitude: float) -> float:
	return pow(10.0, -0.4 * (magnitude - 1.0))


# Peak glow of a deep-sky object: its light spread over its area, boosted so
# the big naked-eye ones (M31, M42, M45) read as faint smudges, as they do outdoors.
static func _deep_sky_glow(magnitude: float, major: float, minor: float) -> float:
	var surface := pow(10.0, -0.4 * (magnitude - 4.0)) / sqrt(major * minor / 100.0 + 1.0)
	return clampf(0.012 * sqrt(surface), 0.0, 0.035)
