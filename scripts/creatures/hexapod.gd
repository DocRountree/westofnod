extends Node3D
## A walking insect built from parts (the grasshopper, the mantis: their
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
## Its transform is set every frame: put it under a node that isn't moved.

const MM := 0.002
const G := 9.8
const SPHERE_N := [14, 8]

# what the species sets
var body_h := 4.0 ## mm its thorax's middle stands over the ground
var walk_speed := 0.03 ## m/s (the adult's)
var stride := 7.0 ## mm a foot's left behind before its set steps
var step_time := 0.14 ## s a set's swing takes
var legs: Array = [] ## the right side's: {hip, f, t, s, home: Vector2 (x, z), dangle: Vector3, pole: Vector3 (body: the knee's way), walks: bool, r: thickness (mm), knee: Vector3 (body mm: held there on the ground, not reached for: a grasshopper's hind knee)}
var tripod := [[0, 3, 4], [1, 2, 5]] ## (a leg: its pair * 2, + 1 the right)

var size := 1.0
var nymph := false
var ground_y := 0.0
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


func _init(nymph_ := false, size_ := 1.0) -> void:
	nymph = nymph_
	size = size_
	_g_to = size_
	rng.randomize()


func _ready() -> void:
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
	for i in 6:
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
	for i in 6:
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
	size = move_toward(size, _g_to, _g_rate * dt)
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
		want = minf(walk_speed * lerpf(0.35, 1.0, size), d * 4.0) * clampf(1.0 - absf(turn) / 1.2, 0.0, 1.0)
	_speed = move_toward(_speed, want, dt * 0.4)
	_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed * dt
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
	for i in 6:
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
	return Vector3(p.x, ground_y, p.z)


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
	for i in 6:
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
		var ankle := foot + (-out * 0.85 + up * 0.5).normalized() * s
		var pl: Vector3 = L.get("pole", Vector3(0.6, 1.0, 0.0))
		var pole := Vector3(pl.x * side, pl.y, pl.z)
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


## Where p (body mm) is, in its parent's space.
func _out(p: Vector3) -> Vector3:
	return transform * (_body.transform * p)
