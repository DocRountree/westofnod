class_name Avatar
extends Node3D
## A stylised figure built from rounded parts, animated procedurally.
##
## Limbs are two-bone chains solved by analytic IK toward targets:
##  - walking: feet step along the ground in turn (a foot stays planted while
##    the other swings forward, lifted), arms swing against the legs;
##  - climbing: hands and feet hold points on the rock surface (found by
##    projecting onto the terrain along its normal). One limb at a time (right
##    hand, left foot, left hand, right foot) lets go, reaches to a new hold
##    ahead in the direction of climbing, and grips; the others stay put.
## The body is oriented by the player: upright when walking, facing into the
## rock when climbing.

const ARM := [0.30, 0.28] # upper, lower
const LEG := [0.44, 0.42]
const SKIN := Color(0.86, 0.68, 0.55)
const SHIRT := Color(0.78, 0.33, 0.20)
const TROUSERS := Color(0.22, 0.27, 0.36)
const HAIR := Color(0.18, 0.12, 0.08)
const SHIRT_DARK := Color(0.6, 0.24, 0.15)
const BELT := Color(0.28, 0.2, 0.13)
const BOOT := Color(0.3, 0.22, 0.15)
const EYE := Color(0.08, 0.07, 0.07)

var world: WorldData
var _hips: Node3D
var _chest: Node3D
var _limbs := {} # name -> {root: Node3D (socket on the body), a, b (bone pivots), len, hold: Vector3, planted}
var _phase := 0.0
var _climb_dist := 0.0
var _mats := {}
var _boots := {}
var sink := 0.0 ## How deep the feet are in mud (the player's).
var _head: MeshInstance3D


func _ready() -> void:
	_hips = Node3D.new()
	_hips.position = Vector3(0, 0.95, 0)
	add_child(_hips)
	_part(_hips, CapsuleMesh, Vector3(0, 0.0, 0), Vector3(0.34, 0.24, 0.22), TROUSERS) # pelvis
	_part(_hips, CylinderMesh, Vector3(0, 0.1, 0), Vector3(0.33, 0.05, 0.215), BELT) # belt
	_chest = Node3D.new()
	_chest.position = Vector3(0, 0.12, 0)
	_hips.add_child(_chest)
	_part(_chest, CapsuleMesh, Vector3(0, 0.12, 0), Vector3(0.31, 0.32, 0.2), SHIRT) # waist
	_part(_chest, CapsuleMesh, Vector3(0, 0.33, 0), Vector3(0.42, 0.36, 0.25), SHIRT) # chest
	_part(_chest, CapsuleMesh, Vector3(0, 0.47, 0), Vector3(0.46, 0.13, 0.2), SHIRT) # shoulders
	_part(_chest, CylinderMesh, Vector3(0, 0.55, 0), Vector3(0.17, 0.05, 0.15), SHIRT_DARK) # collar
	_part(_chest, CylinderMesh, Vector3(0, 0.6, 0), Vector3(0.1, 0.12, 0.1), SKIN) # neck
	_head = _part(_chest, SphereMesh, Vector3(0, 0.75, 0.0), Vector3(0.22, 0.26, 0.24), SKIN)
	_part(_head, SphereMesh, Vector3(0, 0.12, 0.04), Vector3(1.06, 0.72, 1.04), HAIR) # hair cap
	_part(_head, SphereMesh, Vector3(0, -0.02, -0.47), Vector3(0.16, 0.2, 0.16), SKIN) # nose
	_part(_head, SphereMesh, Vector3(0, -0.28, -0.32), Vector3(0.5, 0.25, 0.4), SKIN) # chin
	for side: int in [-1, 1]:
		_part(_head, SphereMesh, Vector3(0.18 * side, 0.08, -0.4), Vector3(0.13, 0.13, 0.08), EYE) # eyes
		_part(_head, SphereMesh, Vector3(0.5 * side, 0.02, 0.0), Vector3(0.12, 0.3, 0.22), SKIN) # ears
		_part(_head, SphereMesh, Vector3(0.18 * side, 0.22, -0.43), Vector3(0.22, 0.05, 0.06), HAIR) # brows
	for side: int in [-1, 1]:
		var sname := "l" if side < 0 else "r"
		_limb(sname + "_arm", _chest, Vector3(0.23 * side, 0.45, 0), ARM, [SHIRT, SKIN], 0.07)
		_limb(sname + "_leg", _hips, Vector3(0.1 * side, -0.02, 0), LEG, [TROUSERS, TROUSERS], 0.085)
		# a hand at the end of the forearm; a boot placed under each foot (see _feet)
		var arm: Dictionary = _limbs[sname + "_arm"]
		_part(arm.b, SphereMesh, Vector3(0, 0, -ARM[1] - 0.05), Vector3(0.09, 0.11, 0.07), SKIN)
		var boot := Node3D.new()
		add_child(boot)
		_part(boot, CapsuleMesh, Vector3(0, 0.05, -0.04), Vector3(0.11, 0.26, 0.11), BOOT).rotation.x = PI / 2
		_part(boot, CylinderMesh, Vector3(0, 0.1, 0.02), Vector3(0.12, 0.1, 0.12), BOOT)
		_boots[sname] = boot


## The boots: under the end of each leg, flat on the ground (or the rock),
## pointing where the figure faces.
func _feet(fwd: Vector3, up: Vector3) -> void:
	for sname in _boots:
		var leg: Dictionary = _limbs[sname + "_leg"]
		var b: Node3D = leg.b
		var ankle: Vector3 = b.global_position - b.global_basis.z * leg.len[1]
		var y := up.normalized()
		var z := -(fwd - y * fwd.dot(y)).normalized()
		var boot: Node3D = _boots[sname]
		boot.global_transform = Transform3D(Basis(y.cross(z), y, z), ankle - y * 0.1)


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
	if mesh is CylinderMesh:
		mesh.top_radius = 0.5
		mesh.bottom_radius = 0.5
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
		var joint := MeshInstance3D.new() # (shoulder, elbow / hip, knee)
		var ball := SphereMesh.new()
		ball.radius = cap.radius * 1.05
		ball.height = ball.radius * 2.0
		joint.mesh = ball
		joint.material_override = _material(cols[k])
		pivot.add_child(joint)
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
	# lean into the pace; the shoulders twist against the hips with the stride,
	# the hips sway a little; the head keeps level
	_hips.rotation = Vector3(-amp * 0.25, sin(_phase) * amp * 0.25, 0.0)
	_chest.rotation = Vector3(-amp * 0.1, -sin(_phase) * amp * 0.6, 0.0)
	_head.rotation = Vector3(amp * 0.3, sin(_phase) * amp * 0.3, 0.0)
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
			foot.y = maxf(foot.y, world.height_at(foot.x, foot.z) - sink + 0.04)
		_solve(leg, foot, fwd)
		var arm: Dictionary = _limbs[sname + "_arm"]
		var sh: Vector3 = arm.root.global_position
		# arms hang a little out from the body, elbows softly bent
		_solve(arm, sh + Vector3.DOWN * 0.5 - fwd * (s * amp * 0.8 - 0.06) + right * 0.07 * fs, -fwd + Vector3.DOWN * 0.3)
		arm.hold = Vector3.INF
		leg.hold = Vector3.INF
	var up := world.normal_at(global_position.x, global_position.z) if world and on_floor else Vector3.UP
	_feet(fwd, up.lerp(Vector3.UP, 0.4))


## Climbing. surface: the rock point under the body's centre; n: its normal;
## up_t: up the fall line; moved: how far the body moved over the rock this
## frame. Each limb holds a point on the rock surface; in turn (right hand,
## left foot, left hand, right foot) one lets go and reaches, in an arc off the
## rock, to a new hold ahead in the direction of travel.
func climb(surface: Vector3, n: Vector3, up_t: Vector3, moved: Vector3) -> void:
	var right := up_t.cross(n)
	_hips.position.y = 0.95
	_hips.rotation = Vector3.ZERO
	_chest.rotation = Vector3.ZERO
	_head.rotation = Vector3(-0.35, 0.0, 0.0) # looking up the rock
	_climb_dist += moved.length()
	var dir := moved.normalized() if moved.length() > 1e-5 else up_t
	var cycle := fmod(_climb_dist / 0.8, 1.0)
	var order := ["r_arm", "l_leg", "l_arm", "r_leg"]
	var active := int(cycle * 4.0) % 4
	var t := fmod(cycle * 4.0, 1.0)
	for k in 4:
		var name: String = order[k]
		var l: Dictionary = _limbs[name]
		var is_arm := name.ends_with("arm")
		var side := -1.0 if name.begins_with("l") else 1.0
		var reach: float = l.len[0] + l.len[1]
		# Where this limb would rest: on the rock around the body, hands above
		# the shoulders, feet below the hips.
		var rest := surface + (up_t * 0.75 + right * side * 0.3 if is_arm else -up_t * 0.7 + right * side * 0.2)
		rest = on_rock(rest)
		var sock: Vector3 = l.root.global_position
		if l.hold == Vector3.INF or l.hold.distance_to(sock) > reach * 1.05:
			l.hold = rest # out of reach (or no hold yet): take the rest hold
		var target: Vector3 = l.hold
		if k == active and moved.length() > 1e-5:
			var next := on_rock(rest + dir * 0.35)
			target = l.hold.lerp(next, t) + n * sin(t * PI) * 0.15
			if t > 0.9:
				l.hold = next
		# the hand or foot rests on the hold, not in it: aim the limb's end
		# that far off the rock
		target += n * (0.1 if is_arm else 0.12)
		# elbows down and out, knees out to the side and toward the wall (a
		# climber faces the rock: knees bend toward it, never back away)
		var pole := (-up_t * 0.6 + right * side * 0.7 + n * 0.2) if is_arm else (right * side * 0.9 - n * 0.3 - up_t * 0.2)
		_solve(l, target, pole)
		# never through the rock: if the elbow or knee is in it, bend away more
		var joint: Vector3 = (l.b as Node3D).global_position
		if _depth(joint) > -0.08:
			_solve(l, target, pole.lerp(n, 0.8))
	_feet(up_t, n)


## The point on the terrain surface nearest p (a few steps along the normal),
## lifted a little so a hand rests on it rather than in it.
func on_rock(p: Vector3) -> Vector3:
	if world == null:
		return p
	for i in 3:
		var n := world.normal_at(p.x, p.z)
		var off := (p.y - world.height_at(p.x, p.z)) * n.y # distance above the surface, along n
		p -= n * off
	return p + world.normal_at(p.x, p.z) * 0.04


## How far p is inside the rock (m, along the surface normal; negative: outside).
func _depth(p: Vector3) -> float:
	if world == null:
		return -1.0
	return (world.height_at(p.x, p.z) - p.y) * world.normal_at(p.x, p.z).y


## How far each hand and foot is from the terrain surface (m): for checks.
func contact_gaps() -> Dictionary:
	var out := {}
	for name in _limbs:
		var l: Dictionary = _limbs[name]
		var b: Node3D = l.b
		var tip: Vector3 = b.global_position - b.global_basis.z * l.len[1]
		var n := world.normal_at(tip.x, tip.z)
		out[name] = snappedf((tip.y - world.height_at(tip.x, tip.z)) * n.y, 0.01)
	return out
