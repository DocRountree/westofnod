extends Node3D
## A plain to watch the wasp (Wasp) on, each of its animations on a key:
## godot --path . res://tools/creatures/wasp_demo.tscn
##
## 1 seek food (flying about)   2 feed on the flower   3 catch and eat the
## caterpillar (R puts a fresh one back on its leaf)   4 land on the plank
## (walk about, settle)   5 sting the red ball   Space slow motion
## Mouse: drag to turn round it, wheel to come nearer or go off; the camera
## follows the wasp (F: or not). The flower's a clump of the game's own
## purple coneflowers, swaying (key 2: off to them, and once near a head
## feeding at it in flight: the CPU only knows where the head stands
## still; the wasp's own shaders sway it with the head, as the flowers'
## shader sways the head). For the scale, things from the game: the
## player's figure with its axe, and on the plank a pawpaw, a black-eyed
## Susan, a yampah and a cattail.

var wasp: Wasp
var cam: Camera3D
var prey: Node3D
var avatar: Avatar
var _axe_held := false
var _yaw := 0.6
var _pitch := -0.35
var _dist := 0.12
var _follow := true
var _focus := Vector3.ZERO
var _label: Label

const CONE_NEAR := Vector2(0.3, -0.2) ## m: the coneflowers about here (the cell whose spot's nearest: where in its cell a clump stands is its hash)
var CONE_CELL := Vector2i.ZERO
const CONE_H := 1.4 ## m: the clump's height (in the game 1.2-1.6 on the prairie)
var _heads: Array = [] # the coneflowers' heads, still: [the disc's top, the way it faces, how far up its clump (its sway's share)]
var _cone_size := 1.0
var _to_flower := false # key 2: feeding at a head once it's near one
const LEAF := Vector3(-0.3, 0.2, 0.0)
const PLANK := Vector3(0.0, 0.06, 0.4)
const BALL := Vector3(-0.35, 0.025, 0.35)


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
	sun.directional_shadow_max_distance = 4.0
	add_child(sun)
	_box(Vector3(0, -0.005, 0), Vector3(4, 0.01, 4), Color(0.33, 0.4, 0.2))
	# the flower: a clump of the game's own purple coneflowers
	_coneflower()
	# the leaf the caterpillar's on, on a stalk
	_box(LEAF + Vector3(0, -0.1, 0), Vector3(0.004, 0.2, 0.004), Color(0.3, 0.42, 0.15))
	_box(LEAF + Vector3(0, 0.001, 0), Vector3(0.12, 0.002, 0.07), Color(0.25, 0.45, 0.15))
	# a plank to land on, and a ball to sting
	_box(PLANK, Vector3(0.3, 0.02, 0.1), Color(0.55, 0.42, 0.28))
	var ball := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.025
	s.height = 0.05
	ball.mesh = s
	ball.position = BALL
	ball.material_override = _mat(Color(0.7, 0.12, 0.1))
	add_child(ball)
	_new_prey()
	_scale_things()
	wasp = Wasp.new()
	add_child(wasp)
	wasp.place(Vector3(0.0, 0.3, 0.0))
	cam = Camera3D.new()
	cam.near = 0.001
	cam.far = 100.0
	cam.fov = 50.0
	add_child(cam)
	_focus = wasp.global_position
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.text = "1 seek food   2 feed on the flower   3 catch the caterpillar (R: a new one)   4 land on the plank   5 sting the ball\nSpace slow motion   F follow on/off   drag: turn round   wheel: nearer / further"
	add_child(_label)
	wasp.seek_food(Vector3.ZERO, 0.6)


## Things from the game, for the scale: the player's figure (Avatar,
## about 1.8 m) beside the plank, the axe in its hand; and on the plank a
## pawpaw, a black-eyed Susan, a yampah and a cattail, as they're carried
## (Items).
func _scale_things() -> void:
	avatar = Avatar.new()
	add_child(avatar)
	avatar.position = Vector3(0.75, 0.0, 0.55)
	avatar.rotation.y = deg_to_rad(60.0) # (facing the plank)
	var on := PLANK + Vector3(0.0, 0.01, 0.0)
	var lay := [["pawpaw", Vector3(0.09, 0.028, -0.02), Vector3(0.0, 0.3, PI * 0.5)],
			["susan", Vector3(-0.02, 0.006, 0.025), Vector3(0.0, 0.2, PI * 0.5)],
			["yampah", Vector3(-0.05, 0.006, -0.03), Vector3(0.0, -0.25, PI * 0.5)],
			["cattail", Vector3(0.04, 0.014, 0.035), Vector3(0.0, 0.1, PI * 0.5)]]
	for t in lay:
		var m := Items.model(t[0])
		m.position = on + t[1]
		m.rotation = t[2]
		add_child(m)


## A clump of the game's purple coneflowers (GroundCover: its mesh, its
## shader, the layer's own colours), as a cell of the prairie's: the cell's
## data (ground_cover_bake.gdshader's two texels) made up here, the
## ground at 0, the clump CONE_H tall; no wind. Notes where its heads are,
## worked out as the shader places them.
func _coneflower() -> void:
	var L: Dictionary
	for l in GroundCover.LAYERS:
		if l.get("flowers", "") == "coneflower":
			L = l
	var best := INF
	for cz in range(-3, 3):
		for cx in range(-3, 3):
			var c := Vector2i(cx, cz)
			var at := Vector2(c) * float(L.cell) + Vector2(GroundCover._h2(c, 1, L.u.seed), GroundCover._h2(c, 2, L.u.seed)) * float(L.cell)
			if at.distance_to(CONE_NEAR) < best:
				best = at.distance_to(CONE_NEAR)
				CONE_CELL = c
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/ground_cover.gdshader")
	m.set_shader_parameter("cell", L.cell)
	for k in L.u:
		if k in GroundCover.DRAW_KEYS:
			m.set_shader_parameter(k, L.u[k])
	var size_b := roundf(CONE_H / GroundCover.SIZE_MAX * 255.0)
	var img := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color8(128, 0, int(size_b), 120)) # (the ground at 0: 512 m over base_h, in 1/64 m; the size; how blonde)
	img.set_pixel(1, 0, Color(0.42, 0.38, 0.28, 1.0)) # (the ground's colour; all prairie)
	m.set_shader_parameter("data_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter("grid_origin", CONE_CELL)
	m.set_shader_parameter("grid_size", Vector2i(1, 1))
	m.set_shader_parameter("base_h", 0.0)
	var mesh := GroundCover.flower_mesh(L.flowers, L.stems, L.radius, L.u.seed)
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 1
	var cell: float = L.cell
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(CONE_CELL.x * cell, 0.0, CONE_CELL.y * cell)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.custom_aabb = AABB(Vector3(-1, -1, -1), Vector3(cell + 2, 4, cell + 2))
	add_child(mi)
	# the heads, as the shader puts them: the clump at the cell's spot, turned
	var seed: int = L.u.seed
	var pos := Vector2(CONE_CELL) * cell + Vector2(GroundCover._h2(CONE_CELL, 1, seed), GroundCover._h2(CONE_CELL, 2, seed)) * cell
	var spin := GroundCover._h2(CONE_CELL, 8, seed) * TAU
	var size := size_b / 255.0 * GroundCover.SIZE_MAX
	var rot := func(v: Vector2) -> Vector2: return Vector2(cos(spin) * v.x - sin(spin) * v.y, sin(spin) * v.x + cos(spin) * v.y)
	var a := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	_heads.clear()
	for i in vs.size():
		if absf(uvs[i].x - 4.5) < 0.01 and uvs[i].y < 0.01: # (a disc's top)
			var root: Vector2 = rot.call(uv2s[i])
			var v: Vector2 = rot.call(Vector2(vs[i].x, vs[i].z))
			var n2: Vector2 = rot.call(Vector2(ns[i].x, ns[i].z))
			var at := Vector3(pos.x + root.x + v.x * size, vs[i].y * size, pos.y + root.y + v.y * size)
			var cols: PackedColorArray = a[Mesh.ARRAY_COLOR]
			_heads.append([at, Vector3(n2.x, ns[i].y, n2.y).normalized(), cols[i].b])
	_cone_size = size


func _new_prey() -> void:
	if prey:
		if wasp:
			wasp.release()
		prey.queue_free()
	prey = Wasp.caterpillar()
	add_child(prey)
	prey.position = LEAF + Vector3(0.02, 0.0035, 0.01)
	prey.rotation.y = 0.7


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				_to_flower = false
				wasp.seek_food(Vector3.ZERO, 0.6)
			KEY_2:
				# off to the flowers: seeking round them, feeding at a head once near one
				wasp.seek_food(Vector3(_heads[0][0].x, 0.0, _heads[0][0].z) + Vector3(0, 1.0, 0), 0.25)
				_to_flower = true
			KEY_3:
				_to_flower = false
				wasp.feed_on_insect(prey, LEAF + Vector3(0, 0.002, 0), Vector3.UP)
			KEY_4:
				_to_flower = false
				wasp.land(PLANK + Vector3(0, 0.01, 0), Vector3.UP)
			KEY_5:
				_to_flower = false
				wasp.sting(BALL + Vector3(0, 0.02, 0))
			KEY_R:
				_new_prey()
			KEY_F:
				_follow = not _follow
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
	elif e is InputEventMouseMotion and e.button_mask != 0:
		_yaw -= e.relative.x * 0.008
		_pitch = clampf(_pitch - e.relative.y * 0.008, -1.4, 1.2)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist * 0.85, 0.02)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 3.0)


func _process(dt: float) -> void:
	# near a head: feeding at it (where it stands still; the wasp's shaders
	# sway it with the head, by the head's share of the wind: the grass's
	# grass_sway, 0.3, * the clump's size * how far up it, squared)
	if _to_flower:
		for h in _heads:
			if wasp.global_position.distance_to(h[0]) < 0.3:
				_to_flower = false
				wasp.feed_on_flower(h[0], h[1], 0.3 * _cone_size * h[2] * h[2])
				break
	avatar.walk(dt, 0.0, true) # (standing)
	if not _axe_held and avatar.grip("r"):
		avatar.grip("r").add_child(Items.model("axe"))
		_axe_held = true
	if _follow:
		_focus = _focus.lerp(wasp.global_position, 1.0 - exp(-6.0 * dt / maxf(Engine.time_scale, 0.01)))
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = _focus + off
	cam.look_at(_focus, Vector3.UP)


func _box(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	mi.material_override = _mat(c)
	add_child(mi)
	return mi


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m
