extends Node3D
## A walking arthropod built from parts (the grasshopper, the mantis, the
## spiders, the pill bug: their
## scripts build the bodies and say what they do), drawn at twice life
## size (model mm: MM), `size` its share of the adult's (a nymph's small,
## growing: grow(to, secs)). The motor under them, every frame:
## - walking on the level ground (ground_y): toward _target at up to
##   walk_speed, turning; its feet planted where they step (world points),
##   in a tripod gait (two sets of three swinging in turn: a set lifted and
##   swung on ahead of its homes when they've been left behind; a leg that
##   doesn't walk, a mantis's raptorial forelegs, posed by the species);
##   each leg reaching from its hip to its foot: femur, tibia (the knee
##   bent toward its pole), tarsus
## - in the air (jump, flight, a fall on a thread): ballistic, or steered
##   (_steer), or let down slowly (_slow_fall); its legs to their dangle
## The species sets the shape (legs: hip, f, t, s, home, dangle, pole,
## walks, r; body_h) and poses its own parts (_pose: head, wings, abdomen),
## and decides what to do (_think).
## Mating (mate(partner), the male leading: hexapod's own, the species
## saying how: _mount, _court, its poses reading mate_stage()): he goes to
## her, courts her (the species' own: drumming, waving, tapping), climbs on
## (carried on her from then: his transform hers, his feet gripping where
## the species says on her body), stays joined (mate_secs), and climbs off
## behind her; both back to what they were doing (_after_mate). die(): it
## rolls over, legs curled, and lies there.
## Steering (a state machine's: pilot.gd): go, go_to, face, stop, act,
## behaviours, is_busy, action_finished; height (the ground, for its feet
## and its walking). Its transform is set every frame: put it under a node
## that isn't moved.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")

const MM := 0.002
const G := 9.8
const SPHERE_N := [14, 8]

# what the species sets
var body_h := 4.0 ## mm its thorax's middle stands over the ground
var walk_speed := 0.03 ## m/s (the adult's)
var stride := 7.0 ## mm a foot's left behind before its set steps
var step_time := 0.14 ## s a set's swing takes
var legs: Array = [] ## the right side's: {hip, f, t, s, home: Vector2 (x, z), dangle: Vector3, pole: Vector3 (body: the knee's way), walks: bool, r: thickness (mm), knee: Vector3 (body mm: held there on the ground, not reached for: a grasshopper's hind knee)}
var tripod := [[0, 3, 4], [1, 2, 5]] ## the gait's two sets (a leg: its pair * 2, + 1 the right): six legs' tripods; eight's, the spiders', [[0, 3, 4, 7], [1, 2, 5, 6]]; more, alternating so down the body
## (any number of pairs: legs' length; the spiders' four, a pill bug's seven)

var size := 1.0
var nymph := false
var male := false ## (set before it's added: the species' build may differ: its size, _male_size())
var dead := false
var ground_y := 0.0
var height: Callable ## (x, z) -> the ground's y (none: level, at ground_y)
var _pilot: PilotScript
var _pace := -1.0 # (m/s, the pilot's: -1 its own)
var rng := RandomNumberGenerator.new()

# where it is, how it's moving
var _pos := Vector3.ZERO # on the ground under its thorax's middle (its parent's space)
var _yaw := 0.0
var _speed := 0.0
var _target := Vector3.ZERO
var _turn_to := INF # (rad: turning on the spot to face)
var airborne := false
var _alt := 0.0 # m over the ground
var _vel := Vector3.ZERO # in the air
var _steer := Vector3.INF # flying: making for this (its parent's space)
var _steer_speed := 0.8
var _slow_fall := false
var _pitch := 0.0 # rad, the body's nose up
var _roll := 0.0
var _crouch := 0.0 # 0..1: the body let down toward the ground
var _lift := 0.0 # mm the body raised (rearing)
var _sway := 0.0 # rad, rocking side to side (a mantis's)
var _t := 0.0
var _g_to := 1.0
var _g_rate := 0.0

# the legs: feet (its parent's space), the gait
var _feet: Array[Vector3] = []
var _from: Array[Vector3] = []
var _to: Array[Vector3] = []
var _swinging := -1
var _swing_t := 0.0
var _next := 0
var _pose_foot: Array = [] # a species-posed leg's foot (body mm), or null: walking

# the parts
var _body: Node3D # in mm
var _leg_mesh: Array = [] # each leg: [femur, tibia, tarsus, knee]
static var _sphere: SphereMesh
static var _cyl: CylinderMesh

# mating
var _mate: Node3D # the partner (a hexapod of its kind)
var _mate_role := "" # "male", "female"
var _mate_stage := "" # the male's: "seek", "court", "mount", "joined", "part"; hers: "wait", "joined"
var _mate_t := 0.0
var mate_secs := 20.0 ## s joined (the species' default; mate(partner, secs) its own)
var _mount_from := Transform3D()
var _mount_to := Transform3D()
var _gripped: Array[int] = []
var _dead_t := 0.0


func _init(nymph_ := false, size_ := 1.0) -> void:
	nymph = nymph_
	size = size_
	_g_to = size_
	rng.randomize()


func _ready() -> void:
	if male and not nymph:
		size *= _male_size()
		_g_to = size
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = SPHERE_N[0]
		_sphere.rings = SPHERE_N[1]
		_cyl = CylinderMesh.new()
		_cyl.top_radius = 0.5
		_cyl.bottom_radius = 0.5
		_cyl.height = 1.0
		_cyl.radial_segments = 6
		_cyl.rings = 1
	_body = Node3D.new()
	add_child(_body)
	_build()
	_place()
	for i in legs.size() * 2:
		_feet.append(_home(i))
		_from.append(_feet[i])
		_to.append(_feet[i])
		_pose_foot.append(null)


## Puts it at p (on the ground), facing yaw.
func place(p: Vector3, yaw := 0.0) -> void:
	_pos = Vector3(p.x, ground_y, p.z)
	ground_y = p.y
	_pos.y = ground_y
	_yaw = yaw
	_target = _pos
	airborne = false
	_alt = 0.0
	if _body:
		_place()
		for i in _feet.size():
			_feet[i] = _home(i)


## Growing to `to` (a share of the adult's) over secs.
func grow(to: float, secs: float) -> void:
	_g_to = to
	_g_rate = absf(to - size) / maxf(secs, 0.01)


# --- for the species ---------------------------------------------------------------

func _build() -> void:
	pass


func _think(_dt: float) -> void:
	pass


## Its own parts posed (head, wings, abdomen, a raptorial leg's foot).
func _pose(_dt: float) -> void:
	pass


## A part: an ellipsoid at `at` (mm), `size_` across (mm), under parent.
func _part(at: Vector3, size_: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.position = at
	mi.scale = size_
	mi.material_override = mat
	(parent if parent else _body).add_child(mi)
	return mi


## Fur on mi (a mammal's: its material's shader takes the fur's instance
## uniforms: shell, fur_obj, fur_dens): shells of it, each a copy a little
## further out along its normals, its hairs thinning to their tips;
## len_mm the hairs' length (mm, the body's), spacing between them.
func _fur_shells(mi: MeshInstance3D, len_mm: float, shells := 8, spacing := -1.0) -> void:
	if mi == null or len_mm <= 0.0:
		return
	var sc := mi.transform.basis.get_scale()
	var avg := maxf((absf(sc.x) + absf(sc.y) + absf(sc.z)) / 3.0, 1e-4)
	var sp := spacing if spacing > 0.0 else clampf(len_mm * 0.12, 0.25, 4.0)
	mi.set_instance_shader_parameter("fur_dens", avg / sp)
	for k in range(1, shells + 1):
		var sh := MeshInstance3D.new()
		sh.mesh = mi.mesh
		sh.material_override = mi.material_override
		sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(sh)
		sh.set_instance_shader_parameter("shell", float(k) / shells)
		sh.set_instance_shader_parameter("fur_obj", len_mm / avg)
		sh.set_instance_shader_parameter("fur_dens", avg / sp)


## A stick (mm) from a to b, r thick, under parent.
func _stick(a: Vector3, b: Vector3, r: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _cyl
	mi.transform = _seg(a, b, r)
	mi.material_override = mat
	(parent if parent else _body).add_child(mi)
	return mi


static func _seg(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d := b - a
	if d.length() < 1e-5:
		d = Vector3.UP * 1e-5
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * 2.0 * r, d, z * 2.0 * r), (a + b) * 0.5)


static func _mat(c: Color, rough := 0.6, fur := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if fur > 0.0:
		m.rim_enabled = true
		m.rim = fur
	return m


static var _band_shader: Shader


## A body part's material, its segments' joints shaded darker across it
## (every seg mm along z from z0; none: seg 0) and mottled (0..1).
static func _banded(c: Color, seg: float, z0 := 0.0, mottle := 0.0, gloss := 0.45) -> ShaderMaterial:
	if _band_shader == null:
		_band_shader = Shader.new()
		_band_shader.code = """shader_type spatial;
uniform vec3 base : source_color;
uniform float seg = 0.0;
uniform float z0 = 0.0;
uniform float mottle = 0.0;
uniform float gloss = 0.45;
varying vec3 o;
void vertex() { o = VERTEX; }
float h(vec3 p) { return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vn(vec3 p) {
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec3 i = floor(p);
	return mix(mix(mix(h(i), h(i + vec3(1, 0, 0)), f.x), mix(h(i + vec3(0, 1, 0)), h(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h(i + vec3(0, 0, 1)), h(i + vec3(1, 0, 1)), f.x), mix(h(i + vec3(0, 1, 1)), h(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void fragment() {
	vec3 c = base;
	if (seg > 0.0 && o.z > z0) {
		float f = fract((o.z - z0) / seg);
		c *= 1.0 - 0.28 * smoothstep(0.8, 0.97, f); // (each segment's back edge, where it laps the next)
	}
	if (mottle > 0.0)
		c *= 1.0 - mottle * (vn(o * 0.9) - 0.5) - mottle * 0.5 * (vn(o * 2.7 + 3.1) - 0.5);
	ALBEDO = c;
	ROUGHNESS = mix(0.75, 0.25, gloss);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _band_shader
	m.set_shader_parameter("base", c)
	m.set_shader_parameter("seg", seg)
	m.set_shader_parameter("z0", z0)
	m.set_shader_parameter("mottle", mottle)
	m.set_shader_parameter("gloss", gloss)
	return m


## How far out to its side a loft (keys as _loft's) reaches at (z, y): its
## surface there (mm), for something set on it (an eye).
static func _surface_x(keys: Array, z: float, y: float) -> float:
	var K := keys.size()
	for k in K - 1:
		var a: Array = keys[k]
		var b: Array = keys[k + 1]
		if (z - float(a[0])) * (z - float(b[0])) <= 0.0:
			var f := clampf((z - float(a[0])) / (float(b[0]) - float(a[0])) if absf(float(b[0]) - float(a[0])) > 1e-5 else 0.0, 0.0, 1.0)
			var yc := lerpf(a[1], b[1], f)
			var hw := lerpf(a[2], b[2], f)
			var hh := lerpf(a[3], b[3], f)
			var u := clampf((y - yc) / maxf(hh, 1e-3), -1.0, 1.0)
			return hw * sqrt(1.0 - u * u)
	return float((keys[0] as Array)[2])


## A smooth body lofted through keys ([z, y, half width, half height] each,
## mm), round (sq 2) or squarer; a mesh in mm.
static func _loft(keys: Array, sq := 2.0) -> ArrayMesh:
	const RING := 14
	const STEPS := 20
	var K := keys.size()
	var key := func(j: int, c: int) -> float:
		return float((keys[clampi(j, 0, K - 1)] as Array)[c])
	var rings := []
	for i in STEPS + 1:
		var t := float(i) / STEPS * (K - 1)
		var j := mini(int(t), K - 2)
		var f := t - j
		var v := []
		for c in 4:
			var p0: float = key.call(j - 1, c)
			var p1: float = key.call(j, c)
			var p2: float = key.call(j + 1, c)
			var p3: float = key.call(j + 2, c)
			v.append(0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f))
		var ring := []
		for k in RING:
			var a := TAU * k / RING
			var cx := signf(cos(a)) * pow(absf(cos(a)), 2.0 / sq)
			var sy := signf(sin(a)) * pow(absf(sin(a)), 2.0 / sq)
			ring.append(Vector3(float(v[2]) * cx, float(v[1]) + float(v[3]) * sy, float(v[0])))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal := func(i: int, k: int) -> Vector3:
		var r: Array = rings[i]
		var pa: Vector3 = (rings[mini(i + 1, STEPS)] as Array)[k]
		var pb: Vector3 = (rings[maxi(i - 1, 0)] as Array)[k]
		var n := (pa - pb).cross((r[(k + 1) % RING] as Vector3) - (r[(k - 1 + RING) % RING] as Vector3))
		var mid := ((r[0] as Vector3) + (r[RING / 2] as Vector3)) * 0.5
		var p: Vector3 = r[k]
		if n.dot(p - mid) < 0.0:
			n = -n
		return n.normalized() if n.length_squared() > 1e-12 else (p - mid).normalized()
	for i in STEPS:
		for k in RING:
			var q := [[i, k], [i + 1, k], [i + 1, (k + 1) % RING], [i, (k + 1) % RING]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var vs := []
				for e: int in tri:
					var ik: Array = q[e]
					vs.append([(rings[ik[0]] as Array)[ik[1]], normal.call(ik[0], ik[1])])
				var a: Vector3 = vs[0][0]
				var b: Vector3 = vs[1][0]
				var c: Vector3 = vs[2][0]
				var want: Vector3 = (vs[0][1] as Vector3) + (vs[1][1] as Vector3) + (vs[2][1] as Vector3)
				var order := [0, 1, 2] if (-(b - a).cross(c - a)).dot(want) >= 0.0 else [0, 2, 1]
				for o: int in order:
					st.set_normal(vs[o][1])
					st.add_vertex(vs[o][0])
	return st.commit()


## The legs' meshes (the species calls it, its legs set): femur, tibia,
## tarsus, a knee; each leg's colours.
func _build_legs(femur_mat: Material, tibia_mat: Material) -> void:
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var f := _part(Vector3.ZERO, Vector3.ONE, L.get("femur_mat", femur_mat))
		var tb := MeshInstance3D.new()
		tb.mesh = _cyl
		tb.material_override = L.get("tibia_mat", tibia_mat)
		_body.add_child(tb)
		var ts := MeshInstance3D.new()
		ts.mesh = _cyl
		ts.material_override = L.get("tibia_mat", tibia_mat)
		_body.add_child(ts)
		var kn := _part(Vector3.ZERO, Vector3.ONE, L.get("femur_mat", femur_mat))
		_leg_mesh.append([f, tb, ts, kn])


# --- the motor ------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	_t += dt
	if dead:
		_lie_dead(dt)
		return
	size = move_toward(size, _g_to, _g_rate * dt)
	if _pilot:
		_pilot.tick(dt)
	if _mate_role == "male" and _mate_stage in ["mount", "joined", "part"]:
		_ride_mate(dt)
		return
	if _mate_role != "":
		_mating(dt)
	else:
		_think(dt)
	if airborne:
		_fly(dt)
	else:
		_walk(dt)
	_place()
	_pose(dt)
	if not airborne:
		_gait(dt)
	_pose_legs()


func _walk(dt: float) -> void:
	var to := _target - _pos
	to.y = 0.0
	var d := to.length()
	var want := 0.0
	if _turn_to != INF:
		var tt := wrapf(_turn_to - _yaw, -PI, PI)
		_yaw += clampf(tt, -2.5 * dt, 2.5 * dt)
		if absf(tt) < 0.02:
			_turn_to = INF
	elif d > 0.002 * size:
		var a := atan2(-to.x, -to.z)
		var turn := wrapf(a - _yaw, -PI, PI)
		_yaw += clampf(turn, -2.5 * dt, 2.5 * dt)
		var pace := _pace if _pace > 0.0 else walk_speed * lerpf(0.35, 1.0, size)
		want = minf(pace, d * 4.0) * clampf(1.0 - absf(turn) / 1.2, 0.0, 1.0)
	_speed = move_toward(_speed, want, dt * 0.4)
	_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed * dt
	ground_y = _ground(_pos.x, _pos.z)
	_pos.y = ground_y


## In the air: steered toward _steer (flying), let down slowly (on a
## thread), or ballistic (a leap); down on the ground, landed.
func _fly(dt: float) -> void:
	if _steer != Vector3.INF:
		var here := _pos + Vector3.UP * _alt
		var to := _steer - here
		var want := to.normalized() * minf(_steer_speed, to.length() * 3.0)
		_vel = _vel.lerp(want, 1.0 - exp(-3.0 * dt))
	elif _slow_fall:
		_vel = _vel.lerp(Vector3(0.0, -0.025, 0.0), 1.0 - exp(-4.0 * dt))
	else:
		_vel.y -= G * dt
	_pos += Vector3(_vel.x, 0.0, _vel.z) * dt
	_alt += _vel.y * dt
	# (its height in the air kept as the ground under it changes)
	var g := _ground(_pos.x, _pos.z)
	_alt += ground_y - g
	ground_y = g
	_pos.y = g
	var hv := Vector2(_vel.x, _vel.z)
	if hv.length() > 0.05:
		var turn := wrapf(atan2(-hv.x, -hv.y) - _yaw, -PI, PI)
		_yaw += clampf(turn, -6.0 * dt, 6.0 * dt)
	if _alt <= 0.0 and _vel.y <= 0.0 and _steer == Vector3.INF:
		_land()


func _land() -> void:
	airborne = false
	_alt = 0.0
	_vel = Vector3.ZERO
	_slow_fall = false
	_speed = 0.0
	_target = _pos
	_place()
	for i in legs.size() * 2:
		_feet[i] = _home(i)
	_swinging = -1
	_on_landed()


## (The species: just landed.)
func _on_landed() -> void:
	pass


## A leap to `to` (on the ground): ballistic, at `angle` up.
func _leap(to: Vector3, angle := 0.75) -> void:
	var d := Vector2(to.x - _pos.x, to.z - _pos.z)
	var dist := maxf(d.length(), 0.01)
	var v := sqrt(dist * G / sin(2.0 * angle))
	var dir := d / dist
	_vel = Vector3(dir.x * cos(angle) * v, sin(angle) * v, dir.y * cos(angle) * v)
	_yaw = atan2(-dir.x, -dir.y)
	airborne = true
	_steer = Vector3.INF
	_alt = 0.001


func _place() -> void:
	var b := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch) * Basis(Vector3.BACK, _roll + _sway)
	var h := (body_h * (1.0 - 0.45 * _crouch) + _lift) * MM * size
	transform = Transform3D(b, _pos + Vector3.UP * (h + _alt))
	_body.scale = Vector3.ONE * MM * size


## Leg i's home: where its foot rests (its parent's space, on the ground).
func _home(i: int) -> Vector3:
	var L: Dictionary = legs[i / 2]
	var side := 1.0 if i % 2 == 1 else -1.0
	var hm: Vector2 = L.home
	var p := transform * (_body.transform * Vector3(hm.x * side, -body_h, hm.y))
	return Vector3(p.x, _ground(p.x, p.z), p.z)


func _gait(dt: float) -> void:
	var vel := Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed
	if _swinging >= 0:
		_swing_t += dt
		var k := clampf(_swing_t / step_time, 0.0, 1.0)
		for i: int in tripod[_swinging]:
			if not legs[i / 2].get("walks", true):
				continue
			var lift := sin(PI * k) * stride * 0.35 * MM * size
			_feet[i] = _from[i].lerp(_to[i], k * k * (3.0 - 2.0 * k)) + Vector3.UP * lift
		if k >= 1.0:
			_swinging = -1
			_next = 1 - _next
		return
	# the next set: has it been left behind (or turned from)?
	var worst := 0.0
	for i: int in tripod[_next]:
		if not legs[i / 2].get("walks", true):
			continue
		var h := _home(i) + vel * step_time
		worst = maxf(worst, Vector2(_feet[i].x - h.x, _feet[i].z - h.z).length())
	if worst > stride * 0.5 * MM * size or (worst > 1.2 * MM * size and _speed < 0.002):
		_swinging = _next
		_swing_t = 0.0
		for i: int in tripod[_next]:
			_from[i] = _feet[i]
			_to[i] = _home(i) + vel * step_time * 1.2
	else:
		_next = 1 - _next if worst < 0.3 * MM * size else _next


## Each leg from its hip to its foot (body mm): walking legs to their
## planted feet; in the air to their dangle; a species-posed one to its.
func _pose_legs() -> void:
	var inv := (transform * _body.transform).affine_inverse()
	var up := (inv.basis * Vector3.UP).normalized()
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var hip := Vector3(hp.x * side, hp.y, hp.z)
		var foot: Vector3
		if _pose_foot[i] != null:
			foot = _pose_foot[i]
		elif airborne:
			var dg: Vector3 = L.dangle
			foot = Vector3(dg.x * side, dg.y, dg.z)
		else:
			foot = inv * _feet[i]
		var out := foot - hip
		out -= up * out.dot(up)
		out = out.normalized() if out.length() > 1e-4 else Vector3(side, 0.0, 0.0)
		var s: float = L.s
		var ankle := foot + (-out * 0.85 + up * float(L.get("ankle_up", 0.5))).normalized() * s
		var pl: Vector3 = L.get("pole", Vector3(0.6, 1.0, 0.0))
		var pole := Vector3(pl.x * side, pl.y, pl.z)
		if L.has("pole_out"): # (the knee up in the leg's own plane, hip to foot: seen from above, one line)
			pole = up + out * float(L.pole_out)
		var knee: Vector3
		if L.has("knee") and not airborne:
			# (held where it is on the body as it walks: the femur still,
			# the tibia reaching from it to the foot; lowered crouching)
			var kn: Vector3 = L.knee
			knee = Vector3(kn.x * side, kn.y - 2.5 * _crouch, kn.z + 1.5 * _crouch)
		else:
			knee = _knee(hip, ankle, L.f, L.t, pole)
		var r: float = L.get("r", 0.5)
		var m: Array = _leg_mesh[i]
		(m[0] as MeshInstance3D).transform = _seg(hip, knee, r * float(L.get("femur_r", 1.6)))
		(m[1] as MeshInstance3D).transform = _seg(knee, ankle, r * 0.55)
		(m[2] as MeshInstance3D).transform = _seg(ankle, foot, r * 0.4)
		(m[3] as MeshInstance3D).transform = Transform3D(Basis().scaled(Vector3.ONE * r * 1.3), knee)


static func _knee(hip: Vector3, ankle: Vector3, f: float, t: float, pole: Vector3) -> Vector3:
	var d := ankle - hip
	var l := clampf(d.length(), absf(f - t) + 0.01, f + t - 0.01)
	var dir := d.normalized() if d.length() > 1e-4 else Vector3.DOWN
	var a := (f * f - t * t + l * l) / (2.0 * l)
	var hh := sqrt(maxf(f * f - a * a, 0.0))
	var p := pole - dir * pole.dot(dir)
	p = p.normalized() if p.length() > 1e-4 else Vector3.UP
	return hip + dir * a + p * hh


## The ground's height at (x, z): height's, or level.
func _ground(x: float, z: float) -> float:
	return float(height.call(x, z)) if height.is_valid() else ground_y


# --- steering: a state machine's (pilot.gd) ---------------------------------------

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
	_piloted()
	_target = point
	_pace = speed
	_turn_to = INF


func _p_hold() -> void:
	_piloted()
	_target = _pos
	_pace = -1.0


func _p_mobile() -> bool:
	return true


func _p_speed() -> float:
	return walk_speed * lerpf(0.35, 1.0, size)


func _p_reach() -> float:
	return 0.012 * size + 0.004


func _p_behaviours() -> PackedStringArray:
	return PackedStringArray()


func _p_act(_name: String, _args: Dictionary) -> bool:
	return false


func _p_act_done(_name: String) -> bool:
	return true


func _p_act_secs(_name: String) -> float:
	return -1.0


## (The species: its own doings set aside, the pilot driving.)
func _piloted() -> void:
	pass


## Where p (body mm) is, in its parent's space.
func _out(p: Vector3) -> Vector3:
	return transform * (_body.transform * p)


# --- mating ---------------------------------------------------------------------------

## Mating with partner (its kind, the other sex): the male goes to her,
## courts, climbs on, joined secs (-1: mate_secs), off again. Either may be
## asked: he leads. False if it can't (young, dead, busy mating, the same
## sex).
func mate(partner: Node3D, secs := -1.0) -> bool:
	if partner == null or partner == self or nymph or dead or _mate_role != "" or not partner.has_method("_mate_join"):
		return false
	if bool(partner.get("male")) == male or bool(partner.get("nymph")) or bool(partner.get("dead")) or partner.get("_mate_role") != "":
		return false
	var him: Node3D = self if male else partner
	var her: Node3D = partner if male else self
	var s := secs if secs > 0.0 else mate_secs
	him.call("_mate_join", her, "male", s)
	her.call("_mate_join", him, "female", s)
	return true


## Whether it's mating (any stage).
func is_mating() -> bool:
	return _mate_role != ""


## The stage it's at: "" (not mating); the male's "seek", "court", "mount",
## "joined", "part"; the female's "wait", "joined".
func mate_stage() -> String:
	return _mate_stage


## (How far through the stage it's at, s.)
func mate_time() -> float:
	return _mate_t


func _mate_join(partner: Node3D, role: String, secs: float) -> void:
	_mate = partner
	_mate_role = role
	_mate_stage = "seek" if role == "male" else "wait"
	_mate_t = 0.0
	mate_secs = secs
	_on_mate_start()


## (The species: how much smaller the male (his share of her size).)
func _male_size() -> float:
	return 1.0


## (The species: where he goes to court her (her body mm), before he climbs
## on.)
func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, 14.0)


## (The species: where he's left when he climbs off (her body mm).)
func _mate_leave() -> Vector3:
	return _mate_approach()


## (The species: s he takes to climb on (and off).)
func _mount_secs() -> float:
	return 0.9


## (The species: s he courts her for once there, facing her.)
func _court_secs() -> float:
	return 0.0


## (The species: how he's carried on her: {at: her body mm, where his body's
## middle is; basis: his turned from hers; grips: {leg: her body mm, his foot
## there}; free: {leg: his body mm, a leg held there}}; the rest of his legs
## to their dangle.)
func _mount() -> Dictionary:
	return {"at": Vector3(0.0, body_h * 1.6, 3.0), "basis": Basis(), "grips": {}}


## (The species: mating's begun; it's ended (each partner).)
func _on_mate_start() -> void:
	pass


func _after_mate() -> void:
	pass


## (The species: something happening during it (his or hers): the mantis's
## meal of him; false: it isn't over yet, on as it is.)
func _mate_over() -> bool:
	return _mate_t >= mate_secs


func _end_mate() -> void:
	for i in _gripped:
		_pose_foot[i] = null
	_gripped.clear()
	_mate = null
	_mate_role = ""
	_mate_stage = ""
	_mate_t = 0.0
	_after_mate()


## Mating, on the ground: she waits (still), he goes to her and courts.
func _mating(dt: float) -> void:
	_mate_t += dt
	if _mate == null or not is_instance_valid(_mate):
		_end_mate()
		return
	var her: Node3D = _mate
	if _mate_role == "female":
		_target = _pos
		_pace = -1.0
		if _mate.get("_mate_role") != "male": # (he's gone)
			_end_mate()
		elif _mate.get("_mate_stage") in ["mount", "joined"]:
			_mate_stage = "joined"
		return
	match _mate_stage:
		"seek":
			var to: Vector3 = her.call("_out", _mate_approach())
			_target = Vector3(to.x, _pos.y, to.z)
			_pace = -1.0
			if Vector2(to.x - _pos.x, to.z - _pos.z).length() < _p_reach() * 0.5:
				_mate_stage = "court"
				_mate_t = 0.0
				var at: Vector3 = her.call("_out", Vector3(0.0, 0.0, 0.0))
				_turn_to = atan2(-(at.x - _pos.x), -(at.z - _pos.z))
		"court":
			_target = _pos
			if _mate_t >= _court_secs():
				_mate_stage = "mount"
				_mate_t = 0.0
				_mount_from = transform
				_speed = 0.0


## Mounted on her: carried (his transform hers, through the climb on and
## the climb off), his feet where they grip.
func _ride_mate(dt: float) -> void:
	_mate_t += dt
	if _mate == null or not is_instance_valid(_mate):
		_dismounted()
		return
	process_priority = _mate.process_priority + 1 # (after her: carried where she is now)
	var m := _mount()
	var her_t: Transform3D = _mate.transform
	var hs := float(_mate.get("size")) * MM
	var mb: Basis = m.get("basis", Basis())
	var mat: Vector3 = m.at
	_mount_to = Transform3D(her_t.basis * mb, her_t * (mat * hs))
	var k := 1.0
	match _mate_stage:
		"mount":
			k = clampf(_mate_t / _mount_secs(), 0.0, 1.0)
			if k >= 1.0:
				_mate_stage = "joined"
				_mate_t = 0.0
		"joined":
			if _mate_over():
				_mate_stage = "part"
				_mate_t = 0.0
				# (off behind her, on the ground)
				var off: Vector3 = _mate.call("_out", _mate_leave())
				_pos = Vector3(off.x, _ground(off.x, off.z), off.z)
				ground_y = _pos.y
				var fwd := -(_mount_to.basis.z)
				_yaw = atan2(-fwd.x, -fwd.z)
				_pitch = 0.0
				_roll = 0.0
				_place()
				_mount_from = transform
		"part":
			k = 1.0 - clampf(_mate_t / _mount_secs(), 0.0, 1.0)
	if _mate == null or dead: # (it ended there: the species' own end)
		return
	var e := k * k * (3.0 - 2.0 * k)
	transform = _mount_from.interpolate_with(_mount_to, e)
	transform.origin += Vector3.UP * sin(PI * e) * body_h * 0.6 * MM * size
	_body.scale = Vector3.ONE * MM * size
	_pose(dt)
	# his feet: gripping her where they hold; the rest held, or dangling
	var inv := (transform * _body.transform).affine_inverse()
	var grips: Dictionary = m.get("grips", {})
	var free: Dictionary = m.get("free", {})
	for i in legs.size() * 2:
		if grips.has(i):
			var w: Vector3 = _mate.call("_out", grips[i])
			var g := inv * w
			_pose_foot[i] = (inv * _feet[i]).lerp(g, e) if _mate_stage == "mount" else g
		elif free.has(i):
			_pose_foot[i] = free[i]
		elif not _gripped.has(i) and _pose_foot[i] != null:
			continue # (the species' own)
		else:
			var dg: Vector3 = legs[i / 2].dangle
			_pose_foot[i] = Vector3(dg.x * (1.0 if i % 2 == 1 else -1.0), dg.y, dg.z)
		if not _gripped.has(i):
			_gripped.append(i)
	_pose_legs()
	if _mate_stage == "part" and k <= 0.0:
		_dismounted()


func _dismounted() -> void:
	process_priority = 0
	var p := transform.origin
	_pos = Vector3(p.x, _ground(p.x, p.z), p.z)
	ground_y = _pos.y
	var fwd := -transform.basis.z
	_yaw = atan2(-fwd.x, -fwd.z)
	_pitch = 0.0
	_roll = 0.0
	_target = _pos
	_speed = 0.0
	_place()
	for i in legs.size() * 2:
		_feet[i] = _home(i)
	_swinging = -1
	var her := _mate
	_end_mate()
	if her != null and is_instance_valid(her) and her.get("_mate_role") == "female":
		her.call("_end_mate")
	_on_parted()


## (The species: he's just climbed off.)
func _on_parted() -> void:
	pass


## Dead: over onto its back, legs curled in, still.
func die() -> void:
	if dead:
		return
	if _mate_role != "":
		var her := _mate
		_end_mate()
		if her != null and is_instance_valid(her) and her.get("_mate_role") != "":
			her.call("_end_mate")
	dead = true
	_dead_t = 0.0
	airborne = false
	_speed = 0.0
	if _pilot:
		_pilot.stop()


func _lie_dead(dt: float) -> void:
	_dead_t += dt
	var k := clampf(_dead_t / 1.2, 0.0, 1.0)
	_roll = lerpf(_roll, PI * 0.92, k)
	_pitch = lerpf(_pitch, 0.0, k)
	_crouch = k
	_lift = lerpf(_lift, -body_h * 0.35, k)
	_alt = 0.0
	_place()
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var f: float = L.f
		# (curled in under it: up, now it's on its back)
		_pose_foot[i] = Vector3(hp.x * side + side * f * 0.35, hp.y - f * 0.5, hp.z * 0.8)
	_pose_legs()
	if _dead_t > 2.0:
		set_process(false)
