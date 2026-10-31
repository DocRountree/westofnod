extends Node3D
## Builds the world: the Galapagos archipelago (real elevation data baked by
## tools/dem/bake_galapagos.py) on one CDLOD quadtree, the ocean, scattered
## trees, sky and atmosphere, the player.

var world: WorldData
var cdlod: Cdlod
var collider: TerrainCollider
var player: Player
var hud: Hud
var env: Environment
var ocean: MeshInstance3D
var ocean_material: ShaderMaterial
var terrain_material: ShaderMaterial
var fields: Array[ScatterField] = []

const TREES_END := 1800.0 # where the far trees have dithered out
const FAR_FADE := 0.6 # ... starting at this fraction of TREES_END
const FAR_CELL := 14.0 # far tree cell (terrain.gdshader reproduces their placement)
const FAR_SCALE := 1.35
var config: WorldConfig
var clock: GameClock
var atmosphere: Atmosphere
var aurora: Aurora
var _sun: DirectionalLight3D
var _sea_sign := Vector2.ONE   # the ocean's coordinates relative to the world's (see _wrap)
var _sea_offset := Vector2.ZERO
var _last_x := 0.0
var _hazed: Array[ShaderMaterial] = []
var _under := false


func _ready() -> void:
	_build_environment()
	world = WorldData.new().load_world()

	var terrain_mat := ShaderMaterial.new()
	terrain_material = terrain_mat
	terrain_mat.shader = load("res://shaders/render/terrain.gdshader")
	terrain_mat.set_shader_parameter("mask_tex", world.mask_tex)
	cdlod = Cdlod.new()
	add_child(cdlod)
	cdlod.setup(world, [terrain_mat])

	ocean_material = ShaderMaterial.new()
	ocean_material.shader = load("res://shaders/render/ocean.gdshader")
	ocean_material.set_shader_parameter("sun_direction", _sun.global_basis.z)
	_set_map(ocean_material)
	ocean = MeshInstance3D.new()
	ocean.mesh = _ocean_mesh()
	ocean.material_override = ocean_material
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ocean.extra_cull_margin = 16.0
	add_child(ocean)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400000, 400000)
	floor_mi.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.32, 0.28)
	floor_mi.material_override = floor_mat
	floor_mi.position.y = WorldData.OCEAN_FLOOR - 0.5
	add_child(floor_mi)

	# Trees: detailed near (with shadows); simple crowns farther out, larger and
	# sparser, no shadows; the two bands cross-fade. As the far trees dither
	# out, the terrain draws each of them as a flat crown in exactly its place
	# (same cells, same hash: see terrain.gdshader), out to the horizon.
	var tree_shader: Shader = load("res://shaders/render/tree.gdshader")
	var near_trees := ScatterField.new(world, PropMeshes.tree(1, 3), tree_shader, 7.0, 260.0, Vector2(-1, 0))
	var far_trees := ScatterField.new(world, PropMeshes.tree(0, 5), tree_shader, FAR_CELL, TREES_END,
			Vector2(190.0, 250.0), {"size_scale": FAR_SCALE})
	far_trees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	far_trees.material.set_shader_parameter("fade_out_start", TREES_END * FAR_FADE)
	fields.append_array([near_trees, far_trees])
	for f in fields:
		add_child(f)
	terrain_mat.set_shader_parameter("canopy_start", TREES_END * FAR_FADE)
	terrain_mat.set_shader_parameter("canopy_cell", FAR_CELL)
	terrain_mat.set_shader_parameter("canopy_scale", FAR_SCALE)
	terrain_mat.set_shader_parameter("sun_direction", _sun.global_basis.z)

	# Aerial perspective (aerial.gdshaderinc) needs the sun on every surface it hazes.
	_hazed = [terrain_mat, ocean_material]
	for f in fields:
		_hazed.append(f.material)
	for m in _hazed:
		m.set_shader_parameter("haze_sun_dir", _sun.global_basis.z)

	collider = TerrainCollider.new()
	collider.world = world
	add_child(collider)
	player = Player.new()
	player.world = world
	add_child(player)
	player.avatar.world = world
	player.global_position = world.spawn
	_last_x = world.spawn.x
	aurora.min_latitude = latitude_at(world.big_island_north_z)
	_update_position_on_planet()
	collider.follow(player.global_position)
	player.frozen = false
	hud = Hud.new()
	hud.player = player
	add_child(hud)
	hud.status.text = ""


func _set_map(m: ShaderMaterial) -> void:
	m.set_shader_parameter("height_tex", world.height_tex)
	m.set_shader_parameter("map_size", float(world.size))
	m.set_shader_parameter("map_domain", world.domain)
	m.set_shader_parameter("map_origin", world.origin)


func _build_environment() -> void:
	# The sky (after DocRountree/game): a single-scattering atmosphere, the
	# clock, sun, moon, planets, stars, meteors and the rare aurora.
	config = WorldConfig.new()
	WorldConfig.active = config
	clock = GameClock.new()
	clock.time_of_day = 15.5
	add_child(clock)
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky/atmosphere_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL # relight over a few frames as the sun moves
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	# Distance haze is the shaders' aerial perspective (aerial.gdshaderinc), on
	# surfaces only, never the sky; the environment fog is only used under water.
	env.fog_enabled = false
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = false
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_hdr_threshold = 1.6 # only the sun on the water blooms
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 350.0
	_sun.directional_shadow_split_1 = 0.05
	_sun.directional_shadow_split_2 = 0.15
	_sun.directional_shadow_split_3 = 0.4
	add_child(_sun)
	var moonlight := DirectionalLight3D.new()
	moonlight.light_color = Color(0.75, 0.83, 1.0)
	moonlight.light_energy = 0.0
	add_child(moonlight)
	var starfield := Starfield.new()
	starfield.catalog = load("res://data/bright_stars.tres")
	starfield.material_override = _sky_material("starfield", 0)
	var planets := PlanetLayer.new()
	planets.material_override = _sky_material("planet_layer", 1)
	var meteors := Meteors.new()
	meteors.material_override = _sky_material("meteors", 1)
	aurora = Aurora.new()
	aurora.material_override = _sky_material("aurora", 1)
	aurora.material_override.set_shader_parameter("gain", 0.035) # (brighter under our ACES tonemap than the repo's)
	var moon := Moon.new()
	moon.material_override = _sky_material("moon", 1)
	for n: GeometryInstance3D in [starfield, planets, meteors, aurora, moon]:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(n)
	atmosphere = Atmosphere.new()
	atmosphere.clock = clock
	atmosphere.sun = _sun
	atmosphere.world_environment = we
	atmosphere.starfield = starfield
	atmosphere.moon = moon
	atmosphere.planets = planets
	atmosphere.meteors = meteors
	atmosphere.aurora = aurora
	atmosphere.moonlight = moonlight
	add_child(atmosphere)


func _sky_material(name: String, priority: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/sky/%s.gdshader" % name)
	m.render_priority = priority
	return m


## Radial grid centred on the camera: ~0.5 m spacing up close, growing
## geometrically to the horizon. UV.x carries the local spacing for the shader.
func _ocean_mesh() -> ArrayMesh:
	const SEGMENTS := 192
	var radii := PackedFloat32Array([0.0])
	var r := 0.0
	while r < 110000.0: # to just inside the camera's far plane, so no ground shows past it
		r += maxf(0.5, r * 0.035)
		radii.append(r)
	var verts := PackedVector3Array([Vector3.ZERO])
	var uvs := PackedVector2Array([Vector2(0.5, 0)])
	var idx := PackedInt32Array()
	for ri in range(1, radii.size()):
		var sp := maxf(radii[ri] - radii[ri - 1], TAU * radii[ri] / SEGMENTS)
		for k in SEGMENTS:
			var a := TAU * k / SEGMENTS
			verts.append(Vector3(cos(a), 0.0, sin(a)) * radii[ri])
			uvs.append(Vector2(sp, 0))
	for k in SEGMENTS:
		idx.append_array([0, 1 + (k + 1) % SEGMENTS, 1 + k])
	for ri in range(1, radii.size() - 1):
		var a0 := 1 + (ri - 1) * SEGMENTS
		var b0 := a0 + SEGMENTS
		for k in SEGMENTS:
			var k2 := (k + 1) % SEGMENTS
			idx.append_array([a0 + k, a0 + k2, b0 + k, a0 + k2, b0 + k2, b0 + k])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## The world is the map, wrapped like a sphere but drawn flat: x is
## longitude (east-west across the map is once round the planet) and z is
## latitude (the north and south edges of the map are the poles). Off the
## east or west edge you come back on the other; over a pole you come back
## down the same edge half a world along, facing the other way. The edges are
## all deep ocean, so the seams are never seen.
func latitude_at(z: float) -> float:
	var zc := world.origin.y + world.domain * 0.5
	return clampf(-(z - zc) / (world.domain * 0.5) * 90.0, -89.9, 89.9)


func longitude_at(x: float) -> float:
	var xc := world.origin.x + world.domain * 0.5
	return (x - xc) / world.domain * 360.0


func _wrap() -> void:
	var w := world.domain
	var p := player.global_position
	# local time follows the player round the planet (the clock keeps local time)
	_shift_time((p.x - _last_x) / w * 24.0)
	var x0 := world.origin.x
	var z0 := world.origin.y
	var moved := Vector3.ZERO
	if p.x >= x0 + w or p.x < x0:
		var dx := -w if p.x >= x0 + w else w
		p.x += dx
		_sea_offset.x -= _sea_sign.x * dx
		# the seam is the date line: going east across it, a day is taken back
		clock.day += 1 if dx > 0.0 else -1
		moved.x = dx
	if p.z < z0 or p.z >= z0 + w:
		var edge := z0 if p.z < z0 else z0 + w
		var dx := w * 0.5 if p.x < x0 + w * 0.5 else -w * 0.5
		# sea coordinates of the same point before and after: q = s * p + o
		_sea_offset.x -= _sea_sign.x * dx
		_sea_offset.y += _sea_sign.y * 2.0 * edge
		_sea_sign.y = -_sea_sign.y
		p = Vector3(p.x + dx, p.y, 2.0 * edge - p.z)
		player.rotate_y(PI)
		player.velocity = Vector3(-player.velocity.x, player.velocity.y, -player.velocity.z)
		# half a world round: twelve hours on, the same date
		clock.time_of_day = fposmod(clock.time_of_day + 12.0, 24.0)
		moved.x = dx
	if moved != Vector3.ZERO or p != player.global_position:
		player.global_position = p
		if absf(_sea_offset.x) > 3.0 * w or absf(_sea_offset.y) > 3.0 * w:
			_sea_offset = Vector2.ZERO # keep float precision (the waves jump, once in many laps)
		ocean_material.set_shader_parameter("sea_sign", _sea_sign)
		ocean_material.set_shader_parameter("sea_offset", _sea_offset)
	_last_x = player.global_position.x


func _shift_time(hours: float) -> void:
	if hours == 0.0:
		return
	var t := clock.time_of_day + hours
	clock.day += floori(t / 24.0)
	clock.time_of_day = fposmod(t, 24.0)


func _update_position_on_planet() -> void:
	var p := player.global_position
	var lat := latitude_at(p.z)
	config.longitude = longitude_at(p.x)
	if absf(lat - config.latitude) > 0.5:
		config.latitude = lat
		clock.relatitude()
	else:
		config.latitude = lat


## The sun, its light and the colour of the air, onto every surface shader.
func _update_light() -> void:
	var dir := _sun.global_basis.z
	var c := _sun.light_color * (_sun.light_energy / 1.4)
	var sun_col := Vector3(c.r, c.g, c.b)
	var haze := atmosphere.haze_now
	for m in _hazed:
		m.set_shader_parameter("haze_sun_dir", dir)
		m.set_shader_parameter("haze_horizon", Vector3(haze.r, haze.g, haze.b))
		m.set_shader_parameter("haze_sun", sun_col * 0.9 + Vector3(haze.r, haze.g, haze.b) * 0.1)
	ocean_material.set_shader_parameter("sun_direction", dir)
	ocean_material.set_shader_parameter("sun_color", sun_col)
	terrain_material.set_shader_parameter("sun_direction", dir)


## The magnified view (Player.zoom): terrain, trees and shadows pick their
## detail as if everything were zoom times nearer, but only in the wedge seen.
func _magnify(cam: Vector3) -> void:
	var z := player.zoom
	var f := -player.camera.global_basis.z
	var dir := Vector2(f.x, f.z)
	dir = dir.normalized() if dir.length() > 1e-3 else Vector2(0, -1)
	var vp := get_viewport().get_visible_rect().size
	# horizontal half-angle, widened by the pitch (looking up or down, the
	# frustum's footprint spreads sideways) and a margin
	var tan_h := tan(deg_to_rad(player.camera.fov) * 0.5) * vp.x / maxf(vp.y, 1.0)
	tan_h = tan_h / maxf(sqrt(1.0 - f.y * f.y), 0.2) * 1.15 + 0.01
	cdlod.magnify(dir, z, tan_h)
	for m in _hazed:
		m.set_shader_parameter("lod_zoom", z)
	var far: ScatterField = fields[1]
	for fld in fields:
		var reach := fld.magnify(cam, dir, z, tan_h)
		if fld == far:
			# where the far trees end (the budget may end them early), the
			# terrain's flat crowns take over, as without magnification
			var end := minf(TREES_END, reach / z)
			far.material.set_shader_parameter("fade_out_start", end * FAR_FADE)
			far.material.set_shader_parameter("fade_out_end", end)
			terrain_material.set_shader_parameter("canopy_start", end * FAR_FADE)
	_sun.directional_shadow_max_distance = 350.0 * z


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		aurora.set_forced(not aurora.forced) # debug: an aurora every night


func _process(_delta: float) -> void:
	_wrap()
	_update_position_on_planet()
	_update_light()
	var cam := player.camera.global_position
	_magnify(cam)
	cdlod.update(cam)
	for f in fields:
		f.update(cam)
	ocean_material.set_shader_parameter("view_pos", cam)
	ocean.global_position = Vector3(snappedf(cam.x, 4.0), 0.0, snappedf(cam.z, 4.0))
	collider.follow(player.global_position)
	var under := cam.y < world.water_at(cam.x, cam.z).x
	if under != _under:
		_under = under
		env.fog_enabled = under
		env.fog_density = 0.06
		env.fog_light_color = Color(0.05, 0.22, 0.28)
		for m in _hazed:
			m.set_shader_parameter("underwater", under)
