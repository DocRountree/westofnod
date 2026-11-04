class_name Spider
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## Spiders, drawn at twice life size (the insects' scale), four kinds
## (Spider.new(kind), a spiderling Spider.new(kind, true): small, pale,
## growing):
## - "wolf": a Carolina wolf spider (Hogna carolinensis): big, hairy, dark
##   brown; hunts on the ground, running down its prey. Its egg sac carried
##   on its spinnerets; its spiderlings, hatched, ride on its back a while
## - "fishing": a six-spotted fishing spider (Dolomedes triton): flat and
##   broad, its very long legs splayed wide and flat, the knees low, the
##   body low on the water; olive brown, a cream
##   band down each side, white spots paired down the abdomen; its eyes two
##   rows of four, both curved back. Runs on water (its ground: the water's
##   surface); catching small fish (a molly) come up near the surface, a
##   rush across the water and a lunge, dragged ashore (shore) and eaten.
##   Its egg sac carried in its jaws, then set down at the
##   water's edge for the spiderlings to come out of
## - "funnel": a grass spider (Agelenopsis): a funnel weaver; spins a sheet
##   web on the ground with a funnel retreat at its side, waits at the
##   funnel's mouth, rushes out at what lands on the sheet and drags it in.
##   Its egg sac, a flat white disc, left on the ground
## - "argiope": a yellow garden spider (Argiope aurantia): black and yellow,
##   its cephalothorax silver; spins an orb web off a branch (a bridge
##   line, a frame, radii, the capture spiral round and round inward, the
##   zigzag band of white silk through its middle), sits head down at its
##   hub; prey caught in it run to, wrapped in silk, bitten, brought back
##   and eaten. Its egg sac, brown, papery, a jar, hung on threads
## Their bodies lofted (shaders/render/spider.gdshader: each its marks),
## eight legs in two alternating sets of four (hexapod.gd's gait: feet
## planted, legs reaching hip to foot, the knees high), chelicerae and
## fangs, pedipalps, eyes in their families' patterns, spinnerets.
##
## - wander(centre, radius): about, stopping, starting
## - hunt(prey): to it, a rush and a pounce, held in the chelicerae, eaten
##   (the jaws working, the palps turning it; it shrinks away)
## - lay(): an egg sac spun at its spinnerets (the abdomen working), then
##   carried (the wolf, the fishing spider) or left (the others); hatching
##   later (EggSac.hatch)
## - spin_funnel(at, radius) (the funnel weaver's): the sheet laid in sweeps
##   out from the funnel; then waiting at its mouth
## - spin_orb(top, left, right) (the garden spider's): the orb spun between
##   them (top: on a branch), thread by thread; then at the hub, head down.
##   Never through the air: it goes along the threads it's spun (the way
##   along them found, OrbWeb.route), or, where there are none yet, on a
##   dragline it pays out as it goes (OrbWeb.add_dragline); out to its prey
##   and back to the hub along them too
## - mate(her) (a male's: Spider.new(kind) with male set before it's
##   added: smaller (the garden spider's a quarter her size, tan, slender),
##   the ends of his palps swollen into their bulbs; otherwise as she is):
##   first, charged: a little sperm web spun under him, a drop of sperm
##   laid on it from under his abdomen, and he turns round and dips his
##   palps in it one and then the other, drawing it up; then to her, and
##   courts (the wolf spider waving his front legs and drumming his palps,
##   the fishing spider tapping, the grass spider plucking her sheet, the
##   garden spider her web's threads); then on: the wolf and fishing
##   spiders' up onto her front, facing back, leaning down one side and the
##   other to reach a palp under her abdomen; the grass spider's the same,
##   she gone still and lying over on her side; the garden spider's up her
##   web to her, under her at the hub; each palp put in to her in turn, its
##   bulb swelling and pulsing. The garden spider's dies there after his
##   second, and she wraps him in silk
## Steering (pilot.gd): act hunt {prey}, lay, spin {at, radius} / {top,
## left, right}, mate {partner}; go, go_to, ... on the ground (not in its
## orb).

const SPECIES := {
	"wolf": {"pattern": 0, "ceph": Vector3(12.0, 4.6, 3.6), "abd": Vector3(13.0, 5.4, 4.4), "leg": Vector3(8.5, 10.0, 10.0), "pairs": [1.0, 0.92, 0.82, 1.06],
			"femur": Color(0.3, 0.22, 0.14), "tibia": Color(0.24, 0.17, 0.11), "body_h": 5.6, "speed": 0.09, "eyes": "wolf", "leg_r": 0.8, "young": 0.16},
	# (the fishing spider: flat, broad, low on the water, its very long legs
	# splayed wide and flat, the knees low; its eyes two curved rows)
	"fishing": {"pattern": 1, "ceph": Vector3(9.0, 4.5, 2.2), "abd": Vector3(12.5, 3.8, 2.8), "leg": Vector3(14.0, 16.5, 17.0), "pairs": [1.0, 1.06, 0.84, 1.02],
			"femur": Color(0.3, 0.27, 0.2), "tibia": Color(0.27, 0.24, 0.17), "body_h": 3.0, "speed": 0.12, "eyes": "pisaurid", "leg_r": 0.55, "young": 0.15,
			"sprawl": 1.2, "knee_up": 0.6, "knee_out": 1.1, "flat": true, "sector": 16.0},
	"funnel": {"pattern": 2, "ceph": Vector3(7.5, 2.9, 2.2), "abd": Vector3(8.5, 3.2, 2.7), "leg": Vector3(7.5, 8.5, 9.5), "pairs": [1.0, 0.92, 0.84, 1.1],
			"femur": Color(0.5, 0.4, 0.28), "tibia": Color(0.42, 0.33, 0.22), "body_h": 3.8, "speed": 0.12, "eyes": "rows", "leg_r": 0.42, "young": 0.2, "spinnerets": 3.2},
	"argiope": {"pattern": 3, "ceph": Vector3(8.5, 3.6, 2.6), "abd": Vector3(17.0, 6.2, 5.2), "leg": Vector3(10.5, 11.5, 12.0), "pairs": [1.0, 0.98, 0.62, 0.95],
			"femur": Color(0.62, 0.28, 0.1), "tibia": Color(0.05, 0.05, 0.05), "body_h": 4.6, "speed": 0.07, "eyes": "rows", "leg_r": 0.6, "young": 0.15},
}
const ANG := [28.0, 64.0, 112.0, 150.0] # (each pair's hip round the cephalothorax, degrees from forward)
const HOME := [22.0, 70.0, 118.0, 162.0] # (and its foot)

var kind := "wolf"
var S: Dictionary
var young := false
var sacs: Array[Node3D] = [] ## its egg sacs (in its parent, or carried)
var web: Node3D ## the web it's spun (FunnelWeb, OrbWeb)
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.15
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _prey: Node3D
var _held := false
var _chew := 0.0
var _carry: Node3D # (an egg sac carried)
var _abd: Node3D
var _chel: Array[Node3D] = []
var _palps: Array[Node3D] = []
var _ceph_c := Vector3.ZERO
# riding on its mother (a wolf spiderling)
var _mother: Node3D
var _ride_at := Vector3.ZERO
var _ride_t := 0.0
# in an orb web
var _in_orb := false
var _web_pos := Vector3.ZERO
var _web_head := Vector3.DOWN
var _path: Array = [] # points to go along, in the web (its parent's space)
var _path_speed := 0.12
var _sub := 0 # (spinning a thread: 0 going to its start, 1 laying it)
var shore := Vector3.INF ## (a fishing spider's: where it takes a fish it's caught, to eat)
var _dragging := false # (going where there's no silk yet: on a dragline it pays out)
var _drag_from := Vector3.ZERO
# mating
var _charged := false # (a male's palps filled from his sperm web)
var _sperm: Node3D # (his sperm web)
var _palp_ask: Array = [null, null] # (each palp's pose, or null: its own)
var _bulbs: Array[Node3D] = []
var _pump := [0.0, 0.0] # (each bulb swelling, in her)
var _pre_mode := ""
var _cata := false # (a grass spider female, still, over on her side)
var _hang: Node3D # (a dead garden spider male: on her)
var _hang_at := Transform3D()
var _wrap: MeshInstance3D
var _wrap_t := 0.0


func _init(kind_ := "wolf", young_ := false) -> void:
	kind = kind_
	S = SPECIES[kind_]
	young = young_
	super(young_, float(S.young) if young_ else 1.0)
	body_h = S.body_h
	walk_speed = S.speed
	stride = float((S.leg as Vector3).x) * 0.9
	step_time = 0.1
	tripod = [[0, 3, 4, 7], [1, 2, 5, 6]]
	var lg: Vector3 = S.leg
	var ceph: Vector3 = S.ceph
	_ceph_c = Vector3(0.0, 0.0, -ceph.x * 0.5 - 0.3)
	var L := []
	for p in 4:
		var k: float = S.pairs[p]
		var a := deg_to_rad(ANG[p])
		var h := deg_to_rad(HOME[p])
		var reach := (lg.x + lg.y) * k * 0.82 * float(S.get("sprawl", 1.0))
		L.append({
			"hip": _ceph_c + Vector3(sin(a) * ceph.y * 0.82, -0.6, -cos(a) * ceph.x * 0.38),
			"f": lg.x * k, "t": lg.y * k, "s": lg.z * k * 0.8,
			"home": Vector2(sin(h) * reach, _ceph_c.z - cos(h) * reach),
			"dangle": Vector3(sin(a) * reach * 0.45, -2.0, _ceph_c.z - cos(a) * reach * 0.45),
			"pole": Vector3(sin(a) * float(S.get("knee_out", 0.5)), float(S.get("knee_up", 1.0)), -cos(a) * 0.3),
			"r": float(S.leg_r) * (0.9 if p == 2 else 1.0),
		})
	legs = L


func _build() -> void:
	var ceph: Vector3 = S.ceph
	var abd: Vector3 = S.abd
	if male and kind == "argiope" and not young: # (his abdomen a slender oval, not her broad one)
		abd = Vector3(abd.x * 0.8, abd.y * 0.55, abd.z * 0.6)
	var L := ceph.x
	var hw := ceph.y
	var hh := ceph.z
	var shader: Shader = preload("res://shaders/render/spider.gdshader")
	var cm := ShaderMaterial.new()
	cm.shader = shader
	cm.set_shader_parameter("species", int(S.pattern))
	cm.set_shader_parameter("young", young)
	cm.set_shader_parameter("male", male and kind == "argiope")
	cm.set_shader_parameter("abd_z", 999.0)
	cm.set_shader_parameter("half_w", hw)
	# the cephalothorax: the head's end raised (the eyes), widest behind it
	var front_up := 0.9 if kind == "wolf" else (0.15 if S.get("flat", false) else 0.4) # (the wolf spider's eyes raised up front; the fishing spider flat)
	var cephm := MeshInstance3D.new()
	cephm.mesh = _loft([[-L - 0.3, front_up, hw * 0.45, hh * 0.45], [-L * 0.88, front_up, hw * 0.66, hh * 0.8], [-L * 0.55, 0.5, hw, hh],
			[-L * 0.22, 0.25, hw * 0.88, hh * 0.78], [-0.5, 0.0, hw * 0.4, hh * 0.42], [-0.05, 0.0, 0.5, 0.5]], 2.2)
	cephm.material_override = cm
	_body.add_child(cephm)
	# the abdomen (its own joint: it works as it spins), behind the pedicel
	_abd = Node3D.new()
	_abd.position = Vector3(0.0, 0.2, 0.0)
	_body.add_child(_abd)
	var am := ShaderMaterial.new()
	am.shader = shader
	am.set_shader_parameter("species", int(S.pattern))
	am.set_shader_parameter("young", young)
	am.set_shader_parameter("male", male and kind == "argiope")
	am.set_shader_parameter("abd_z", -1.0)
	am.set_shader_parameter("abd_len", abd.x)
	am.set_shader_parameter("half_w", abd.y)
	var A := abd.x
	var widest := 0.3 if kind == "argiope" else 0.45 # (the garden spider's broad shoulders)
	var abm := MeshInstance3D.new()
	abm.mesh = _loft([[-0.2, 0.0, 0.8, 0.8], [A * 0.1, 0.4, abd.y * 0.7, abd.z * 0.7], [A * widest, 0.9, abd.y, abd.z],
			[A * 0.72, 0.7, abd.y * 0.86, abd.z * 0.85], [A * 0.94, 0.2, abd.y * 0.42, abd.z * 0.45], [A, 0.0, 0.4, 0.4]], 2.0)
	abm.material_override = am
	_abd.add_child(abm)
	# the spinnerets (the grass spider's long, two-jointed, sticking out behind)
	var dark := _mat(Color(0.12, 0.09, 0.06), 0.5)
	var sp_len: float = S.get("spinnerets", 1.0)
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(0.5 * side, -0.4, A * 0.95), Vector3(0.9 * side, -0.2 - sp_len * 0.15, A * 0.95 + sp_len), 0.3, dark, _abd)
	# the eyes: the wolf spiders' (and the fishing spider's) a row of four
	# small low, two big facing forward, two more on top behind; the
	# others' two rows of four
	var eye := _mat(Color(0.02, 0.02, 0.02), 0.08)
	var front := _ceph_c.z - L * 0.5 - 0.3
	if S.eyes == "pisaurid": # (two rows of four, both curved back: the outer eyes behind the inner)
		for row in 2:
			for k in 4:
				var x := (k - 1.5) * (0.7 + 0.25 * row)
				var back := absf(x) * (0.45 + 0.2 * row)
				_part(Vector3(x, front_up + hh * (0.55 + 0.25 * row), front + 0.3 + row * 1.0 + back), Vector3.ONE * (0.5 + 0.12 * row), eye)
	elif S.eyes == "wolf":
		for k in 4:
			_part(Vector3((k - 1.5) * 0.55, front_up + hh * 0.35, front + 0.2), Vector3.ONE * 0.45, eye)
		for side: float in [-1.0, 1.0]:
			_part(Vector3(0.75 * side, front_up + hh * 0.7, front + 0.55), Vector3.ONE * 1.15, eye)
			_part(Vector3(1.4 * side, front_up + hh * 0.85, front + 1.9), Vector3.ONE * 0.85, eye)
	else:
		for row in 2:
			for k in 4:
				var x := (k - 1.5) * 0.62
				_part(Vector3(x, front_up + hh * (0.45 + 0.25 * row) - absf(x) * 0.1 * (1 - row), front + 0.35 + row * 0.6), Vector3.ONE * 0.42, eye)
	# the chelicerae, their fangs; the pedipalps
	var chel_c := _mat((S.femur as Color).darkened(0.35), 0.4)
	for side: float in [-1.0, 1.0]:
		var ch := Node3D.new()
		ch.position = Vector3(0.65 * side, front_up - hh * 0.2, front + 0.4)
		_body.add_child(ch)
		_part(Vector3(0.0, -1.0, -0.3), Vector3(1.3, 2.6, 1.3), chel_c, ch)
		_stick(Vector3(0.0, -2.2, -0.4), Vector3(-0.5 * side, -2.6, 0.1), 0.15, dark, ch) # (a fang)
		ch.set_meta("side", side)
		_chel.append(ch)
		var pp := Node3D.new()
		pp.position = Vector3(1.3 * side, front_up - hh * 0.2, front + 0.6)
		_body.add_child(pp)
		var pc := _mat(S.femur, 0.6)
		_stick(Vector3.ZERO, Vector3(0.6 * side, -0.6, -2.2), 0.32, pc, pp)
		_stick(Vector3(0.6 * side, -0.6, -2.2), Vector3(0.8 * side, -2.0, -3.2), 0.36, pc, pp)
		if male and not young: # (his palp's end: the cymbium cupping the bulb, dark, glossy)
			var bulb := Node3D.new()
			bulb.position = Vector3(0.85 * side, -2.3, -3.4)
			pp.add_child(bulb)
			_part(Vector3(0.0, 0.1, -0.1), Vector3(1.3, 1.1, 1.7), _mat((S.femur as Color).darkened(0.25), 0.6, 0.3), bulb)
			_part(Vector3(0.0, -0.35, 0.1), Vector3(0.9, 0.8, 1.1), _mat(Color(0.12, 0.08, 0.05), 0.25), bulb)
			_bulbs.append(bulb)
		pp.set_meta("side", side)
		_palps.append(pp)
	if male and kind == "argiope" and not young: # (his legs brown, banded paler; not her red and black)
		_build_legs(_mat(Color(0.42, 0.3, 0.17), 0.7, 0.3), _mat(Color(0.33, 0.24, 0.14), 0.7, 0.3))
	else:
		_build_legs(_mat(S.femur, 0.7, 0.3), _mat(S.tibia, 0.7, 0.3))


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0


func hunt(prey: Node3D) -> void:
	if not is_instance_valid(prey):
		return
	_prey = prey
	_held = false
	_stage = 0
	_st = 0.0
	_path.clear()
	_mode = "orb_hunt" if _in_orb else "hunt"


func lay() -> void:
	if young or male:
		return
	_mode = "lay"
	_stage = 0
	_st = 0.0
	if not _in_orb:
		_target = _pos


## (The funnel weaver's.) The sheet web laid at `at` (its middle, on the
## ground), radius across, its funnel at its side; then waiting at the
## funnel's mouth.
func spin_funnel(at: Vector3, radius := 0.14) -> void:
	if kind != "funnel":
		return
	var w := FunnelWeb.new()
	w.radius = radius
	get_parent().add_child(w)
	w.position = at
	w.rotation.y = rng.randf() * TAU
	web = w
	# its sweeps: from the funnel's mouth out across the sheet, back and
	# forth, further each time
	_path.clear()
	var mouth: Vector3 = w.call("mouth")
	var away: Vector3 = (at - mouth).normalized()
	for k in 9:
		var d := radius * 2.0 * float(k + 1) / 9.0
		var spread := 0.9 * minf(1.0, d / radius)
		for sgn: float in [-1.0, 1.0]:
			_path.append(mouth + away.rotated(Vector3.UP, sgn * spread) * d)
	_path.append(mouth)
	_mode = "spin_funnel"
	_stage = 0
	_st = 0.0
	# (its ground the sheet, while it's on it: _ground)


## (The garden spider's.) An orb web spun between top (on a branch), left
## and right (low: stems, the ground). (Three contact points: spin_orb_at
## for any number.)
func spin_orb(top: Vector3, left: Vector3, right: Vector3) -> void:
	spin_orb_at([top, left, right])


## (The garden spider's.) An orb web spun between whatever contact points
## it's given (its parent's space; three or more): its frame through
## them, its hub, radii and spiral fitted to that frame.
func spin_orb_at(points: Array, normal := Vector3.ZERO) -> bool:
	if kind != "argiope" or points.size() < 3:
		return false
	var w := OrbWeb.new()
	w.anchors = points
	w.normal_hint = normal
	get_parent().add_child(w)
	web = w
	_in_orb = true
	var top: Vector3 = points[0]
	for p: Vector3 in points:
		if p.y > top.y:
			top = p
	_web_pos = top # (it begins up where the first line goes from)
	_path.clear()
	_dragging = false
	_web_head = Vector3.DOWN
	_path_speed = 0.35
	_sub = 0
	_mode = "spin_orb"
	_stage = 0
	_st = 0.0
	w.set("built", -1.0)
	return true


## (The garden spider's.) An orb web round centre in the plane facing
## `normal`, moored to whatever's there to moor it to: lines cast out from
## centre every way in that plane (as far as reach) find the stems, the
## branches, the posts round it (anything with a collider); it spins its web
## between those it finds. False if there aren't enough of them (three, not
## all to one side).
func spin_orb_auto(centre: Vector3, normal := Vector3.BACK, reach := 0.45) -> bool:
	var pts := find_contacts(centre, normal, reach)
	if pts.size() < 3:
		return false
	return spin_orb_at(pts, normal)


## The contact points round centre in the plane facing normal, within
## reach (its parent's space): where lines cast out from it every way meet
## something solid; near ones merged. Empty, if none.
func find_contacts(centre: Vector3, normal := Vector3.BACK, reach := 0.45) -> Array:
	var parent := get_parent() as Node3D
	if parent == null or not is_inside_tree():
		return []
	var space := get_world_3d().direct_space_state
	var n := normal.normalized()
	var up := (Vector3.UP - n * Vector3.UP.dot(n))
	up = up.normalized() if up.length() > 1e-3 else Vector3.FORWARD
	var right := up.cross(n).normalized()
	var found: Array = []
	var gc := parent.to_global(centre)
	const RAYS := 360 # (a degree apart: a stem a few mm thick, a hand away, still caught)
	for k in RAYS:
		var a := TAU * k / RAYS
		var dir := (right * cos(a) + up * sin(a))
		var q := PhysicsRayQueryParameters3D.create(gc, gc + parent.global_transform.basis * dir * reach)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var p := parent.to_local(hit.position)
		var near := false
		for f: Vector3 in found:
			if f.distance_to(p) < reach * 0.18:
				near = true
				break
		if not near:
			found.append(p)
	# (not all to one side: they must go round it)
	if found.size() >= 3:
		var sum := Vector2.ZERO
		for f: Vector3 in found:
			var d := f - centre
			sum += Vector2(d.dot(right), d.dot(up)).normalized()
		if sum.length() / found.size() > 0.7:
			return []
	return found


# --- thinking ------------------------------------------------------------------------

func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	match _mode:
		"wander":
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius if rng.randf() < 0.7 else _pos
				_wait = rng.randf_range(1.5, 5.0)
		"hunt":
			if not is_instance_valid(_prey):
				wander(_pos, 0.15)
				return
			var p := _prey.position
			var reach := float((S.ceph as Vector3).x) * 1.2 * MM * size
			match _stage:
				0: # to it, fast
					_pace = walk_speed * 1.8
					var to := p - _pos
					to.y = 0.0
					_target = p - to.normalized() * reach
					if to.length() < reach * 2.5:
						_stage = 1
						_st = 0.0
				1: # the pounce
					_crouch = 0.6
					if _st > 0.12:
						_crouch = 0.0
						_leap(p - (p - _pos).normalized() * reach * 0.6, 0.35)
						_stage = 2
						_st = 0.0
				2: # holding it in its jaws (once landed)
					if not airborne:
						_held = true
						_pace = -1.0
						_target = _pos
						_stage = 3
						_st = 0.0
				3: # eating it (the funnel weaver back in its funnel's mouth with it first)
					var home_to := Vector3.INF
					if kind == "funnel" and is_instance_valid(web):
						home_to = web.call("mouth")
					elif kind == "fishing" and shore != Vector3.INF: # (a fish: dragged ashore to eat)
						home_to = shore
					if home_to != Vector3.INF and _pos.distance_to(home_to) > 0.008:
						_target = home_to
						_pace = walk_speed
						_st = 0.0
					else:
						_pace = -1.0
						_chew = 1.0
						_prey.scale = Vector3.ONE * maxf(1.0 - _st / 12.0, 0.05)
						if _st > 12.0:
							_prey.queue_free()
							_prey = null
							_held = false
							if home_to != Vector3.INF:
								_mode = "ambush"
							else:
								wander(_pos, 0.12)
		"lay":
			_lay(dt)
		"spin_funnel":
			_target = _path[_stage] if _stage < _path.size() else _pos
			_pace = walk_speed * 0.6
			var w := web
			if is_instance_valid(w):
				w.set("built", maxf(float(w.get("built")), _pos.distance_to(w.call("mouth")) + 0.01))
			if _pos.distance_to(_target) < 0.006:
				_stage += 1
				if _stage >= _path.size():
					w.set("built", 1e9)
					_pace = -1.0
					_mode = "ambush"
					_stage = 0
		"ambush": # (at its funnel's mouth, facing out over the sheet)
			if is_instance_valid(web):
				var m: Vector3 = web.call("mouth")
				_target = m
				if _pos.distance_to(m) < 0.006 and _speed < 0.004:
					var out: Vector3 = web.position - m
					_turn_to = atan2(-out.x, -out.z)


## Laying: the sac spun at its spinnerets, the abdomen working; then
## carried (in its jaws, the fishing spider; on its spinnerets, the wolf)
## or left (hung, or on the ground).
func _lay(_dt: float) -> void:
	match _stage:
		0:
			var sac := EggSac.new()
			sac.kind = kind
			sac.mother = self
			_abd.add_child(sac)
			sac.position = Vector3(0.0, -1.0, float((S.abd as Vector3).x) + 2.0)
			sac.scale = Vector3.ONE * 0.01
			_carry = sac
			sacs.append(sac)
			_stage = 1
			_st = 0.0
		1: # spinning it: the abdomen bobbing and swaying, the sac growing
			_abd.rotation = Vector3(0.25 * sin(_st * 4.0), 0.2 * sin(_st * 2.3), 0.0)
			_carry.scale = Vector3.ONE * clampf(_st / 8.0, 0.01, 1.0) / (MM * size)
			if _st > 8.0:
				_abd.rotation = Vector3.ZERO
				_stage = 2
		2:
			var sac := _carry
			match kind:
				"wolf": # (on its spinnerets, carried)
					pass
				"fishing": # (into its jaws, carried)
					sac.reparent(_body, false)
					sac.position = Vector3(0.0, -2.0, _ceph_c.z - float((S.ceph as Vector3).x) * 0.5 - 3.5)
				_: # (left: the garden spider's hung by its web, the grass spider's on the ground)
					var gp := sac.global_position
					sac.reparent(get_parent(), false)
					sac.global_position = gp if kind != "argiope" else gp + Vector3.DOWN * 0.01
					sac.scale = Vector3.ONE
					sac.rotation = Vector3.ZERO
					if kind == "funnel":
						sac.global_position.y = _ground(gp.x, gp.z)
					_carry = null
			_mode = "hub" if _in_orb else "idle"


func _process(dt: float) -> void:
	if dead and _hang != null:
		_hung(dt)
		return
	if _mother != null:
		_ride(dt)
		return
	if _in_orb:
		_orb(dt)
		return
	super(dt)


## (A wolf spiderling) riding on its mother's back, then off.
func _ride(dt: float) -> void:
	_t += dt
	_ride_t -= dt
	if not is_instance_valid(_mother) or _ride_t <= 0.0:
		var m := _mother
		_mother = null
		for i in _pose_foot.size(): # (its own feet again, walking)
			_pose_foot[i] = null
		if is_instance_valid(m):
			var p: Vector3 = m.get("_pos")
			place(p + Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03)), randf() * TAU)
			wander(p, 0.25)
		return
	var ab: Node3D = _mother.get("_abd")
	var g := ab.global_transform * _ride_at
	var parent := get_parent() as Node3D
	var at := parent.to_local(g) if parent else g
	transform = Transform3D(Basis(Vector3.UP, _yaw) * Basis.from_scale(Vector3.ONE), at + Vector3.UP * body_h * MM * size * 0.5)
	_body.scale = Vector3.ONE * MM * size
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var dg: Vector3 = L.dangle
		_pose_foot[i] = Vector3(dg.x * side * 1.4, -body_h * 0.6, dg.z * 1.2)
	_pose(dt)
	_pose_legs()


func ride(mother: Node3D, secs := 25.0) -> void:
	_mother = mother
	_ride_t = secs
	var A: Vector3 = mother.get("S").abd
	_ride_at = Vector3(randf_range(-0.7, 0.7) * A.y, A.z * 0.95 + 0.5, randf_range(0.15, 0.8) * A.x)


## In its orb: its body on the web's face, going along its path (spinning)
## or to its prey and back, or at the hub, head down.
func _orb(dt: float) -> void:
	_t += dt
	_st += dt
	if _pilot:
		_pilot.tick(dt)
	var w := web
	if not is_instance_valid(w):
		_in_orb = false
		return
	var n: Vector3 = w.call("normal")
	var moving := false
	match _mode:
		"spin_orb":
			# each thread laid as it goes: first to where it starts (along
			# what's spun already: back to the hub for each radius), then
			# along it, the silk drawn out behind it from there to it; the
			# thread one of the web's once it's at its end
			var count: int = w.call("count")
			var at := clampi(_stage, 0, count - 1)
			var fast := _path_speed * (2.0 if at > count * 0.3 else 1.0)
			if _sub == 0:
				# (to its start along the silk there is; where there's none
				# yet to walk on, on a dragline it pays out as it goes)
				var to: Vector3 = w.call("start", at)
				if _path.is_empty() and not _dragging:
					if _web_pos.distance_to(to) > 0.002:
						_path = w.call("route", _web_pos, to)
						if _path.is_empty():
							_dragging = true
							_drag_from = _web_pos
							_path = [to]
				moving = _follow_web(fast * 1.6, dt)
				w.call("live", _drag_from if _dragging else Vector3.INF, _web_pos)
				if not moving:
					if _dragging:
						w.call("add_dragline", _drag_from, _web_pos)
						_dragging = false
					w.call("live", Vector3.INF, Vector3.INF)
					_sub = 1
			else:
				moving = _go_web(w.call("point", at), fast, dt)
				w.call("live", w.call("start", at), _web_pos)
				if not moving:
					w.set("built", float(at))
					w.call("add_thread", at)
					_stage += 1
					_sub = 0
					if _stage >= count:
						w.call("live", Vector3.INF, Vector3.INF)
						w.set("built", 1e9)
						_mode = "hub"
		"hub":
			if _path.is_empty() and _web_pos.distance_to(w.call("hub")) > 0.004:
				_path = w.call("route", _web_pos, w.call("hub"))
				if _path.is_empty():
					_path = [w.call("hub")]
			_follow_web(0.06, dt)
			if _web_pos.distance_to(w.call("hub")) < 0.004:
				_web_head = _web_head.lerp(Vector3.DOWN, 1.0 - exp(-4.0 * dt)).normalized()
		"orb_hunt":
			if not is_instance_valid(_prey):
				_mode = "hub"
			else:
				match _stage:
					0: # out to it along the web (along its threads)
						if _path.is_empty():
							_path = w.call("route", _web_pos, _prey.position)
							_path.append(_prey.position)
						if not _follow_web(0.2, dt):
							_stage = 1
							_st = 0.0
					1: # wrapping it: turning it over and over in silk
						var wrap := _prey.get_node_or_null("wrap") as MeshInstance3D
						if wrap == null:
							wrap = MeshInstance3D.new()
							wrap.name = "wrap"
							var sm := SphereMesh.new()
							sm.radius = 0.5
							sm.height = 1.0
							wrap.mesh = sm
							var silk := StandardMaterial3D.new()
							silk.albedo_color = Color(0.95, 0.95, 0.92)
							silk.roughness = 0.7
							wrap.material_override = silk
							_prey.add_child(wrap)
						wrap.scale = Vector3(0.012, 0.01, 0.018) * clampf(_st / 3.0, 0.05, 1.0)
						_prey.rotation.z += dt * 8.0
						_abd.rotation.x = 0.3 * sin(_st * 10.0)
						if _st > 3.5:
							_abd.rotation.x = 0.0
							_held = true
							_stage = 2
							_st = 0.0
					2: # back to the hub with it
						if _path.is_empty():
							_path = w.call("route", _web_pos, w.call("hub"))
							_path.append(w.call("hub"))
						if not _follow_web(0.12, dt):
							_stage = 3
							_st = 0.0
					3: # eating it at the hub, head down
						_web_head = _web_head.lerp(Vector3.DOWN, 1.0 - exp(-4.0 * dt)).normalized()
						_chew = 1.0
						_prey.scale = Vector3.ONE * maxf(1.0 - _st / 15.0, 0.05)
						if _st > 15.0:
							_prey.queue_free()
							_prey = null
							_held = false
							_mode = "hub"
		"lay":
			_lay(dt)
	# its body on the web's face: its back to the front, its head its way
	var head := _web_head - n * _web_head.dot(n)
	head = head.normalized() if head.length() > 1e-4 else Vector3.DOWN
	transform = Transform3D(Basis.looking_at(head, n) * Basis.from_scale(Vector3.ONE), _web_pos + n * body_h * MM * size * 0.45)
	_body.scale = Vector3.ONE * MM * size
	# the legs spread on the web, stepping as it goes
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var step := (sin(_t * 18.0 + (PI if i in tripod[0] else 0.0)) * 1.5) if moving else 0.0
		_pose_foot[i] = Vector3(hm.x * side, -body_h * 0.9, hm.y + step)
	_pose(dt)
	_pose_legs()


## Its gait (the walker's); then each foot kept in its own sector round
## the body (S.sector, degrees either side of its home's way: a fishing
## spider's long legs never crossing their neighbours') and within its reach.
func _gait(dt: float) -> void:
	super(dt)
	if float(S.get("sector", 0.0)) <= 0.0:
		return
	for i in legs.size() * 2:
		_feet[i] = _in_sector(i, _feet[i])
		_to[i] = _in_sector(i, _to[i]) # (where it's stepping to, too)


## A foot's place (its parent's space) kept in leg i's sector and reach.
func _in_sector(i: int, at: Vector3) -> Vector3:
	var w := deg_to_rad(float(S.get("sector", 0.0)))
	var to_world := transform * _body.transform
	var p := i / 2
	var side := 1.0 if i % 2 == 1 else -1.0
	var lg: Vector3 = S.leg
	var f := to_world.affine_inverse() * at
	var rel := Vector2(f.x * side, -(f.z - _ceph_c.z)) # (out to its side, forward)
	var a := atan2(rel.x, rel.y)
	var h := deg_to_rad(HOME[p])
	var ca := clampf(a, h - w, h + w)
	var reach := (lg.x + lg.y) * float(S.pairs[p]) * float(S.get("sprawl", 1.0))
	var r := clampf(rel.length(), reach * 0.55, reach * 1.02)
	if absf(ca - a) < 1e-4 and absf(r - rel.length()) < 1e-3:
		return at
	var wpos := to_world * Vector3(sin(ca) * r * side, f.y, _ceph_c.z - cos(ca) * r)
	wpos.y = at.y
	return wpos


## The ground at (x, z): its funnel web's sheet, while it's on it (the
## grass spider's), else the ground's.
func _ground(x: float, z: float) -> float:
	if web is FunnelWeb and is_instance_valid(web):
		var y: float = web.call("surface_y", x, z)
		if y > -1e8:
			return y
	return super(x, z)


## Along its path (points on the web's threads) at speed: whether it's still going.
func _follow_web(speed: float, dt: float) -> bool:
	while not _path.is_empty():
		if _go_web(_path[0], speed, dt):
			return true
		_path.pop_front()
	return false


## Along the web toward goal at speed: whether it's still going.
func _go_web(goal: Vector3, speed: float, dt: float) -> bool:
	var to := goal - _web_pos
	var d := to.length()
	if d < 0.002:
		_web_pos = goal
		return false
	var stepv := minf(speed * dt, d)
	_web_pos += to / d * stepv
	_web_head = _web_head.lerp(to / d, 1.0 - exp(-10.0 * dt)).normalized()
	return true


func _pose(dt: float) -> void:
	# the chelicerae working, the palps turning what it eats; idly twitching
	for c in _chel:
		var side: float = c.get_meta("side")
		c.rotation = Vector3(-0.3 * _chew * (0.5 + 0.5 * sin(_t * 9.0)), side * 0.25 * _chew * sin(_t * 9.0), 0.0)
	for k in _palps.size():
		var pp := _palps[k]
		if _palp_ask[k] != null:
			pp.rotation = pp.rotation.lerp(_palp_ask[k], 1.0 - exp(-12.0 * dt))
		else:
			pp.rotation = Vector3(0.25 * sin(_t * (6.0 if _chew > 0.0 else 1.3) + k * 1.7), 0.15 * sin(_t * 1.1 + k), 0.0)
	for k in _bulbs.size(): # (swelling, pulsing, in her)
		_pump[k] = move_toward(float(_pump[k]), 0.0, dt * 0.5)
		_bulbs[k].scale = Vector3.ONE * (1.0 + float(_pump[k]) * (0.3 + 0.15 * sin(_t * 7.0)))
	if not _cata:
		_roll = lerpf(_roll, 0.0, 1.0 - exp(-3.0 * dt))
	# the prey held in the jaws
	if _held and is_instance_valid(_prey):
		var ceph: Vector3 = S.ceph
		_prey.global_position = _body.global_transform * Vector3(0.0, -2.5, _ceph_c.z - ceph.x * 0.5 - 2.5)
	if _mode == "lay" and not _in_orb:
		_pitch = 0.08 * sin(_t * 3.0)
	elif not airborne:
		_pitch = lerpf(_pitch, 0.0, 1.0 - exp(-6.0 * dt))


func _on_landed() -> void:
	pass


# --- mating ------------------------------------------------------------------------

func _male_size() -> float:
	return {"wolf": 0.75, "fishing": 0.6, "funnel": 0.85, "argiope": 0.28}.get(kind, 0.8)


## (How many times he puts a palp in to her, by turns.)
func _insertions() -> int:
	return 2 if kind == "argiope" else 6


func _mate_approach() -> Vector3:
	if kind == "argiope": # (below her hub, on the ground: up her web from there)
		return Vector3(0.0, 0.0, 0.0)
	return Vector3(0.0, -body_h, -float((S.ceph as Vector3).x) * 2.6) # (before her, facing her)


func _mate_leave() -> Vector3:
	return Vector3(float((S.leg as Vector3).x) * 2.2, -body_h, -float((S.ceph as Vector3).x) * 2.0)


func _court_secs() -> float:
	return {"wolf": 6.0, "fishing": 5.0, "funnel": 5.0, "argiope": 0.5}.get(kind, 4.0)


func _mount_secs() -> float:
	if kind == "argiope" and _mate != null: # (up a thread to her: as far as it is, at 5 cm/s)
		if _climb < 0.0:
			_climb = clampf(_mount_from.origin.distance_to(_mate.transform.origin) / 0.05, 0.8, 8.0)
		return _climb
	return 0.9


var _climb := -1.0


func _on_mate_start() -> void:
	_pre_mode = _mode
	if male and kind == "funnel" and is_instance_valid(_mate):
		web = _mate.get("web") # (on her sheet with her)


func _after_mate() -> void:
	_palp_ask = [null, null]
	_cata = false
	_climb = -1.0
	if male:
		if kind == "funnel":
			web = null
		_charged = false
		if not dead:
			wander(_pos, 0.2)
	elif _pre_mode in ["ambush", "hub"]:
		_mode = _pre_mode
	else:
		wander(_pos, 0.15)


## Which palp's in her (0, 1), or -1 (between); and how far into that one
## (0..1).
func _insertion() -> Vector2:
	var n := _insertions()
	var t := clampf(_mate_t / maxf(mate_secs, 0.01), 0.0, 0.999) * n
	var k := fmod(t, 1.0)
	var which := int(t) % 2
	return Vector2(which if k > 0.15 and k < 0.9 else -1, k)


func _mount() -> Dictionary:
	var hc: Vector3 = S.ceph
	var ha: Vector3 = S.abd
	var r := size / maxf(float(_mate.get("size")), 0.01) # (his size to hers)
	var ins := _insertion() if _mate_stage == "joined" else Vector2(-1, 0)
	var grips := {}
	if kind == "argiope":
		# under her at the hub, belly to belly, his head to hers; his legs
		# holding her abdomen's sides
		var b := Basis(Vector3.BACK, PI)
		for i in 8:
			var p := i / 2
			var sd := 1.0 if i % 2 == 1 else -1.0
			grips[i] = Vector3(-sd * ha.y * 0.5, -ha.z * 0.2, ha.x * (0.1 + 0.12 * p))
		return {"at": Vector3(0.0, -ha.z * 0.75, ha.x * 0.2), "basis": b, "grips": grips}
	# on her front, facing back over her abdomen, leaning down to one side
	# then the other (the palp on that side down under her abdomen's front)
	var side := (-1.0 if int(ins.x) == 0 else 1.0) if ins.x >= 0.0 else 0.0
	var lean := sin(clampf((ins.y - 0.1) / 0.8, 0.0, 1.0) * PI) if ins.x >= 0.0 else 0.0
	var b := Basis(Vector3.UP, PI) * Basis(Vector3.BACK, side * 0.45 * lean)
	for i in 8:
		var p := i / 2
		var sd := 1.0 if i % 2 == 1 else -1.0
		# (his right side over her left: he faces the other way)
		var z := lerpf(ha.x * 0.25, -hc.x * 0.9, float(p) / 3.0)
		grips[i] = Vector3(-sd * (hc.y * 1.05 if z < 0.0 else ha.y * 0.95), -hc.z * 0.25, z)
	var at := Vector3(side * hc.y * 0.3 * lean, hc.z * 0.95 + 0.6 * r * hc.z, -hc.x * r * 0.6 + 0.6)
	return {"at": at, "basis": b, "grips": grips}


func _mate_over() -> bool:
	if male and _mate_stage == "joined":
		var ins := _insertion()
		_palp_ask = [null, null]
		if ins.x >= 0.0:
			var w := int(ins.x)
			var sd := -1.0 if w == 0 else 1.0
			# (down and back under her abdomen, to her epigyne)
			_palp_ask[w] = Vector3(-1.1, sd * 0.5, sd * 0.3) if kind != "argiope" else Vector3(-0.5, sd * 0.2, 0.0)
			_pump[w] = minf(float(_pump[w]) + get_process_delta_time() * 2.0, 1.0)
		if kind == "argiope" and _mate_t >= mate_secs: # (his second in: he dies there)
			_die_on(_mate)
			return false
	return super()


func _mating(dt: float) -> void:
	if _mate_role == "male" and not _charged and _mate_stage == "seek":
		_mate_stage = "sperm"
		_mate_t = 0.0
		_stage = 0
	if _mate_role == "male" and _mate_stage == "sperm":
		_mate_t += dt
		_charge(dt)
		return
	super(dt)
	if _mate_role == "male" and _mate_stage == "court":
		_court(dt)
	elif _mate_role == "female":
		# (the grass spider gone still, over on her side, her legs drawn in)
		var lie := kind == "funnel" and _mate_stage == "joined"
		_cata = lie
		if lie:
			_roll = lerpf(_roll, 1.25, 1.0 - exp(-2.0 * dt))


## His sperm web: spun under him (his abdomen working), a drop of sperm laid
## on it, then round to it, his palps dipped in it by turns.
func _charge(dt: float) -> void:
	var A := float((S.abd as Vector3).x)
	match _stage:
		0: # spinning it, under his abdomen
			_target = _pos
			if _sperm == null:
				var sw := SpermWeb.new()
				sw.across = float((S.ceph as Vector3).y) * 2.4 * MM * size
				get_parent().add_child(sw)
				var at := _out(Vector3(0.0, -body_h, A * 0.35))
				sw.position = Vector3(at.x, _ground(at.x, at.z), at.z)
				sw.rotation.y = _yaw
				_sperm = sw
			_abd.rotation = Vector3(0.35 + 0.15 * sin(_mate_t * 9.0), 0.25 * sin(_mate_t * 4.0), 0.0)
			_sperm.set("built", clampf(_mate_t / 5.0, 0.0, 1.0))
			if _mate_t > 5.0:
				_stage = 1
				_mate_t = 0.0
		1: # the drop laid on it from under his abdomen
			_crouch = minf(_crouch + dt * 2.0, 0.8)
			_abd.rotation = _abd.rotation.lerp(Vector3(0.45, 0.0, 0.0), 1.0 - exp(-6.0 * dt))
			_sperm.set("drop", clampf(_mate_t / 2.0, 0.0, 1.0))
			if _mate_t > 2.2:
				_stage = 2
				_mate_t = 0.0
		2: # round, to it, his front over it
			_crouch = move_toward(_crouch, 0.0, dt * 2.0)
			_abd.rotation = _abd.rotation.lerp(Vector3.ZERO, 1.0 - exp(-4.0 * dt))
			var to := _sperm.position - _pos
			to.y = 0.0
			var reach := (float((S.ceph as Vector3).x) * 0.5 - _ceph_c.z + 2.5) * MM * size
			var goal := _sperm.position - to.normalized() * reach
			_target = Vector3(goal.x, _pos.y, goal.z)
			_pace = walk_speed * 0.3
			if Vector2(goal.x - _pos.x, goal.z - _pos.z).length() < 0.002 or _mate_t > 8.0:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 3
				_mate_t = 0.0
		3: # his palps dipped in the drop by turns, drawing it up
			_pace = -1.0
			_target = _pos
			var w := int(_mate_t / 1.2) % 2
			_palp_ask = [null, null]
			_palp_ask[w] = Vector3(-0.8 - 0.15 * sin(_mate_t * 8.0), 0.0, 0.0)
			_pump[w] = minf(float(_pump[w]) + dt, 0.5)
			_sperm.set("drop", clampf(1.0 - _mate_t / 7.0, 0.0, 1.0))
			if _mate_t > 7.2:
				_palp_ask = [null, null]
				_charged = true
				_sperm.set("left", true)
				_sperm = null
				_mate_stage = "seek"
				_mate_t = 0.0
				_stage = 0


## Courting her (his own way, by kind), facing her.
func _court(_dt: float) -> void:
	var t := _mate_t
	var up := Vector3(0.0, 0.0, 0.0)
	match kind:
		"wolf": # (his front legs raised, waving; his palps drumming the ground)
			up = Vector3(0.0, 5.0 + 3.0 * sin(t * 3.0), -2.0)
			var w := int(t * 8.0) % 2
			_palp_ask = [null, null]
			_palp_ask[w] = Vector3(-0.7, 0.0, 0.0)
		"fishing": # (tapping the surface with his front legs)
			up = Vector3(0.0, 2.0 * maxf(sin(t * 12.0), 0.0), -1.0)
		"funnel": # (plucking her sheet, his abdomen jerking)
			up = Vector3(0.0, 1.5 * maxf(sin(t * 9.0), 0.0), 0.0)
			_abd.rotation.x = 0.12 * sin(t * 25.0)
		_: # (plucking her threads)
			up = Vector3(0.0, 2.0 * maxf(sin(t * 6.0), 0.0), 0.0)
	for i in [0, 1]:
		var L: Dictionary = legs[0]
		var sd := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var phase := sin(t * 3.0 + PI * i) * 0.5 + 0.5 if kind == "wolf" else 1.0
		_pose_foot[i] = Vector3(hm.x * sd * 0.6, -body_h + up.y * phase, hm.y * 0.8 + up.z)
		if not _gripped.has(i):
			_gripped.append(i)
	if t + get_process_delta_time() >= _court_secs():
		_palp_ask = [null, null]
		_abd.rotation = Vector3.ZERO


## (A garden spider male: dead on her, after his second; she wraps him.)
func _die_on(her: Node3D) -> void:
	_hang = her
	_hang_at = her.transform.affine_inverse() * transform
	_palp_ask = [null, null]
	die()


func _hung(dt: float) -> void:
	_t += dt
	_wrap_t += dt
	if not is_instance_valid(_hang):
		_hang = null
		return
	transform = _hang.transform * _hang_at
	_body.scale = Vector3.ONE * MM * size
	# his legs drawn in
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		_pose_foot[i] = Vector3(hp.x * side * 2.0, hp.y + float(L.f) * 0.55, hp.z * 0.7)
	_pose_legs()
	# (and she wraps him in silk)
	if _wrap_t > 3.0:
		if _wrap == null:
			_wrap = MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.5
			sm.height = 1.0
			_wrap.mesh = sm
			var silk := StandardMaterial3D.new()
			silk.albedo_color = Color(0.95, 0.95, 0.92)
			silk.roughness = 0.7
			_wrap.material_override = silk
			_body.add_child(_wrap)
		var k := clampf((_wrap_t - 3.0) / 4.0, 0.02, 1.0)
		var A: Vector3 = S.abd
		_wrap.position = Vector3(0.0, 0.0, A.x * 0.15)
		_wrap.scale = Vector3(A.y * 2.2, A.z * 2.0, A.x * 1.9 + float((S.ceph as Vector3).x)) * k


# --- steering (pilot.gd): its behaviours -------------------------------------------

## hunt {prey}, lay, spin {at, radius} (the funnel weaver) / {top, left,
## right} (the garden spider).
func _p_behaviours() -> PackedStringArray:
	if young:
		return PackedStringArray(["hunt"])
	if male:
		return PackedStringArray(["hunt", "mate"])
	if kind in ["funnel", "argiope"]:
		return PackedStringArray(["hunt", "lay", "spin", "mate"])
	return PackedStringArray(["hunt", "lay", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"hunt":
			var prey: Node3D = args.get("prey")
			if prey == null:
				return false
			hunt(prey)
		"lay":
			lay()
		"spin":
			if kind == "funnel":
				spin_funnel(args.get("at", _pos), float(args.get("radius", 0.14)))
			elif kind == "argiope" and args.has("top"):
				spin_orb(args.top, args.get("left", _pos + Vector3(-0.2, 0.0, 0.0)), args.get("right", _pos + Vector3(0.2, 0.0, 0.0)))
			else:
				return false
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"hunt":
			return _mode not in ["hunt", "orb_hunt"]
		"lay":
			return _mode != "lay"
		"spin":
			return _mode not in ["spin_funnel", "spin_orb"]
	return false


func _p_mobile() -> bool:
	return not _in_orb and _mother == null


func _piloted() -> void:
	if _mode in ["wander", "idle", "ambush"]:
		_mode = "piloted"


## A spider's egg sac (spun by lay()): the wolf spider's a grey white ball,
## the fishing spider's a bigger one, the grass spider's a flat white
## disc, the garden spider's a brown papery jar hung on threads. hatch():
## the spiderlings out of it: the wolf spider's up onto its mother's back
## to ride; the fishing spider's out where she's set it down, then away; the others out, clustered a while, then away.
class EggSac extends Node3D:
	var kind := "wolf"
	var mother: Node3D
	var spiderlings: Array[Node3D] = []
	var _shell: MeshInstance3D
	var _t := -1.0
	var _left := 0

	func _ready() -> void:
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 14
		s.rings = 8
		_shell = MeshInstance3D.new()
		_shell.mesh = s
		var m := StandardMaterial3D.new()
		m.roughness = 0.9
		match kind:
			"wolf":
				m.albedo_color = Color(0.8, 0.78, 0.72)
				_shell.scale = Vector3.ONE * 0.016
			"fishing":
				m.albedo_color = Color(0.88, 0.86, 0.8)
				_shell.scale = Vector3.ONE * 0.022
			"funnel":
				m.albedo_color = Color(0.94, 0.94, 0.9)
				_shell.scale = Vector3(0.018, 0.005, 0.018)
				_shell.position.y = 0.0025
			_:
				m.albedo_color = Color(0.5, 0.36, 0.2)
				_shell.scale = Vector3(0.026, 0.032, 0.026)
				# (its neck, and the threads it hangs from)
				var neck := MeshInstance3D.new()
				neck.mesh = s
				neck.scale = Vector3(0.012, 0.012, 0.012)
				neck.position = Vector3(0.0, 0.018, 0.0)
				neck.material_override = m
				add_child(neck)
		_shell.material_override = m
		add_child(_shell)

	## Hatching: see the class.
	func hatch() -> void:
		if _t >= 0.0 or mother == null:
			return
		_t = 0.0
		_left = {"wolf": 14, "fishing": 12, "funnel": 9, "argiope": 12}.get(kind, 10)
		if kind == "fishing" and is_instance_valid(mother):
			# (she sets it down at the water's edge, the spiderlings out of it there)
			var gp := global_position
			var parent := mother.get_parent() as Node3D
			reparent(parent, false)
			global_position = Vector3(gp.x, float(mother.call("_ground", gp.x, gp.z)) + 0.02, gp.z)
			scale = Vector3.ONE
			mother.set("_carry", null)

	func _process(dt: float) -> void:
		if _t < 0.0:
			return
		_t += dt
		if _t < 1.5:
			_shell.rotation.z = sin(_t * 10.0) * 0.08
			return
		if _left > 0 and fmod(_t, 0.25) < dt:
			_left -= 1
			var parent := (mother.get_parent() if is_instance_valid(mother) else get_parent()) as Node3D
			var sl: Node3D = (mother.get_script() as Script).new(kind, true) if is_instance_valid(mother) else null
			if sl == null:
				_left = 0
				return
			parent.add_child(sl)
			var gp := global_position
			var y := float(mother.call("_ground", gp.x, gp.z)) if is_instance_valid(mother) else gp.y
			sl.call("place", Vector3(gp.x, y, gp.z), randf() * TAU)
			sl.call("grow", 0.45, 150.0)
			if kind == "wolf" and is_instance_valid(mother) and not bool(mother.get("_in_orb")):
				sl.call("ride", mother, randf_range(20.0, 35.0))
			else:
				sl.call("wander", Vector3(gp.x, y, gp.z), 0.04 if _left > 3 else 0.2)
			spiderlings.append(sl)
			if _left == 0:
				_shell.scale.y *= 0.5 # (empty, slack)


## The funnel weaver's sheet web (spin_funnel): a sheet of silk on the
## ground, its edges drawn up a little where it's tied to the grass, the
## funnel its retreat at one side, going down; built: how far out from the
## funnel's mouth it's been laid (m).
class FunnelWeb extends Node3D:
	var radius := 0.14
	var built := 0.0
	var _mat: ShaderMaterial
	const LIFT := 0.012 # m: the sheet over the ground at its middle
	const RINGS := 10
	const AROUND := 36

	func _ready() -> void:
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://shaders/render/silk.gdshader")
		_mat.set_shader_parameter("sheet", true)
		_mat.set_shader_parameter("opacity", 0.8)
		var mi := MeshInstance3D.new()
		mi.mesh = _sheet()
		mi.material_override = _mat
		add_child(mi)

	## Its funnel's mouth (its parent's space).
	func mouth() -> Vector3:
		return transform * Vector3(radius * 0.95, LIFT * 1.2, 0.0)

	## The sheet's height at (x, z) (its parent's space), or -1e9 off it.
	func surface_y(x: float, z: float) -> float:
		var l := transform.affine_inverse() * Vector3(x, position.y, z)
		var r := Vector2(l.x, l.z).length() / radius
		if r > 1.05:
			return -1e9
		return position.y + LIFT * (1.0 + 0.6 * r * r)

	func _process(_dt: float) -> void:
		_mat.set_shader_parameter("built", built)

	func _sheet() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var m := Vector3(radius * 0.95, LIFT * 1.2, 0.0)
		var pt := func(i: int, k: int) -> Vector3:
			var r := radius * float(i) / RINGS * (1.0 + 0.08 * sin(float(k) * 1.7))
			var a := TAU * float(k % AROUND) / AROUND
			var rr := r / radius
			return Vector3(cos(a) * r, LIFT * (1.0 + 0.6 * rr * rr), sin(a) * r)
		var put := func(p: Vector3) -> void:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(p.distance_to(m), 0.0))
			st.add_vertex(p)
		for i in RINGS:
			for k in AROUND:
				var a: Vector3 = pt.call(i, k)
				var b: Vector3 = pt.call(i + 1, k)
				var c: Vector3 = pt.call(i + 1, k + 1)
				var d: Vector3 = pt.call(i, k + 1)
				for p in [a, b, c, a, c, d]:
					put.call(p)
		# the funnel: a tube from its mouth down and away into the grass
		const SEG := 12
		for j in 6:
			var t0 := float(j) / 6.0
			var t1 := float(j + 1) / 6.0
			var c0 := m + Vector3(t0 * radius * 0.45, -t0 * LIFT * 1.5, 0.0)
			var c1 := m + Vector3(t1 * radius * 0.45, -t1 * LIFT * 1.5, 0.0)
			var r0 := radius * 0.16 * (1.0 - t0 * 0.55)
			var r1 := radius * 0.16 * (1.0 - t1 * 0.55)
			for k in SEG:
				var a0 := TAU * k / SEG
				var a1 := TAU * (k + 1) / SEG
				var q := [c0 + Vector3(0.0, sin(a0), cos(a0)) * r0, c1 + Vector3(0.0, sin(a0), cos(a0)) * r1,
						c1 + Vector3(0.0, sin(a1), cos(a1)) * r1, c0 + Vector3(0.0, sin(a1), cos(a1)) * r0]
				for e in [0, 1, 2, 0, 2, 3]:
					st.set_normal(Vector3.UP)
					st.set_uv(Vector2(0.0, 0.0))
					st.add_vertex(q[e])
		return st.commit()


## The garden spider's orb web (spin_orb_at): between its anchors (any
## number, three or more, wherever they are), in the plane that best fits
## them: mooring lines from each anchor in to the frame, the frame a
## polygon through them (taken in a little), the hub above the frame's
## middle (an orb's lower half the larger), radii out from it to the frame
## each its own length (more of them the bigger the web), a dense little
## hub, the capture spiral round and round inward following the frame's
## shape (as many turns as its size calls for), the zigzag band of white
## silk up and down through the middle (as long as there's room). Every
## thread in the order it's spun (its vertices' UV.x), drawn so far as
## built; point(i) where the spider is when it's laid thread i.
class OrbWeb extends Node3D:
	var anchors: Array = [] # (its parent's space)
	var normal_hint := Vector3.ZERO
	var built := -1.0
	var _mat: ShaderMaterial
	var _ends: Array[Vector3] = [] # each thread's end (local)
	var _starts: Array[Vector3] = [] # and its start
	var _live: MeshInstance3D # (the thread being laid: from its start to the spider)
	var _live_mesh: ImmediateMesh
	var _hub := Vector3.ZERO
	var _n := Vector3.BACK

	func _ready() -> void:
		# the plane: through their middle, facing the hint or the way that
		# fits them best (the sum of the turns between them, round it)
		var c := Vector3.ZERO
		for p: Vector3 in anchors:
			c += p
		c /= anchors.size()
		var n := normal_hint
		if n.length() < 1e-3:
			var srt := anchors.duplicate()
			var ref: Vector3 = (srt[0] as Vector3) - c
			srt.sort_custom(func(p: Vector3, q: Vector3) -> bool:
				return ref.signed_angle_to(p - c, ref.cross(Vector3.UP) if ref.cross(Vector3.UP).length() > 1e-3 else Vector3.BACK) < ref.signed_angle_to(q - c, ref.cross(Vector3.UP) if ref.cross(Vector3.UP).length() > 1e-3 else Vector3.BACK))
			for i in srt.size():
				n += ((srt[i] as Vector3) - c).cross((srt[(i + 1) % srt.size()] as Vector3) - c)
			if n.length() < 1e-6:
				n = Vector3.BACK
		n = n.normalized()
		var up := Vector3.UP - n * Vector3.UP.dot(n)
		up = up.normalized() if up.length() > 1e-3 else Vector3.FORWARD
		var x := up.cross(n).normalized()
		# the anchors in the plane (2D), round their middle in order
		var flat: Array[Vector2] = []
		for p: Vector3 in anchors:
			var d := p - c
			flat.append(Vector2(d.dot(x), d.dot(up)))
		var order_i: Array = range(flat.size())
		order_i.sort_custom(func(i: int, j: int) -> bool: return flat[i].angle() < flat[j].angle())
		# the frame: each anchor taken in toward the middle (the mooring
		# lines between)
		var frame: Array[Vector2] = []
		for i: int in order_i:
			frame.append(flat[i] * 0.72)
		# the hub: the frame's middle, then up a little (its height's eighth)
		var mid := Vector2.ZERO
		var lo := INF
		var hi := -INF
		for f in frame:
			mid += f
			lo = minf(lo, f.y)
			hi = maxf(hi, f.y)
		mid /= frame.size()
		mid.y += (hi - lo) * 0.12
		transform = Transform3D(Basis(x, up, n), c + x * mid.x + up * mid.y)
		_n = n
		for i in frame.size():
			frame[i] -= mid
		var moor: Array[Vector2] = []
		for i: int in order_i:
			moor.append(flat[i] - mid)
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://shaders/render/silk.gdshader")
		_mat.set_shader_parameter("opacity", 0.85)
		var lines := SurfaceTool.new()
		lines.begin(Mesh.PRIMITIVE_LINES)
		var ribbon := SurfaceTool.new()
		ribbon.begin(Mesh.PRIMITIVE_TRIANGLES)
		var order := [0]
		var add := func(a: Vector2, b: Vector2) -> void:
			for p in [a, b]:
				lines.set_uv(Vector2(float(order[0]), 0.0))
				lines.add_vertex(Vector3(p.x, p.y, 0.0))
			_starts.append(Vector3(a.x, a.y, 0.0))
			_ends.append(Vector3(b.x, b.y, 0.0))
			order[0] += 1
		var F := frame.size()
		# the bridge line first, between the two highest; then each anchor
		# moored to its frame corner, and the frame round
		var top_i := 0
		for i in F:
			if moor[i].y > moor[top_i].y:
				top_i = i
		var next_i := (top_i + 1) % F
		add.call(moor[top_i], moor[next_i])
		for i in F:
			add.call(moor[i], frame[i])
		for i in F:
			add.call(frame[i], frame[(i + 1) % F])
		# how far out to the frame the way a points (a ray from the hub to
		# its polygon)
		var to_frame := func(a: float) -> float:
			var dir := Vector2(cos(a), sin(a))
			var best := INF
			for i in F:
				var p: Vector2 = frame[i]
				var q: Vector2 = frame[(i + 1) % F]
				var e := q - p
				var den := dir.x * e.y - dir.y * e.x
				if absf(den) < 1e-9:
					continue
				var t := (p.x * e.y - p.y * e.x) / den # (along the ray)
				var u := (p.x * dir.y - p.y * dir.x) / den # (along the edge)
				if t > 0.0 and u >= -1e-4 and u <= 1.0001:
					best = minf(best, t)
			return best if best < INF else 0.1
		# the radii, as many as its size calls for, spun across and about
		var size := 0.0
		for f in frame:
			size += f.length()
		size /= F
		var RADII := clampi(int(size / 0.012), 16, 34)
		var ends: Array[Vector2] = []
		for k in RADII:
			var a := TAU * k / RADII
			ends.append(Vector2(cos(a), sin(a)) * to_frame.call(a) * 0.98)
		var step := 7 if RADII % 7 != 0 else 5
		for j in RADII:
			add.call(Vector2.ZERO, ends[(j * step) % RADII])
		# the hub: a few tight turns
		var prev := ends[0].normalized() * size * 0.03
		for i in RADII * 3:
			var a := TAU * i / RADII
			var p := Vector2(cos(a), sin(a)) * size * (0.03 + 0.03 * float(i) / (RADII * 3))
			add.call(prev, p)
			prev = p
		# the capture spiral: inward from the frame, each radius its own
		# length (the spiral follows the frame's shape), as many turns as
		# its size calls for
		var turns := clampi(int(size * 0.75 / 0.011), 8, 30)
		prev = ends[0] * 0.92
		for i in turns * RADII:
			var f := float(i) / (turns * RADII)
			var e := ends[i % RADII]
			var inner := size * 0.22 / maxf(e.length(), 1e-4)
			var p := e * lerpf(0.92, minf(inner, 0.9), f)
			add.call(prev, p)
			prev = p
		# the stabilimentum: a zigzag band straight up and down from the
		# hub, as long as there's room
		var room_up := to_frame.call(PI * 0.5) as float
		var room_down := to_frame.call(-PI * 0.5) as float
		var w := size * 0.05
		for sgn: float in [1.0, -1.0]:
			var room := room_up if sgn > 0.0 else room_down
			var n_z := clampi(int(room * 0.55 / (size * 0.035)), 3, 18)
			for i in n_z:
				var y0 := sgn * (size * 0.14 + size * 0.035 * i)
				var y1 := sgn * (size * 0.14 + size * 0.035 * (i + 1))
				var x0 := w * (1.0 if i % 2 == 0 else -1.0)
				var x1 := -x0
				var hw := size * 0.006
				var q := [Vector3(x0 - hw, y0, 0.0), Vector3(x1 - hw, y1, 0.0), Vector3(x1 + hw, y1, 0.0), Vector3(x0 + hw, y0, 0.0)]
				for e2 in [0, 1, 2, 0, 2, 3]:
					ribbon.set_uv(Vector2(float(order[0]), 0.0))
					ribbon.add_vertex(q[e2])
				_starts.append(Vector3((x0 + x1) * 0.5 if i > 0 else 0.0, y0, 0.0))
				_ends.append(Vector3((x0 + x1) * 0.5, y1, 0.0))
				order[0] += 1
		var mesh := lines.commit()
		ribbon.commit(mesh)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _mat
		add_child(mi)
		_live_mesh = ImmediateMesh.new()
		_live = MeshInstance3D.new()
		_live.mesh = _live_mesh
		var lm := ShaderMaterial.new()
		lm.shader = _mat.shader
		lm.set_shader_parameter("opacity", 0.85)
		_live.material_override = lm
		add_child(_live)

	## The thread being laid, from a to b (its parent's space); INF: none.
	func live(a: Vector3, b: Vector3) -> void:
		_live_mesh.clear_surfaces()
		if a == Vector3.INF:
			return
		var inv := transform.affine_inverse()
		_live_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		_live_mesh.surface_set_uv(Vector2.ZERO)
		_live_mesh.surface_add_vertex(inv * a)
		_live_mesh.surface_set_uv(Vector2.ZERO)
		_live_mesh.surface_add_vertex(inv * b)
		_live_mesh.surface_end()

	# --- the silk to walk on: every thread spun, as a graph ---------------------
	var _gp: Array[Vector3] = [] # (its points, local)
	var _gadj: Array = [] # (each point's neighbours along the silk)
	var _gseg: Array = [] # (each thread: [a, b, its points along it: [t, id]])
	var _drags: Array = [] # (draglines: [a, b], local)
	var _drag_mesh: ImmediateMesh
	const EPS := 0.0015

	## Thread i spun: on the silk to walk on.
	func add_thread(i: int) -> void:
		if i >= 0 and i < _starts.size():
			_gadd(_starts[i], _ends[i])

	## A dragline paid out from a to b (its parent's space): silk too.
	func add_dragline(a: Vector3, b: Vector3) -> void:
		var inv := transform.affine_inverse()
		var la := inv * a
		var lb := inv * b
		_drags.append([la, lb])
		if _drag_mesh == null:
			_drag_mesh = ImmediateMesh.new()
			var mi := MeshInstance3D.new()
			mi.mesh = _drag_mesh
			var lm := ShaderMaterial.new()
			lm.shader = _mat.shader
			lm.set_shader_parameter("opacity", 0.6)
			mi.material_override = lm
			add_child(mi)
		_drag_mesh.clear_surfaces()
		_drag_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for d: Array in _drags:
			for p: Vector3 in d:
				_drag_mesh.surface_set_uv(Vector2.ZERO)
				_drag_mesh.surface_add_vertex(p)
		_drag_mesh.surface_end()
		_gadd(la, lb)

	func _link(i: int, j: int) -> void:
		if i == j:
			return
		if not (_gadj[i] as Array).has(j):
			(_gadj[i] as Array).append(j)
		if not (_gadj[j] as Array).has(i):
			(_gadj[j] as Array).append(i)

	func _unlink(i: int, j: int) -> void:
		(_gadj[i] as Array).erase(j)
		(_gadj[j] as Array).erase(i)

	## (The point at p: one there already, or a new one, set into whatever
	## thread it lies on.)
	func _gnode(p: Vector3) -> int:
		for k in _gp.size():
			if _gp[k].distance_to(p) < EPS:
				return k
		var id := _gp.size()
		_gp.append(p)
		_gadj.append([])
		for s: Array in _gseg:
			var a: Vector3 = s[0]
			var b: Vector3 = s[1]
			var ab := b - a
			var t := (p - a).dot(ab) / maxf(ab.length_squared(), 1e-12)
			if t <= 0.0 or t >= 1.0 or (a + ab * t).distance_to(p) > EPS:
				continue
			var ids: Array = s[2]
			var j := 0
			while j < ids.size() and float(ids[j][0]) < t:
				j += 1
			if j > 0 and j < ids.size():
				_unlink(int(ids[j - 1][1]), int(ids[j][1]))
			if j > 0:
				_link(int(ids[j - 1][1]), id)
			if j < ids.size():
				_link(id, int(ids[j][1]))
			ids.insert(j, [t, id])
		return id

	func _gadd(a: Vector3, b: Vector3) -> void:
		_gnode(a)
		_gnode(b)
		var ab := b - a
		var L2 := maxf(ab.length_squared(), 1e-12)
		var ids := []
		for k in _gp.size():
			var t := (_gp[k] - a).dot(ab) / L2
			if t >= -1e-4 and t <= 1.0001 and (a + ab * t).distance_to(_gp[k]) < EPS:
				ids.append([t, k])
		ids.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
		for j in ids.size() - 1:
			_link(int(ids[j][1]), int(ids[j + 1][1]))
		_gseg.append([a, b, ids])

	## The way along the silk from a to b (its parent's space): the points to
	## go through, b last; empty if there's no way (no silk there yet).
	func route(a: Vector3, b: Vector3) -> Array:
		var inv := transform.affine_inverse()
		var la := inv * a
		var lb := inv * b
		var from := -1
		var to := -1
		var fd := EPS * 4.0
		var td := EPS * 4.0
		for k in _gp.size():
			var d1 := _gp[k].distance_to(la)
			var d2 := _gp[k].distance_to(lb)
			if d1 < fd:
				fd = d1
				from = k
			if d2 < td:
				td = d2
				to = k
		if from < 0 or to < 0:
			return []
		# (the shortest way: Dijkstra's, near enough for a web)
		var dist := {from: 0.0}
		var prev := {}
		var open := [from]
		var done := {}
		while not open.is_empty():
			var best := 0
			for k in open.size():
				if float(dist[open[k]]) < float(dist[open[best]]):
					best = k
			var u: int = open[best]
			open.remove_at(best)
			if u == to:
				break
			done[u] = true
			for v: int in _gadj[u]:
				if done.has(v):
					continue
				var nd := float(dist[u]) + _gp[u].distance_to(_gp[v])
				if not dist.has(v) or nd < float(dist[v]):
					if not dist.has(v):
						open.append(v)
					dist[v] = nd
					prev[v] = u
		if not dist.has(to):
			return []
		var path := []
		var k := to
		while k != from:
			path.push_front(transform * _gp[k])
			k = prev[k]
		path.append(b)
		return path

	## Where thread i starts (its parent's space).
	func start(i: int) -> Vector3:
		return transform * _starts[clampi(i, 0, _starts.size() - 1)]

	func count() -> int:
		return _ends.size()

	## Where the spider is when it's laid thread i (its parent's space).
	func point(i: int) -> Vector3:
		return transform * _ends[clampi(i, 0, _ends.size() - 1)]

	func hub() -> Vector3:
		return transform * _hub

	func normal() -> Vector3:
		return _n

	func _process(_dt: float) -> void:
		_mat.set_shader_parameter("built", built)


## A male spider's sperm web (his, before he goes to find a female): a
## little sheet of silk a few mm off the ground on threads to its corners;
## the drop of sperm he lays on it, milky (drop, 0..1), drawn up again into
## his palps; left there.
class SpermWeb extends Node3D:
	var across := 0.01 # m
	var built := 0.0
	var drop := 0.0
	var left := false
	var _sheet: MeshInstance3D
	var _drop: MeshInstance3D
	var _threads: Array[MeshInstance3D] = []
	var _gone := 0.0

	func _ready() -> void:
		var silk := StandardMaterial3D.new()
		silk.albedo_color = Color(0.95, 0.95, 0.93, 0.6)
		silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		silk.cull_mode = BaseMaterial3D.CULL_DISABLED
		silk.roughness = 0.6
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		_sheet = MeshInstance3D.new()
		_sheet.mesh = q
		_sheet.rotation.x = -PI * 0.5
		_sheet.material_override = silk
		add_child(_sheet)
		var c := CylinderMesh.new()
		c.top_radius = 0.5
		c.bottom_radius = 0.5
		c.height = 1.0
		c.radial_segments = 4
		c.rings = 1
		for k in 4:
			var th := MeshInstance3D.new()
			th.mesh = c
			th.material_override = silk
			add_child(th)
			_threads.append(th)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 10
		s.rings = 6
		var milk := StandardMaterial3D.new()
		milk.albedo_color = Color(0.93, 0.92, 0.86)
		milk.roughness = 0.15
		_drop = MeshInstance3D.new()
		_drop.mesh = s
		_drop.material_override = milk
		add_child(_drop)

	func _process(dt: float) -> void:
		var h := across * 0.35
		var w := across * built
		_sheet.position = Vector3(0.0, h, 0.0)
		_sheet.scale = Vector3(maxf(w, 1e-5), maxf(w * 0.8, 1e-5), 1.0)
		_sheet.visible = built > 0.01
		for k in 4:
			var cx := (0.5 if k % 2 == 0 else -0.5) * w
			var cz := (0.4 if k < 2 else -0.4) * w
			var a := Vector3(cx, h, cz)
			var b := Vector3(cx * 1.6, 0.0, cz * 1.6)
			var d := a - b
			_threads[k].visible = built > 0.3
			var q := Quaternion(Vector3.UP, d.normalized()) if d.length() > 1e-6 else Quaternion()
			_threads[k].transform = Transform3D(Basis(q) * Basis.from_scale(Vector3(across * 0.01, maxf(d.length(), 1e-5), across * 0.01)), (a + b) * 0.5)
		_drop.visible = drop > 0.01
		_drop.position = Vector3(0.0, h + across * 0.05 * drop, 0.0)
		_drop.scale = Vector3(1.0, 0.6, 1.0) * across * 0.22 * drop
		if left:
			_gone += dt
			if _gone > 60.0:
				queue_free()
