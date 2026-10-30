class_name Player
extends CharacterBody3D
## First-person controller: walk/sprint/jump, swim, optional fly mode, and
## block interaction (dig terrain / break blocks, place blocks).

signal inventory_changed

const WALK_SPEED := 4.6
const SPRINT_SPEED := 7.5
const FLY_SPEED := 30.0
const JUMP_VELOCITY := 7.6
const GRAVITY := 24.0
const REACH := 6.0
const MOUSE_SENS := 0.0025
const HOTBAR := [BlockWorld.DIRT, BlockWorld.GRASS, BlockWorld.STONE, BlockWorld.SAND,
		BlockWorld.GRAVEL, BlockWorld.LOG, BlockWorld.PLANKS, BlockWorld.LEAVES, BlockWorld.GLASS]

var terrain: TerrainWorld
var blocks: BlockWorld
var camera: Camera3D
var flying := false
var frozen := true
var selected := 0
var inventory := {}
var _cooldown := 0.0
var _outline: MeshInstance3D


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = 0.9
	add_child(cs)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.far = 7000.0
	camera.near = 0.08
	camera.fov = 75.0
	add_child(camera)
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.6
	for t in HOTBAR:
		inventory[t] = 0
	inventory[BlockWorld.PLANKS] = 16
	inventory[BlockWorld.GLASS] = 8
	_outline = _make_outline()
	get_parent().add_child.call_deferred(_outline)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select(selected - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select(selected + 1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_place()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * MOUSE_SENS, -1.55, 1.55)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_F:
				flying = not flying
			KEY_C:
				_craft()
			_:
				if event.keycode >= KEY_1 and event.keycode <= KEY_9:
					_select(event.keycode - KEY_1)


func _select(i: int) -> void:
	selected = posmod(i, HOTBAR.size())
	inventory_changed.emit()


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var in_water := global_position.y + 0.9 < 0.0

	if flying:
		var vy := 0.0
		if Input.is_action_pressed("jump"):
			vy += 1.0
		if Input.is_action_pressed("descend"):
			vy -= 1.0
		var spd := FLY_SPEED * (2.5 if Input.is_action_pressed("sprint") else 1.0)
		velocity = dir * spd + Vector3.UP * vy * spd * 0.6
	else:
		var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		if in_water:
			speed *= 0.6
			velocity.y = move_toward(velocity.y, -1.5, 8.0 * delta)
			if Input.is_action_pressed("jump"):
				velocity.y = 3.2
		else:
			velocity.y -= GRAVITY * delta
			if Input.is_action_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
		var accel := 40.0 if is_on_floor() else 12.0
		velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	move_and_slide()

	_cooldown -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _cooldown <= 0.0:
		_break()
		_cooldown = 0.22
	_update_outline()


func _ray() -> Dictionary:
	var from := camera.global_position
	var to := from - camera.global_basis.z * REACH
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q)


func _break() -> void:
	var hit := _ray()
	if hit.is_empty():
		return
	var kind: String = hit.collider.get_meta("kind", "")
	if kind == "blocks":
		var c := Vector3i((hit.position - hit.normal * 0.5).floor())
		var t := blocks.get_block(c)
		if t != BlockWorld.AIR:
			blocks.set_block(c, BlockWorld.AIR)
			_give(t)
	elif kind == "terrain":
		_give(terrain.dig(hit.position))


func _place() -> void:
	var t: int = HOTBAR[selected]
	if inventory.get(t, 0) <= 0:
		return
	var hit := _ray()
	if hit.is_empty():
		return
	var c := Vector3i((hit.position + hit.normal * 0.5).floor())
	if blocks.get_block(c) != BlockWorld.AIR:
		return
	# Don't place a block inside ourselves.
	var me := AABB(global_position - Vector3(0.3, 0.0, 0.3), Vector3(0.6, 1.8, 0.6))
	if me.intersects(AABB(Vector3(c), Vector3.ONE)):
		return
	blocks.set_block(c, t)
	inventory[t] -= 1
	inventory_changed.emit()


func _give(t: int) -> void:
	if inventory.has(t):
		inventory[t] += 1
		inventory_changed.emit()


## The only "recipes": a log splits into 4 planks, sand smelts into glass.
func _craft() -> void:
	var t: int = HOTBAR[selected]
	if t == BlockWorld.LOG and inventory[t] > 0:
		inventory[t] -= 1
		inventory[BlockWorld.PLANKS] += 4
	elif t == BlockWorld.SAND and inventory[t] > 0:
		inventory[t] -= 1
		inventory[BlockWorld.GLASS] += 1
	inventory_changed.emit()


func _make_outline() -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var e := 0.005
	var corners := []
	for i in 8:
		corners.append(Vector3(i & 1, (i >> 1) & 1, (i >> 2) & 1) * (1.0 + 2.0 * e) - Vector3.ONE * e)
	for a in 8:
		for b in range(a + 1, 8):
			var d: int = a ^ b
			if d == 1 or d == 2 or d == 4:
				im.surface_add_vertex(corners[a])
				im.surface_add_vertex(corners[b])
	im.surface_end()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0, 0, 0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi


func _update_outline() -> void:
	var hit := _ray()
	if hit.is_empty() or hit.collider.get_meta("kind", "") != "blocks":
		_outline.visible = false
		return
	_outline.visible = true
	_outline.global_position = Vector3((hit.position - hit.normal * 0.5).floor())
