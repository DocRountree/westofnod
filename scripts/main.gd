extends Node3D
## Builds the vertical slice: real terrain (Hanalei, Kauai, from USGS elevation
## data baked by tools/dem/bake_slice.py) on one CDLOD quadtree, river meshes,
## the ocean, scattered trees, rocks and grass, sky and atmosphere, the player.

var world: WorldData
var cdlod: Cdlod
var collider: TerrainCollider
var player: Player
var hud: Hud
var env: Environment
var ocean: MeshInstance3D
var ocean_material: ShaderMaterial
var river_material: ShaderMaterial
var fields: Array[ScatterField] = []
var _sun: DirectionalLight3D


func _ready() -> void:
	_build_environment()
	world = WorldData.new().load_slice()

	var terrain_mat := ShaderMaterial.new()
	terrain_mat.shader = load("res://shaders/render/terrain.gdshader")
	terrain_mat.set_shader_parameter("mask_tex", world.mask_tex)
	cdlod = Cdlod.new()
	add_child(cdlod)
	cdlod.setup(world, [terrain_mat])

	river_material = ShaderMaterial.new()
	river_material.shader = load("res://shaders/render/river.gdshader")
	river_material.set_shader_parameter("sun_direction", _sun.global_basis.z)
	var rivers := MeshInstance3D.new()
	rivers.mesh = RiverMeshes.build(world)
	rivers.material_override = river_material
	rivers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rivers)

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
	plane.size = Vector2(80000, 80000)
	floor_mi.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.32, 0.28)
	floor_mi.material_override = floor_mat
	floor_mi.position.y = WorldData.OCEAN_FLOOR - 0.5
	add_child(floor_mi)

	# Props: near trees in detail, far trees as simpler crowns (the two bands
	# cross-fade), then the terrain's canopy colour beyond; rocks; grass.
	var tree_shader: Shader = load("res://shaders/render/tree.gdshader")
	fields.append(ScatterField.new(world, PropMeshes.tree(1, 3), tree_shader, 7.0, 320.0, Vector2(-1, 0)))
	fields.append(ScatterField.new(world, PropMeshes.tree(0, 5), tree_shader, 7.0, 1800.0, Vector2(220, 300)))
	fields.append(ScatterField.new(world, PropMeshes.rock(11), load("res://shaders/render/rock.gdshader"),
			5.0, 300.0, Vector2(-1, 0)))
	var grass := ScatterField.new(world, PropMeshes.grass(13), load("res://shaders/render/grass.gdshader"),
			0.8, 45.0, Vector2(-1, 0))
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fields.append(grass)
	for f in fields:
		add_child(f)
	# The far trees' outer band must match the terrain's switch to canopy colour.
	terrain_mat.set_shader_parameter("trees_end", 1800.0)

	collider = TerrainCollider.new()
	collider.world = world
	add_child(collider)
	player = Player.new()
	player.world = world
	add_child(player)
	player.global_position = world.spawn
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
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.24, 0.42, 0.72)
	sky_mat.sky_horizon_color = Color(0.68, 0.76, 0.84)
	sky_mat.sky_curve = 0.12
	# Below the horizon (past the ocean grid's edge, seen from high up): the hazy sea.
	sky_mat.ground_horizon_color = Color(0.6, 0.68, 0.76)
	sky_mat.ground_bottom_color = Color(0.32, 0.42, 0.5)
	sky_mat.ground_curve = 0.5
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
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
	# Aerial perspective: distant ridges fade into the sky's colour.
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.72, 0.84)
	env.fog_density = 0.00022
	env.fog_aerial_perspective = 0.85
	env.fog_sky_affect = 0.0
	env.fog_height = 400.0
	env.fog_height_density = 0.0006
	# Haze that hangs in the valleys and catches the sun.
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0009
	env.volumetric_fog_albedo = Color(0.9, 0.93, 1.0)
	env.volumetric_fog_length = 400.0
	env.volumetric_fog_anisotropy = 0.3
	env.glow_enabled = true
	env.glow_intensity = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	# Late afternoon: low enough to rake the ridges.
	_sun.rotation_degrees = Vector3(-24, -55, 0)
	_sun.light_energy = 1.4
	_sun.light_color = Color(1.0, 0.95, 0.86)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 800.0
	_sun.directional_shadow_split_1 = 0.05
	_sun.directional_shadow_split_2 = 0.15
	_sun.directional_shadow_split_3 = 0.4
	add_child(_sun)


## Radial grid centred on the camera: ~0.5 m spacing up close, growing
## geometrically to the horizon. UV.x carries the local spacing for the shader.
func _ocean_mesh() -> ArrayMesh:
	const SEGMENTS := 192
	var radii := PackedFloat32Array([0.0])
	var r := 0.0
	while r < 40000.0:
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
	var cam := player.camera.global_position
	cdlod.update(cam)
	for f in fields:
		f.update(cam)
	ocean_material.set_shader_parameter("view_pos", cam)
	ocean.global_position = Vector3(snappedf(cam.x, 4.0), 0.0, snappedf(cam.z, 4.0))
	collider.follow(player.global_position)
	var under := cam.y < world.water_at(cam.x, cam.z).x
	env.fog_density = 0.06 if under else 0.00022
	env.fog_light_color = Color(0.05, 0.22, 0.28) if under else Color(0.62, 0.72, 0.84)
