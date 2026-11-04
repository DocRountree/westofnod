extends Node3D
## A plain to watch the hummingbird moth (HummingbirdMoth) and the monarch
## (Monarch) on, each of their animations on a key:
## godot --path . res://tools/creatures/lepidoptera_demo.tscn
##
## Moth: 1 search (darting about the flowers)   2 feed at the milkweed
## Monarch: 3 fly (flap and glide)   4 bask on the stone   5 feed at the
## swamp milkweed   6 feed at the milkweed
## Tab: follow the moth or the monarch   F follow on/off   Space slow motion
## Mouse: drag to turn round, wheel to come nearer or go off.
##
## The flowers are the game's own: a clump of common milkweed and one of
## swamp milkweed (GroundCover: their meshes, their shader, the layers' own
## colours), as cells of the prairie's and the swamp's, still (no wind, so
## the CPU knows where their flowers are: noted from their meshes as the
## shader places them).

# (by path, not by class name: found whether or not the editor has seen these yet)
const MothScript := preload("res://scripts/creatures/hummingbird_moth.gd")
const MonarchScript := preload("res://scripts/creatures/monarch.gd")
const Flowers := preload("res://tools/creatures/demo_flowers.gd")

var moth: MothScript
var monarch: MonarchScript
var cam: Camera3D
var _following: Node3D
var _yaw := 0.6
var _pitch := -0.3
var _dist := 0.5
var _follow := true
var _focus := Vector3.ZERO
var _milkweed: Array = [] # its flowers (points)
var _swamp: Array = []
const STONE := Vector3(-0.45, 0.04, 0.35)


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 6.0
	add_child(sun)
	_box(Vector3(0, -0.005, 0), Vector3(5, 0.01, 5), Color(0.36, 0.4, 0.2))
	# a flat stone, to bask on
	var stone := _box(STONE - Vector3(0, 0.02, 0), Vector3(0.25, 0.04, 0.18), Color(0.5, 0.48, 0.44))
	stone.rotation.y = 0.4
	_milkweed = Flowers.clump(self, "milkweed", Vector2(0.35, -0.2), 1.3, Color(0.42, 0.38, 0.28))
	_swamp = Flowers.clump(self, "swamp_milkweed", Vector2(-0.4, -0.45), 1.2, Color(0.2, 0.22, 0.14))
	moth = MothScript.new()
	add_child(moth)
	moth.place(Vector3(0.0, 0.6, 0.3))
	monarch = MonarchScript.new()
	add_child(monarch)
	monarch.place(Vector3(-0.3, 1.0, 0.2))
	cam = Camera3D.new()
	cam.near = 0.002
	cam.far = 100.0
	cam.fov = 50.0
	add_child(cam)
	_following = moth
	_focus = moth.global_position
	var label := Label.new()
	label.position = Vector2(12, 8)
	label.text = "Moth: 1 search   2 feed at the milkweed\nMonarch: 3 fly   4 bask on the stone   5 feed at the swamp milkweed   6 feed at the milkweed\nTab: follow the other   F follow on/off   Space slow motion   drag: turn round   wheel: nearer / further"
	add_child(label)
	moth.search(Vector3(0.0, 0.0, 0.0), 0.7, Flowers.heads(_milkweed) + Flowers.heads(_swamp))
	monarch.fly(Vector3(0.0, 0.0, 0.0), 1.2)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				moth.search(Vector3.ZERO, 0.7, Flowers.heads(_milkweed) + Flowers.heads(_swamp))
				_following = moth
			KEY_2:
				moth.feed(_milkweed)
				_following = moth
			KEY_3:
				monarch.fly(Vector3.ZERO, 1.2)
				_following = monarch
			KEY_4:
				monarch.bask(STONE, Vector3.UP)
				_following = monarch
			KEY_5:
				monarch.feed(_swamp)
				_following = monarch
			KEY_6:
				monarch.feed(_milkweed)
				_following = monarch
			KEY_TAB:
				_following = monarch if _following == moth else moth
			KEY_F:
				_follow = not _follow
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
	elif e is InputEventMouseMotion and e.button_mask != 0:
		_yaw -= e.relative.x * 0.008
		_pitch = clampf(_pitch - e.relative.y * 0.008, -1.4, 1.2)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist * 0.85, 0.03)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 4.0)


func _process(dt: float) -> void:
	if _follow:
		_focus = _focus.lerp(_following.global_position, 1.0 - exp(-6.0 * dt / maxf(Engine.time_scale, 0.01)))
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = _focus + off
	cam.look_at(_focus, Vector3.UP)


func _box(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	mi.material_override = m
	add_child(mi)
	return mi
