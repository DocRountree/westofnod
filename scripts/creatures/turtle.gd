class_name Turtle
extends Node3D
## A painted turtle (Chrysemys picta), drawn at twice life size (its parts
## modelled at life size, its shell about 15 cm long: MM). Built from parts,
## posed every frame by hand (procedural: no clips).
##
## Its shell low and smooth: the carapace olive black, its scutes edged with
## pale olive yellow seams, the marginals round its rim barred and lined red;
## the plastron beneath yellow. Its skin near black, striped: yellow lines
## down its head and neck, red ones too down its neck, its legs and tail; a
## yellow spot behind each eye. Its feet webbed, clawed; a male's foreclaws
## long (to court with), his tail longer and thicker. A hatchling
## (Turtle.new(true)): a coin of a turtle, its shell rounder, its markings
## brighter; growing.
##
## What it does (each a method; its own ways when told none):
## - wander(centre, radius): walking (a slow diagonal gait), or swimming in
##   the water (its legs paddling, its head out ahead), surfacing to breathe
## - bask(at) (a log, a rock: its top): out onto it, its legs splayed out
##   behind and its neck stretched up, still in the sun; back in after
## - dive(): down to the floor, a while, up again
## - withdraw(): (its alarm) its head and legs pulled in under its shell
## - eat(food) (Turtle.weed_of(), or a fly: Frog.fly_of()): to it, its neck
##   shot out and its jaws snapping, swallowed
## - mate(her): (a male's) he swims to her and turns to face her, his long
##   foreclaws stretched out and fluttered against her face, again and again;
##   if she sinks to the bottom, he's over her, clasping her shell; off
## - nest(): (a female's) up out of the water onto the bank, a hole dug with
##   her hind feet, one then the other; her eggs laid in it (Nest: leathery
##   white, oval), the earth pushed back over them and pressed down; back to
##   the water. hatch() (or a while after) the hatchlings up out of it and off
##   to the water
##
## Its world: water_y (the pond's surface), floor_y (its floor), pond
## (centre, half extents x, z), height (the ground's y at x, z, outside it),
## bank (a point on land to nest at), basks (points: tops of logs, rocks).
## Steering (pilot.gd): go, go_to, face, stop, act (wander {centre, radius},
## bask {at}, dive, hide, eat {food}, mate {partner}, nest), behaviours,
## is_busy, action_finished.
## Its position is set every frame: put it under a node that isn't moved.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.002 ## m drawn per model mm (twice life size)
const SKIN := Color(0.09, 0.1, 0.07)
const YELLOW := Color(0.86, 0.74, 0.25)
const RED := Color(0.72, 0.2, 0.1)

var male := false
var young := false
var size := 1.0
var height: Callable
var water_y := 0.0
var floor_y := -0.3
var pond := [Vector3.ZERO, Vector2(0.6, 0.5)]
var bank := Vector3.INF
var basks: Array = []
var nests: Array[Node3D] = []

var _pos := Vector3.ZERO
var _yaw := 0.0
var _pitch := 0.0
var _roll := 0.0
var _t := 0.0
var _st := 0.0
var _wait := 0.0
var _mode := "wander"
var _stage := 0
var _centre := Vector3.ZERO
var _radius := 0.4
var _target := Vector3.ZERO
var _speed := 0.0
var _depth := 0.0 # (swimming: how far under the surface, m)
var _depth_to := 0.0
var _neck := 0.0 # (0 in .. 1 out .. 1.6 stretched / shot out)
var _neck_to := 1.0
var _limbs := 1.0 # (0 pulled in .. 1 out)
var _limbs_to := 1.0
var _jaw := 0.0
var _flutter := 0.0
var _dig := 0.0
var _food: Node3D
var _mate: Turtle
var _role := ""
var _mate_len := 12.0 # (how long a mating lasts, s)
var _pilot: PilotScript
var _piloting := false
var rng := RandomNumberGenerator.new()
# the parts
var _body: Node3D
var _head: Node3D
var _neck_n: Node3D
var _jaw_n: Node3D
var _legs: Array = [] # [hip node, upper, lower, foot, fore?, side, claws]
var _tail_n: Node3D

static var _sphere: SphereMesh
static var _shell_sh: Shader
static var _stripe_sh: Shader


func _init(young_ := false) -> void:
	young = young_
	size = 0.22 if young_ else 1.0
	rng.randomize()


func _ready() -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 24
		_sphere.rings = 12
	_body = Node3D.new()
	add_child(_body)
	_build()


func place(p: Vector3, yaw := 0.0) -> void:
	_pos = p
	_pos.y = _ground_at(p.x, p.z)
	_yaw = yaw
	_place()


# --- its model ----------------------------------------------------------------

func _mat(c: Color, rough := 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(at: Vector3, sz: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.position = at
	mi.scale = sz
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func _seg_to(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float, flat := 1.0) -> void:
	var d := b - a
	var l := maxf(d.length(), 0.01)
	var z := d / l
	var x := z.cross(Vector3.UP if absf(z.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := z.cross(x)
	mi.transform = Transform3D(Basis(x * r * 2.0, y * r * 2.0 * flat, z * (l + r)), (a + b) * 0.5)


## The carapace: its scutes (a vertebral row down the middle, the costals
## either side, the marginals round the rim) olive black, edged with pale
## seams; the marginals barred red. (On the shell's ellipsoid: local x
## across, z along, y up.)
static func _shell_shader() -> Shader:
	if _shell_sh == null:
		_shell_sh = Shader.new()
		_shell_sh.code = """shader_type spatial;
uniform float bright = 1.0; // (a hatchling's brighter)
varying vec3 o;
void vertex() { o = VERTEX; }
void fragment() {
	vec3 dark = vec3(0.1, 0.11, 0.07);
	vec3 seam = vec3(0.62, 0.58, 0.32) * bright;
	vec3 red = vec3(0.7, 0.2, 0.09) * bright;
	float ax = abs(o.x);
	float r = length(o.xz * vec2(1.0, 0.75)) * 2.0; // (0 middle .. 1 rim)
	vec3 c = dark;
	float s = 0.0;
	if (o.y < -0.02) { // (under the rim: the bridge and plastron, yellow)
		ALBEDO = vec3(0.8, 0.66, 0.26);
		ROUGHNESS = 0.5;
	} else if (o.y < 0.13) { // (the marginals: a ring of small scutes round the rim, red barred)
		float a = atan(o.x, o.z);
		float cell = fract(a / 6.2832 * 24.0);
		s = 1.0 - smoothstep(0.0, 0.08, min(cell, 1.0 - cell));
		c = mix(dark, red, (1.0 - smoothstep(0.05, 0.12, abs(cell - 0.5) - 0.12)) * 0.85);
		s = max(s, 1.0 - smoothstep(0.0, 0.02, 0.13 - o.y));
	} else if (ax < 0.12) { // (the vertebrals, down the middle)
		float cz = fract((o.z + 0.5) * 5.0);
		s = max(1.0 - smoothstep(0.0, 0.06, min(cz, 1.0 - cz)), 1.0 - smoothstep(0.0, 0.015, 0.12 - ax));
	} else { // (the costals, four a side)
		float cz = fract((o.z + 0.5) * 4.0 + 0.5);
		s = 1.0 - smoothstep(0.0, 0.06, min(cz, 1.0 - cz));
	}
	if (o.y >= -0.02) {
		c = mix(c, seam, s * 0.9);
		ALBEDO = c;
		ROUGHNESS = 0.35;
	}
	SPECULAR = 0.55;
	CLEARCOAT = 0.3;
}
"""
	return _shell_sh


## Its skin: near black, striped along its length, yellow, and red (its
## neck's, legs', tail's: red the share given).
static func _stripe_shader() -> Shader:
	if _stripe_sh == null:
		_stripe_sh = Shader.new()
		_stripe_sh.code = """shader_type spatial;
uniform float red = 0.0;
uniform float count = 8.0;
varying vec3 o;
void vertex() { o = VERTEX; }
void fragment() {
	vec3 skin = vec3(0.09, 0.1, 0.07);
	float a = atan(o.x, o.y) / 6.2832 * count;
	float st = 1.0 - smoothstep(0.05, 0.12, abs(fract(a) - 0.5));
	vec3 line = mix(vec3(0.8, 0.7, 0.26), vec3(0.62, 0.2, 0.1), step(0.5, fract(floor(a) * 0.5)) * red);
	ALBEDO = mix(skin, line, st);
	ROUGHNESS = 0.5;
}
"""
	return _stripe_sh


func _stripes(red_: float, n := 8.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _stripe_shader()
	m.set_shader_parameter("red", red_)
	m.set_shader_parameter("count", n)
	return m


func _build() -> void:
	var shell := ShaderMaterial.new()
	shell.shader = _shell_shader()
	shell.set_shader_parameter("bright", 1.25 if young else 1.0)
	var round_ := 1.15 if young else 1.0
	_part(Vector3(0.0, 17.0, 0.0), Vector3(110.0 * round_, 40.0 * round_, 150.0), shell, _body) # (the carapace)
	_part(Vector3(0.0, 10.0, 2.0), Vector3(100.0, 10.0, 138.0), _mat(Color(0.85, 0.7, 0.28), 0.5), _body) # (the plastron)
	var skin_y := _stripes(0.0, 16.0)
	var skin_r := _stripes(0.5, 14.0)
	# the neck and head
	_neck_n = Node3D.new()
	_neck_n.position = Vector3(0.0, 18.0, -62.0)
	_body.add_child(_neck_n)
	var nk := _part(Vector3(0.0, 0.0, -14.0), Vector3(20.0, 18.0, 34.0), skin_r, _neck_n)
	nk.rotation.z = PI * 0.5
	_head = Node3D.new()
	_head.position = Vector3(0.0, 3.0, -30.0)
	_neck_n.add_child(_head)
	var hd := _part(Vector3(0.0, 0.0, -8.0), Vector3(20.0, 16.0, 28.0), skin_y, _head)
	hd.rotation.z = PI * 0.5
	for side: float in [-1.0, 1.0]:
		_part(Vector3(7.5 * side, 3.5, -12.0), Vector3(5.0, 5.0, 5.0), _mat(Color(0.12, 0.1, 0.04), 0.15), _head) # (its eye)
		_part(Vector3(8.5 * side, 1.0, -3.0), Vector3(2.5, 4.5, 6.0), _mat(YELLOW, 0.5), _head) # (the yellow spot behind it)
	_jaw_n = Node3D.new()
	_jaw_n.position = Vector3(0.0, -4.0, -6.0)
	_head.add_child(_jaw_n)
	_part(Vector3(0.0, -1.0, -9.0), Vector3(14.0, 4.0, 14.0), skin_y, _jaw_n)
	# the legs: webbed feet, claws (a male's foreclaws long)
	var claw := _mat(Color(0.22, 0.2, 0.15), 0.4)
	for fore: bool in [true, false]:
		for side: float in [-1.0, 1.0]:
			var hip := Node3D.new()
			hip.position = Vector3(38.0 * side, 14.0, -40.0 if fore else 46.0)
			_body.add_child(hip)
			var cl := []
			for k in 4:
				var c := MeshInstance3D.new()
				c.mesh = _sphere
				c.material_override = claw
				_body.add_child(c)
				cl.append(c)
			var up := MeshInstance3D.new()
			up.mesh = _sphere
			up.material_override = skin_r
			_body.add_child(up)
			var lo := MeshInstance3D.new()
			lo.mesh = _sphere
			lo.material_override = skin_r
			_body.add_child(lo)
			var ft := MeshInstance3D.new()
			ft.mesh = _sphere
			ft.material_override = _mat(SKIN, 0.5)
			_body.add_child(ft)
			_legs.append([hip, up, lo, ft, fore, side, cl])
	_tail_n = Node3D.new()
	_tail_n.position = Vector3(0.0, 14.0, 72.0)
	_body.add_child(_tail_n)
	_part(Vector3(0.0, 0.0, 12.0 if male else 8.0), Vector3(10.0, 8.0, 30.0 if male else 18.0), skin_r, _tail_n)


# --- what it does ---------------------------------------------------------------

func wander(centre: Vector3, radius := 0.4) -> void:
	_go_mode("wander")
	_centre = centre
	_radius = radius


func bask(at := Vector3.INF) -> void:
	_go_mode("bask")
	if at == Vector3.INF:
		at = basks[rng.randi() % basks.size()] if not basks.is_empty() else _pos
	_target = at


func dive() -> void:
	_go_mode("dive")


func withdraw() -> void:
	_go_mode("hide")


func eat(food: Node3D) -> void:
	if food == null:
		return
	_go_mode("eat")
	_food = food


func nest() -> void:
	if male or young or bank == Vector3.INF:
		return
	_go_mode("nest")


func _go_mode(m: String) -> void:
	_mode = m
	_stage = 0
	_st = 0.0
	_wait = 0.0
	_neck_to = 1.0
	_limbs_to = 1.0
	_flutter = 0.0
	_dig = 0.0


func mate(partner: Node3D, secs := 12.0) -> bool:
	if partner == null or not (partner is Turtle) or not male or young or _role != "":
		return false
	var her := partner as Turtle
	if her.male or her.young or her._role != "":
		return false
	_mate = her
	_role = "male"
	her._mate = self
	her._role = "female"
	her._go_mode("courted")
	_go_mode("mate")
	_mate_len = secs
	return true


func _end_mate() -> void:
	var her := _mate
	_mate = null
	_role = ""
	if is_instance_valid(her):
		her._mate = null
		her._role = ""
		her.wander(pond[0], 0.4)
	wander(pond[0], 0.4)


# --- the motor -------------------------------------------------------------------

func _in_water(p: Vector3) -> bool:
	var c: Vector3 = pond[0]
	var e: Vector2 = pond[1]
	return absf(p.x - c.x) < e.x and absf(p.z - c.z) < e.y


## Where its shell's bottom rests at x, z: the ground; in the water, at the
## surface (floating) less how deep it's gone.
func _ground_at(x: float, z: float) -> float:
	if _in_water(Vector3(x, 0.0, z)):
		return maxf(water_y - 0.03 * size - _depth, floor_y)
	return float(height.call(x, z)) if height.is_valid() else 0.0


func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	_t += dt
	_st += dt
	_wait -= dt
	if _pilot:
		_pilot.tick(dt)
	if not _piloting:
		_think(dt)
	_move(dt)
	_place()
	_pose(dt)


func _think(dt: float) -> void:
	match _mode:
		"wander":
			_depth_to = 0.0
			if _wait <= 0.0 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.03:
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a), 0.0, sin(a)) * _radius * rng.randf()
				_speed = 0.05 if _in_water(_pos) else 0.02
				_wait = rng.randf_range(4.0, 9.0)
				if rng.randf() < 0.3:
					_target = _pos
				if _in_water(_pos) and rng.randf() < 0.15:
					dive()
		"bask":
			match _stage:
				0: # (to it, and up onto it)
					_go_to(_target, 0.04)
					if Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.04:
						_pos.y = _target.y
						_stage = 1
						_st = 0.0
				1: # (still in the sun, its legs splayed out behind, its neck up)
					_speed = 0.0
					_neck_to = 1.45
					_limbs_to = 1.0
					if _st > 25.0:
						wander(pond[0], 0.4)
		"dive":
			_depth_to = maxf(water_y - floor_y - 0.04 * size, 0.0) if _st < 8.0 else 0.0
			_speed = 0.04
			if _st > 12.0:
				wander(pond[0], 0.4)
		"hide":
			_speed = 0.0
			_neck_to = 0.0
			_limbs_to = 0.0
			if _st > 8.0:
				wander(_pos, 0.3)
		"eat":
			if not is_instance_valid(_food):
				wander(_pos, 0.3)
				return
			var d := Vector3(_food.position.x - _pos.x, 0.0, _food.position.z - _pos.z)
			if d.length() > 0.11 * size and _stage == 0:
				_go_to(_food.position - d.normalized() * 0.1 * size, 0.04)
			else:
				_speed = 0.0
				_face(d)
				if _stage == 0:
					_stage = 1
					_st = 0.0
				_neck_to = 1.0 + 0.6 * sin(clampf(_st / 0.35, 0.0, 1.0) * PI) # (its neck shot out)
				_jaw = 0.5 * maxf(sin(_st * 14.0), 0.0) if _st < 1.4 else 0.0
				if _st > 0.25 and is_instance_valid(_food):
					_food.queue_free()
					_food = null
				if _st > 1.6:
					wander(_pos, 0.3)
		"courted": # (a female: floating, still; at the end sinking to the floor)
			_speed = 0.0
			_depth_to = 0.0
		"mate":
			_mate_think(dt)
		"nest":
			_nest_think(dt)


func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	if not _in_water(her._pos):
		her._go_to(pond[0], 0.05)
	var hb := Basis(Vector3.UP, her._yaw)
	match _stage:
		0: # (to just before her face, turned to face her)
			var front := her._pos + hb * Vector3(0.0, 0.0, -0.36 * size)
			_go_to(front, 0.06)
			if Vector2(_pos.x - front.x, _pos.z - front.z).length() < 0.04:
				_stage = 1
				_st = 0.0
		1: # (his long foreclaws out, fluttered at her face, in bouts)
			_speed = 0.0
			_yaw = lerp_angle(_yaw, her._yaw + PI, 0.1)
			_flutter = 1.0 if fmod(_st, 2.5) < 1.6 else 0.0
			if _st > _mate_len * 0.6:
				her._depth_to = maxf(water_y - floor_y - 0.04 * size, 0.0) # (she sinks: accepting)
				_stage = 2
				_st = 0.0
				_flutter = 0.0
		2: # (over her on the floor, clasping her shell)
			_depth_to = her._depth + 0.012
			var over := her._pos + hb * Vector3(0.0, 0.035, 0.03) * size
			_go_to(over, 0.05)
			_yaw = lerp_angle(_yaw, her._yaw, 0.1)
			_pitch = lerpf(_pitch, -0.25, 0.1)
			if _st > _mate_len * 0.5:
				_pitch = 0.0
				her._depth_to = 0.0
				_end_mate()


func _nest_think(_dt: float) -> void:
	match _stage:
		0: # (out onto the bank)
			_go_to(bank, 0.06)
			if Vector2(_pos.x - bank.x, _pos.z - bank.z).length() < 0.04:
				_stage = 1
				_st = 0.0
		1: # (digging with her hind feet, one then the other; her shell tipped up in front)
			_speed = 0.0
			_dig = 1.0
			_pitch = lerpf(_pitch, -0.18, 0.05)
			if _st > 8.0:
				_stage = 2
				_st = 0.0
		2: # (laying)
			_dig = 0.0
			if _st > 3.0:
				var n := Nest.new()
				n.maker = get_script()
				n.turtle = self
				n.at = _pos + Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.0, 0.17 * size)
				n.at.y = _ground_at(n.at.x, n.at.z)
				get_parent().add_child(n)
				nests.append(n)
				_stage = 3
				_st = 0.0
		3: # (the earth pushed back over them, pressed down)
			_dig = 0.6
			if _st > 4.0:
				_dig = 0.0
				_pitch = 0.0
				_stage = 4
		4: # (back to the water)
			_go_to(pond[0], 0.06)
			if _in_water(_pos):
				wander(pond[0], 0.4)


func _go_to(p: Vector3, speed: float) -> void:
	_target = p
	_speed = speed


func _face(d: Vector3) -> void:
	if Vector2(d.x, d.z).length() > 0.002:
		_yaw = lerp_angle(_yaw, atan2(-d.x, -d.z), 0.15)


func _move(dt: float) -> void:
	_depth = move_toward(_depth, _depth_to, dt * 0.05)
	var d := Vector3(_target.x - _pos.x, 0.0, _target.z - _pos.z)
	var sp := _speed * (2.0 if _in_water(_pos) else 1.0) * clampf(d.length() / 0.04, 0.0, 1.0) * size
	if sp > 0.0005 and _limbs > 0.5:
		var y := atan2(-d.x, -d.z)
		_yaw += clampf(wrapf(y - _yaw, -PI, PI), -1.2 * dt, 1.2 * dt)
		_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * sp * dt
	if not (_mode == "bask" and _stage == 1):
		_pos.y = lerpf(_pos.y, _ground_at(_pos.x, _pos.z), 1.0 - exp(-6.0 * dt))


# --- the pose -------------------------------------------------------------------

func _place() -> void:
	transform = Transform3D(Basis.from_euler(Vector3(_pitch, _yaw, _roll)), _pos)
	if _body:
		_body.scale = Vector3.ONE * MM * size


func _pose(dt: float) -> void:
	_neck = move_toward(_neck, _neck_to, dt * (6.0 if _mode == "eat" else 2.0))
	_limbs = move_toward(_limbs, _limbs_to, dt * 3.0)
	_neck_n.position = Vector3(0.0, 18.0, lerpf(-40.0, -66.0, minf(_neck, 1.0)) - 22.0 * maxf(_neck - 1.0, 0.0))
	_neck_n.rotation.x = 0.35 * maxf(_neck - 1.0, 0.0) * (1.0 if _mode == "bask" else -0.2)
	_neck_n.scale = Vector3.ONE * lerpf(0.6, 1.0, minf(_neck, 1.0))
	_jaw_n.rotation.x = _jaw
	var swimming := _in_water(_pos) and not (_mode == "bask" and _stage == 1)
	var moving := _speed > 0.0005 and _limbs > 0.5
	var basking := _mode == "bask" and _stage == 1
	for L: Array in _legs:
		var hip: Vector3 = (L[0] as Node3D).position
		var fore: bool = L[4]
		var side: float = L[5]
		var ph := _t * (4.0 if swimming else 2.4) + (0.0 if (fore == (side > 0.0)) else PI) # (diagonal pairs together)
		var sw := sin(ph) if moving else 0.0
		var out := hip + Vector3(22.0 * side, -6.0, (-14.0 if fore else 14.0) + sw * 12.0)
		var foot := out + Vector3(8.0 * side, -12.0 if not swimming else -2.0, (-10.0 if fore else 10.0) + sw * 10.0)
		if swimming: # (paddling: out wide, the feet flat)
			foot += Vector3(10.0 * side, 6.0, sw * 8.0)
		if basking and not fore: # (the hind legs splayed out behind)
			out = hip + Vector3(18.0 * side, -6.0, 26.0)
			foot = out + Vector3(6.0 * side, -6.0, 26.0)
		if _dig > 0.0 and not fore: # (digging: one hind foot then the other, scooping)
			var dp := sin(_t * 3.0 + (0.0 if side > 0.0 else PI))
			out = hip + Vector3(10.0 * side, -8.0, 22.0)
			foot = out + Vector3(-6.0 * side * maxf(dp, 0.0), -14.0 - 6.0 * maxf(dp, 0.0), 10.0)
		if fore and _flutter > 0.0: # (his foreclaws out before her face, fluttering)
			var fl := sin(_t * 30.0) * 4.0
			out = hip + Vector3(12.0 * side, 4.0, -26.0)
			foot = out + Vector3(-4.0 * side + fl * side * 0.3, 2.0 + fl, -20.0)
		# pulled in: under the shell's rim
		out = hip.lerp(out, _limbs)
		foot = hip.lerp(foot, _limbs)
		_seg_to(L[1], hip, out, 8.0 * _limbs + 2.0)
		_seg_to(L[2], out, foot, 6.5 * _limbs + 2.0, 0.7)
		_seg_to(L[3], foot, foot + (foot - out).normalized() * 10.0, 7.0 * _limbs + 1.0, 0.35) # (the webbed foot, flat)
		var cl: Array = L[6]
		var tip := foot + (foot - out).normalized() * 12.0
		for k in cl.size():
			var spread := (float(k) - 1.5) * 3.2
			var long_ := (14.0 if fore and male and not young else 5.0)
			var cdir := ((foot - out).normalized() + Vector3(side * 0.1, 0.0, 0.0)).normalized()
			var c0 := tip + Vector3(spread, 0.0, 0.0)
			_seg_to(cl[k], c0, c0 + cdir * long_ * _limbs, 0.9)
	_tail_n.scale = Vector3.ONE * lerpf(0.3, 1.0, _limbs)


# --- steering (pilot.gd) -------------------------------------------------------

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
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _p_steer(point: Vector3, speed: float) -> void:
	_piloting = true
	_limbs_to = 1.0
	_go_to(point, speed if speed > 0.0 else 0.03)


func _p_hold() -> void:
	_piloting = true
	_speed = 0.0


func _p_mobile() -> bool:
	return _mode != "hide"


func _p_speed() -> float:
	return 0.03


func _p_reach() -> float:
	return 0.03


func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["wander", "bask", "dive", "hide", "eat"])
	if not young:
		b.append("mate" if male else "nest")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	_piloting = false
	match name:
		"wander":
			wander(args.get("centre", _pos), float(args.get("radius", 0.4)))
		"bask":
			bask(args.get("at", Vector3.INF))
		"dive":
			dive()
		"hide":
			withdraw()
		"eat":
			if args.get("food") == null:
				return false
			eat(args.food)
		"mate":
			return mate(args.get("partner"), float(args.get("seconds", 12.0)))
		"nest":
			if male or young:
				return false
			nest()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"bask":
			return _mode == "bask" and _stage == 1
		"dive", "hide":
			return _mode == "wander"
		"eat":
			return _mode != "eat"
		"mate":
			return _role == ""
		"nest":
			return _mode != "nest"
	return false


func _p_act_secs(name: String) -> float:
	return 15.0 if name == "wander" else -1.0


# --- props -------------------------------------------------------------------------

## A strand of pondweed floating (its food, as much as small animals): at.
static func weed_of(at: Vector3) -> Node3D:
	var w := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.46, 0.18)
	for k in 5:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.material_override = m
		mi.scale = Vector3(0.008, 0.003, 0.03)
		mi.position = Vector3(0.006 * k - 0.012, 0.0, 0.004 * sin(k * 2.0))
		mi.rotation.y = 0.6 * sin(k * 1.7)
		w.add_child(mi)
	w.position = at
	return w


## Her nest: a patch of earth pressed down over her eggs (six, leathery,
## white, oval: shown till they're covered); hatch() (or a while after) the
## hatchlings up out of it and away to the water.
class Nest extends Node3D:
	var maker: Script
	var turtle: Node3D
	var at := Vector3.ZERO
	var left := 70.0
	var _done := false
	var _eggs: Array[MeshInstance3D] = []
	var _t := 0.0

	func _ready() -> void:
		position = at # (where it is: its parts about it)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		var dirt := StandardMaterial3D.new()
		dirt.albedo_color = Color(0.4, 0.32, 0.2)
		var d := MeshInstance3D.new()
		d.mesh = s
		d.material_override = dirt
		d.scale = Vector3(0.1, 0.012, 0.09)
		d.position = Vector3(0.0, 0.002, 0.0)
		add_child(d)
		var em := StandardMaterial3D.new()
		em.albedo_color = Color(0.93, 0.9, 0.84)
		for k in 6:
			var e := MeshInstance3D.new()
			e.mesh = s
			e.material_override = em
			e.scale = Vector3(0.012, 0.012, 0.018) * 1.6
			e.position = Vector3(randf_range(-0.02, 0.02), 0.008, randf_range(-0.02, 0.02))
			add_child(e)
			_eggs.append(e)

	func _process(dt: float) -> void:
		_t += dt
		if _t > 7.0: # (covered)
			for e in _eggs:
				e.visible = false
		left -= dt
		if left <= 0.0 and not _done:
			hatch()

	func hatch(n := 4) -> void:
		if _done or maker == null:
			return
		_done = true
		var tt := turtle as Turtle
		for k in n:
			var y: Node3D = maker.new(true)
			if is_instance_valid(tt):
				for p in ["water_y", "floor_y", "pond", "height", "basks"]:
					y.set(p, tt.get(p))
			get_parent().add_child(y)
			y.call("place", at + Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03)), randf() * TAU)
			var c: Vector3 = (y.get("pond") as Array)[0]
			y.call("wander", c, 0.3) # (off to the water)
		queue_free()
