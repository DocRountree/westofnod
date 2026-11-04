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

var moth: HummingbirdMoth
var monarch: Monarch
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
	_milkweed = _clump("milkweed", Vector2(0.35, -0.2), 1.3, Color(0.42, 0.38, 0.28))
	_swamp = _clump("swamp_milkweed", Vector2(-0.4, -0.45), 1.2, Color(0.2, 0.22, 0.14))
	moth = HummingbirdMoth.new()
	add_child(moth)
	moth.place(Vector3(0.0, 0.6, 0.3))
	monarch = Monarch.new()
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
	moth.search(Vector3(0.0, 0.0, 0.0), 0.7, _heads(_milkweed) + _heads(_swamp))
	monarch.fly(Vector3(0.0, 0.0, 0.0), 1.2)


## The flowers' middles, one a flower ball or cluster (the florets' mean,
## grouped), for the moth to look in at as it searches.
func _heads(florets: Array) -> Array:
	var out := []
	for p: Vector3 in florets:
		var near := false
		for q: Vector3 in out:
			if q.distance_to(p) < 0.08:
				near = true
				break
		if not near:
			out.append(p)
	return out


## A clump of one of the game's flowers (GroundCover's layer with that
## `flowers`), as a cell of its layer: the cell's data (ground_cover_bake's
## two texels) made up here, the ground at 0, the clump `tall` m; no wind.
## Its florets' tops, as the shader places them (the map's = this scene's).
func _clump(flowers: String, near: Vector2, tall: float, ground: Color) -> Array:
	var L: Dictionary
	for l in GroundCover.LAYERS:
		if l.get("flowers", "") == flowers:
			L = l
	var cell: float = L.cell
	var seed: int = L.u.seed
	var at_cell := Vector2i.ZERO
	var best := INF
	for cz in range(-3, 3):
		for cx in range(-3, 3):
			var c := Vector2i(cx, cz)
			var at := Vector2(c) * cell + Vector2(GroundCover._h2(c, 1, seed), GroundCover._h2(c, 2, seed)) * cell
			if at.distance_to(near) < best:
				best = at.distance_to(near)
				at_cell = c
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/ground_cover.gdshader")
	m.set_shader_parameter("cell", cell)
	for k in L.u:
		if k in GroundCover.DRAW_KEYS:
			m.set_shader_parameter(k, L.u[k])
	m.set_shader_parameter("grass_sway", 0.0) # (still: the insects go by where the flowers are)
	m.set_shader_parameter("fade_out", Vector2(1000.0, 1001.0))
	m.set_shader_parameter("thin_from", 1000.0)
	var size_b := roundf(tall / GroundCover.SIZE_MAX * 255.0)
	var img := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color8(128, 0, int(size_b), 120)) # (the ground at 0: 512 m over base_h, in 1/64 m; the size; how blonde)
	img.set_pixel(1, 0, Color(ground.r, ground.g, ground.b, 1.0))
	m.set_shader_parameter("data_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter("grid_origin", at_cell)
	m.set_shader_parameter("grid_size", Vector2i(1, 1))
	m.set_shader_parameter("base_h", 0.0)
	var mesh := GroundCover.flower_mesh(L.flowers, L.stems, L.radius, seed)
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 1
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(at_cell.x * cell, 0.0, at_cell.y * cell)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.custom_aabb = AABB(Vector3(-1, -1, -1), Vector3(cell + 2, 4, cell + 2))
	add_child(mi)
	# the florets' tops (a head's disc's top: UV 4.5, 0), as the shader puts
	# them: the clump at the cell's spot, turned, sized
	var pos := Vector2(at_cell) * cell + Vector2(GroundCover._h2(at_cell, 1, seed), GroundCover._h2(at_cell, 2, seed)) * cell
	var spin := GroundCover._h2(at_cell, 8, seed) * TAU
	var size := size_b / 255.0 * GroundCover.SIZE_MAX
	var a := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var out := []
	for i in vs.size():
		if absf(uvs[i].x - 4.5) < 0.01 and uvs[i].y < 0.01:
			var root := _turn(uv2s[i], spin)
			var v := _turn(Vector2(vs[i].x, vs[i].z), spin)
			out.append(Vector3(pos.x + root.x + v.x * size, vs[i].y * size, pos.y + root.y + v.y * size))
	return out


## v turned by a (as ground_cover.gdshader turns a clump: mat2(cos, sin; -sin, cos)).
static func _turn(v: Vector2, a: float) -> Vector2:
	return Vector2(cos(a) * v.x - sin(a) * v.y, sin(a) * v.x + cos(a) * v.y)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				moth.search(Vector3.ZERO, 0.7, _heads(_milkweed) + _heads(_swamp))
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
