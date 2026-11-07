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
## - mate(partner): he (male set: no different to see) finds her trail
##   and comes up behind her, then crawls up along her back from her tail
##   to her neck, lying over her, rubbing his chin along her and jerking,
##   his tongue going; his tail finds hers and they're twisted together,
##   and the pair lie still, joined, a long while; then his tail unwinds
##   and he's off. She lies still through it
## Steering (a state machine's: pilot.gd): go, go_to, face, stop, act
## (eat {prey}, coil {seconds}, lay {n}, mate {partner}), behaviours, is_busy,
## action_finished; height (the ground under every point of it).
## Put it under a node that isn't moved: its own transform stays identity.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const PersonalSpace := preload("res://scripts/creatures/personal_space.gd")

const SPINE := 40
const MIN_BEND := 2.5 ## its tightest curve's radius, in its thickness (its radius)...
const MIN_BEND_L := 0.06 ## ... or in its length, whichever's more
const KINDS := {
	"rattler": {"len": 1.4, "r": 0.042, "head": Vector3(0.066, 0.03, 0.078), "speed": 0.14, "young": 0.26, "rattle": 9, "egg": "sac"},
	"milk": {"len": 0.85, "r": 0.014, "head": Vector3(0.022, 0.013, 0.03), "speed": 0.2, "young": 0.3, "rattle": 0, "egg": "egg"},
}

var kind := "rattler"
var K: Dictionary
var young := false
var size := 1.0
var ground_y := 0.0
var height: Callable ## (x, z) -> the ground's y (none: level, at ground_y)
var _pilot: PilotScript
var _pace := -1.0
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
var _swallow_from := Vector3.ZERO # (its head, swallowing: from, to, over its prey)
var _swallow_to := Vector3.ZERO
var _meal: Node3D # (its prey, swallowed whole: Meal, each part gone as the jaws come over it)
const MealScript := preload("res://scripts/creatures/meal.gd")
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
# mating
var male := false
var mate_secs := 40.0 ## s joined
var _mate: Node3D
var _mate_role := ""
var _mate_stage := 0 # his: 0 to her tail, 1 up along her back, 2 joined, 3 unwinding
var _mate_i := 0 # (the point of hers he's making for)
var _twine := 0.0 # 0..1 his tail round hers
var _wave := 0.55 # rad: how wide its waves swing
var _was_mode := "wander"

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
	_meal = null
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
	if _pilot:
		_pilot.tick(dt)
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
		"piloted": # (going where it's sent)
			_coil_k = move_toward(_coil_k, 0.0, dt * 0.8)
			go = _pos.distance_to(_target) > 0.02 * size
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
		"mate":
			go = _mate_think(dt)
	# moving: the head on toward its target, its way swinging in waves
	var want := (_pace if _pace > 0.0 else float(K.speed) * lerpf(0.5, 1.0, size)) if go else 0.0
	_speed = move_toward(_speed, want, dt * 0.5)
	if _speed > 0.0005:
		var to := _target - _pos
		to.y = 0.0
		if to.length() > 0.001:
			var turn := _dir.signed_angle_to(to.normalized(), Vector3.UP)
			_dir = _dir.rotated(Vector3.UP, clampf(turn, -1.0 * dt, 1.0 * dt))
		var wl := float(K.len) * size * 0.45 # (a wave's length along its path)
		_phase += _speed * dt / wl * TAU
		var way := _dir.rotated(Vector3.UP, _wave * sin(_phase))
		# never through its own body: steering away from any of it ahead,
		# slowing for it; its head kept clear of it whatever (the body
		# follows the head's path: if the head never crosses it, nor does
		# the body)
		var clear := float(K.r) * size * 2.4
		var steer := 0.0
		var slow := 1.0
		var ahead := _pos + way * clear * 1.8
		var bodies: Array = [[_pts, 6, clear]] # (its own body; and the other snakes' near it: their heads go round its body, its round theirs, so their bodies, following, never cross)
		for o in PersonalSpace.all:
			if o != self and is_instance_valid(o) and o.get_script() != null and o.has_method("_space_spines") and o.get("_pts") is Array and not PersonalSpace.touching(o):
				var op: Array = o.get("_pts")
				if not op.is_empty() and (op[op.size() / 2] as Vector3).distance_to(_pos) < float(o.get("K").len) * float(o.get("size")) + clear * 3.0:
					bodies.append([op, 0, clear * 0.5 + float(o.get("K").r) * float(o.get("size")) * 1.2])
		for bd: Array in bodies:
			var pts: Array = bd[0]
			var cl: float = bd[2]
			for i in range(int(bd[1]), pts.size()):
				var q: Vector3 = pts[i]
				var d := Vector2(ahead.x - q.x, ahead.z - q.z).length()
				if d < cl * 1.8:
					var side := signf(_dir.cross(q - _pos).y) # (+: it's to the left)
					var k := 1.0 - d / (cl * 1.8)
					steer -= (side if side != 0.0 else 1.0) * k
					slow = minf(slow, lerpf(1.0, 0.35, k))
		if steer != 0.0:
			_dir = _dir.rotated(Vector3.UP, clampf(steer * 3.0 * dt, -2.5 * dt, 2.5 * dt))
			way = _dir.rotated(Vector3.UP, 0.3 * sin(_phase))
		_pos += way * _speed * slow * dt
	# (kept off the others moving or not: its head eased off them; its body,
	# which can't be shifted, they keep off: PersonalSpace)
	PersonalSpace.keep_apart(self)
	ground_y = _ground(_pos.x, _pos.z)
	_pos.y = ground_y
	if _speed > 0.0005:
		_keep_clear(float(K.r) * size * 2.4)
	if _trail.is_empty() or _trail[0].distance_to(_pos) > float(K.len) * size / SPINE / 3.0:
		_trail.push_front(_pos)
		while _trail.size() > SPINE * 4 + 20:
			_trail.pop_back()


## The ground's height at (x, z): height's, or level; a male mating, over
## her body where it's under him.
func _ground(x: float, z: float) -> float:
	var g := float(height.call(x, z)) if height.is_valid() else ground_y
	if _mate_role == "male" and _mate_stage >= 1 and is_instance_valid(_mate):
		var hp: Array[Vector3] = _mate.get("_pts")
		var hr := float(_mate.get("K").r) * float(_mate.get("size"))
		var best := INF
		var top := g
		for q in hp:
			var d := Vector2(x - q.x, z - q.z).length()
			if d < best:
				best = d
				top = q.y
		if best < hr * 1.6:
			var k := 1.0 - best / (hr * 1.6)
			g = maxf(g, lerpf(g, top + hr * 0.75, sqrt(k)))
	return g


# --- mating ------------------------------------------------------------------------

## Mating with partner (a snake of its kind, the other sex; neither young
## or mating): see the class. False if they can't.
func mate(partner: Node3D, secs := -1.0) -> bool:
	if partner == null or partner == self or not partner.has_method("_mate_begin") or young or bool(partner.get("young")):
		return false
	if bool(partner.get("male")) == male or partner.get("kind") != kind or _mate_role != "" or partner.get("_mate_role") != "":
		return false
	var him: Node3D = self if male else partner
	var her: Node3D = partner if male else self
	var t := secs if secs > 0.0 else mate_secs
	him.call("_mate_begin", her, "male", t)
	her.call("_mate_begin", him, "female", t)
	return true


func is_mating() -> bool:
	return _mate_role != ""


func _mate_begin(partner: Node3D, role: String, secs: float) -> void:
	_was_mode = _mode if _mode in ["wander", "coil"] else "wander"
	_mate = partner
	_mate_role = role
	_mate_stage = 0
	mate_secs = secs
	_st = 0.0
	_mode = "mate"
	_target = _pos


func _mate_end() -> void:
	var m := _mate
	_mate = null
	_mate_role = ""
	_wave = 0.55
	_twine = 0.0
	_strike_k = 0.0
	if _was_mode == "coil":
		coil()
	else:
		wander(_pos, 0.6)
	if m != null and is_instance_valid(m) and m.get("_mate_role") != "":
		m.call("_mate_end")


## Mating: whether it's going.
func _mate_think(dt: float) -> bool:
	_coil_k = move_toward(_coil_k, 0.0, dt * 0.8)
	if _mate == null or not is_instance_valid(_mate):
		_mate_end()
		return false
	if _mate_role == "female": # (still, through it)
		_target = _pos
		return false
	var hp: Array[Vector3] = _mate.get("_pts")
	if hp.size() < SPINE:
		return false
	var hr := float(_mate.get("K").r) * float(_mate.get("size"))
	match _mate_stage:
		0: # to behind her tail
			_wave = 0.45
			var tail: Vector3 = hp[SPINE - 1]
			var back := (tail - hp[SPINE - 4])
			back.y = 0.0
			back = back.normalized() if back.length() > 1e-5 else -_dir
			_target = tail + back * hr * 4.0
			if Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < hr * 3.0 or _st > 40.0:
				_mate_stage = 1
				_mate_i = SPINE - 1
				_st = 0.0
			return true
		1: # up along her back, his chin on her, jerking, his tongue going
			_wave = 0.1
			_pace = float(K.speed) * 0.25
			var q: Vector3 = hp[_mate_i]
			_target = q
			if Vector2(_pos.x - q.x, _pos.z - q.z).length() < hr * 2.0:
				_mate_i -= 1
			if _mate_i <= 3 or _st > 60.0:
				_mate_stage = 2
				_st = 0.0
				_pace = -1.0
			return true
		2: # joined: his tail twisted round hers; still, his chin on her now and then
			_wave = 0.1
			_twine = move_toward(_twine, 1.0, dt / 4.0)
			_target = _pos
			if _st > mate_secs:
				_mate_stage = 3
				_st = 0.0
			return false
		3: # unwinding, then off
			_twine = move_toward(_twine, 0.0, dt / 3.0)
			if _twine <= 0.0:
				_mate_end()
			return false
	return false


## His tail wound round hers (as far as it's twined): his last points a
## helix round her last ones; and his chin jerking on her back, courting.
func _mate_pose() -> void:
	if _mate_role != "male" or not is_instance_valid(_mate):
		return
	var R := float(K.r) * size
	if _mate_stage == 1 or _mate_stage == 2: # (the chin pressed down on her, jerking)
		var jerk := maxf(sin(_t * 7.0), 0.0) * maxf(sin(_t * 1.3), 0.0)
		_pts[0] += Vector3.UP * R * 0.6 * jerk
		_pts[1] += Vector3.UP * R * 0.3 * jerk
	if _twine <= 0.0:
		return
	var hp: Array[Vector3] = _mate.get("_pts")
	var hr := float(_mate.get("K").r) * float(_mate.get("size"))
	const N := 10
	for k in N:
		var i := SPINE - 1 - k
		var c: Vector3 = hp[i]
		var fwd := (hp[i - 1] - hp[i]).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var up := side.cross(fwd).normalized()
		var a := k * 0.85 + 0.6
		var w := _twine * clampf(1.0 - float(k) / N, 0.0, 1.0) * 1.2 # (fully round at the tip, easing in up the tail)
		var on := c + (side * cos(a) + up * sin(a)) * (hr + R) * 0.95
		_pts[i] = _pts[i].lerp(on, clampf(w, 0.0, 1.0))


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
	return _dir


func _p_steer(point: Vector3, speed: float) -> void:
	_mode = "piloted"
	_target = point
	_pace = speed


func _p_hold() -> void:
	_mode = "hold"
	_target = _pos
	_pace = -1.0


func _p_mobile() -> bool:
	return _mode != "peek"


func _p_speed() -> float:
	return float(K.speed) * lerpf(0.5, 1.0, size)


func _p_reach() -> float:
	return float(K.r) * size * 3.0 + 0.02


## eat {prey: a Node3D, its mouse}, coil {seconds}, lay {n} (the adult's:
## the rattler's, born).
func _p_behaviours() -> PackedStringArray:
	if young:
		return PackedStringArray(["eat", "coil"])
	return PackedStringArray(["eat", "coil", "mate"]) if male else PackedStringArray(["eat", "coil", "lay", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"eat":
			var prey: Node3D = args.get("prey")
			if prey == null or not is_instance_valid(prey):
				return false
			eat(prey)
		"coil":
			coil()
		"lay":
			lay(int(args.get("n", 6)))
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"eat", "lay":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 8.0 if name == "coil" else -1.0


## The head pushed out of its own body wherever it's come within `clear`
## of it (its neck's first points left out: they're its own).
func _keep_clear(clear: float) -> void:
	for pass_ in 2:
		for i in range(6, _pts.size()):
			var q: Vector3 = _pts[i]
			var off := Vector2(_pos.x - q.x, _pos.z - q.z)
			var d := off.length()
			if d < clear:
				var out := off / d if d > 1e-5 else Vector2(_dir.z, -_dir.x)
				_pos += Vector3(out.x, 0.0, out.y) * (clear - d)


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
				MealScript.subdue(_prey) # (a live animal: struck, still)
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
		7: # swallowing: the jaws gaping, walking on over it where it lies (it not moved), head first
			var into := clampf(_st / 7.0, 0.0, 1.0)
			_gape = 0.85 - 0.15 * sin(_st * 4.0)
			if _meal == null:
				_meal = MealScript.of(_prey, 6, 0)
				if _meal:
					_meal.set("swallow", true)
				var along := Vector3(p.x - _pos.x, 0.0, p.z - _pos.z)
				along = along.normalized() if along.length() > 1e-4 else _dir
				_swallow_from = _pos
				_swallow_to = Vector3(p.x, _pos.y, p.z) + along * (float(_meal.call("span")) * 0.55 if _meal else 0.05)
			# (its head creeping on over it, its jaws walked over it, a side at a time)
			var was := _pos
			_pos = _swallow_from.lerp(_swallow_to, smoothstep(0.0, 1.0, into))
			_pos.y = _ground(_pos.x, _pos.z)
			if (_pos - was).length() > 1e-6:
				_dir = Vector3(_pos.x - was.x, 0.0, _pos.z - was.z).normalized()
			_speed = 0.0
			_target = _pos
			if _meal:
				var par := get_parent() as Node3D
				_meal.call("tear", into, par.global_transform * _pts[0] if par else _pts[0])
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
	var at := Vector3(vent.x, 0.0, vent.z) + Vector3(cos(a), 0.0, sin(a)) * float(K.r) * 1.5
	at.y = _ground(at.x, at.z)
	e.position = at
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
		_pts.append(Vector3(p.x, _ground(p.x, p.z) + R * _profile(float(i) / (SPINE - 1)) * 0.85, p.z))
	# no kinks: laid from the head back, each joint turned no more than a
	# snake's body bends (round a curve no tighter than MIN_BEND of its own
	# thickness, or MIN_BEND_L of its length): where its head's path jogs
	# (pushed, turned hard) the body curves through it, a little off the
	# path, not creased (the coil, the strike, the mating pose, after: theirs)
	var max_turn := seg / maxf(R * MIN_BEND, L * MIN_BEND_L)
	# (each joint, every frame the same way, so nothing toggles: its own
	# length (the path's, there) behind the joint before, toward its point
	# on the path (steadied by the path's own way there, so a joint just on
	# its point doesn't spin), turned no more than its body bends. Its
	# length the path's: never more, the tail never stretched out)
	var path: Array[Vector2] = []
	for q in _pts:
		path.append(Vector2(q.x, q.z))
	var prev := Vector2.ZERO
	for i in range(1, SPINE):
		var a := Vector2(_pts[i - 1].x, _pts[i - 1].z)
		var along := path[i] - path[i - 1]
		var l := along.length()
		if l < 1e-6:
			continue
		var d := (path[i] - a) + along * 0.5
		d = d.normalized() if d.length() > 1e-7 else along / l
		if prev != Vector2.ZERO:
			var turn := prev.angle_to(d)
			if absf(turn) > max_turn:
				d = prev.rotated(signf(turn) * max_turn)
		var q := a + d * l
		_pts[i] = Vector3(q.x, _ground(q.x, q.y) + R * _profile(float(i) / (SPINE - 1)) * 0.85, q.y)
		prev = d
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
			var y := _ground(c.x, c.z) + R * _profile(float(i) / (SPINE - 1)) * 0.85 + (R * 1.6 if i < raised * 2 else 0.0)
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
	_mate_pose()
	# the rattle: the tail's tip raised, buzzing
	if _rattle > 0.0:
		for i in range(SPINE - 4, SPINE):
			_pts[i] += Vector3.UP * R * 3.0 * _rattle * float(i - (SPINE - 4)) / 3.0
	# its node at its middle, its parts drawn in its own frame from there (so
	# it's one thing, there: caught, held, carried, eaten, its parts with it)
	var o: Vector3 = _pts[SPINE / 2]
	position = o
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
		sp.append(_pts[i] - o)
		sx.append(bs.x)
		sy.append(bs.y)
	_mat.set_shader_parameter("sp", sp)
	_mat.set_shader_parameter("sx", sx)
	_mat.set_shader_parameter("sy", sy)
	_mat.set_shader_parameter("size", size)
	_mat.set_shader_parameter("bulge_s", _bulge_s)
	_mat.set_shader_parameter("bulge_r", _bulge_r)
	# the head on the neck (its back at the first point), the jaw, the tongue
	_head.transform = Transform3D(frames[0] * Basis.from_scale(Vector3.ONE * size), _pts[0] - o)
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
	_tail.transform = Transform3D(tb, _pts[SPINE - 1] - o)
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


func _enter_tree() -> void:
	PersonalSpace.join(self)


func _exit_tree() -> void:
	PersonalSpace.leave(self)


## (Its personal space: its whole length, in SPACE_SEGS capsules down its
## spine from the head, as thick as it is, coiled or not; the head's the
## only one it's moved by, its body behind following the head's way: the
## others keep off that.)
const SPACE_SEGS := 5
const SPACE_PUSH := 0.8 ## of its thickness its head's put off another a frame, at most (its body bends smoothly after it, whatever: _update)


## (Its head put off another, its body following; and its way turned along
## the other, not on into it again (no shoving back and forth).)
func _space_push(v: Vector2) -> void:
	var most := float(K.r) * size * SPACE_PUSH
	var w := v.limit_length(most)
	_pos += Vector3(w.x, 0.0, w.y)
	if w.length() > 1e-6:
		var n := Vector3(w.x, 0.0, w.y).normalized()
		var into := _dir.dot(-n)
		if into > 0.0: # (heading into it: turned to slide along it)
			var along := _dir + n * into
			if along.length() > 1e-4:
				_dir = _dir.slerp(along.normalized(), 0.5).normalized()


func _space_spines() -> Array:
	if _pts.size() < SPINE:
		return [_space_spine()]
	var out: Array = []
	var step := (SPINE - 1) / float(SPACE_SEGS)
	for i in SPACE_SEGS:
		var a: Vector3 = _pts[roundi(i * step)]
		var b: Vector3 = _pts[roundi((i + 1) * step)]
		out.append([Vector2(a.x, a.z), Vector2(b.x, b.z)])
	return out


func _space_fixed(i: int) -> bool:
	return i > 0


## (One capsule, before its spine's laid out: from its head back along the
## first third of it.)
func _space_spine() -> Array:
	var h := Vector2(_pos.x, _pos.z)
	var back := h - Vector2(_dir.x, _dir.z).normalized() * float(K.len) * size * 0.3
	if _trail.size() > 4:
		var want := float(K.len) * size * 0.3
		var acc := 0.0
		for i in range(1, _trail.size()):
			acc += _trail[i].distance_to(_trail[i - 1])
			if acc >= want:
				back = Vector2(_trail[i].x, _trail[i].z)
				break
	return [back, h]


func _space_r() -> float:
	return float(K.r) * size


func _touch_ok() -> bool:
	# (coiled, it keeps its room: a coiled rattler isn't walked over; after
	# its prey or eating it, it touches only that: PersonalSpace)
	return young or _mate_role != "" or _mode in ["lay", "birth", "hatch", "mate"]
