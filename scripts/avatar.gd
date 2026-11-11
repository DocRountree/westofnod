class_name Avatar
extends Node3D
## A figure, built from its look (CharacterLook, CharacterParts: its body,
## hair and clothes) onto a few bones, animated procedurally.
##
## Limbs are two-bone chains solved by analytic IK toward targets:
##  - walking: feet step along the ground in turn (a foot stays planted while
##    the other swings forward, lifted), arms swing against the legs;
##  - climbing: hands and feet hold points on the rock surface (found by
##    projecting onto the terrain along its normal), or a tree's bark
##    (`trunk`: projected onto it). One limb at a time (right
##    hand, left foot, left hand, right foot) lets go, reaches to a new hold
##    ahead in the direction of climbing, and grips; the others stay put.
## The body is oriented by the player: upright when walking, facing into the
## rock when climbing.

const ARM := [0.30, 0.28] # upper, lower
const LEG := [0.44, 0.42]

## How it looks (CharacterLook: the player's from the character picker, an
## NPC's from CharacterLook.random()): set_look() builds it.
var look: CharacterLook
var world: WorldData
var _hips: Node3D
var _chest: Node3D
## Hands held to a place (world: drawn positions) instead of swinging with
## the walk: "l"/"r" -> [the hand's target, the elbow's pole] (Felling: on
## the axe's handle as it swings). Cleared by whoever set them.
var arm_targets := {}
var crouch := 0.0 ## 0 standing .. 1 crouched (the player's): hips down, knees bent, leaning in
var _grips := {} # "l"/"r" -> Node3D: where the hands hold things
var _limbs := {} # name -> {root: Node3D (socket on the body), a, b (bone pivots), len, hold: Vector3, planted}
var _phase := 0.0
var _climb_dist := 0.0
var _boots := {}
var _hands := {} # "l"/"r" -> [open, closed]: the hand's two meshes (CharacterParts)
var sink := 0.0 ## How deep the feet are in mud (the player's).
var trunk := PackedFloat32Array() ## The tree being climbed (Population trunk), if any: holds are on its bark.
var _head: Node3D
var _pack: Node3D # the knapsack on its back (wear_pack)


func _ready() -> void:
	# its bones: the hips, the chest on them, the head on that; each limb's
	# socket on the body and its two bones; a foot under each leg. What's
	# seen is built onto them from its look (set_look, CharacterParts).
	_hips = Node3D.new()
	_hips.position = Vector3(0, 0.95, 0)
	add_child(_hips)
	_chest = Node3D.new()
	_chest.position = CharacterParts.CHEST_AT
	_hips.add_child(_chest)
	_head = Node3D.new()
	_head.position = CharacterParts.HEAD_AT
	_head.scale = Vector3.ONE * 1.05 # (a little large: read at a distance)
	_chest.add_child(_head)
	for side: int in [-1, 1]:
		var sname := "l" if side < 0 else "r"
		_limb(sname + "_arm", _chest, CharacterParts.SHOULDER * Vector3(side, 1, 1), ARM)
		_limb(sname + "_leg", _hips, CharacterParts.HIP * Vector3(side, 1, 1), LEG)
		var arm: Dictionary = _limbs[sname + "_arm"]
		var grip := Node3D.new() # what the hand holds (Player.set_held), across the fist
		grip.position = Vector3(0, 0, -ARM[1] - 0.07)
		arm.b.add_child(grip)
		_grips[sname] = grip
		var boot := Node3D.new() # (placed under each foot: _feet)
		add_child(boot)
		_boots[sname] = boot
	_pack = Pack.model() # (on its back: its front, the flap and buckles, out)
	_pack.position = Vector3(0, -0.02, 0.225)
	_chest.add_child(_pack)
	set_look(look if look else CharacterLook.new())


## Builds the figure as l says (its body, hair, clothes: CharacterParts),
## in place of how it looked; its bones, and what its hands hold, as they
## were.
func set_look(l: CharacterLook) -> void:
	look = l
	if _hips == null:
		return # (not in the scene yet: built then)
	var limbs := {}
	for name in _limbs:
		limbs[name] = {"a": _limbs[name].a, "b": _limbs[name].b}
	_hands = CharacterParts.build({"hips": _hips, "chest": _chest, "head": _head, "limbs": limbs, "boots": _boots}, l).hands


## The knapsack on its back, or not (set down: Knapsack.set_down).
func wear_pack(on: bool) -> void:
	if _pack:
		_pack.visible = on


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
		# (and its hands: closed round what they hold, else open)
		var held: bool = (_grips[sname] as Node3D).get_child_count() > 0
		if _hands.has(sname) and (_hands[sname][1] as Node3D).visible != held:
			(_hands[sname][0] as Node3D).visible = not held
			(_hands[sname][1] as Node3D).visible = held


## A two-bone limb: pivots whose -Z axis points down the bone (so look_at aims it).
func _limb(name: String, parent: Node3D, socket: Vector3, lens: Array) -> void:
	var root := Node3D.new()
	root.position = socket
	parent.add_child(root)
	var a := Node3D.new()
	add_child(a)
	var b := Node3D.new()
	add_child(b)
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
	_hips.position.y = 0.95 - absf(sin(_phase)) * 0.04 * amp * 3.0 - crouch * 0.42
	# lean into the pace; the shoulders twist against the hips with the stride,
	# the hips sway a little; the head keeps level (crouched: the body leans
	# in over the bent knees, the head up)
	_hips.rotation = Vector3(-amp * 0.25 - crouch * 0.5, sin(_phase) * amp * 0.25, 0.0)
	_chest.rotation = Vector3(-amp * 0.1 - crouch * 0.15, -sin(_phase) * amp * 0.6, 0.0)
	_head.rotation = Vector3(amp * 0.3 + crouch * 0.6, sin(_phase) * amp * 0.3, 0.0)
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
			var fm := Origin.map(foot) # (bones are drawn positions; the ground goes by the map's)
			foot.y = maxf(foot.y, world.height_at(fm.x, fm.z) - sink + 0.04)
		_solve(leg, foot, fwd)
		var arm: Dictionary = _limbs[sname + "_arm"]
		var sh: Vector3 = arm.root.global_position
		# arms hang a little out from the body, elbows softly bent (unless
		# held somewhere: arm_targets)
		if arm_targets.has(sname):
			_solve(arm, arm_targets[sname][0], arm_targets[sname][1])
		else:
			_solve(arm, sh + Vector3.DOWN * 0.5 - fwd * (s * amp * 0.8 - 0.06) + right * 0.07 * fs, -fwd + Vector3.DOWN * 0.3)
		arm.hold = Vector3.INF
		leg.hold = Vector3.INF
	var at := Origin.map(global_position)
	var up := world.normal_at(at.x, at.z) if world and on_floor else Vector3.UP
	_feet(fwd, up.lerp(Vector3.UP, 0.4))


## Swimming, lying along the way (the player turns the figure): arms reach
## ahead and pull back in turn, legs flutter behind. speed in m/s.
func swim(delta: float, speed: float) -> void:
	_phase += delta * (2.0 + speed * 0.25)
	_hips.position.y = 0.95
	_hips.rotation = Vector3(0.0, sin(_phase) * 0.15, 0.0)  # a roll with the strokes
	_chest.rotation = Vector3.ZERO
	_head.rotation = Vector3(-1.2, 0.0, 0.0)                 # looking ahead, not down
	var t := global_transform
	for side: int in [-1, 1]:
		var sname := "l" if side < 0 else "r"
		var fs := float(side)
		var a := _phase + (0.0 if side < 0 else PI)
		# crawl: the hand reaches past the head, then pulls down to the hip
		var reach := Vector3(0.2 * fs, 1.95 + 0.35 * cos(a), -0.12 + 0.25 * maxf(sin(a), 0.0))
		var arm: Dictionary = _limbs[sname + "_arm"]
		_solve(arm, t * reach, t.basis * Vector3(fs * 0.5, 0.0, 0.6))
		# flutter kick
		var kick := Vector3(0.11 * fs, 0.12, 0.12 * sin(_phase * 3.0 + (0.0 if side < 0 else PI)))
		var leg: Dictionary = _limbs[sname + "_leg"]
		_solve(leg, t * kick, t.basis * Vector3(0.0, 0.0, -1.0))
		arm.hold = Vector3.INF
		leg.hold = Vector3.INF
	_feet(-t.basis.y, t.basis.z) # pointed toes, trailing


## Climbing. surface: the rock point under the body's centre (on the map, as
## the holds: Origin); n: its normal;
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
		var sock := Origin.map(l.root.global_position) # (the holds are on the map: they stay put when the origin moves)
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
		_solve(l, Origin.render(target), pole)
		# never through the rock: if the elbow or knee is in it, bend away more
		var joint := Origin.map((l.b as Node3D).global_position)
		if _depth(joint) > -0.08:
			_solve(l, Origin.render(target), pole.lerp(n, 0.8))
	_feet(up_t, n)


## The point on the terrain surface nearest p (a few steps along the normal),
## lifted a little so a hand rests on it rather than in it. (On the map, as
## p: not a drawn position.)
func on_rock(p: Vector3) -> Vector3:
	if not trunk.is_empty():
		var f := Population.trunk_frame(trunk, Population.trunk_nearest(trunk, p))
		var axis: Vector3 = f[0]
		var d := p - axis
		d -= (f[2] as Vector3) * d.dot(f[2])
		return axis + d.normalized() * ((f[1] as float) + 0.04)
	if world == null:
		return p
	for i in 3:
		var n := world.normal_at(p.x, p.z)
		var off := (p.y - world.height_at(p.x, p.z)) * n.y # distance above the surface, along n
		p -= n * off
	return p + world.normal_at(p.x, p.z) * 0.04


## How far p (on the map) is inside the rock (m, along the surface normal;
## negative: outside).
func _depth(p: Vector3) -> float:
	if not trunk.is_empty():
		var f := Population.trunk_frame(trunk, Population.trunk_nearest(trunk, p))
		return (f[1] as float) - p.distance_to(f[0])
	if world == null:
		return -1.0
	return (world.height_at(p.x, p.z) - p.y) * world.normal_at(p.x, p.z).y


## How far each hand and foot is from the terrain surface (m): for checks.
func contact_gaps() -> Dictionary:
	var out := {}
	for name in _limbs:
		var l: Dictionary = _limbs[name]
		var b: Node3D = l.b
		var tip := Origin.map(b.global_position - b.global_basis.z * l.len[1])
		var n := world.normal_at(tip.x, tip.z)
		out[name] = snappedf((tip.y - world.height_at(tip.x, tip.z)) * n.y, 0.01)
	return out


## Where a hand ("l" or "r") holds what it carries.
func grip(side: String) -> Node3D:
	return _grips.get(side)
