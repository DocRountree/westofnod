extends Node3D
## Builds the scene: sky/fog, sun, ocean, streamed terrain, blocks, player, HUD.

var terrain: TerrainWorld
var blocks: BlockWorld
var player: Player
var hud: Hud
var env: Environment
var ocean: MeshInstance3D
var water_material: ShaderMaterial


func _ready() -> void:
	_build_environment()

	water_material = ShaderMaterial.new()
	water_material.shader = load("res://shaders/water.gdshader")
	ocean = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(16000, 16000)
	ocean.mesh = plane
	ocean.material_override = water_material
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ocean)

	blocks = BlockWorld.new()
	add_child(blocks)
	terrain = TerrainWorld.new()
	terrain.block_world = blocks
	terrain.water_material = water_material
	add_child(terrain)
	terrain.spawn_found.connect(_on_spawn_found)

	player = Player.new()
	player.terrain = terrain
	player.blocks = blocks
	add_child(player)
	player.global_position = Vector3(0, 160, 0)

	hud = Hud.new()
	hud.player = player
	add_child(hud)
	player.inventory_changed.connect(hud.refresh)
	hud.refresh.call_deferred()
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

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	add_child(sun)


func _on_spawn_found(pos: Vector3) -> void:
	player.global_position = pos + Vector3(0, 40, 0)
	hud.status.text = "Loading terrain..."


func _process(_delta: float) -> void:
	var p := player.global_position
	ocean.global_position = Vector3(snappedf(p.x, 64.0), 0.0, snappedf(p.z, 64.0))
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
