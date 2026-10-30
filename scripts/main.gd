extends Node3D
## Builds the scene: sky, sun, the simulated island (terrain + inland water on
## one CDLOD quadtree), the ocean, the player and the HUD. The island is
## simulated on a worker thread the first time, then loaded from the cache.

const SEED := 1337

var island: IslandData
var cdlod: Cdlod
var collider: TerrainCollider
var player: Player
var hud: Hud
var env: Environment
var ocean: MeshInstance3D
var ocean_material: ShaderMaterial
var _sun: DirectionalLight3D
var _thread: Thread
var _status := ""
var _mutex := Mutex.new()


func _ready() -> void:
	_build_environment()
	player = Player.new()
	add_child(player)
	player.global_position = Vector3(0, 300, 0)
	hud = Hud.new()
	hud.player = player
	add_child(hud)
	_thread = Thread.new()
	_thread.start(_generate)


func _generate() -> void:
	var preset := "test" if OS.get_cmdline_user_args().has("--test") else "full"
	var gen := IslandGenerator.new(SEED, preset)
	gen.progress = func(m: String) -> void:
		_mutex.lock()
		_status = m
		_mutex.unlock()
	var data := gen.generate(preset)
	_on_generated.call_deferred(data)


func _on_generated(data: IslandData) -> void:
	_thread.wait_to_finish()
	island = data
	island.make_textures()
	print("island: ", island.stats)

	var terrain_mat := ShaderMaterial.new()
	terrain_mat.shader = load("res://shaders/render/terrain.gdshader")
	terrain_mat.set_shader_parameter("material_tex", island.material_tex)
	terrain_mat.set_shader_parameter("wattr_tex", island.wattr_tex)
	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://shaders/render/inland_water.gdshader")
	water_mat.set_shader_parameter("water_tex", island.water_tex)
	water_mat.set_shader_parameter("wattr_tex", island.wattr_tex)
	water_mat.set_shader_parameter("sun_direction", _sun.global_basis.z)
	cdlod = Cdlod.new()
	add_child(cdlod)
	cdlod.setup(island, [terrain_mat, water_mat])

	ocean_material = ShaderMaterial.new()
	ocean_material.shader = load("res://shaders/render/ocean.gdshader")
	ocean_material.set_shader_parameter("sun_direction", _sun.global_basis.z)
	ocean_material.set_shader_parameter("height_tex", island.height_tex)
	ocean_material.set_shader_parameter("map_size", float(island.size))
	ocean_material.set_shader_parameter("map_domain", island.domain)
	ocean_material.set_shader_parameter("map_origin", island.origin)
	ocean = MeshInstance3D.new()
	ocean.mesh = _ocean_mesh()
	ocean.material_override = ocean_material
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ocean.extra_cull_margin = 16.0
	add_child(ocean)
	# Below the sea, beyond the island's domain: the ocean floor.
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60000, 60000)
	floor_mi.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.27, 0.24)
	floor_mi.material_override = floor_mat
	floor_mi.position.y = IslandGenerator.OCEAN_FLOOR - 0.5
	add_child(floor_mi)

	collider = TerrainCollider.new()
	collider.island = island
	add_child(collider)
	player.island = island
	var s := island.spawn
	player.global_position = Vector3(s.x, island.height_at(s.x, s.z) + 1.0, s.z)
	collider.follow(player.global_position)
	player.frozen = false
	hud.status.text = ""


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.3, 0.5, 0.8)
	sky_mat.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky_mat.ground_horizon_color = Color(0.7, 0.8, 0.9)
	sky_mat.ground_bottom_color = Color(0.2, 0.3, 0.4)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.78, 0.88)
	env.fog_density = 0.00012
	env.fog_aerial_perspective = 0.7
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-38, -35, 0)
	_sun.light_energy = 1.2
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 600.0
	add_child(_sun)


## Radial grid centred on the camera: ~0.5 m spacing up close, growing
## geometrically to the horizon. UV.x carries the local spacing for the shader.
func _ocean_mesh() -> ArrayMesh:
	const SEGMENTS := 192
	var radii := PackedFloat32Array([0.0])
	var r := 0.0
	while r < 30000.0:
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


func _process(_delta: float) -> void:
	if island == null:
		_mutex.lock()
		hud.status.text = _status
		_mutex.unlock()
		return
	var cam := player.camera.global_position
	cdlod.update(cam)
	ocean_material.set_shader_parameter("view_pos", cam)
	# Snap the ocean grid to a coarse step so its vertices don't swim.
	ocean.global_position = Vector3(snappedf(cam.x, 4.0), 0.0, snappedf(cam.z, 4.0))
	collider.follow(player.global_position)
	var under := cam.y < island.water_at(cam.x, cam.z).x
	env.fog_density = 0.06 if under else 0.00012
	env.fog_light_color = Color(0.05, 0.22, 0.28) if under else Color(0.68, 0.78, 0.88)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
