class_name Snake
extends Node3D
## Snakes, life size (unlike the insects: not doubled): an eastern
## diamondback rattlesnake (Crotalus adamanteus: Snake.new("rattler")) or an
## eastern milk snake (Lampropeltis triangulum: Snake.new("milk")); young:
## Snake.new(kind, true) (a newborn's size and colours: the rattler's only a
## button for a rattle, the milk snake's saddles bright red), growing.
## The body one smooth skin bent along a spine of SPINE points
## (snake.gdshader: its pattern, its scales; a meal's bulge going down it),
## the head lofted (the rattler's broad, a triangle, heat pits, slit
## pupils, a dark stripe through each eye edged in cream; the milk snake's
## narrow, little wider than its neck, round pupils), the lower jaw hinged,
## the forked tongue flicking; the rattler's rattle.
##
## - wander(centre, radius): slithering (lateral undulation: the head
##   going in waves, every point of the body following where it went),
##   pausing, the tongue flicking
## - coil(): coiled up at rest, the head raised a little on the coil
## - eat(prey): to it; the rattler coils, rattles, strikes and lets go,
##   waits, then swallows it; the milk snake strikes and holds, throws its
##   coils round it, constricts, then swallows: the jaws gaping, walking
##   over it head first, the meal a bulge going down the body
## - lay(n): the milk snake loosely coiled, laying n eggs by its tail
##   (leathery, white: Egg), later hatching (Egg.hatch: a slit, the young's
##   head out, waiting, then out and away); the rattler gives birth (no
##   eggs): n young, each in a clear membrane it wriggles free of at once
## Put it under a node that isn't moved: its own transform stays identity.

const SPINE := 40
const KINDS := {
	"rattler": {"len": 1.4, "r": 0.042, "head": Vector3(0.066, 0.03, 0.078), "speed": 0.14, "young": 0.26, "rattle": 9, "egg": "sac"},
	"milk": {"len": 0.85, "r": 0.014, "head": Vector3(0.022, 0.013, 0.03), "speed": 0.2, "young": 0.3, "rattle": 0, "egg": "egg"},
}

var kind := "rattler"
var K: Dictionary
var young := false
var size := 1.0
var ground_y := 0.0
var rng := RandomNumberGenerator.new()
var eggs: Array[Node3D] = [] ## its eggs (or birth sacs) laid, in its parent
var _g_to := 1.0
var _g_rate := 0.0

var _pos := Vector3.ZERO # the head's front, on the ground
var _dir := Vector3.FORWARD # the way it's heading (the waves about it)
var _phase := 0.0
var _trail: Array[Vector3] = []
var _target := Vector3.ZERO
var _centre := Vector3.ZERO
var _radius := 0.5
var _wait := 0.0
var _mode := "wander"
var _stage := 0
var _st := 0.0
var _t := 0.0
var _speed := 0.0
var _prey: Node3D
var _coil_k := 0.0 # 0 as it goes .. 1 coiled
var _coil_at := Vector3.ZERO
var _coil_r0 := 0.0 # the coil's innermost radius (m)
var _strike_k := 0.0
var _strike_at := Vector3.ZERO
var _gape := 0.0
var _rattle := 0.0
var _bulge_s := -100.0
var _bulge_r := 0.0
var _lay_left := 0
var _lay_t := 0.0
var _peek := 0.0 # s it keeps its head out of its egg before coming on out

var _skin: MeshInstance3D
var _mat: ShaderMaterial
var _head: Node3D
var _jaw: Node3D
var _tongue: Node3D
var _tail: Node3D
var _rattle_node: Node3D
var _pts: Array[Vector3] = []


func _init(k := "rattler", young_ := false) -> void:
	kind = k
	K = KINDS[k]
	young = young_
	size = float(K.young) if young_ else 1.0
	_g_to = size
	rng.randomize()


## Puts its head at `at` (on the ground), facing `facing`, its body
## stretched out behind it.
func place(at: Vector3, facing := Vector3.FORWARD) -> void:
	ground_y = at.y
	_pos = at
	_dir = Vector3(facing.x, 0.0, facing.z).normalized()
	_trail.clear()
	_target = at


## Its body coiled up inside something (an egg, a birth sac) at c, r
## round, its head at the rim toward `out`: as it comes out, its body
## follows its head out.
func curled_in(c: Vector3, r: float, out: Vector3) -> void:
	ground_y = c.y
	_dir = Vector3(out.x, 0.0, out.z).normalized()
	_pos = c + _dir * r
	_trail.clear()
	var L := float(K.len) * size
	var turns := L / (TAU * r * 0.6)
	var n := 120
	var a0 := atan2(_dir.z, _dir.x)
	for k in n:
		var f := float(k) / (n - 1)
		var a := a0 - f * turns * TAU
		var rr := r * lerpf(0.9, 0.3, f)
		_trail.append(c + Vector3(cos(a), 0.0, sin(a)) * rr + Vector3.UP * (rr * 0.0 + f * r * 0.6))
	_mode = "peek"
	_peek = 3.0
	_target = _pos


func grow(to: float, secs: float) -> void:
	_g_to = to
	_g_rate = absf(to - size) / maxf(secs, 0.01)


func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0


func coil() -> void:
	_mode = "coil"
	_coil_at = _pts[SPINE / 2] if _pts.size() > SPINE / 2 else _pos
	_coil_r0 = float(K.r) * size * 2.2


func eat(prey: Node3D) -> void:
	_mode = "eat"
	_prey = prey
	_stage = 0
	_st = 0.0


func lay(n := 6) -> void:
	if young:
		return
	_mode = "lay"
	_lay_left = n
	_lay_t = 0.0
	_coil_at = _pts[SPINE / 2] if _pts.size() > SPINE / 2 else _pos
	_coil_r0 = float(K.r) * size * 3.5


# --- the body -----------------------------------------------------------------------

func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/render/snake.gdshader")
	_mat.set_shader_parameter("species", 0 if kind == "rattler" else 1)
	_mat.set_shader_parameter("young", young)
	_mat.set_shader_parameter("count", SPINE)
	_mat.set_shader_parameter("girths", float(K.len) / (2.0 * float(K.r))) # (its length in its thickness)
	_skin = MeshInstance3D.new()
	_skin.mesh = _tube()
	_skin.material_override = _mat
	_skin.custom_aabb = AABB(Vector3(-200, -200, -200), Vector3(400, 400, 400)) # (it's placed by its shader)
	add_child(_skin)
	_build_head()
	_tail = Node3D.new()
	add_child(_tail)
	if int(K.rattle) > 0:
		_rattle_node = Node3D.new()
		_tail.add_child(_rattle_node)
		var segs := 1 if young else int(K.rattle)
		var rr := float(K.r) * 0.32
		var keratin := _plain(Color(0.55, 0.5, 0.4), 0.5)
		for k in segs:
			var b := MeshInstance3D.new()
			b.mesh = _sphere()
			b.scale = Vector3(rr * 2.0 * (1.0 - 0.03 * k), rr * 1.3, rr * 1.5)
			b.position = Vector3(0.0, 0.0, rr * (0.6 + 1.05 * k))
			b.material_override = keratin
			_rattle_node.add_child(b)
	_update(0.0)


static var _sph: SphereMesh


static func _sphere() -> SphereMesh:
	if _sph == null:
		_sph = SphereMesh.new()
		_sph.radius = 0.5
		_sph.height = 1.0
		_sph.radial_segments = 12
		_sph.rings = 7
	return _sph


static func _plain(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


## The body's radius at t (0 the neck .. 1 the tail's tip), a share of its
## thickest.
func _profile(t: float) -> float:
	var tail_from := 0.8 if kind == "rattler" else 0.72 # (a rattler's tail short, a milk snake's long and slender)
	var r := lerpf(0.45, 1.0, smoothstep(0.0, 0.3, t))
	r *= lerpf(1.0, 0.82, smoothstep(0.45, tail_from, t))
	r *= lerpf(1.0, 0.18 if kind == "rattler" else 0.06, smoothstep(tail_from, 1.0, t))
	return r


## The body's skin: rings along the spine (VERTEX.z, 0 .. SPINE - 1),
## round each a slightly flattened oval, its belly flatter; full size (m).
func _tube() -> ArrayMesh:
	const PER := 3
	const ROUND := 14
	var R := float(K.r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := (SPINE - 1) * PER + 1
	var vert := func(k: int, a_i: int) -> Array:
		var s := float(k) / PER
		var t := s / (SPINE - 1)
		var r := _profile(t) * R
		var dr := (_profile(minf(t + 0.01, 1.0)) - _profile(maxf(t - 0.01, 0.0))) * R / 0.02 / (float(K.len) / (SPINE - 1))
		var a := TAU * float(a_i % ROUND) / ROUND
		var hy := 0.85 * (0.7 if cos(a) < 0.0 else 1.0) # (round = 0 its back: up)
		var x := sin(a) * r
		var y := cos(a) * r * hy
		var n := Vector3(sin(a) * hy, cos(a), -dr).normalized()
		return [Vector3(x, y, s), n, Vector2(t, float(a_i) / ROUND)]
	for k in rings - 1:
		for a_i in ROUND:
			var q := [vert.call(k, a_i), vert.call(k + 1, a_i), vert.call(k + 1, a_i + 1), vert.call(k, a_i + 1)]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var A: Array = q[tri[0]]
				var B: Array = q[tri[1]]
				var C: Array = q[tri[2]]
				var seg := float(K.len) / (SPINE - 1)
				var pa := Vector3(A[0].x, A[0].y, A[0].z * seg)
				var pb := Vector3(B[0].x, B[0].y, B[0].z * seg)
				var pc := Vector3(C[0].x, C[0].y, C[0].z * seg)
				var face := -(pb - pa).cross(pc - pa)
				var out := Vector3(pa.x + pb.x + pc.x, pa.y + pb.y + pc.y, 0.0)
				var order := [A, B, C] if face.dot(out) >= 0.0 else [A, C, B]
				for v: Array in order:
					st.set_normal(v[1])
					st.set_uv(v[2])
					st.add_vertex(v[0])
	return st.commit()


## The head (m, full size; its own frame: -z its snout, its back at the
## neck): lofted, the lower jaw hinged under it, the eyes, the tongue.
func _build_head() -> void:
	_head = Node3D.new()
	add_child(_head)
	var hd: Vector3 = K.head # (width, height, length)
	var W := hd.x * 0.5
	var H := hd.y * 0.5
	var L := hd.z
	var nk := float(K.r) * 0.45
	var keys: Array
	if kind == "rattler": # (broad behind, a triangle, flat topped)
		keys = [[0.01, 0.0, nk, nk * 0.9], [-0.15 * L, 0.0, W * 0.75, H * 1.1], [-0.38 * L, 0.06 * H, W, H], [-0.65 * L, 0.06 * H, W * 0.78, H * 0.85],
				[-0.86 * L, 0.03 * H, W * 0.5, H * 0.65], [-0.97 * L, 0.0, W * 0.25, H * 0.4], [-L, 0.0, W * 0.05, H * 0.08]]
	else: # (narrow, little wider than the neck, rounded)
		keys = [[0.01, 0.0, nk, nk * 0.9], [-0.2 * L, 0.0, W * 0.9, H], [-0.45 * L, 0.04 * H, W, H], [-0.75 * L, 0.03 * H, W * 0.8, H * 0.85],
				[-0.93 * L, 0.0, W * 0.45, H * 0.55], [-L, 0.0, W * 0.08, H * 0.1]]
	var col := Color(0.42, 0.35, 0.22) if kind == "rattler" else Color(0.66, 0.6, 0.5)
	if young:
		col = col.lightened(0.12)
	var skin := _plain(col, 0.6 if kind == "rattler" else 0.3)
	var hm := MeshInstance3D.new()
	hm.mesh = _loft(keys, 2.4)
	hm.material_override = skin
	_head.add_child(hm)
	# the lower jaw: hinged at the back of the head, under it
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -H * 0.55, -0.22 * L)
	_head.add_child(_jaw)
	var jm := MeshInstance3D.new()
	jm.mesh = _sphere()
	jm.scale = Vector3(W * 1.5, H * 0.45, L * 0.78)
	jm.position = Vector3(0.0, -H * 0.1, -0.36 * L)
	jm.material_override = _plain(col.lightened(0.25), 0.6)
	_jaw.add_child(jm)
	# the eyes; the rattler's slit pupils, its heat pits, the dark stripe
	# back from each eye edged in cream; the milk snake's round, dark
	var er := W * (0.2 if kind == "rattler" else 0.32)
	for side: float in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		e.mesh = _sphere()
		e.scale = Vector3.ONE * er * 2.0
		e.position = Vector3(W * 0.72 * side, H * 0.45, -0.66 * L)
		e.material_override = _plain(Color(0.55, 0.42, 0.18) if kind == "rattler" else Color(0.06, 0.05, 0.05), 0.15)
		_head.add_child(e)
		if kind == "rattler":
			var pupil := MeshInstance3D.new()
			pupil.mesh = _sphere()
			pupil.scale = Vector3(er * 0.5, er * 1.7, er * 0.5)
			pupil.position = e.position + Vector3(er * 0.85 * side, 0.0, 0.0)
			pupil.material_override = _plain(Color(0.02, 0.02, 0.02), 0.1)
			_head.add_child(pupil)
			var pit := MeshInstance3D.new()
			pit.mesh = _sphere()
			pit.scale = Vector3.ONE * er * 0.8
			pit.position = Vector3(W * 0.62 * side, H * 0.15, -0.84 * L)
			pit.material_override = _plain(Color(0.05, 0.04, 0.03), 0.4)
			_head.add_child(pit)
			for k in 3: # (the stripe: cream, dark, cream, back from the eye to the jaw's corner)
				var sp := MeshInstance3D.new()
				sp.mesh = _sphere()
				sp.scale = Vector3(W * 0.12, H * 0.22, L * 0.55)
				sp.position = Vector3(W * 0.84 * side, H * (0.2 - 0.28 * k), -0.4 * L)
				sp.rotation = Vector3(-0.35, 0.18 * side, 0.0)
				sp.material_override = _plain(Color(0.85, 0.78, 0.55) if k != 1 else Color(0.1, 0.07, 0.05), 0.6)
				_head.add_child(sp)
	# the tongue: forked, out from under the snout
	_tongue = Node3D.new()
	_tongue.position = Vector3(0.0, -H * 0.35, -0.95 * L)
	_head.add_child(_tongue)
	var tc := _plain(Color(0.08, 0.06, 0.06) if kind == "rattler" else Color(0.7, 0.12, 0.1), 0.4)
	var tl := L * 0.55
	_tstick(Vector3.ZERO, Vector3(0.0, 0.0, -tl * 0.65), tl * 0.035, tc)
	for side: float in [-1.0, 1.0]:
		_tstick(Vector3(0.0, 0.0, -tl * 0.65), Vector3(tl * 0.12 * side, 0.0, -tl), tl * 0.025, _plain(Color(0.05, 0.04, 0.04), 0.4) if kind != "rattler" else tc)


func _tstick(a: Vector3, b: Vector3, r: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 4
	c.rings = 1
	mi.mesh = c
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x * r * 2.0, d, z * r * 2.0), (a + b) * 0.5)
	mi.material_override = m
	_tongue.add_child(mi)


## A smooth shell lofted through keys ([z, y, half width, half height], m).
static func _loft(keys: Array, sq := 2.0) -> ArrayMesh:
	const RING := 14
	const STEPS := 16
	var K_ := keys.size()
	var key := func(j: int, c: int) -> float:
		return float((keys[clampi(j, 0, K_ - 1)] as Array)[c])
	var rings := []
	for i in STEPS + 1:
		var t := float(i) / STEPS * (K_ - 1)
		var j := mini(int(t), K_ - 2)
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
	for i in STEPS:
		for k in RING:
			var q := [[i, k], [i + 1, k], [i + 1, (k + 1) % RING], [i, (k + 1) % RING]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var ps := []
				for e: int in tri:
					var ik: Array = q[e]
					ps.append((rings[ik[0]] as Array)[ik[1]])
				var a: Vector3 = ps[0]
				var b: Vector3 = ps[1]
				var c: Vector3 = ps[2]
				var r0: Array = rings[q[tri[0]][0]]
				var mid := ((r0[0] as Vector3) + (r0[RING / 2] as Vector3)) * 0.5
				var out := (a + b + c) / 3.0 - mid
				out.z = 0.0
				var order := [0, 1, 2] if (-(b - a).cross(c - a)).dot(out) >= 0.0 else [0, 2, 1]
				var p0: Vector3 = ps[order[0]]
				var p1: Vector3 = ps[order[1]]
				var p2: Vector3 = ps[order[2]]
				var n := (-(p1 - p0).cross(p2 - p0)).normalized()
				for o: int in order:
					var p: Vector3 = ps[o]
					var rn := (p - mid)
					rn.z *= 0.3
					st.set_normal((rn.normalized() + n * 0.3).normalized())
					st.add_vertex(p)
	return st.commit()


# --- moving ------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or _skin == null:
		return
	_t += dt
	_st += dt
	size = move_toward(size, _g_to, _g_rate * dt)
	_think(dt)
	_update(dt)


func _think(dt: float) -> void:
	var go := false
	match _mode:
		"peek": # (its head out of its egg, tasting the air; then on out)
			_peek -= dt
			if _peek <= 0.0:
				wander(_pos + _dir * 0.1 * size, 0.4 * size + 0.2)
		"wander":
			_coil_k = move_toward(_coil_k, 0.0, dt * 0.8)
			_wait -= dt
			if _wait <= 0.0 or _pos.distance_to(_target) < 0.03 * size:
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
				_wait = rng.randf_range(4.0, 10.0)
				if rng.randf() < 0.2:
					_target = _pos # (a rest)
			go = _pos.distance_to(_target) > 0.03 * size
		"coil":
			_coil_k = move_toward(_coil_k, 1.0, dt * 0.6)
		"lay":
			_coil_k = move_toward(_coil_k, 0.8, dt * 0.6)
			if _coil_k > 0.75:
				_lay_t -= dt
				if _lay_t <= 0.0 and _lay_left > 0:
					_lay_left -= 1
					_lay_t = 2.2
					_drop_egg()
				elif _lay_left == 0 and _lay_t <= -2.0:
					wander(_pos, 0.6)
		"eat":
			go = _eat(dt)
	# moving: the head on toward its target, its way swinging in waves
	var want := float(K.speed) * lerpf(0.5, 1.0, size) if go else 0.0
	_speed = move_toward(_speed, want, dt * 0.5)
	if _speed > 0.0005:
		var to := _target - _pos
		to.y = 0.0
		if to.length() > 0.001:
			var turn := _dir.signed_angle_to(to.normalized(), Vector3.UP)
			_dir = _dir.rotated(Vector3.UP, clampf(turn, -1.0 * dt, 1.0 * dt))
		var wl := float(K.len) * size * 0.45 # (a wave's length along its path)
		_phase += _speed * dt / wl * TAU
		var way := _dir.rotated(Vector3.UP, 0.55 * sin(_phase))
		_pos += way * _speed * dt
		_pos.y = ground_y
	if _trail.is_empty() or _trail[0].distance_to(_pos) > float(K.len) * size / SPINE / 3.0:
		_trail.push_front(_pos)
		while _trail.size() > SPINE * 4 + 20:
			_trail.pop_back()


## Eating: to it, the strike, (the milk snake's coils round it), then
## swallowing it head first, the bulge going down. Whether it's going on.
func _eat(dt: float) -> bool:
	if not is_instance_valid(_prey):
		wander(_pos, 0.6)
		return false
	var p := _prey.position
	var hl := float((K.head as Vector3).z) * size
	match _stage:
		0: # nearer, within a strike (a third of its length)
			var to := p - _pos
			to.y = 0.0
			var reach := float(K.len) * size * 0.25
			if to.length() > reach:
				_target = p - to.normalized() * reach * 0.9
				return true
			_stage = 1
			_st = 0.0
		1: # (the rattler) coiled, rattling, its head drawn back in an S
			if kind == "rattler":
				_coil_at = _pts[SPINE / 2]
				_coil_r0 = float(K.r) * size * 2.2
				_coil_k = move_toward(_coil_k, 0.6, dt * 1.2)
				_rattle = 1.0
				if _st > 1.6:
					_stage = 2
					_st = 0.0
			else:
				_stage = 2
				_st = 0.0
		2: # the strike: out and back in a fifth of a second (the milk snake holds on)
			_strike_at = p + Vector3.UP * 0.01 * size
			var k := clampf(_st / 0.08, 0.0, 1.0)
			_strike_k = k * k * (3.0 - 2.0 * k)
			_gape = _strike_k * 0.9
			if _st > 0.14:
				_stage = 3 if kind == "rattler" else 4
				_st = 0.0
		3: # (the rattler) back, waiting for its venom to work, the tongue going
			_strike_k = move_toward(_strike_k, 0.0, dt * 4.0)
			_gape = move_toward(_gape, 0.0, dt * 4.0)
			_rattle = move_toward(_rattle, 0.0, dt)
			if _st > 3.0:
				_coil_k = 0.0
				_stage = 5
				_st = 0.0
		4: # (the milk snake) its coils thrown round it, squeezing
			_strike_k = move_toward(_strike_k, 0.0, dt * 2.0)
			_gape = 0.3
			_coil_at = p
			_coil_r0 = float(K.r) * size * 1.4 + 0.012 * size
			_coil_k = move_toward(_coil_k, 1.0, dt * 1.5)
			if _st > 5.0:
				_coil_k = 0.0
				_stage = 5
				_st = 0.0
		5: # to it, its head to the meal's head
			_coil_k = move_toward(_coil_k, 0.0, dt)
			_strike_k = 0.0
			var to := p - _pos
			to.y = 0.0
			if to.length() > hl * 0.6:
				_target = p
				_st = 0.0
				return true
			_stage = 7
			_st = 0.0
		7: # swallowing: the jaws gaping, walking on over it, the meal drawn in
			var into := clampf(_st / 7.0, 0.0, 1.0)
			_gape = 0.85 - 0.15 * sin(_st * 4.0)
			_prey.position = p.lerp(_pts[0], 1.0 - exp(-dt * 0.6))
			_prey.scale = Vector3.ONE * maxf(1.0 - into, 0.02)
			if into >= 1.0:
				_prey.queue_free()
				_prey = null
				_gape = 0.0
				_bulge_s = 1.0
				_bulge_r = 0.7
				_stage = 6
				_st = 0.0
		6: # the bulge going down
			_bulge_s = lerpf(1.0, SPINE * 0.45, clampf(_st / 10.0, 0.0, 1.0))
			if _st > 10.0:
				_bulge_r = move_toward(_bulge_r, 0.35, dt * 0.2)
				wander(_pos, 0.6)
	return false


## An egg (the milk snake's) or a young in its sac (the rattler's), out
## by its tail.
func _drop_egg() -> void:
	var parent := get_parent() as Node3D
	if parent == null or _pts.size() < SPINE:
		return
	var vent: Vector3 = _pts[int(SPINE * 0.85)]
	var e := Egg.new()
	e.kind = K.egg
	e.mother = self
	parent.add_child(e)
	var a := rng.randf() * TAU
	e.position = Vector3(vent.x, ground_y, vent.z) + Vector3(cos(a), 0.0, sin(a)) * float(K.r) * 1.5
	e.rotation.y = rng.randf() * TAU
	eggs.append(e)
	if K.egg == "sac": # (born, not laid: out of its membrane at once)
		e.call_deferred("hatch")


## The spine's points (the body following its head's trail; coiled; the
## strike), the skin bent along them, the head, the tail, the tongue.
func _update(_dt: float) -> void:
	var L := float(K.len) * size
	var seg := L / (SPINE - 1)
	var R := float(K.r) * size
	_pts.clear()
	for i in SPINE:
		var p := _along_trail(i * seg)
		_pts.append(Vector3(p.x, ground_y + R * _profile(float(i) / (SPINE - 1)) * 0.85, p.z))
	# coiled: an Archimedean spiral round _coil_at, the tail outside, the
	# head on top of it, raised a little
	if _coil_k > 0.0:
		var gap := R * 2.1
		var b := gap / TAU
		var a0 := _coil_r0
		var raised := int(SPINE * 0.16)
		for i in SPINE:
			var s := i * seg # (from the head, inside, outward to the tail)
			var th := (-a0 + sqrt(a0 * a0 + 2.0 * b * s)) / maxf(b, 1e-6)
			var r := a0 + b * th
			var c := _coil_at + Vector3(cos(-th), 0.0, sin(-th)) * r
			var y := ground_y + R * _profile(float(i) / (SPINE - 1)) * 0.85 + (R * 1.6 if i < raised * 2 else 0.0)
			if i < raised: # (the neck in an S, the head up, looking out)
				y += R * 2.5 * (1.0 - float(i) / raised) + R
			var coiled := Vector3(c.x, y, c.z)
			_pts[i] = _pts[i].lerp(coiled, _coil_k)
	# the strike: the front third reaching straight out to its mark, arched
	if _strike_k > 0.0:
		var k0 := int(SPINE * 0.3)
		var base: Vector3 = _pts[k0]
		for i in k0:
			var f := float(k0 - i) / k0
			var line := base.lerp(_strike_at, f) + Vector3.UP * sin(PI * f) * L * 0.05
			_pts[i] = _pts[i].lerp(line, _strike_k)
	# the rattle: the tail's tip raised, buzzing
	if _rattle > 0.0:
		for i in range(SPINE - 4, SPINE):
			_pts[i] += Vector3.UP * R * 3.0 * _rattle * float(i - (SPINE - 4)) / 3.0
	var sp := PackedVector3Array()
	var sx := PackedVector3Array()
	var sy := PackedVector3Array()
	var frames: Array[Basis] = []
	for i in SPINE:
		var fwd: Vector3
		if i == 0:
			fwd = _pts[0] - _pts[1]
		else:
			fwd = _pts[i - 1] - _pts[i]
		if fwd.length_squared() < 1e-10:
			fwd = _dir
		fwd = fwd.normalized()
		var up := Vector3.UP if absf(fwd.y) < 0.95 else Vector3.BACK
		var bs := Basis.looking_at(fwd, up)
		frames.append(bs)
		sp.append(_pts[i])
		sx.append(bs.x)
		sy.append(bs.y)
	_mat.set_shader_parameter("sp", sp)
	_mat.set_shader_parameter("sx", sx)
	_mat.set_shader_parameter("sy", sy)
	_mat.set_shader_parameter("size", size)
	_mat.set_shader_parameter("bulge_s", _bulge_s)
	_mat.set_shader_parameter("bulge_r", _bulge_r)
	# the head on the neck (its back at the first point), the jaw, the tongue
	_head.transform = Transform3D(frames[0] * Basis.from_scale(Vector3.ONE * size), _pts[0])
	_jaw.rotation.x = _gape * 0.9
	var flick := fmod(_t, 2.6)
	var out := 0.0
	if flick < 0.9 and _gape < 0.1:
		out = absf(sin(flick / 0.9 * PI * 3.0))
	_tongue.scale = Vector3(1.0, 1.0, maxf(out, 0.01))
	_tongue.visible = out > 0.02
	_tongue.rotation.x = 0.25 * sin(_t * 30.0) * out
	# the tail's tip, the rattle on it, buzzing
	var tb: Basis = frames[SPINE - 1]
	_tail.transform = Transform3D(tb, _pts[SPINE - 1])
	if _rattle_node:
		_rattle_node.scale = Vector3.ONE * size
		_rattle_node.rotation = Vector3(0.0, 0.25 * sin(_t * 120.0) * _rattle, 0.0)


func _along_trail(d: float) -> Vector3:
	var prev := _pos
	var left := d
	for q in _trail:
		var l := prev.distance_to(q)
		if l >= left and l > 1e-7:
			return prev.lerp(q, left / l)
		left -= l
		prev = q
	var back := -_dir
	if _trail.size() >= 2:
		var tb := _trail[_trail.size() - 1] - _trail[_trail.size() - 2]
		if tb.length() > 1e-6:
			back = tb.normalized()
	return prev + back * left


## A mouse, for a snake to eat (life size: its body ~8 cm; size: a share,
## a young snake's smaller meal): grey brown, its head, ears, tail; its
## origin on the ground under it.
static func mouse(sz := 1.0) -> Node3D:
	var root := Node3D.new()
	var fur := _plain(Color(0.45, 0.38, 0.3), 0.9)
	var pink := _plain(Color(0.75, 0.55, 0.5), 0.6)
	for p in [[Vector3(0.0, 0.017, 0.0), Vector3(0.034, 0.03, 0.075), fur], [Vector3(0.0, 0.02, -0.045), Vector3(0.022, 0.022, 0.032), fur],
			[Vector3(0.009, 0.034, -0.038), Vector3(0.012, 0.014, 0.004), pink], [Vector3(-0.009, 0.034, -0.038), Vector3(0.012, 0.014, 0.004), pink],
			[Vector3(0.0, 0.006, 0.075), Vector3(0.004, 0.004, 0.07), pink]]:
		var mi := MeshInstance3D.new()
		mi.mesh = _sphere()
		mi.position = (p[0] as Vector3) * sz
		mi.scale = (p[1] as Vector3) * sz
		mi.material_override = p[2]
		root.add_child(mi)
	return root


## A milk snake's egg (leathery, white, long: ~3.5 cm) or a young
## rattlesnake's birth sac (a clear membrane, the young coiled inside it).
## hatch(): the egg slit at one end, the young's head out (tasting the air
## a while), then out and away; the sac torn at once, the young out.
class Egg extends Node3D:
	var kind := "egg" # or "sac"
	var mother: Node3D
	var young: Node3D
	var _shell: MeshInstance3D
	var _slit: MeshInstance3D
	var _t := -1.0

	func _ready() -> void:
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 14
		s.rings = 8
		_shell = MeshInstance3D.new()
		_shell.mesh = s
		var m := StandardMaterial3D.new()
		if kind == "sac":
			m.albedo_color = Color(0.85, 0.8, 0.75, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.15
			_shell.scale = Vector3(0.06, 0.04, 0.06)
			_shell.position.y = 0.02
		else:
			m.albedo_color = Color(0.93, 0.91, 0.84)
			m.roughness = 0.85
			_shell.scale = Vector3(0.018, 0.017, 0.036)
			_shell.position.y = 0.0085
		_shell.material_override = m
		add_child(_shell)
		_slit = MeshInstance3D.new()
		_slit.mesh = s
		_slit.scale = Vector3(0.008, 0.0015, 0.012)
		_slit.position = Vector3(0.0, 0.016, -0.012)
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.1, 0.08, 0.06)
		dark.roughness = 0.8
		_slit.material_override = dark
		_slit.visible = false
		add_child(_slit)
		if kind == "sac": # (the young inside it already, coiled)
			_young_in()

	func _young_in() -> void:
		if mother == null:
			return
		var mk: String = mother.get("kind")
		var y: Node3D = (mother.get_script() as Script).new(mk, true) # (its mother's kind: the snake script, not named here)
		get_parent().add_child.call_deferred(y)
		young = y
		var out := (global_transform.basis * Vector3.FORWARD).normalized()
		var r := 0.022 if kind == "sac" else 0.008
		y.call_deferred("curled_in", position + Vector3.UP * 0.004, r, out)

	## Hatching: see the class.
	func hatch() -> void:
		if _t >= 0.0:
			return
		_t = 0.0
		if young == null:
			_young_in()

	func _process(dt: float) -> void:
		if _t < 0.0:
			return
		_t += dt
		if kind == "egg":
			_slit.visible = _t > 0.8
			_shell.rotation.z = sin(_t * 9.0) * 0.06 * clampf(1.0 - _t / 1.5, 0.0, 1.0)
			# (the egg collapsing a little once it's empty)
			if _t > 8.0:
				_shell.scale.y = lerpf(_shell.scale.y, 0.01, 1.0 - exp(-dt * 0.5))
		else:
			if _t > 0.5: # (the membrane, torn, shrivelling)
				_shell.scale = _shell.scale.lerp(Vector3(0.03, 0.006, 0.03), 1.0 - exp(-dt * 0.6))
		if young and is_instance_valid(young) and young.get("_mode") == "peek":
			young.set("_peek", 3.0 if _t < 0.9 else float(young.get("_peek")))
