extends Node3D
## Schools of fish (FishSchool: every fish drawn by the shader, a school a
## draw call), each in its own water: Chinook salmon at sea, rainbow trout
## in a stream (its current flowing: they hold facing up it), Atlantic
## bluefin tuna in the open sea:
## godot --path . res://tools/creatures/fish_demo.tscn
##
## Tab the next water   1 schooling (the trout holding)   2 the salmon and
## trout rise to the surface, the tuna feed on a bait ball   3 scatter them
## 4 the other variant (spawning salmon, steelheads)   P one steered
## + / - more or fewer   Space slow motion   drag: turn round   wheel: nearer / further

const FishScript := preload("res://scripts/creatures/fish_school.gd")
# each water: [kind, variants, its corner, its size (m), how many, its current]
const WATERS := [
	["chinook", ["ocean", "spawning"], Vector3(-40.0, 0.0, -4.0), Vector3(14.0, 4.0, 8.0), 24, Vector3.ZERO],
	["rainbow", ["", "steelhead"], Vector3(-4.0, 0.0, -1.5), Vector3(8.0, 0.9, 3.0), 10, Vector3(0.35, 0.0, 0.0)],
	["bluefin", [""], Vector3(30.0, 0.0, -15.0), Vector3(60.0, 10.0, 30.0), 20, Vector3.ZERO],
]

var schools: Array = [null, null, null]
var _variant := [0, 0, 0]
var _count := [24, 10, 20]
var _at := 0
var cam: Camera3D
var _yaw := 0.4
var _pitch := -0.25
var _dist := 14.0
var _label: Label


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
	sun.rotation = Vector3(deg_to_rad(-60), deg_to_rad(-30), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	for k in WATERS.size():
		var W: Array = WATERS[k]
		var c: Vector3 = W[2]
		var sz: Vector3 = W[3]
		var mid := c + sz * 0.5
		# its bed (gravel for the stream, sand), its water, faintly tinted
		_box(Vector3(mid.x, c.y - 0.05, mid.z), Vector3(sz.x, 0.1, sz.z), Color(0.48, 0.44, 0.38) if k == 1 else Color(0.62, 0.58, 0.46), 1.0)
		var tint := Color(0.4, 0.6, 0.62, 0.14) if k != 2 else Color(0.2, 0.4, 0.6, 0.12)
		var w := _box(mid, sz, tint, 0.05)
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_make(k)
	cam = Camera3D.new()
	cam.near = 0.02
	cam.far = 400.0
	cam.fov = 55.0
	add_child(cam)
	_label = Label.new()
	_label.position = Vector2(12, 8)
	add_child(_label)
	_say()


func _make(k: int) -> void:
	var W: Array = WATERS[k]
	if schools[k]:
		(schools[k] as Node).queue_free()
	var vars: Array = W[1]
	var f := FishScript.new(W[0], vars[_variant[k] % vars.size()])
	var c: Vector3 = W[2]
	var sz: Vector3 = W[3]
	f.tank_min = c
	f.tank_max = c + sz
	f.current = W[5]
	add_child(f)
	f.setup(_count[k], c + sz * 0.5, minf(sz.x, sz.z) * 0.2)
	schools[k] = f


func _say() -> void:
	var W: Array = WATERS[_at]
	var vars: Array = W[1]
	var v: String = vars[_variant[_at] % vars.size()]
	_label.text = "%d %s%s   Tab the next   1 school   2 rise / feed   3 scatter   4 the other variant   P one steered   + / - more or fewer   Space slow motion" % [_count[_at], W[0], (" (" + v + ")") if v != "" else ""]
	_dist = [14.0, 6.0, 45.0][_at]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var f: FishScript = schools[_at]
		var W: Array = WATERS[_at]
		match e.keycode:
			KEY_TAB:
				_at = (_at + 1) % WATERS.size()
				_say()
			KEY_1:
				for i in _count[_at]:
					f.rejoin(i)
			KEY_2:
				if W[0] == "bluefin":
					var c: Vector3 = W[2]
					var sz: Vector3 = W[3]
					f.feed(c + Vector3(sz.x * randf_range(0.3, 0.7), sz.y * 0.6, sz.z * randf_range(0.3, 0.7)))
				else:
					for i in _count[_at]:
						if randf() < 0.5:
							f.rise(i)
			KEY_3:
				f.scatter(f.pos[0] + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)))
			KEY_4:
				_variant[_at] += 1
				_make(_at)
				_say()
			KEY_P:
				var m: Object = f.member(0)
				var c: Vector3 = W[2]
				var sz: Vector3 = W[3]
				m.call("go_to", c + sz * Vector3(0.8, 0.5, 0.5))
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				_count[_at] = mini(_count[_at] * 2, 1000)
				_make(_at)
				_say()
			KEY_MINUS, KEY_KP_SUBTRACT:
				_count[_at] = maxi(_count[_at] / 2, 1)
				_make(_at)
				_say()
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
	elif e is InputEventMouseMotion and e.button_mask != 0:
		_yaw -= e.relative.x * 0.008
		_pitch = clampf(_pitch - e.relative.y * 0.008, -1.4, 1.2)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist * 0.85, 0.5)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 200.0)


func _process(_dt: float) -> void:
	var W: Array = WATERS[_at]
	var focus: Vector3 = (W[2] as Vector3) + (W[3] as Vector3) * 0.5
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = focus + off
	cam.look_at(focus, Vector3.UP)


func _box(at: Vector3, size: Vector3, c: Color, rough: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	add_child(mi)
	return mi
