class_name Larva
extends Node3D
## The larvae of every creature so far, drawn at twice life size: the body
## one smooth skin (a tube, built once a kind, bent along its spine by
## larva.gdshader, its creases between segments shallow) and a head
## capsule; the spine's points worked out every frame on the CPU (cheap: a
## dozen points, a frame each for what rides on it: legs, filaments, horn).
## A crawler's body bends at most `bend` a joint (rad). Each kind (KINDS):
## - monarch: the caterpillar, banded white, black and yellow, two pairs of
##   black filaments (front and back) waving; true legs and prolegs
## - hemaris: the clearwing's hornworm, green, a pale line along each side,
##   pale slanting stripes, a horn at its tail
## - lady: the lady beetle's larva ("alligator"), blackish, bumpy, tapering,
##   orange patches on its sides, six legs, quick
## - june: a June bug's white grub, C-curled on its side, a brown head, six
##   small legs, its rear end dark (the soil it's eaten, showing through)
## - wasp: a paper wasp's grub, white, fat, legless, curled
## - carpenter, harvester: an ant's, white, crook-necked, pear-shaped
## Crawlers (the caterpillars, the lady beetle larva) wander about a place
## on a level surface (wander(centre, radius)), the caterpillars' bodies
## rippling as they go (waves of their prolegs, tail to head), or stop and
## eat (eat(): the head working side to side); the grubs lie curled where
## they're put (place), slowly curling and uncurling, wriggling.
## Larva.new(kind, size): size its share of its full size (a hatchling's
## small: grow(to, secs) to grow it). Put it under a node that isn't moved
## (it's drawn in its parent's space: its own transform stays identity).

const MM := 0.002 ## m drawn per mm (twice life size)
## kind: style ("crawl" or "curl"), segments, length and width (mm, life
## size), the width along it (head .. tail: keys), pattern and colours
## (larva.gdshader's), the head's colour, speed (m/s drawn), extras
const KINDS := {
	"monarch": {"style": "crawl", "n": 12, "len": 42.0, "w": 6.5, "shape": [0.75, 1.0, 1.0, 1.0, 0.95, 0.7],
			"pattern": 1, "base": Color(0.95, 0.94, 0.9), "band_a": Color(0.03, 0.03, 0.03), "band_b": Color(0.96, 0.8, 0.08),
			"head": Color(0.9, 0.88, 0.8), "head_band": true, "speed": 0.012, "filaments": true, "legs": "caterpillar", "crease": 0.07, "bend": 0.12},
	"hemaris": {"style": "crawl", "n": 12, "len": 46.0, "w": 7.5, "shape": [0.7, 1.0, 1.05, 1.05, 1.0, 0.75],
			"pattern": 2, "base": Color(0.42, 0.6, 0.2), "line": Color(0.85, 0.85, 0.5),
			"head": Color(0.45, 0.62, 0.25), "speed": 0.012, "horn": true, "legs": "caterpillar", "crease": 0.06, "bend": 0.12},
	"lady": {"style": "crawl", "n": 10, "len": 10.0, "w": 2.6, "shape": [0.8, 1.0, 0.95, 0.75, 0.5, 0.3],
			"pattern": 3, "base": Color(0.16, 0.16, 0.18), "band_b": Color(0.95, 0.45, 0.08), "spots": [3, 6],
			"head": Color(0.05, 0.05, 0.06), "speed": 0.02, "legs": "six", "gloss": 0.3, "crease": 0.1, "bend": 0.22, "tubercles": true},
	"june": {"style": "curl", "n": 11, "len": 35.0, "w": 9.0, "shape": [0.75, 0.85, 0.9, 0.95, 1.05, 1.2],
			"pattern": 4, "base": Color(0.93, 0.9, 0.82), "dark_tail": Color(0.42, 0.38, 0.32),
			"head": Color(0.62, 0.38, 0.15), "curl": 3.6, "legs": "grub", "crease": 0.12, "mandibles": true},
	"wasp": {"style": "curl", "n": 9, "len": 15.0, "w": 5.5, "shape": [0.65, 0.9, 1.0, 1.0, 0.95, 0.7],
			"pattern": 4, "base": Color(0.95, 0.93, 0.86), "head": Color(0.75, 0.62, 0.4), "curl": 2.4, "crease": 0.08},
	"carpenter": {"style": "curl", "n": 8, "len": 8.0, "w": 3.6, "shape": [0.4, 0.55, 0.85, 1.0, 1.0, 0.85],
			"pattern": 4, "base": Color(0.96, 0.95, 0.9), "head": Color(0.92, 0.88, 0.78), "curl": 1.8, "neck": true, "crease": 0.03},
	"harvester": {"style": "curl", "n": 8, "len": 5.0, "w": 2.3, "shape": [0.4, 0.55, 0.85, 1.0, 1.0, 0.85],
			"pattern": 4, "base": Color(0.96, 0.95, 0.9), "head": Color(0.92, 0.88, 0.78), "curl": 1.8, "neck": true, "crease": 0.03},
}

var kind := "monarch"
var K: Dictionary
var rng := RandomNumberGenerator.new()
var _holders: Array[Node3D] = [] # each segment's frame (unscaled: its extras ride on it)
var _skin: MeshInstance3D # the body
var _skin_mat: ShaderMaterial # (its own: its spine's set on it every frame)
var _head: Node3D
var _seg := 0.0 # m: a segment's length (full grown)
var _g := 1.0 # its size now, a share of full grown
var _g_to := 1.0
var _g_rate := 0.0
var _widths: Array[float] = []
var _pos := Vector3.ZERO # the head's front
var _dir := Vector3.FORWARD # the way the head goes
var _trail: Array[Vector3] = [] # where the head's been (newest first)
var _mode := "rest"
var _centre := Vector3.ZERO
var _radius := 0.1
var _target := Vector3.ZERO
var _wait := 0.0
var _t := 0.0
var _legs: Array[Node3D] = []
var _whips: Array[Node3D] = []

static var _sphere: SphereMesh
static var _stick: CylinderMesh
static var _cone: CylinderMesh
static var _mats := {}
static var _tubes := {} # kind: its body's tube


func _init(k := "monarch", size := 1.0) -> void:
	kind = k
	_g = size
	_g_to = size
	K = KINDS[k]
	rng.randomize()


func _ready() -> void:
	_build()
	if K.style == "crawl" and _mode == "rest":
		_mode = "wander"
		_centre = _pos
		_radius = 0.05


## Puts it at `at` (its head's front), facing `facing` (level).
func place(at: Vector3, facing := Vector3.FORWARD) -> void:
	_pos = at
	_dir = Vector3(facing.x, 0.0, facing.z).normalized()
	if _dir == Vector3.ZERO:
		_dir = Vector3.FORWARD
	_trail.clear()
	_target = at


## Crawling about round centre (within radius), on the level surface there
## (a crawler's).
func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	if _trail.is_empty():
		_pos = centre
		_target = centre


## Growing to `to` (a share of full grown) over secs.
func grow(to: float, secs: float) -> void:
	_g_to = to
	_g_rate = absf(to - _g) / maxf(secs, 0.01)


## Stopping where it is, eating: the head working side to side.
func eat() -> void:
	_mode = "eat"


# --- the body ------------------------------------------------------------------

func _build() -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 14
		_sphere.rings = 8
		_stick = CylinderMesh.new()
		_stick.top_radius = 0.5
		_stick.bottom_radius = 0.5
		_stick.height = 1.0
		_stick.radial_segments = 5
		_stick.rings = 1
		_cone = CylinderMesh.new()
		_cone.top_radius = 0.0
		_cone.bottom_radius = 0.5
		_cone.height = 1.0
		_cone.radial_segments = 6
		_cone.rings = 1
	var n: int = K.n
	_seg = float(K.len) / n * MM
	var w: float = K.w * MM * 0.5
	var shape: Array = K.shape
	for i in n:
		# the width along it: the keys eased between
		var t := float(i) / maxf(n - 1, 1) * (shape.size() - 1)
		var j := mini(int(t), shape.size() - 2)
		var f := t - j
		_widths.append(w * lerpf(shape[j], shape[j + 1], f * f * (3.0 - 2.0 * f)))
		var h := Node3D.new()
		add_child(h)
		_holders.append(h)
	# the body: one skin over the spine
	if not _tubes.has(kind):
		_tubes[kind] = _tube()
	_skin = MeshInstance3D.new()
	_skin.mesh = _tubes[kind]
	_skin_mat = _mat("body").duplicate() as ShaderMaterial
	_skin_mat.set_shader_parameter("skinned", true)
	_skin_mat.set_shader_parameter("count", n)
	var mask := 0
	for i: int in K.get("spots", []):
		mask |= 1 << i
	_skin_mat.set_shader_parameter("spot_mask", mask)
	if K.has("dark_tail"):
		_skin_mat.set_shader_parameter("tail_from", n - 2)
		_skin_mat.set_shader_parameter("tail", K.dark_tail)
	_skin.material_override = _skin_mat
	_skin.custom_aabb = AABB(Vector3(-100.0, -100.0, -100.0), Vector3(200.0, 200.0, 200.0)) # (it's placed by its shader)
	add_child(_skin)
	# the head capsule, ahead of the first segment
	_head = Node3D.new()
	_holders[0].add_child(_head)
	var hw := _widths[0] * 0.9
	var hm := MeshInstance3D.new()
	hm.mesh = _sphere
	hm.scale = Vector3(hw * 2.0, hw * 1.9, hw * 1.7)
	hm.position = Vector3(0.0, -hw * 0.1, -_seg * 0.55 - hw * 0.5)
	hm.material_override = _mat("head")
	_head.add_child(hm)
	if K.get("head_band", false): # (a monarch caterpillar's face striped black)
		for k in 2:
			var b := MeshInstance3D.new()
			b.mesh = _sphere
			b.scale = Vector3(hw * 2.05, hw * 1.95, hw * 0.35)
			b.position = hm.position + Vector3(0.0, 0.0, (-0.2 + 0.45 * k) * hw)
			b.material_override = _flat(Color(0.03, 0.03, 0.03), 0.4)
			_head.add_child(b)
	var dark := _flat(Color(0.05, 0.05, 0.05), 0.4)
	if K.get("mandibles", false): # (a grub's dark jaws)
		for side: float in [-1.0, 1.0]:
			var mj := MeshInstance3D.new()
			mj.mesh = _sphere
			mj.scale = Vector3(hw * 0.45, hw * 0.4, hw * 0.6)
			mj.position = hm.position + Vector3(hw * 0.3 * side, -hw * 0.35, -hw * 0.75)
			mj.material_override = _flat(Color(0.18, 0.1, 0.05), 0.3)
			_head.add_child(mj)
	if K.get("tubercles", false): # (a lady beetle larva's: a pair of spiny bumps on each segment's back)
		for i in range(1, n - 1):
			for side: float in [-1.0, 1.0]:
				var tb := MeshInstance3D.new()
				tb.mesh = _cone
				var tw := _widths[i]
				tb.scale = Vector3(tw * 0.3, tw * 0.45, tw * 0.3)
				tb.position = Vector3(tw * 0.5 * side, tw * 0.95, 0.0)
				tb.rotation = Vector3(0.0, 0.0, -0.4 * side)
				tb.material_override = dark
				_holders[i].add_child(tb)
	# the monarch caterpillar's filaments: a pair behind its head, a pair
	# near its tail, black, long and supple
	if K.get("filaments", false):
		for at in [1, n - 2]:
			for side: float in [-1.0, 1.0]:
				var root := Node3D.new()
				root.position = Vector3(_widths[at] * 0.55 * side, _widths[at] * 0.7, 0.0)
				_holders[at].add_child(root)
				var length := (8.0 if at == 1 else 4.5) * MM
				var prev := root
				for k in 3:
					var seg := Node3D.new()
					seg.position = Vector3.ZERO if k == 0 else Vector3(0.0, length / 3.0, 0.0)
					prev.add_child(seg)
					var s := MeshInstance3D.new()
					s.mesh = _stick
					s.scale = Vector3(0.35 * MM, length / 3.0, 0.35 * MM)
					s.position = Vector3(0.0, length / 6.0, 0.0)
					s.material_override = dark
					seg.add_child(s)
					seg.rotation = Vector3(-0.5 if at == 1 else 0.6, 0.0, 0.35 * side) if k == 0 else Vector3(-0.25 if at == 1 else 0.25, 0.0, 0.0)
					seg.set_meta("rest", seg.rotation)
					_whips.append(seg)
					prev = seg
	# the hornworm's horn, at its tail, curving up and back
	if K.get("horn", false):
		var hn := MeshInstance3D.new()
		hn.mesh = _cone
		var tw := _widths[n - 1]
		hn.scale = Vector3(tw * 0.5, 4.0 * MM, tw * 0.5)
		hn.position = Vector3(0.0, tw * 0.9 + 2.0 * MM, 0.0)
		hn.rotation = Vector3(0.7, 0.0, 0.0)
		hn.material_override = _flat(Color(0.35, 0.3, 0.12), 0.5)
		_holders[n - 1].add_child(hn)
	# legs
	match K.get("legs", ""):
		"caterpillar": # (three pairs of true legs behind the head, dark; four pairs of prolegs mid-body and a pair at the tail)
			for i in n:
				var true_leg := i >= 1 and i <= 3
				if not (true_leg or (i >= 6 and i <= 9) or i == n - 1):
					continue
				for side: float in [-1.0, 1.0]:
					var l := MeshInstance3D.new()
					l.mesh = _sphere
					var lw := _widths[i]
					l.scale = Vector3(lw * 0.45, lw * 0.6, lw * 0.5) if not true_leg else Vector3(lw * 0.25, lw * 0.5, lw * 0.25)
					l.position = Vector3(lw * 0.55 * side, -lw * 0.85, 0.0)
					l.material_override = dark if true_leg else _mat("body")
					_holders[i].add_child(l)
		"six", "grub": # (three pairs on the thorax; the lady beetle larva's long, a grub's short)
			var long: bool = K.legs == "six"
			for i in [1, 2, 3]:
				for side: float in [-1.0, 1.0]:
					var hip := Node3D.new()
					var lw := _widths[i]
					hip.position = Vector3(lw * 0.7 * side, -lw * 0.4, 0.0)
					_holders[i].add_child(hip)
					var length := lw * (2.6 if long else 1.1)
					var l := MeshInstance3D.new()
					l.mesh = _stick
					l.scale = Vector3(lw * 0.18, length, lw * 0.18)
					l.position = Vector3(length * 0.45 * side, -length * 0.2, 0.0)
					l.rotation = Vector3(0.0, 0.0, -1.2 * side)
					l.material_override = dark if long else _flat(Color(0.6, 0.42, 0.2), 0.4)
					hip.add_child(l)
					hip.set_meta("side", side)
					hip.set_meta("pair", i)
					_legs.append(hip)
	_place_spine()


## The body's tube, full grown (m): rings along the spine (its segments'
## centres at whole numbers along VERTEX.z, from -0.5 at the head to n -
## 0.5 at the tail, rounded shut at both), a little narrower at each
## segment's joints (crease); round each, an ellipse (a caterpillar's belly
## flatter). VERTEX.xy, NORMAL in the body's frame; CUSTOM0: where on its
## segment, and which.
func _tube() -> ArrayMesh:
	var n := _widths.size()
	const PER := 6 # rings a segment
	const ROUND := 14
	var crease: float = K.get("crease", 0.06)
	var flat_belly: bool = K.get("legs", "") == "caterpillar"
	var radius := func(s: float) -> float:
		var c := clampf(s, 0.0, n - 1.0)
		var i := mini(int(c), n - 2) if n > 1 else 0
		var f := c - i
		var w := lerpf(_widths[i], _widths[mini(i + 1, n - 1)], f) if n > 1 else _widths[0]
		# rounded shut at the ends
		var e := minf(s + 0.5, n - 0.5 - s) / 0.5
		if e < 1.0:
			w *= sqrt(maxf(1.0 - (1.0 - e) * (1.0 - e), 0.0))
		# the creases at the joints
		var j := absf(fposmod(s, 1.0) - 0.5)
		return w * (1.0 - crease * exp(-pow(j / 0.12, 2.0)))
	var rings := n * PER + 1
	var grid := [] # each ring: [s, r, dr/ds]
	for k in rings:
		var sv := -0.5 + float(k) / PER
		var r: float = radius.call(sv)
		var dr: float = (float(radius.call(sv + 0.02)) - float(radius.call(sv - 0.02))) / 0.04
		grid.append([sv, r, dr])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var vert := func(k: int, a_i: int) -> Array:
		var g: Array = grid[k]
		var sv: float = g[0]
		var r: float = g[1]
		var a := TAU * float(a_i % ROUND) / ROUND
		var hy := 0.92 * (0.8 if flat_belly and sin(a) < 0.0 else 1.0)
		var x := cos(a) * r
		var y := sin(a) * r * hy
		# (outward round the ellipse; tipped forward where it widens back)
		var nrm := Vector3(cos(a) * hy, sin(a), -float(g[2]) / maxf(_seg, 1e-6)).normalized()
		var near := floorf(sv + 0.5)
		return [Vector3(x, y, sv), nrm, Color(0.5 * cos(a), 0.5 * sin(a), sv - near, clampf(near, 0.0, n - 1.0))]
	var put := func(v: Array) -> void:
		st.set_normal(v[1])
		st.set_custom(0, v[3])
		st.add_vertex(v[0])
	for k in rings - 1:
		for a_i in ROUND:
			var q := [vert.call(k, a_i), vert.call(k + 1, a_i), vert.call(k + 1, a_i + 1), vert.call(k, a_i + 1)]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var A: Array = q[tri[0]]
				var B: Array = q[tri[1]]
				var C: Array = q[tri[2]]
				# (the straight body: along z, s a segment long; a front face
				# clockwise, its normal along -cross(b - a, c - a))
				var pa := Vector3(A[0].x, A[0].y, A[0].z * _seg)
				var pb := Vector3(B[0].x, B[0].y, B[0].z * _seg)
				var pc := Vector3(C[0].x, C[0].y, C[0].z * _seg)
				var face := -(pb - pa).cross(pc - pa)
				var out := Vector3(pa.x + pb.x + pc.x, pa.y + pb.y + pc.y, 0.0)
				if face.dot(out) >= 0.0:
					put.call(A)
					put.call(B)
					put.call(C)
				else:
					put.call(A)
					put.call(C)
					put.call(B)
	return st.commit()


func _mat(which: String) -> ShaderMaterial:
	var key := kind + ":" + which
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/larva.gdshader")
	m.set_shader_parameter("pattern", 0 if which == "head" else int(K.pattern))
	m.set_shader_parameter("base", K.head if which == "head" else (K.dark_tail if which == "tail" else K.base))
	for p in ["line", "band_a", "band_b", "gloss"]:
		if K.has(p):
			m.set_shader_parameter(p, K[p])
	m.set_shader_parameter("spot", which == "spot")
	if which == "head":
		m.set_shader_parameter("line", K.head)
		m.set_shader_parameter("gloss", 0.7)
	_mats[key] = m
	return m


static func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var key := "flat:" + c.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	_mats[key] = m
	return m


# --- moving --------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or _holders.is_empty():
		return
	_t += dt
	_g = move_toward(_g, _g_to, _g_rate * dt)
	if K.style == "crawl":
		_crawl(dt)
	_place_spine()
	# the filaments waving, the legs stepping
	for k in _whips.size():
		var wv := _whips[k]
		var r0: Vector3 = wv.get_meta("rest")
		wv.rotation = r0 + Vector3(0.12 * sin(_t * 1.7 + k * 0.9), 0.0, 0.18 * sin(_t * 2.3 + k * 1.3))
	var going := 1.0 if _mode == "wander" and _pos.distance_to(_target) > 0.004 else 0.0
	for l in _legs:
		var side: float = l.get_meta("side")
		var pair: int = l.get_meta("pair")
		var ph := _t * 9.0 + (PI if (pair + (1 if side > 0.0 else 0)) % 2 == 0 else 0.0)
		l.rotation = Vector3(0.0, 0.45 * sin(ph) * going * side, 0.0)


func _crawl(dt: float) -> void:
	var speed: float = K.speed
	if _mode == "wander":
		_wait -= dt
		if _wait <= 0.0 or _pos.distance_to(_target) < 0.004:
			var a := rng.randf() * TAU
			_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
			_wait = rng.randf_range(3.0, 8.0)
		var to := _target - _pos
		to.y = 0.0
		if to.length() > 0.004:
			var want := to.normalized()
			var turn := _dir.signed_angle_to(want, Vector3.UP)
			_dir = _dir.rotated(Vector3.UP, clampf(turn, -0.8 * dt, 0.8 * dt))
			# a caterpillar goes in surges, a wave of its prolegs at a time
			var surge := 1.0
			if K.get("legs", "") == "caterpillar":
				surge = 0.3 + 1.4 * maxf(sin(_t * TAU * 0.7), 0.0)
			_pos += _dir * speed * lerpf(0.25, 1.0, _g) * surge * dt
			_pos.y = _centre.y
	# the trail: where the head's been, for the body to follow
	if _trail.is_empty() or _trail[0].distance_to(_pos) > _seg * _g * 0.25:
		_trail.push_front(_pos)
		var keep := int(K.n) * 5 + 8
		if _trail.size() > keep:
			_trail.resize(keep)


## Each segment's centre and frame along the spine: a crawler's along the
## head's trail (lifted by its wave), bending at most `bend` a joint; a
## grub's round its C, lying on its side (its back out, its legs in); the
## skin bent along them (its shader), what rides on them placed.
func _place_spine() -> void:
	var n := _holders.size()
	var sg := _seg * _g
	var pts: Array[Vector3] = []
	var ups: Array[Vector3] = []
	if K.style == "crawl":
		for i in n:
			var p := _along_trail((i + 0.5) * sg)
			var lift := 0.0
			if K.get("legs", "") == "caterpillar": # (the wave, tail to head)
				lift = maxf(sin(_t * TAU * 0.7 * 2.0 + float(i) * 0.7), 0.0) * _widths[i] * _g * 0.35
			pts.append(p + Vector3.UP * (_widths[i] * _g * 0.95 + lift))
			ups.append(Vector3.UP)
		if _mode == "eat": # (the head working side to side, nibbling)
			pts[0] += (_dir.cross(Vector3.UP) * sin(_t * 3.0) * _widths[0] * 0.8 + Vector3.DOWN * _widths[0] * 0.3 * (0.5 + 0.5 * sin(_t * 6.0))) * _g
		# no joint bent more than `bend`: each segment laid on from the one
		# ahead, its way turned no further than that from the one ahead's
		var most: float = K.get("bend", 0.2)
		var ahead := _dir
		for i in range(1, n):
			var d := pts[i - 1] - pts[i]
			d.y = 0.0
			var dn := d.normalized() if d.length() > 1e-7 else ahead
			var ang := ahead.signed_angle_to(dn, Vector3.UP)
			if absf(ang) > most:
				dn = ahead.rotated(Vector3.UP, signf(ang) * most)
			var y := pts[i].y
			pts[i] = pts[i - 1] - dn * sg
			pts[i].y = y
			ahead = dn
	else:
		# a C, on its side: an arc in the level plane, curling and
		# uncurling slowly; an ant's larva, its neck crooked
		var curl: float = K.curl * (1.0 + 0.12 * sin(_t * 1.1)) + 0.15 * sin(_t * 3.7) * (0.5 + 0.5 * sin(_t * 0.5))
		var p := _pos
		var d := _dir
		for i in n:
			var k := curl / n
			if K.get("neck", false):
				k = curl / n * (2.2 if i < 3 else 0.5)
			pts.append(p + Vector3.UP * _widths[i] * _g * 0.9)
			d = d.rotated(Vector3.UP, -k)
			p -= d * sg
		# lying on its side: its back out from the C's middle, its belly
		# (and legs) in
		var mid := Vector3.ZERO
		for q in pts:
			mid += q
		mid /= n
		for i in n:
			var out := pts[i] - mid
			out.y = 0.0
			ups.append(out.normalized() if out.length() > 1e-6 else _dir.cross(Vector3.UP))
	var sp := PackedVector3Array()
	var sx := PackedVector3Array()
	var sy := PackedVector3Array()
	for i in n:
		var p: Vector3 = pts[i]
		var fwd: Vector3
		if i == 0:
			fwd = (pts[0] - pts[1]).normalized() if n > 1 else _dir
		else:
			fwd = (pts[i - 1] - p).normalized()
		if fwd.length_squared() < 1e-6:
			fwd = _dir
		var up := ups[i]
		if absf(fwd.dot(up)) > 0.98:
			up = Vector3.UP if absf(fwd.y) < 0.9 else Vector3.RIGHT
		var b := Basis.looking_at(fwd, up)
		_holders[i].transform = Transform3D(b * Basis.from_scale(Vector3.ONE * _g), p) # (what rides on it in full-grown size, scaled to its size now)
		sp.append(p)
		sx.append(b.x)
		sy.append(b.y)
	if _skin_mat:
		_skin_mat.set_shader_parameter("sp", sp)
		_skin_mat.set_shader_parameter("sx", sx)
		_skin_mat.set_shader_parameter("sy", sy)
		_skin_mat.set_shader_parameter("size", _g)


## The point d (m) back along the head's trail (straight back past its end).
func _along_trail(d: float) -> Vector3:
	var prev := _pos
	var left := d
	for q in _trail:
		var l := prev.distance_to(q)
		if l >= left and l > 1e-6:
			return prev.lerp(q, left / l)
		left -= l
		prev = q
	var back := -_dir
	if _trail.size() >= 2:
		back = (_trail[_trail.size() - 1] - _trail[_trail.size() - 2]).normalized()
		if back.length_squared() < 1e-6:
			back = -_dir
	return prev + back * left
