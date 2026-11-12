class_name Bird
extends Node3D
## A bird, the make they share (docs/birds.md; the wild turkey its first:
## WildTurkey), life size: one mesh, posed in its shader (bird.gdshader,
## bird_rig.gdshaderinc), no Skeleton3D. This is the body and the motors
## under a species, which says its shape, its colours and its ways (_think).
##
## The body (_build, from `shape`, cm): one skin swept from its tail's root
## along its back, up its neck and over its head to its bill's tip, bending
## smoothly at each neck joint; its lower bill; its legs (feathered thigh
## and shin, scaled tarsus, four toes); each wing its own surface over three
## bones and its flight feathers, every one a card (primaries on the hand,
## secondaries on the forearm, tertials on the upper arm); the tail's
## feathers and its coverts, cards fanned about its joint.
##
## The joints (16, given to the shader each frame as skin matrices): the
## trunk; four neck joints, the head, the lower bill; the tail; each leg's
## thigh, shin, tarsus, toes. The wings are four numbers each (raised,
## swept, twisted, spread), the shader's to work out.
##
## The motors:
## - the ground: walking and running on two legs, each foot planted where
##   it comes down and left there till its next step (no sliding), the
##   hock bending back; standing, crouching, sitting
## - the head: held still in the air while the body moves under it, thrust
##   forward to its next place each step (a walking bird's bob); reached
##   to a point (pecking); the neck's joints following (a chain drawn out
##   to wherever the head is)
## - the air: fly_to(point): a crouch, a leap, flapping up and away,
##   then wings set, a glide down, a flare, the legs brought forward, and
##   run out on landing; its speeds and its beat from its weight and its
##   wings (BirdFlight)
## Steering (pilot.gd): go, go_to, face, stop, act, behaviours, is_busy,
## action_finished.

signal action_finished(name: String, ok: bool)

const SHADER := preload("res://shaders/render/bird.gdshader")
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const CM := 0.01
const J_BODY := 0
const J_NECK := 1
const J_HEAD := 5
const J_JAW := 6
const J_TAIL := 7
const J_LEG := [8, 12] # (left, right: thigh, shin, tarsus, toes)

var shape := {} ## the species' (cm): see WildTurkey
var colors := {} ## its shader's
var male := false
var young := false
var dead := false
var height := Callable() ## (x, z) -> the ground's y
var ground_y := 0.0
var mass := 1.0 ## kg
var span := 1.0 ## m
var wing_area := 0.2 ## m2
var walk_speed := 0.7 ## m/s
var run_speed := 4.0
var size := 1.0 ## (a share of the shape's size: a growing poult)

var _pos := Vector3.ZERO
var _yaw := 0.0
var _speed := 0.0
var _goal := Vector3.ZERO
var _going := false
var _pace := 0.7
var _face_to := NAN # (a yaw to turn to, standing)
var _t := 0.0
var rng := RandomNumberGenerator.new()

# the pose: what it is (cur) and what it's wanted to be (want), eased
var cur := {}
var want := {}
var rate := {} # (each one's own quickness, /s; else 6)
var head_off := Vector3.ZERO # the head's place, from where it's held at rest (m: right, up, back)
var head_want := Vector3.ZERO
var head_rate := 6.0
var head_point := Vector3.INF # (the world: its bill's tip reached to here, if set)
var look_yaw := 0.0
var foot_off: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO] # (each foot moved from where it's planted: scratching, treading; m)
var lift_y := 0.0 # (m: stood on something, hopping)
var beat_amp := 1.0 ## how deep its wingbeat (a falcon's shallow, quick)
var air_foot := Vector3.ZERO ## (in the air: its feet thrust this far from their place, body m: striking, landing)
var talon_open := 0.0 ## its toes spread, reaching (0 .. 1)

var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _rest := {} # joint -> its place at rest (m)
var _neck_rest: Array[Vector3] = []
var _g: Array[Transform3D] = []
var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO] # planted (the world)
var _swing: Array[float] = [-1.0, -1.0]
var _from: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _swing_t := 0.3
var _head_hold := Vector3.INF
var _thrust := 0.0
var _bob := 0.0
var _phase := 0.0 # the wingbeat's
var _flap := 0.0 # 0 wings as posed .. 1 beating
var _fly := {} # a flight under way
var _air := false
var _pilot: PilotScript
var _piloted := false
static var _meshes := {}


func _init() -> void:
	rng.randomize()
	for k: String in ["pitch", "drop", "roll", "head_pitch", "jaw", "tail_up", "tail_yaw", "tail_spread", "tail_arch", "puff", "flush", "snood",
			"load", "droop", "crouch", "legs_tuck", "sway", "eye_shut", "fold_pitch"]:
		cur[k] = 0.0
		want[k] = 0.0
	for s: String in ["l", "r"]:
		for k: String in ["up", "sweep", "twist", "spread"]:
			cur["w%s_%s" % [s, k]] = 0.0
			want["w%s_%s" % [s, k]] = 0.0
	fold_wings()
	for k: String in cur:
		cur[k] = want[k]


func _ready() -> void:
	_build()
	if _pos == Vector3.ZERO and position != Vector3.ZERO:
		place(position, rotation.y)


## Put down at `at` (its parent's space), facing yaw.
func place(at: Vector3, yaw := 0.0) -> void:
	_pos = Vector3(at.x, _ground(at.x, at.z), at.z)
	_yaw = yaw
	_goal = _pos
	_going = false
	_plant_feet()
	_head_hold = Vector3.INF
	position = _pos
	rotation = Vector3(0.0, _yaw, 0.0)


func _ground(x: float, z: float) -> float:
	return float(height.call(x, z)) if height.is_valid() else ground_y


func _fwd() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _right() -> Vector3:
	return Vector3(cos(_yaw), 0.0, -sin(_yaw))


## Wings folded to its sides (what they are unless something spreads them).
func fold_wings() -> void:
	for s: String in ["l", "r"]:
		want["w%s_up" % s] = -1.62
		want["w%s_sweep" % s] = 0.2
		want["w%s_twist" % s] = -0.05
		want["w%s_spread" % s] = 0.0


func set_wings(up: float, sweep: float, twist: float, spread: float) -> void:
	for s: String in ["l", "r"]:
		want["w%s_up" % s] = up
		want["w%s_sweep" % s] = sweep
		want["w%s_twist" % s] = twist
		want["w%s_spread" % s] = spread


# --- going about ------------------------------------------------------------------

## Walking (or, faster than its walk, running) to `to`.
func walk_to(to: Vector3, pace := -1.0) -> void:
	_goal = Vector3(to.x, 0.0, to.z)
	_going = true
	_pace = pace if pace > 0.0 else walk_speed
	_face_to = NAN


func halt() -> void:
	_going = false
	_goal = _pos


func turn_to(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 1e-4:
		_face_to = atan2(-dir.x, -dir.z)


func arrived() -> bool:
	return not _going


func in_air() -> bool:
	return _air


## Up and away to `to` (the ground there): a leap, flapping up, a glide
## down, a flare, landing at a run. top: how high it gets (m; -1 its own).
func fly_to(to: Vector3, top := -1.0) -> void:
	if dead or _air:
		return
	var d := Vector2(to.x - _pos.x, to.z - _pos.z).length()
	if d < 1.0:
		return
	var vmax := minf(BirdFlight.best_glide_speed(mass, span, wing_area) * 0.8, sqrt(d) * 2.6)
	_fly = {"from": _pos, "to": Vector3(to.x, _ground(to.x, to.z), to.z), "s": 0.0, "d": d, "v": 0.0, "vmax": vmax,
			"top": top if top > 0.0 else clampf(d * 0.22, 1.2, 6.0), "crouch": 0.22, "hz": BirdFlight.wingbeat_hz(mass, span, wing_area)}
	_going = false
	_air = true
	_yaw = atan2(-(to.x - _pos.x), -(to.z - _pos.z))


func _process(dt: float) -> void:
	if _mat == null or dt <= 0.0:
		return
	_t += dt
	if _pilot:
		_pilot.tick(dt)
	if not dead:
		_think(dt)
	if _air:
		_fly_step(dt)
	else:
		_ground_step(dt)
	for k: String in cur:
		var r: float = rate.get(k, 6.0)
		cur[k] = lerpf(cur[k], want[k], 1.0 - exp(-r * dt))
	head_off = head_off.lerp(head_want, 1.0 - exp(-head_rate * dt))
	position = _pos + Vector3(0.0, lift_y, 0.0)
	rotation = Vector3(0.0, _yaw, 0.0)
	_mi.scale = Vector3.ONE * size
	_solve(dt)


## (The species': what it does.)
func _think(_dt: float) -> void:
	pass


func _ground_step(dt: float) -> void:
	var to := Vector3(_goal.x - _pos.x, 0.0, _goal.z - _pos.z)
	var dist := to.length()
	var target_speed := 0.0
	if _going and not dead:
		if dist < maxf(0.05, _speed * 0.12):
			_going = false
		else:
			var wyaw := atan2(-to.x, -to.z)
			var turn := wrapf(wyaw - _yaw, -PI, PI)
			_yaw += clampf(turn, -3.2 * dt, 3.2 * dt)
			target_speed = _pace * clampf(1.2 - absf(turn) * 0.9, 0.15, 1.0) * clampf(dist / 0.25, 0.3, 1.0)
	elif not is_nan(_face_to) and not dead:
		var turn := wrapf(_face_to - _yaw, -PI, PI)
		_yaw += clampf(turn, -2.0 * dt, 2.0 * dt)
		if absf(turn) < 0.03:
			_face_to = NAN
	_speed = move_toward(_speed, target_speed, (3.0 + _pace * 3.0) * dt)
	_pos += _fwd() * _speed * dt
	_pos.y = _ground(_pos.x, _pos.z)
	if dead:
		return
	# the feet: each left where it came down, till it's a step behind its
	# place under the body; then swung to where that will be
	var stride := clampf(_speed * 0.42, 0.06, 0.62) * size
	_swing_t = clampf(0.3 / (0.45 + _speed), 0.11, 0.36)
	var hip: Vector3 = shape.hip * CM * size
	var lead := _fwd() * (_speed * _swing_t + stride * 0.5)
	var bob := 0.0
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var home := _pos + _right() * side * hip.x * (1.0 - 0.35 * clampf(_speed / run_speed, 0.0, 1.0)) + _fwd() * -(float(shape.foot.z) * CM * size)
		home.y = _ground(home.x, home.z)
		if _swing[i] >= 0.0:
			_swing[i] += dt / _swing_t
			var s := clampf(_swing[i], 0.0, 1.0)
			var e := s * s * (3.0 - 2.0 * s)
			var tgt := home + lead * (1.0 - s * 0.5)
			var p := _from[i].lerp(tgt, e)
			p.y = lerpf(_from[i].y, _ground(tgt.x, tgt.z), e) + sin(PI * s) * (0.035 + stride * 0.3)
			_feet[i] = p
			bob = sin(PI * s)
			if s >= 1.0:
				_swing[i] = -1.0
				_feet[i].y = _ground(p.x, p.z)
				_step_down(i)
		else:
			var o := 1 - i
			var off := home + _fwd() * _speed * _swing_t * 0.5 - _feet[i]
			off.y = 0.0
			var off_o := home - _feet[o]
			var trig := stride * 0.5 if _speed > 0.05 else 0.05 * size
			var other_free := _swing[o] < 0.0 or (_speed > run_speed * 0.6 and _swing[o] > 0.55)
			if other_free and off.length() > trig and (_swing[o] >= 0.0 or off.length() >= (Vector3(off_o.x, 0.0, off_o.z)).length() * 0.6):
				_swing[i] = 0.0
				_from[i] = _feet[i]
	_bob = lerpf(_bob, bob, 1.0 - exp(-14.0 * dt))


## (A foot's come down: the species', if it cares.)
func _step_down(_i: int) -> void:
	pass


func _plant_feet() -> void:
	if shape.is_empty():
		return
	var hip: Vector3 = shape.hip * CM * size
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var p := _pos + _right() * side * hip.x + _fwd() * -(float(shape.foot.z) * CM * size)
		p.y = _ground(p.x, p.z)
		_feet[i] = p
		_swing[i] = -1.0


func _fly_step(dt: float) -> void:
	var f := _fly
	var hz: float = f.hz
	if float(f.crouch) > 0.0: # (down on its hocks, then up)
		f.crouch = float(f.crouch) - dt
		want.crouch = 0.5
		rate["crouch"] = 18.0
		set_wings(0.6, 0.2, 0.2, 0.9)
		return
	var s: float = f.s
	var d: float = f.d
	var vmax: float = f.vmax
	var want_v := vmax * (0.25 + 0.75 * smoothstep(0.0, 0.25, s)) * (1.0 - 0.65 * smoothstep(0.78, 1.0, s))
	f.v = move_toward(float(f.v), want_v, vmax * 2.5 * dt)
	s = minf(s + float(f.v) * dt / d, 1.0)
	f.s = s
	var from: Vector3 = f.from
	var to: Vector3 = f.to
	var hgt := float(f.top) * smoothstep(0.0, 0.34, s) * (1.0 - pow(smoothstep(0.34, 1.0, s), 1.25))
	var slope := (float(f.top) * (smoothstep(0.0, 0.34, s + 0.02) * (1.0 - pow(smoothstep(0.34, 1.0, s + 0.02), 1.25))) - hgt) / (0.02 * d)
	var p := from.lerp(to, s)
	p.y = lerpf(from.y, to.y, s) + hgt
	_pos = p
	_speed = f.v
	# beating up and away; then its wings set, cupped, gliding down; a
	# few hard beats in the flare
	var beating := 1.0 - smoothstep(0.45, 0.58, s) + smoothstep(0.86, 0.93, s)
	_flap = move_toward(_flap, clampf(beating, 0.0, 1.0), dt * 5.0)
	_phase += TAU * hz * dt * (1.15 if s < 0.3 else 1.0)
	var flare := smoothstep(0.82, 0.97, s)
	want.pitch = -clampf(atan(slope) * 0.8, -0.35, 0.6) - 0.5 * flare
	want.crouch = 0.0
	want.legs_tuck = 1.0 - smoothstep(0.8, 0.92, s)
	want.tail_spread = 0.55 + 0.4 * flare + 0.2 * (1.0 - smoothstep(0.0, 0.2, s))
	want.tail_up = -0.15 - 0.5 * flare
	want.load = 0.35 + 0.5 * flare
	head_want = Vector3(0.0, -0.2, -0.1)
	head_rate = 8.0
	for k: String in ["pitch", "legs_tuck", "tail_spread", "tail_up"]:
		rate[k] = 8.0
	if s >= 1.0: # (down, at a run)
		_air = false
		_flap = 0.0
		_pos.y = _ground(_pos.x, _pos.z)
		_speed = minf(float(f.v), run_speed * 0.6)
		_goal = _pos + _fwd() * _speed * 0.5
		_going = true
		_pace = walk_speed
		_plant_feet()
		fold_wings()
		want.legs_tuck = 0.0
		want.pitch = 0.0
		want.load = 0.0
		want.tail_up = 0.0
		want.tail_spread = 0.0
		head_want = Vector3.ZERO
		_landed()


## (Down from a flight: the species'.)
func _landed() -> void:
	pass


# --- the joints -------------------------------------------------------------------

func _xb(p: Vector3) -> Vector3: # (a point of the body at rest, where the trunk has it)
	return _g[J_BODY] * (p - (_rest[J_BODY] as Vector3))


func _solve(dt: float) -> void:
	var sz := 1.0
	var pivot: Vector3 = _rest[J_BODY]
	var inv := Basis(Vector3.UP, -_yaw)
	# the trunk: pitched (nose down), rolled, dropped (crouching, sitting), bobbing
	var drop: float = cur.drop + cur.crouch * 0.16 * sz
	var b := Basis(Vector3.FORWARD, cur.roll) * Basis(Vector3.RIGHT, -float(cur.pitch))
	var heave := 0.0
	if _air:
		heave = BirdFlight.heave(float(_fly.hz)) * sin(_phase) * _flap
	_g[J_BODY] = Transform3D(b, pivot + Vector3(0.0, -drop - _bob * 0.012 * sz * minf(_speed, 1.5) + heave, 0.0))
	# the tail
	_g[J_TAIL] = Transform3D(b * Basis(Vector3.RIGHT, -float(cur.tail_up)) * Basis(Vector3.UP, cur.tail_yaw), _xb(_rest[J_TAIL]))
	# the head: where it wants to be (from its place at rest, or reached to
	# a point), held still in the air between a walking bird's thrusts
	var head_rest: Vector3 = _rest[J_HEAD]
	var d_model := head_rest + head_off
	if _air or dead:
		d_model = _xb(head_rest) + b * head_off
	var xf := Transform3D(Basis(Vector3.UP, _yaw) * size, _pos)
	var d_world := xf * d_model
	if head_point != Vector3.INF:
		d_world = head_point + (xf.basis * (head_rest - (_bill_tip() as Vector3))) * 0.9
	if _head_hold == Vector3.INF or _air or dead:
		_head_hold = d_world
	var bobs := _speed > 0.08 and _speed < run_speed * 0.55 and head_point == Vector3.INF and not _air
	if bobs:
		var ahead := (d_world - _head_hold).dot(_fwd())
		if _thrust <= 0.0 and ahead > 0.035 * size + _speed * 0.06:
			_thrust = 1.0
		if _thrust > 0.0:
			_thrust -= dt / 0.11
			_head_hold = _head_hold.lerp(d_world + _fwd() * (0.02 * size + _speed * 0.05), 1.0 - exp(-26.0 * dt))
		else: # (held: only its height and its side kept up)
			var keep := _head_hold
			var along := (d_world - keep).dot(_fwd())
			_head_hold = d_world - _fwd() * along
			_head_hold = keep.lerp(_head_hold, 1.0 - exp(-10.0 * dt))
	else:
		_head_hold = _head_hold.lerp(d_world, 1.0 - exp(-(head_rate + 6.0) * dt))
		_thrust = 0.0
	var h := inv * (_head_hold - _pos) / size
	# the neck: a chain from its root to the head, drawn out to wherever that is
	var pts: Array[Vector3] = []
	for r in _neck_rest:
		pts.append(_xb(r))
	var n := pts.size()
	var lens: Array[float] = []
	var total := 0.0
	for i in n - 1:
		lens.append(_neck_rest[i].distance_to(_neck_rest[i + 1]))
		total += lens[i]
	var root := pts[0]
	if (h - root).length() > total * 0.985:
		h = root + (h - root).normalized() * total * 0.985
	for it in 5:
		pts[n - 1] = h
		for i in range(n - 2, -1, -1):
			pts[i] = pts[i + 1] + (pts[i] - pts[i + 1]).normalized() * lens[i]
		pts[0] = root
		for i in range(1, n):
			pts[i] = pts[i - 1] + (pts[i] - pts[i - 1]).normalized() * lens[i - 1]
	for i in n - 1:
		var rd := (_neck_rest[i + 1] - _neck_rest[i]).normalized()
		var cd := (pts[i + 1] - pts[i]).normalized()
		_g[J_NECK + i] = Transform3D(Basis(Quaternion(rd, cd)), pts[i])
	var hb := Basis(Vector3.UP, look_yaw) * Basis(Vector3.RIGHT, -float(cur.head_pitch))
	if dead or _air:
		hb = b * hb
	_g[J_HEAD] = Transform3D(hb, pts[n - 1])
	var jaw_rest: Vector3 = _rest[J_JAW]
	_g[J_JAW] = Transform3D(hb * Basis(Vector3.RIGHT, -float(cur.jaw)), pts[n - 1] + hb * (jaw_rest - head_rest))
	# the legs: thigh with the trunk; shin and tarsus reaching the foot, the hock bent back
	var knee0: Vector3 = shape.knee * CM * sz
	var ank0: Vector3 = shape.ankle * CM * sz
	var foot0: Vector3 = shape.foot * CM * sz
	var hip0: Vector3 = shape.hip * CM * sz
	var la := knee0.distance_to(ank0)
	var lb := ank0.distance_to(foot0)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var m := Vector3(side, 1.0, 1.0)
		var hip := _xb(hip0 * m)
		var knee := _xb(knee0 * m)
		var foot := inv * (_feet[i] - _pos) / size + Vector3(0.0, foot0.y, 0.0) + foot_off[i]
		var lifted := clampf((foot.y - foot0.y) / (0.06 * sz), 0.0, 1.0) if _swing[i] >= 0.0 or foot_off[i].y > 0.0 else 0.0
		var tuck: float = cur.legs_tuck
		if _air or dead:
			# (in the air: drawn up under its tail, or let down forward to land; dead: stiff)
			var down_p := _xb(foot0 * m + Vector3(0.0, 0.0, -0.05 * sz) + air_foot)
			var up_p := _xb((knee0 + (shape.get("tuck", Vector3(0.0, -0.03, 0.2)) as Vector3) * sz) * m)
			foot = down_p.lerp(up_p, tuck)
			lifted = tuck
		var kd := foot - knee
		var dl := clampf(kd.length(), absf(la - lb) + 0.002, la + lb - 0.002)
		var dir := kd.normalized()
		var x := (la * la - lb * lb + dl * dl) / (2.0 * dl)
		var y := sqrt(maxf(la * la - x * x, 0.0))
		var back := (Vector3.BACK - dir * dir.z)
		back = back.normalized() if back.length() > 1e-4 else Vector3.BACK
		var ank := knee + dir * x + back * y
		var ft := knee + dir * dl
		var j: int = J_LEG[i]
		_g[j] = Transform3D(Basis(Quaternion(((knee0 - hip0) * m).normalized(), (knee - hip).normalized())), hip)
		_g[j + 1] = Transform3D(Basis(Quaternion(((ank0 - knee0) * m).normalized(), (ank - knee).normalized())), knee)
		_g[j + 2] = Transform3D(Basis(Quaternion(((foot0 - ank0) * m).normalized(), (ft - ank).normalized())), ank)
		var tb := Basis(Vector3.RIGHT, -(0.9 * lifted + 0.5 * tuck) * (1.0 - talon_open) + 0.5 * talon_open)
		if dead:
			tb = b * Basis(Vector3.RIGHT, -0.7)
		_g[j + 3] = Transform3D(tb, ft)
	# to the shader: each joint's skin matrix, three rows
	var rows := PackedVector4Array()
	rows.resize(48)
	for j in 16:
		var g := _g[j]
		var o: Vector3 = g.origin - g.basis * (_rest[j] as Vector3)
		rows[j * 3] = Vector4(g.basis.x.x, g.basis.y.x, g.basis.z.x, o.x)
		rows[j * 3 + 1] = Vector4(g.basis.x.y, g.basis.y.y, g.basis.z.y, o.y)
		rows[j * 3 + 2] = Vector4(g.basis.x.z, g.basis.y.z, g.basis.z.z, o.z)
	_mat.set_shader_parameter("jm", rows)
	# the wings: as posed, or beating (down spread and twisted nose down, up half folded)
	var wl := Vector4(cur.wl_up, cur.wl_sweep, cur.wl_twist, cur.wl_spread)
	var wr := Vector4(cur.wr_up, cur.wr_sweep, cur.wr_twist, cur.wr_spread)
	if _flap > 0.0:
		var sn := sin(_phase)
		var cs := cos(_phase)
		var upstroke := smoothstep(-0.3, 0.8, cs)
		var beat := Vector4(0.12 + 0.95 * beat_amp * sn, 0.12 + 0.28 * upstroke, 0.3 * cs, lerpf(1.0, lerpf(1.0, 0.62, beat_amp), upstroke))
		wl = wl.lerp(beat, _flap)
		wr = wr.lerp(beat, _flap)
	_mat.set_shader_parameter("wing", PackedVector4Array([wl, wr]))
	for k: String in ["tail_spread", "tail_arch", "puff", "flush", "snood", "sway", "eye_shut", "fold_pitch"]:
		_mat.set_shader_parameter(k, cur[k])
	_mat.set_shader_parameter("feather_load", cur.load)
	_mat.set_shader_parameter("wing_droop", cur.droop)


func _bill_tip() -> Vector3:
	var sp: Array = shape.spine
	var e: Array = sp[sp.size() - 1]
	return Vector3(0.0, e[0], e[1]) * CM


## Where its bill's tip is (the world).
func bill_tip() -> Vector3:
	return global_transform * ((_g[J_HEAD] * (_bill_tip() - (_rest[J_HEAD] as Vector3))) * size)


# --- steering (pilot.gd) ----------------------------------------------------------

func _pl() -> PilotScript:
	if _pilot == null:
		_pilot = PilotScript.new(self)
		_pilot.finished = action_finished.emit
	return _pilot


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_pl().go(direction, speed, seconds)


func go_to(point: Vector3, speed := -1.0) -> void:
	_pl().go_to(point, speed)


func face(direction: Vector3) -> void:
	_pl().face(direction)


func stop() -> void:
	_pl().stop()


func act(name: String, args := {}) -> bool:
	return _pl().act(name, args)


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func is_busy() -> bool:
	return _pilot != null and _pilot.busy()


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return _fwd()


func _p_steer(point: Vector3, speed: float) -> void:
	_piloted = true
	walk_to(point, speed)


func _p_hold() -> void:
	_piloted = true
	halt()


func _p_mobile() -> bool:
	return not dead and not _air


func _p_speed() -> float:
	return walk_speed


func _p_reach() -> float:
	return 0.12 * size + 0.05


func _p_behaviours() -> PackedStringArray:
	return PackedStringArray()


func _p_act(_name: String, _args: Dictionary) -> bool:
	return false


func _p_act_done(_name: String) -> bool:
	return true


func _p_act_secs(_name: String) -> float:
	return -1.0


# --- the mesh ---------------------------------------------------------------------

## (What tells one mesh of this species from another: the species'.)
func _mesh_key() -> String:
	return "%s:%s:%s" % [(get_script() as Script).resource_path, male, young]


## Its mesh made again (a new shape: a chick fledged).
func _rebuild() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	_build()


func _build() -> void:
	var key := _mesh_key()
	if not _meshes.has(key):
		_meshes[key] = _make_mesh()
	var built: Array = _meshes[key]
	_rest = built[1]
	_neck_rest.assign(built[2])
	_mi = MeshInstance3D.new()
	_mi.mesh = built[0]
	_mi.custom_aabb = AABB(Vector3(-1.6, -0.5, -1.6), Vector3(3.2, 2.6, 3.2))
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mi.material_override = _mat
	add_child(_mi)
	var S := shape
	_mat.set_shader_parameter("shoulder", (S.shoulder as Vector3) * CM)
	_mat.set_shader_parameter("wing_len", (S.wing as Vector3) * CM)
	_mat.set_shader_parameter("tail_at", (S.tail as Vector3) * CM)
	_mat.set_shader_parameter("snood_at", (S.get("snood", Vector3.ZERO) as Vector3) * CM)
	_mat.set_shader_parameter("eye_at", (S.eye as Vector3) * CM)
	_mat.set_shader_parameter("fold_chord", float(S.get("fold_chord", 0.3)))
	_mat.set_shader_parameter("fold_fan", S.get("fold_fan", Vector3.ZERO))
	_mat.set_shader_parameter("fold_tuck", float(S.get("fold_tuck", 0.0)))
	_mat.set_shader_parameter("fold_tuck_front", float(S.get("fold_tuck_front", 0.6)))
	for k: String in colors:
		_mat.set_shader_parameter(k, colors[k])
	_g.resize(16)
	for j in 16:
		_g[j] = Transform3D(Basis(), _rest[j])
	_plant_feet()


static func _cr(p0: float, p1: float, p2: float, p3: float, f: float) -> float:
	return 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)


static func _vert(st: SurfaceTool, p: Vector3, n: Vector3, c0: Color, c1: Color, c2 := Color(0, 0, 0, 0), uv := Vector2.ZERO) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.set_custom(0, c0)
	st.set_custom(1, c1)
	st.set_custom(2, c2)
	st.add_vertex(p)


## A grid (rows of [p, n, c0, c1, c2, uv]) into st.
static func _grid(st: SurfaceTool, rows: Array) -> void:
	for i in rows.size() - 1:
		var a: Array = rows[i]
		var b: Array = rows[i + 1]
		for j in a.size() - 1:
			for q: Array in [a[j], b[j], b[j + 1], a[j], b[j + 1], a[j + 1]]:
				_vert(st, q[0], q[1], q[2], q[3], q[4], q[5])


## A ball (radii r, turned by basis) at c, rigid to joint j.
static func _ball(st: SurfaceTool, c: Vector3, r: Vector3, part: float, j: int, basis := Basis(), along_y := false, uv := Vector2(-1.0, -1.0)) -> void:
	var rows := []
	for i in 7:
		var la := PI * i / 6.0
		var row := []
		for k in 11:
			var lo := TAU * k / 10.0
			var d := Vector3(sin(la) * cos(lo), cos(la), sin(la) * sin(lo))
			var cu := Color(part, (1.0 - d.y) * 0.5 if along_y else 0.5, 0.5, 0) if uv.x < 0.0 else Color(part, uv.x, uv.y, 0)
			row.append([c + basis * (d * r), (basis * (d / r)).normalized(), cu, Color(0, j, j, 0), Color(0, 0, 0, 0), Vector2(lo * r.x, la * r.y)])
		rows.append(row)
	_grid(st, rows)


## A tube through pts ([p, r, ja, jb, wb] each), its part; u 0..1 along it.
static func _tube(st: SurfaceTool, pts: Array, part: float, ring := 10, cap := true) -> void:
	var rows := []
	var n := pts.size()
	var total := 0.0
	for i in n - 1:
		total += ((pts[i + 1] as Array)[0] as Vector3).distance_to((pts[i] as Array)[0])
	var along := 0.0
	for i in n:
		var p: Vector3 = (pts[i] as Array)[0]
		var t: Vector3 = (((pts[mini(i + 1, n - 1)] as Array)[0] as Vector3) - ((pts[maxi(i - 1, 0)] as Array)[0] as Vector3)).normalized()
		if i > 0:
			along += p.distance_to((pts[i - 1] as Array)[0])
		var sx := t.cross(Vector3.BACK if absf(t.z) < 0.9 else Vector3.UP).normalized()
		var sy := t.cross(sx).normalized()
		var r: float = (pts[i] as Array)[1]
		var row := []
		for k in ring + 1:
			var a := TAU * k / ring
			var d := sx * cos(a) + sy * sin(a)
			row.append([p + d * r, d, Color(part, along / maxf(total, 1e-5), float(k) / ring, 0), Color(0, (pts[i] as Array)[2], (pts[i] as Array)[3], (pts[i] as Array)[4]), Color(0, 0, 0, 0),
					Vector2(float(k) / ring * TAU * r, along)])
		rows.append(row)
	if cap:
		var e: Array = pts[n - 1]
		var tip := []
		for k in ring + 1:
			var q: Array = ((rows[n - 1] as Array)[k] as Array).duplicate()
			q[0] = e[0]
			tip.append(q)
		rows.append(tip)
	_grid(st, rows)


## A feather: a card, its outline cut in it (len, wide: m; round: where
## along it its tip begins to round). c1: how it's posed (bird_rig); root:
## its root's reach along its bone (or out from the tail's joint).
static func _feather(st: SurfaceTool, part: float, idx: float, c1: Color, root: float, len: float, wide: float, lift: float, round_from := 0.8) -> void:
	var us := [0.0, 0.1, 0.26, 0.45, 0.64, 0.8, 0.9, 0.96, 1.0]
	var rows := []
	for u: float in us:
		var wp := lerpf(0.22, 1.0, smoothstep(0.0, 0.26, u))
		if u > round_from:
			wp *= sqrt(maxf(1.0 - pow((u - round_from) / (1.0 - round_from), 2.0), 0.0))
		var row := []
		for k in 5:
			var v := -1.0 + 0.5 * k
			var w := v * wide * 0.5 * wp
			var h := lift + (1.0 - v * v) * wide * 0.07
			row.append([Vector3.ZERO, Vector3(-v * 0.32, 1.0, 0.0).normalized(), Color(part, u, v, idx), c1, Color(root, u * len, w, h), Vector2.ZERO])
		rows.append(row)
	_grid(st, rows)


## The mesh at rest (m): [mesh, its joints' places, the neck's chain].
func _make_mesh() -> Array:
	var S := shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		st.set_custom_format(k, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var rest := {}
	rest[J_BODY] = (S.pivot as Vector3) * CM
	# the skin: tail's root to bill's tip, one sweep ([y, z, half width,
	# half height, where along the chain: 0 the trunk, 0.5 the first neck
	# joint .. 4.5 the head's, past 5 the bill])
	var sp: Array = S.spine
	var K := sp.size()
	var SUB := 5
	var line := [] # [p, w, h, c]
	for i in K - 1:
		for q in SUB + (1 if i == K - 2 else 0):
			var f := float(q) / SUB
			var vals := []
			for c in 5:
				vals.append(_cr((sp[maxi(i - 1, 0)] as Array)[c], (sp[i] as Array)[c], (sp[i + 1] as Array)[c], (sp[mini(i + 2, K - 1)] as Array)[c], f))
			line.append([Vector3(0.0, vals[0], vals[1]) * CM, maxf(float(vals[2]), 0.02) * CM, maxf(float(vals[3]), 0.02) * CM, clampf(lerpf((sp[i] as Array)[4], (sp[i + 1] as Array)[4], f), 0.0, 6.0)])
	var neck: Array[Vector3] = []
	var rows := []
	var along := 0.0
	var RING := 22
	var skin_rings := [] # (kept: [p, dorsal, c] for what's set on the skin)
	for i in line.size():
		var e: Array = line[i]
		var p: Vector3 = e[0]
		var c: float = e[3]
		if i > 0:
			var e0: Array = line[i - 1]
			along += p.distance_to(e0[0])
			for k in 5: # (a joint where the chain's count passes k + 0.5)
				if float(e0[3]) < k + 0.5 and c >= k + 0.5:
					neck.append((e0[0] as Vector3).lerp(p, (k + 0.5 - float(e0[3])) / maxf(c - float(e0[3]), 1e-5)))
		var t: Vector3 = (((line[mini(i + 1, line.size() - 1)] as Array)[0] as Vector3) - ((line[maxi(i - 1, 0)] as Array)[0] as Vector3)).normalized()
		# (the body's big rings kept upright: tipped with the chain where it
		# bends up into the neck they'd fold over each other on its inside)
		if not S.get("tilt_rings", false): # (a raptor's: all tilted with it, its body leaning)
			t = Vector3(0.0, 0.0, -1.0).lerp(t, smoothstep(0.12, 0.06, maxf(float(e[1]), float(e[2])) / maxf(size, 0.01) * 1.0)).normalized()
		var dorsal := Vector3.RIGHT.cross(t).normalized()
		skin_rings.append([p, dorsal, c, e[1], e[2]])
		var ja := clampi(int(floorf(c)), 0, 5)
		var jb := mini(ja + 1, 5)
		var wb := smoothstep(0.2, 0.8, c - floorf(c)) if c < 5.0 else 0.0
		var part := 2.0 if c > 5.02 else 0.0
		var u := (c - 5.0) if c > 5.02 else c / 5.0
		var w: float = e[1]
		var h: float = e[2]
		var per := TAU * sqrt((w * w + h * h) * 0.5)
		var row := []
		for k in RING + 1:
			var v := float(k) / RING
			var a := TAU * v
			var d := Vector3.RIGHT * sin(a) * w - dorsal * cos(a) * h
			var nn := (Vector3.RIGHT * sin(a) / w - dorsal * cos(a) / h).normalized()
			row.append([p + d, nn, Color(part, u, v, 0), Color(0, ja, jb, wb), Color(0, 0, 0, 0), Vector2((v - 0.5) * per, along)])
		rows.append(row)
	_grid(st, rows)
	for k in 4:
		rest[J_NECK + k] = neck[k]
	rest[J_HEAD] = neck[4]
	rest[J_JAW] = (S.jaw as Vector3) * CM
	rest[J_TAIL] = (S.tail as Vector3) * CM
	# the lower bill
	var jl := []
	for e: Array in S.lower_bill:
		jl.append([Vector3(0.0, e[0], e[1]) * CM, float(e[2]) * CM, J_JAW, J_JAW, 0.0])
	_tube(st, jl, 2.0, 8)
	# the eyes
	var eye: Vector3 = (S.eye as Vector3) * CM
	var er: float = float(S.eye_r) * CM
	for side: float in [-1.0, 1.0]:
		_ball(st, Vector3(eye.x * side, eye.y, eye.z), Vector3.ONE * er, 3.0, J_HEAD)
		if S.has("eye_ring"): # (bare skin round it: a raptor's yellow ring)
			_ball(st, Vector3((eye.x - er * 0.45) * side, eye.y, eye.z), Vector3(0.9, float(S.eye_ring), float(S.eye_ring)) * er, 1.0, J_HEAD)
		if S.has("brow"): # (the bony shelf over the eye: a hawk's scowl)
			var bw: Array = S.brow
			var bo: Vector3 = (bw[0] as Vector3) * CM
			_ball(st, Vector3(bo.x * side, bo.y, bo.z), (bw[1] as Vector3) * CM, 0.0, J_HEAD, Basis(Vector3.RIGHT, -0.15), false, Vector2(0.95, 0.5))
	if S.has("head_ball"): # (an owl's big round head, its face flattened: [centre, radii, how flat its front]; its poles fore and aft, its feathers lying back)
		var hb: Array = S.head_ball
		var hc: Vector3 = (hb[0] as Vector3) * CM
		var hr: Vector3 = (hb[1] as Vector3) * CM
		var hrows := []
		for i in 13:
			var la := PI * i / 12.0
			var row := []
			for k in 21:
				var lo := TAU * k / 20.0
				var d := Vector3(sin(la) * sin(lo), -sin(la) * cos(lo), -cos(la)) # (its seam under its chin)
				var rr := hr * Vector3(1.0, 1.0, float(hb[2]) if d.z < 0.0 else 1.0)
				row.append([hc + d * rr, (d / rr).normalized(), Color(0, 0.93, 0.5, 0), Color(0, J_HEAD, J_HEAD, 0), Color(0, 0, 0, 0), Vector2(lo * hr.x * 0.6, -la * hr.z * 1.3)])
			hrows.append(row)
		_grid(st, hrows)
	for tf: Array in S.get("tufts", []): # (ear tufts: [root, radii, leaning out, leaning back])
		for side: float in [-1.0, 1.0]:
			var tb := Basis(Vector3.RIGHT, float(tf[3])) * Basis(Vector3.FORWARD, float(tf[2]) * side)
			var t0: Vector3 = (tf[0] as Vector3) * CM * Vector3(side, 1.0, 1.0)
			_ball(st, t0 + tb.y * float((tf[1] as Vector3).y) * CM * 0.75, (tf[1] as Vector3) * CM, 0.0, J_HEAD, tb, false, Vector2(0.93, 0.5))
	if S.has("cere"): # (the bare waxy skin at the bill's root, the nostrils in it)
		var ce: Array = S.cere
		_ball(st, (ce[0] as Vector3) * CM, (ce[1] as Vector3) * CM, 1.0, J_HEAD)
	# the snood (a horn over the bill's root), the wattle under the chin,
	# the caruncles at the bare neck's foot
	if S.has("snood"):
		var sn: Vector3 = (S.snood as Vector3) * CM
		var srows := []
		for i in 9:
			var f := i / 8.0
			var r := lerpf(0.55, 0.16, f) * CM * float(S.get("snood_r", 1.0))
			var row := []
			for k in 9:
				var a := TAU * k / 8.0
				var d := Vector3(cos(a), 0.0, sin(a))
				row.append([sn + d * r + Vector3(0.0, f * 0.022, 0.0), d, Color(4, f, 0.5, 0), Color(0, J_HEAD, J_HEAD, 0), Color(0, 0, 0, 0), Vector2.ZERO])
			srows.append(row)
		_grid(st, srows)
	if S.has("wattle"):
		var wt: Array = S.wattle
		_ball(st, (wt[0] as Vector3) * CM, (wt[1] as Vector3) * CM, 5.0, J_HEAD, Basis(Vector3.RIGHT, 0.25), true)
	for cdef: Array in S.get("caruncles", []): # [where along the chain, round it (0 its front), its size (cm)]
		for r: Array in skin_rings:
			if float(r[2]) >= float(cdef[0]):
				var a: float = cdef[1]
				var out: Vector3 = (Vector3.RIGHT * sin(a) * float(r[3]) - (r[1] as Vector3) * cos(a) * float(r[4]))
				_ball(st, (r[0] as Vector3) + out * 0.82, Vector3(1.0, 0.8, 0.75) * float(cdef[2]) * CM, 5.0, clampi(int(floorf(float(r[2]))), 0, 5))
				break
	# the beard: bristles from the breast
	if S.has("beard"):
		var bd: Array = S.beard
		for k in 9:
			var a := TAU * k / 9.0
			var root: Vector3 = (bd[0] as Vector3) * CM + Vector3(cos(a), 0.0, sin(a) * 0.5) * 0.006
			var tip := root + (Vector3(cos(a) * 0.1, -1.0, -0.22 + sin(a) * 0.08)).normalized() * float(bd[1]) * CM * (0.85 + 0.15 * sin(k * 2.4))
			_tube(st, [[root, 0.0035, 0, 0, 0.0], [root.lerp(tip, 0.5) + Vector3(0.0, 0.0, 0.01), 0.003, 0, 0, 0.0], [tip, 0.0012, 0, 0, 0.0]], 6.0, 5)
	# the legs
	var hip: Vector3 = (S.hip as Vector3) * CM
	var knee: Vector3 = (S.knee as Vector3) * CM
	var ank: Vector3 = (S.ankle as Vector3) * CM
	var foot: Vector3 = (S.foot as Vector3) * CM
	var tr: Array = S.thigh_r
	var lr: float = float(S.leg_r) * CM
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var m := Vector3(side, 1.0, 1.0)
		var j: int = J_LEG[i]
		rest[j] = hip * m
		rest[j + 1] = knee * m
		rest[j + 2] = ank * m
		rest[j + 3] = foot * m
		_tube(st, [[hip * m, float(tr[0]) * CM, j, j, 0.0], [hip.lerp(knee, 0.6) * m, float(tr[0]) * CM, j, j, 0.0], [knee * m, float(tr[1]) * CM, j, j + 1, 0.5],
				[knee.lerp(ank, 0.4) * m, float(tr[1]) * CM * 0.85, j + 1, j + 1, 0.0], [knee.lerp(ank, 0.85) * m, lr * 1.5, j + 1, j + 1, 0.0], [knee.lerp(ank, 0.93) * m, lr * 1.1, j + 1, j + 1, 0.0]], 7.0, 12)
		_tube(st, [[knee.lerp(ank, 0.82) * m, lr * 1.05, j + 1, j + 1, 0.0], [ank * m, lr * 1.25, j + 1, j + 2, 0.5], [ank.lerp(foot, 0.3) * m, lr, j + 2, j + 2, 0.0],
				[ank.lerp(foot, 0.85) * m, lr, j + 2, j + 2, 0.0], [foot * m, lr * 1.3, j + 2, j + 2, 0.0]], float(S.get("leg_part", 8.0)), 9) # (an owl's: feathered to its toes)
		# the toes: three forward, one back, a claw on each
		var toes: Array = S.toes # [middle, side, back] (cm)
		for td: Array in [[0.0, toes[0]], [0.62, toes[1]], [-0.62, toes[1]], [PI, toes[2]]]:
			var dir := Vector3(sin(float(td[0])) * side, -0.1 if float(td[0]) < 3.0 else 0.12, -cos(float(td[0]))).normalized()
			var ln: float = float(td[1]) * CM
			var a0 := foot * m + Vector3(0.0, -foot.y * 0.25, 0.0)
			var a1 := a0 + dir * ln
			a1.y = maxf(a1.y, lr * 0.5) if float(td[0]) < 3.0 else a1.y
			_tube(st, [[a0, lr * 0.9, j + 3, j + 3, 0.0], [a0.lerp(a1, 0.5) + Vector3(0.0, lr * 0.3, 0.0), lr * 0.75, j + 3, j + 3, 0.0], [a1, lr * 0.55, j + 3, j + 3, 0.0]], 8.0, 7)
			var cl: float = float(S.get("claw", 0.22))
			var cr: float = float(S.get("claw_r", 0.45))
			_tube(st, [[a1, lr * cr, j + 3, j + 3, 0.0], [a1 + dir * ln * cl * 0.6 + Vector3(0.0, lr * 0.15, 0.0), lr * cr * 0.7, j + 3, j + 3, 0.0],
					[a1 + dir * ln * cl + Vector3(0.0, -ln * cl * 0.55, 0.0), lr * 0.06, j + 3, j + 3, 0.0]], 9.0, 6)
		if S.has("spur"):
			var sp0 := ank.lerp(foot, 0.55) * m
			_tube(st, [[sp0, lr * 0.7, j + 2, j + 2, 0.0], [sp0 + Vector3(-0.2 * side, 0.25, 1.0).normalized() * float(S.spur) * CM, lr * 0.08, j + 2, j + 2, 0.0]], 9.0, 6)
	# the wings: their own surface over each bone (thick over the arm,
	# thinning back over the flight feathers' roots: the coverts), and the
	# flight feathers
	var wl: Vector3 = (S.wing as Vector3) * CM
	var cov: Array = S.coverts # (how far back the surface reaches, cm: at the shoulder, elbow, wrist, tip)
	var thick: Array = S.get("wing_thick", [2.6, 1.9, 1.2, 0.5])
	var span_total := wl.x + wl.y + wl.z
	for side: float in [-1.0, 1.0]:
		var span0 := 0.0
		for k in 3:
			var L: float = wl[k]
			var wrows := []
			for si in 6:
				var f := clampf((si - 0.5) / 4.0, -0.12, 1.12) if si in [0, 5] else (si - 1) / 3.0
				f = [-0.12, 0.0, 0.34, 0.67, 1.0, 1.12][si]
				var ff := clampf(f, 0.0, 1.0)
				var back := lerpf(cov[k], cov[k + 1], ff) * CM
				var th := lerpf(thick[k], thick[k + 1], ff) * CM
				var prof := [Vector2(-0.9 * th, 0.0), Vector2(-0.5 * th, 0.42 * th), Vector2(0.4 * th, 0.55 * th), Vector2(back * 0.45, 0.36 * th), Vector2(back, 0.1 * th + 0.002),
						Vector2(back, 0.001), Vector2(back * 0.45, -0.2 * th), Vector2(0.4 * th, -0.4 * th), Vector2(-0.5 * th, -0.32 * th), Vector2(-0.9 * th, 0.0)]
				var row := []
				for q in prof.size():
					var pa: Vector2 = prof[maxi(q - 1, 0)]
					var pb: Vector2 = prof[mini(q + 1, prof.size() - 1)]
					var tn := (pb - pa).normalized()
					var n2 := Vector2(-tn.y, tn.x) * -1.0 # (outward: up over the top)
					var pt: Vector2 = prof[q]
					var top := q <= 4
					row.append([Vector3.ZERO, Vector3(0.0, n2.y if top else -absf(n2.y), n2.x), Color(10, (span0 + L * ff) / span_total, clampf(pt.x / back, 0.0, 1.0), 0.0 if top else 1.0),
							Color(1, k, side, 0), Color(L * f, pt.x, pt.y, 0), Vector2(span0 + L * f, pt.x)])
				wrows.append(row)
			_grid(st, wrows)
			span0 += L
		var prim: Array = S.primaries
		var np := prim.size()
		for i in np:
			var f := float(i) / maxf(np - 1, 1)
			_feather(st, 11.0, i + (0.0 if side > 0.0 else 40.0), Color(2, 2, side, lerpf(0.2, 1.2, pow(f, 1.1))), wl.z * (0.04 + 0.96 * f), float(prim[i]) * CM, float(S.feather_w) * CM, -0.004 - 0.0012 * i, 0.72)
		var sec: Array = S.secondaries # [how many, the outermost's length, the innermost's]
		var ns := int(sec[0])
		for i in ns:
			var f := (i + 0.5) / ns
			_feather(st, 12.0, i + (0.0 if side > 0.0 else 40.0), Color(2, 1, side, 0.14 - 0.12 * f), wl.y * (1.0 - f), lerpf(sec[1], sec[2], f) * CM, float(S.feather_w) * CM * 1.05, -0.003 + 0.0006 * i, 0.82)
		var ter: Array = S.get("tertials", [4, 20.0, 13.0])
		for i in int(ter[0]):
			var f := (i + 0.5) / float(ter[0])
			_feather(st, 13.0, i + (0.0 if side > 0.0 else 40.0), Color(2, 0, side, -0.1 - 0.35 * f), wl.x * (0.95 - 0.5 * f), lerpf(ter[1], ter[2], f) * CM, float(S.feather_w) * CM * 1.1, 0.004 + 0.001 * i, 0.8)
	# the tail: its feathers, and its coverts over them (rows, shorter)
	var tl: Array = S.tail_feathers # [how many, long, wide] (cm)
	var nt := int(tl[0])
	for i in nt:
		var t := lerpf(-1.0, 1.0, float(i) / maxf(nt - 1, 1))
		_feather(st, 14.0, i, Color(3, 1.0, 0, t), 0.025, float(tl[1]) * CM * (1.0 - 0.07 * t * t), float(tl[2]) * CM, 0.006 - 0.006 * absf(t), 0.93)
	var ri := 0
	for cr: Array in S.get("tail_coverts", []): # [how many, long, wide, lifted, its share of the spread]
		for i in int(cr[0]):
			var t := lerpf(-1.0, 1.0, float(i) / maxf(int(cr[0]) - 1, 1))
			_feather(st, 15.0, i + ri * 30.0, Color(3, cr[4], 0, t), 0.01, float(cr[1]) * CM * (1.0 - 0.1 * t * t), float(cr[2]) * CM, float(cr[3]) * CM - 0.004 * absf(t), 0.9)
		ri += 1
	return [st.commit(), rest, neck]
