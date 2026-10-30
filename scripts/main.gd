extends Node3D
## Builds the scene: sky/fog, sun, ocean, streamed terrain, player, HUD.

var terrain: TerrainWorld
var player: Player
var hud: Hud
var env: Environment
var ocean: MeshInstance3D
var water_material: ShaderMaterial
var _sun: DirectionalLight3D


func _ready() -> void:
	_build_environment()

	var water_shader: Shader = load("res://shaders/water.gdshader")
	var ocean_material := ShaderMaterial.new()
	ocean_material.shader = water_shader
	ocean = MeshInstance3D.new()
	ocean.mesh = _ocean_mesh()
	ocean_material.set_shader_parameter("amplitude", 0.6)
	ocean_material.set_shader_parameter("sun_direction", _sun.global_basis.z)
	ocean.material_override = ocean_material
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ocean.extra_cull_margin = 16.0
	add_child(ocean)
	# Rivers and lakes: the same waves shrunk to short, low ripples, in
	# siltier water; rivers carry their flow in the mesh UVs.
	water_material = ShaderMaterial.new()
	water_material.shader = water_shader
	water_material.set_shader_parameter("amplitude", 0.35)
	water_material.set_shader_parameter("length_scale", 0.12)
	water_material.set_shader_parameter("mesh_spacing", TerrainWorld.NEAR_SPACING)
	water_material.set_shader_parameter("murk", 0.12)
	water_material.set_shader_parameter("silt_color", Vector3(0.07, 0.09, 0.06))
	water_material.set_shader_parameter("sun_direction", _sun.global_basis.z)
	var far_water := water_material.duplicate()
	far_water.set_shader_parameter("near_cutoff", TerrainWorld.FAR_CUTOFF)
	far_water.set_shader_parameter("mesh_spacing", TerrainWorld.FAR_SPACING)

	terrain = TerrainWorld.new()
	terrain.water_material = water_material
	terrain.far_water_material = far_water
	add_child(terrain)
	terrain.spawn_found.connect(_on_spawn_found)

	player = Player.new()
	player.terrain = terrain
	add_child(player)
	player.global_position = Vector3(0, 160, 0)

	hud = Hud.new()
	hud.player = player
	add_child(hud)
	hud.status.text = "Generating archipelago..."


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.52, 0.82)
	sky_mat.sky_horizon_color = Color(0.68, 0.79, 0.9)
	sky_mat.ground_horizon_color = Color(0.68, 0.79, 0.9)
	sky_mat.ground_bottom_color = Color(0.2, 0.3, 0.4)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.ambient_light_sky_contribution = 0.6
	env.ambient_light_color = Color(0.75, 0.75, 0.7)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.78, 0.88)
	env.fog_density = 0.00035
	env.fog_aerial_perspective = 0.6
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-38, -35, 0)
	_sun.light_energy = 1.15
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 160.0
	add_child(_sun)


## Radial grid centred on the camera: ~0.5 m spacing up close, growing
## geometrically out to the horizon, so Gerstner waves have vertices to move.
func _ocean_mesh() -> ArrayMesh:
	const SEGMENTS := 192
	var radii := PackedFloat32Array([0.0])
	var r := 0.0
	while r < 9000.0:
		r += maxf(0.5, r * 0.035)
		radii.append(r)
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	verts.append(Vector3.ZERO)
	for ri in range(1, radii.size()):
		for k in SEGMENTS:
			var a := TAU * k / SEGMENTS
			verts.append(Vector3(cos(a), 0.0, sin(a)) * radii[ri])
	for k in SEGMENTS:
		var k2 := (k + 1) % SEGMENTS
		idx.append_array([0, 1 + k2, 1 + k])
	for ri in range(1, radii.size() - 1):
		var a0 := 1 + (ri - 1) * SEGMENTS
		var b0 := a0 + SEGMENTS
		for k in SEGMENTS:
			var k2 := (k + 1) % SEGMENTS
			idx.append_array([a0 + k, a0 + k2, b0 + k, a0 + k2, b0 + k2, b0 + k])
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _on_spawn_found(pos: Vector3) -> void:
	player.global_position = pos + Vector3(0, 40, 0)
	hud.status.text = "Loading terrain..."


func _process(_delta: float) -> void:
	var p := player.global_position
	ocean.global_position = Vector3(snappedf(p.x, 2.0), 0.0, snappedf(p.z, 2.0))
	if terrain.spawned:
		terrain.focus = p
		if player.frozen and terrain.has_collision_at(p):
			var h := terrain.height_at(p.x, p.z)
			player.global_position = Vector3(p.x, h + 0.5, p.z)
			player.frozen = false
			hud.status.text = ""
	var under := player.camera.global_position.y < 0.0
	env.fog_density = 0.06 if under else 0.00035
	env.fog_light_color = Color(0.05, 0.25, 0.35) if under else Color(0.68, 0.78, 0.88)
