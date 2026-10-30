class_name Avatar
extends Node3D
## A stylised figure built from rounded parts, animated procedurally.
##
## Limbs are two-bone chains solved by analytic IK toward targets:
##  - walking: feet step along the ground in turn (a foot stays planted while
##    the other swings forward, lifted), arms swing against the legs;
##  - climbing: hands and feet hold points on the rock. One limb at a time
##    (right hand, left foot, left hand, right foot) lets go, reaches to a new
##    hold ahead in the direction of climbing, and grips; the others stay put.
## The body is oriented by the player: upright when walking, facing into the
## rock when climbing.

const ARM := [0.30, 0.28] # upper, lower
const LEG := [0.44, 0.42]
const SKIN := Color(0.86, 0.68, 0.55)
const SHIRT := Color(0.78, 0.33, 0.20)
const TROUSERS := Color(0.22, 0.27, 0.36)
const HAIR := Color(0.18, 0.12, 0.08)

var world: WorldData
var _hips: Node3D
var _chest: Node3D
var _limbs := {} # name -> {root: Node3D (socket on the body), a, b (bone pivots), len, hold: Vector3, planted}
var _phase := 0.0
var _climb_dist := 0.0
var _mats := {}


func _ready() -> void:
	_hips = Node3D.new()
	_hips.position = Vector3(0, 0.95, 0)
	add_child(_hips)
	_part(_hips, CapsuleMesh, Vector3(0, 0.02, 0), Vector3(0.32, 0.22, 0.2), TROUSERS)
	_chest = Node3D.new()
	_chest.position = Vector3(0, 0.12, 0)
	_hips.add_child(_chest)
	_part(_chest, CapsuleMesh, Vector3(0, 0.25, 0), Vector3(0.38, 0.52, 0.24), SHIRT)
	var head := _part(_chest, SphereMesh, Vector3(0, 0.66, 0), Vector3(0.24, 0.27, 0.25), SKIN)
	_part(head, SphereMesh, Vector3(0, 0.07, 0.02), Vector3(1.05, 0.75, 1.05), HAIR)
	_part(head, SphereMesh, Vector3(0, 0.0, -0.13), Vector3(0.05, 0.06, 0.05), SKIN) # nose
	for side: int in [-1, 1]:
		var sname := "l" if side < 0 else "r"
		_limb(sname + "_arm", _chest, Vector3(0.22 * side, 0.46, 0), ARM, [SHIRT, SKIN], 0.075)
		_limb(sname + "_leg", _hips, Vector3(0.1 * side, 0.0, 0), LEG, [TROUSERS, TROUSERS], 0.09)


func _material(c: Color) -> StandardMaterial3D:
	if not _mats.has(c):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		_mats[c] = m
	return _mats[c]


func _part(parent: Node3D, kind, pos: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh: PrimitiveMesh = kind.new()
	if mesh is CapsuleMesh:
		mesh.radius = 0.5
		mesh.height = 1.0
	else:
		mesh.radius = 0.5
		mesh.height = 1.0
	mi.mesh = mesh
	mi.scale = size
	mi.position = pos
	mi.material_override = _material(c)
	parent.add_child(mi)
	return mi


## A two-bone limb: pivots whose -Z axis points down the bone (so look_at aims it).
func _limb(name: String, parent: Node3D, socket: Vector3, lens: Array, cols: Array, r: float) -> void:
	var root := Node3D.new()
	root.position = socket
	parent.add_child(root)
	var a := Node3D.new()
	add_child(a)
	var b := Node3D.new()
	add_child(b)
	for k in 2:
		var pivot: Node3D = [a, b][k]
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = r * (1.0 if k == 0 else 0.85)
		cap.height = lens[k] + cap.radius * 2.0
		mi.mesh = cap
		mi.rotation.x = -PI / 2 # capsule along -Z
		mi.position = Vector3(0, 0, -lens[k] * 0.5)
		mi.material_override = _material(cols[k])
		pivot.add_child(mi)
	_limbs[name] = {"root": root, "a": a, "b": b, "len": lens, "hold": Vector3.INF, "planted": true}


## Two-bone IK: places the limb from its socket toward target, bending toward pole.
func _solve(l: Dictionary, target: Vector3, pole: Vector3) -> void:
	var root: Vector3 = l.root.global_position
	var la: float = l.len[0]
	var lb: float = l.len[1]
	var to := target - root
	var d := clampf(to.length(), 0.05, la + lb - 0.001)
	var dir := to.normalized() if to.length() > 1e-4 else Vector3.DOWN
	var cos_a := clampf((la * la + d * d - lb * lb) / (2.0 * la * d), -1.0, 1.0)
	var bend := (pole - dir * pole.dot(dir))
	bend = bend.normalized() if bend.length() > 1e-4 else dir.cross(Vector3.RIGHT).normalized()
	var joint := root + dir * la * cos_a + bend * la * sqrt(1.0 - cos_a * cos_a)
	var end := root + dir * d
	var a: Node3D = l.a
	var b: Node3D = l.b
	a.global_position = root
	b.global_position = joint
	_aim(a, joint, bend)
	_aim(b, end, bend)


func _aim(n: Node3D, at: Vector3, up_hint: Vector3) -> void:
	var f := at - n.global_position
	if f.length() < 1e-4:
		return
	var up := up_hint if absf(f.normalized().dot(up_hint.normalized())) < 0.98 else Vector3.UP
	n.look_at(at, up)


## Walking (or standing / swimming): speed in m/s, delta time.
func walk(delta: float, speed: float, on_floor: bool) -> void:
	_phase += delta * (1.2 + speed * 1.1)
	var b := global_basis.orthonormalized()
	var fwd := -b.z
	var right := b.x
	var amp := clampf(speed / 4.6, 0.0, 1.4) * 0.35
	_hips.position.y = 0.95 - absf(sin(_phase)) * 0.04 * amp * 3.0
	for side: int in [-1, 1]:
		var sname := "l" if side < 0 else "r"
		var s := sin(_phase + (0.0 if side < 0 else PI))
		var fs := float(side)
		var leg: Dictionary = _limbs[sname + "_leg"]
		var hip: Vector3 = leg.root.global_position
		var foot := global_position + right * 0.11 * fs + fwd * s * amp
		foot.y += maxf(0.0, -cos(_phase + (0.0 if side < 0 else PI))) * 0.15 * amp * 3.0 * (1.0 if on_floor else 0.0)
		if not on_floor:
			foot = hip + Vector3.DOWN * 0.8 + fwd * 0.1
		elif world:
			foot.y = maxf(foot.y, world.height_at(foot.x, foot.z) + 0.04)
		_solve(leg, foot, fwd)
		var arm: Dictionary = _limbs[sname + "_arm"]
		var sh: Vector3 = arm.root.global_position
		_solve(arm, sh + Vector3.DOWN * 0.52 - fwd * s * amp * 0.8 + right * 0.05 * fs, -fwd)
		arm.hold = Vector3.INF
		leg.hold = Vector3.INF


## Climbing: body centre, wall normal n, climbing "up" tangent, how far the
## body moved along the wall this frame (signed vector).
func climb(n: Vector3, up_t: Vector3, moved: Vector3) -> void:
	var right := up_t.cross(n)
	_hips.position.y = 0.95
	_climb_dist += moved.length()
	var dir := moved.normalized() if moved.length() > 1e-5 else up_t
	# Which limb is moving: a quarter of each 0.8 m cycle each.
	var cycle := fmod(_climb_dist / 0.8, 1.0)
	var order := ["r_arm", "l_leg", "l_arm", "r_leg"]
	var active := int(cycle * 4.0) % 4
	var t := fmod(cycle * 4.0, 1.0)
	for k in 4:
		var name: String = order[k]
		var l: Dictionary = _limbs[name]
		var is_arm := name.ends_with("arm")
		var side := -1.0 if name.begins_with("l") else 1.0
		var sock: Vector3 = l.root.global_position
		# Rest hold: hands up and out, feet down and out, on the rock.
		var rest := sock + (up_t * 0.42 + right * side * 0.22 if is_arm else -up_t * 0.62 + right * side * 0.16)
		var ahead := rest + dir * 0.3
		ahead = _on_rock(ahead, n)
		if l.hold == Vector3.INF or l.hold.distance_to(rest) > 0.9:
			l.hold = _on_rock(rest, n)
		var target: Vector3 = l.hold
		if k == active and moved.length() > 1e-5:
			# Reaching: off the rock in an arc, onto the next hold.
			target = l.hold.lerp(ahead, t) + n * sin(t * PI) * 0.12
			if t > 0.9:
				l.hold = ahead
		_solve(l, target, n if is_arm else n + up_t * 0.3)


func _on_rock(p: Vector3, n: Vector3) -> Vector3:
	if world == null:
		return p
	var h := world.height_at(p.x, p.z)
	return Vector3(p.x, h, p.z) + n * 0.05
