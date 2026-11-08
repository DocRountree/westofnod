class_name Crayfish
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A crayfish (a mudbug), drawn life size (hexapod.gd's motor: its eight
## walking legs; its own build): the cephalothorax under its smooth shell
## (the carapace), its pointed rostrum between the eyes on their stalks, the
## cervical groove across it, the areola down its back; the long antennae
## (as long as it is), their scales at their bases, the short forked
## antennules flicking; the third maxillipeds over its mouth, working; the
## big claws (the chelipeds): the merus, the carpus, the hand and its two
## fingers (the dactyl the inner one, hinged); four pairs of walking legs;
## the abdomen's six segments, their side plates (the pleura), the
## swimmerets under them; the tail fan (the telson and the uropods). Its
## shell wet, glossy. The species (_spec): RedSwampCrayfish (Procambarus
## clarkii), VirileCrayfish (Faxonius virilis). Young (Crayfish.new(true)):
## tiny, pale, growing; a soft one, just moulted, pale too, colouring again.
## Not yet in the game (tools/creatures/ecology_demo.tscn).
##
## - wander(centre, radius): walking slowly over the bottom (or the bank),
##   stopping, its antennae sweeping, the antennules flicking
## - forage(centre, radius): about the bottom, stopping to pick at it with
##   its small front walking legs (their own little pincers), bits to its
##   mouth, its mouthparts working
## - eat(food): to it where it lies (not moved): down over it, its claws
##   either side of it, its small legs on it, its mouth on each next bite
##   (Meal), bitten off there
## - hunt(prey): creeping up to it, the claws open; a lunge, the claws
##   snapped shut on it (pinning it where it is); eaten as eat
## - threat(at): turned to it, reared up on its legs, its claws raised high
##   and wide open, snapping; then down, and on
## - flee(from): the tail flip: the abdomen snapped under it, again and
##   again, darting backward through the water (on land a lurch), its claws
##   together before it, its legs trailing; then settled, facing back
## - burrow(at): a burrow dug at the water's edge (the red swamp's, its
##   chimney of mud pellets built up round its mouth, ring on ring); then in
##   it, backing down out of sight (out again: any other action)
## - moult(): over on its side, working, the shell split between the
##   carapace and the abdomen, and it pulls itself out backward; the cast
##   shell (the exuvia) left, pale, whole; it soft and pale a while, a little
##   bigger, colouring again
## - mate(her) (hexapod's mate: he leads): face to face, their claws raised,
##   touching; he takes her claws in his, turns her over onto her back, and
##   lies over her, holding her; then lets go and she turns back
## - lay(): (a female's) "in berry": her eggs, a dark cluster under her
##   abdomen on her swimmerets, her tail curled down over them, the
##   swimmerets fanning them; hatch(): the young out, clinging under her, a
##   while, then off on their own, tiny, growing
## Steering (pilot.gd): act forage {centre, radius}, eat {food}, hunt
## {prey}, threat {at}, flee {from}, burrow {at}, moult, lay, hatch; mate
## {partner}.

const MealScript := preload("res://scripts/creatures/meal.gd")
const ADULT := 0.5 ## its size grown: hexapod draws at twice life size; this, life size
const YOUNG := 0.07
const MOUTH := Vector3(0.0, -6.5, -30.0) ## mm: its mouth, under the rostrum
const SHOULDER := Vector3(7.5, -6.0, -22.0) ## mm: the right claw's base
## a claw's pose: [out (yaw), up (pitch), the elbow bent in, the wrist in, the wrist up, open]
const CL_REST := [0.3, -0.18, 0.6, 0.15, -0.05, 0.08]
const CL_WALK := [0.25, -0.05, 0.55, 0.15, 0.0, 0.05]
const CL_REACH := [0.12, -0.38, 0.2, 0.05, -0.1, 0.85]
const CL_PIN := [0.18, -0.42, 0.3, 0.1, -0.15, 0.12]
const CL_THREAT := [0.95, 1.05, 0.55, -0.25, 0.25, 1.0]
const CL_FLIP := [-0.05, 0.08, 0.12, 0.0, 0.0, 0.0]
const CL_GRIP := [0.02, 0.05, 0.15, 0.05, 0.0, 0.15]
const CL_SCOOP := [0.05, -0.45, 0.35, 0.3, -0.2, 0.4]
const TAIL_REST := [0.05, 0.06, 0.08, 0.1, 0.12, 0.15] ## each joint's curl under (rad)
const TAIL_FLIP := [0.55, 0.6, 0.62, 0.6, 0.55, 0.5]
const TAIL_BERRY := [0.18, 0.22, 0.25, 0.25, 0.25, 0.3]
const SEG_L := [7.0, 8.0, 8.0, 8.0, 7.5, 7.0]

var young := false
var S: Dictionary ## the species' (_spec)
var water_y := INF ## (its pond's surface: under it, it swims its flips; INF: none)
var berried := false ## (a female's: her eggs under her)
var brood: Array[Node3D] = [] ## its young, hatched
var burrow_at := Vector3.INF ## its burrow's mouth (once dug)
var pond := Rect2() ## its pond (x, z: banks and all), if it has one: in it, out of it by its ramp
var ramp: Array = [] ## its pond's sloping bank: [its foot, its top, its half width]; in and out that way
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.3
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _food: Node3D
var _prey: Node3D
var _meal: Node3D
var _at := Vector3.ZERO
var _chew := 0.0
var _flick := 0.0
var _sweep := 0.0
var _soft := 0.0 # (just moulted: 1 pale, soft .. 0 its colour)
var _fan := 0.6 # (the tail fan: 0 shut .. 1 spread)
var _cl_ask := [CL_REST, CL_REST]
var _cl_now := [CL_REST.duplicate(), CL_REST.duplicate()]
var _cl_rate := 5.0
var _tail_ask := TAIL_REST
var _tail_now := TAIL_REST.duplicate()
var _tail_rate := 4.0
var _flips := 0
var _flip_v := 0.0
var _bite := 0.0 # (its front's pitch, eating: its mouth to the next bite)
var _swim_h := 0.0 # (m: swum up off the bottom, after food over it in the water)
var _swim_want := 0.0
var _mother: Node3D
var _ride_t := 0.0
var _ride_at := Vector3.ZERO
var _exuvia: Node3D
var _chimney: MultiMeshInstance3D
var _hole: MeshInstance3D
var _pellets := 0

# its parts
var _claws: Array = [] # each side: [shoulder, elbow, wrist, dactyl]
var _tail: Array[Node3D] = []
var _uropods: Array[Node3D] = []
var _swimmerets: Array[Node3D] = []
var _antennae: Array[Node3D] = []
var _antennules: Array[Node3D] = []
var _maxillipeds: Array[Node3D] = []
var _pincers: Array[Node3D] = [] # (the first two pairs of walking legs' little pincers)
var _eggs: MultiMeshInstance3D
var _mats: Array = [] # [material, its colour]
static var _dot_mesh: SphereMesh


## The species' look and size (the red swamp's here; its own script's).
func _spec() -> Dictionary:
	return {}


func _init(young_ := false) -> void:
	young = young_
	S = _spec()
	super(young_, YOUNG if young_ else ADULT * float(S.get("size", 1.0)))
	body_h = 13.0
	walk_speed = 0.07
	stride = 10.0
	step_time = 0.16
	mate_secs = 22.0
	tripod = [[0, 3, 4, 7], [1, 2, 5, 6]]
	var lens := [[10.0, 10.0, 6.0], [11.0, 11.0, 6.0], [12.0, 12.0, 6.5], [12.0, 12.0, 7.0]]
	var hips := [Vector3(6.0, -7.0, -15.0), Vector3(7.0, -7.5, -9.0), Vector3(7.0, -7.5, -3.0), Vector3(6.5, -7.0, 3.0)]
	var homes := [Vector2(19.0, -25.0), Vector2(24.0, -12.0), Vector2(25.0, 1.0), Vector2(21.0, 15.0)]
	var L := []
	for p in 4:
		var l: Array = lens[p]
		L.append({"hip": hips[p], "f": l[0], "t": l[1], "s": l[2], "home": homes[p],
				"dangle": Vector3(14.0, -6.0, -14.0 + 8.0 * p), "pole": Vector3(0.4, 1.0, -0.2 + 0.15 * p), "r": 0.95, "femur_r": 1.5})
	legs = L


func _male_size() -> float:
	return 1.05 # (his claws, and he, a little bigger)


# --- its build ---------------------------------------------------------------------

func _paint(c: Color, rough := 0.3) -> StandardMaterial3D:
	var m := _mat(c, rough)
	m.clearcoat_enabled = true # (wet: glossy)
	m.clearcoat = 0.7
	m.clearcoat_roughness = 0.15
	_mats.append([m, c])
	return m


func _mottled(c: Color, mottle: float) -> ShaderMaterial:
	var m := _banded(c, 0.0, 0.0, mottle, 0.75)
	_mats.append([m, c])
	return m


func _build() -> void:
	var shell := _paint(S.shell, 0.28)
	var back := _paint(S.back, 0.3)
	var tail := _paint(S.tail, 0.28)
	var groove := _paint((S.shell as Color).darkened(0.45), 0.4)
	var claw := _mottled(S.claw, float(S.get("claw_mottle", 0.15)))
	var tuber := _paint(S.tuber, 0.25)
	var tip := _paint(S.tip, 0.2)
	var leg := _paint(S.leg, 0.35)
	var dots := _paint(S.dots, 0.3)
	var ant := _paint(S.antenna, 0.4)
	var pale := _paint((S.tail as Color).lightened(0.25), 0.5)
	var eye := _mat(Color(0.03, 0.03, 0.03), 0.05)
	# the carapace, smooth, round in section; the rostrum, flat, pointed,
	# its edges raised a little
	var car := [[-30.0, 2.0, 3.0, 2.5], [-26.0, 1.5, 6.5, 6.0], [-20.0, 1.0, 9.0, 8.5], [-12.0, 0.5, 11.0, 10.0], [-2.0, 0.0, 12.0, 10.5], [6.0, 0.0, 11.5, 9.5], [10.5, -0.5, 9.5, 7.5]]
	_mesh_on(_loft(car, 2.2), shell, _body)
	_mesh_on(_loft([[-41.0, 4.2, 0.35, 0.3], [-37.0, 4.0, 1.5, 0.7], [-32.0, 3.6, 2.6, 1.2], [-27.0, 3.0, 3.2, 1.6]], 2.0), shell, _body)
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(1.4 * side, 4.8, -37.0), Vector3(2.6 * side, 4.4, -28.0), 0.35, shell)
	# the cervical groove round its back, and the areola's two lines
	var prev := Vector3.ZERO
	for k in 9:
		var a := lerpf(-1.25, 1.25, float(k) / 8.0)
		var q := Vector3(10.6 * sin(a), 0.5 + 9.8 * cos(a), -12.0 + 1.5 * absf(sin(a)))
		if k > 0:
			_stick(prev, q, 0.32, groove)
		prev = q
	var ar := float(S.get("areola", 2.0))
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(ar * side, 10.6, -11.5), Vector3(ar * 0.8 * side, 10.0, 6.0), 0.25, groove)
	# its spots (the red swamp's pale dots; the virile's dark speckling)
	var pts := PackedVector3Array()
	var rr := RandomNumberGenerator.new()
	rr.seed = 5
	for k in int(S.get("dot_n", 80)):
		var z := rr.randf_range(-26.0, 9.0)
		var hw := _key_at(car, z, 2)
		var hh := _key_at(car, z, 3)
		var yc := _key_at(car, z, 1)
		var a := rr.randf_range(-1.35, 1.35)
		pts.append(Vector3(hw * sin(a) * 1.02, yc + hh * cos(a) * 1.02, z))
	_dots(_body, pts, float(S.get("dot_r", 0.5)), dots)
	# the eyes, on their stalks
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(3.0 * side, 2.5, -28.5), Vector3(5.0 * side, 3.8, -32.0), 1.0, shell)
		_part(Vector3(5.3 * side, 4.0, -32.6), Vector3(3.0, 3.0, 3.2), eye)
	# the antennae: the peduncle, the scale (the scaphocerite), the long whip
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(4.0 * side, -1.0, -30.0), Vector3(5.5 * side, -0.5, -36.0), 1.3, shell)
		_stick(Vector3(5.5 * side, -0.5, -36.0), Vector3(6.2 * side, -0.4, -41.0), 0.9, ant)
		_part(Vector3(7.0 * side, 0.2, -38.0), Vector3(2.6, 0.6, 9.0), shell)
		var root := Node3D.new()
		root.position = Vector3(6.2 * side, -0.4, -41.0)
		_body.add_child(root)
		var at := Vector3.ZERO
		var dir := Vector3(0.45 * side, 0.12, -1.0).normalized()
		var n := 14
		for k in n:
			var l := 6.0
			var nx := at + dir * l
			_stick(at, nx, lerpf(0.55, 0.14, float(k) / (n - 1)), ant, root)
			at = nx
			dir = dir.rotated(Vector3.UP, -0.2 * side).rotated(Vector3.RIGHT, -0.02)
		root.set_meta("side", side)
		_antennae.append(root)
		# the antennules: short, forked, flicking
		var au := Node3D.new()
		au.position = Vector3(1.6 * side, 1.5, -33.0)
		_body.add_child(au)
		_stick(Vector3.ZERO, Vector3(0.6 * side, 0.4, -6.0), 0.5, shell, au)
		for f: float in [-1.0, 1.0]:
			_stick(Vector3(0.6 * side, 0.4, -6.0), Vector3((0.6 + 1.6 * f) * side, 1.8, -17.0), 0.2, ant, au)
		au.set_meta("side", side)
		_antennules.append(au)
		# the third maxillipeds over its mouth
		var mx := Node3D.new()
		mx.position = Vector3(1.6 * side, -6.0, -25.0)
		_body.add_child(mx)
		_stick(Vector3.ZERO, Vector3(-0.4 * side, -0.6, -8.0), 0.7, leg, mx)
		mx.set_meta("side", side)
		_maxillipeds.append(mx)
	# the claws: the merus, the carpus, the hand, its fingers; tubercles
	for side: float in [-1.0, 1.0]:
		_claws.append(_claw(side, claw, tuber, tip, shell))
	# the abdomen: six segments, each lapping the next, its side plates; the
	# swimmerets under them; the tail fan
	var hws := [9.6, 9.8, 9.4, 8.8, 7.8, 6.6]
	var hhs := [5.4, 5.6, 5.4, 5.0, 4.4, 3.8]
	var parent: Node3D = _body
	for k in 6:
		var sn := Node3D.new()
		sn.position = Vector3(0.0, -1.0, 9.0) if k == 0 else Vector3(0.0, 0.0, SEG_L[k - 1])
		parent.add_child(sn)
		var l: float = SEG_L[k]
		var hw: float = hws[k]
		var hh: float = hhs[k]
		# (one smooth taper down it: each segment the size of the last where they
		# meet, lapping it a little; flat beneath)
		var hw0: float = hws[maxi(k - 1, 0)] if k > 0 else hw * 1.02
		var hh0: float = hhs[maxi(k - 1, 0)] if k > 0 else hh * 1.05
		_mesh_on(_loft([[-1.8, 0.0, hw0 * 0.97, hh0 * 0.96], [l * 0.45, 0.0, hw, hh], [l + 1.2, -0.1, (hw + float(hws[mini(k + 1, 5)])) * 0.5, (hh + float(hhs[mini(k + 1, 5)])) * 0.5]], 2.7), tail, sn)
		for e in 4: # (its back edge, lapping the next: a fine line over its back)
			var a0 := lerpf(-1.3, 1.3, e / 4.0)
			var a1 := lerpf(-1.3, 1.3, (e + 1) / 4.0)
			_stick(Vector3(hw * sin(a0), hh * cos(a0), l + 0.6), Vector3(hw * sin(a1), hh * cos(a1), l + 0.6), 0.22, groove, sn)
		for s2: float in [-1.0, 1.0]: # (the pleura)
			var pl := _part(Vector3(hw * 0.9 * s2, -hh * 0.6, l * 0.5), Vector3(1.4, hh * 0.75, l * 0.9), tail, sn)
			pl.rotation = Vector3(0.0, 0.0, 0.3 * s2)
		if S.get("wedge", false): # (the red swamp's black wedge down its back)
			_part(Vector3(0.0, hh * 0.93, l * 0.5), Vector3(hw * lerpf(0.75, 0.25, k / 5.0), 0.5, l * 1.05), back, sn)
		if S.get("blotch", false): # (the virile's paired dark blotches)
			for s2: float in [-1.0, 1.0]:
				var bl := _part(Vector3(hw * 0.42 * s2, hh * 0.86, l * 0.45), Vector3(hw * 0.38, 0.45, l * 0.5), back, sn)
				bl.rotation = Vector3(0.0, 0.0, -0.35 * s2)
		if k < 5: # (the swimmerets, a pair a segment)
			for s2: float in [-1.0, 1.0]:
				var sw := Node3D.new()
				sw.position = Vector3(hw * 0.35 * s2, -hh * 0.75, l * 0.5)
				sn.add_child(sw)
				_stick(Vector3.ZERO, Vector3(0.6 * s2, -4.0, -1.5), 0.35, pale, sw)
				_stick(Vector3(0.6 * s2, -4.0, -1.5), Vector3(0.9 * s2, -5.5, 0.5), 0.2, pale, sw)
				_swimmerets.append(sw)
		_tail.append(sn)
		parent = sn
	var tel := Node3D.new()
	tel.position = Vector3(0.0, -0.3, SEG_L[5])
	parent.add_child(tel)
	_part(Vector3(0.0, 0.0, 6.5), Vector3(8.5, 1.5, 13.0), tail, tel)
	for side: float in [-1.0, 1.0]:
		for k in 2: # (the inner and outer uropods, fanned)
			var u := Node3D.new()
			u.position = Vector3((2.5 + 2.5 * k) * side, -0.3 - 0.2 * k, 0.5)
			tel.add_child(u)
			_part(Vector3(0.0, 0.0, 6.5), Vector3(6.5, 1.2, 13.0 - k), tail, u)
			_stick(Vector3(-2.5 * side, 0.4, 12.5 - k), Vector3(2.5 * side, 0.4, 12.5 - k), 0.25, groove, u) # (the outer's suture)
			u.set_meta("side", side)
			u.set_meta("k", k)
			_uropods.append(u)
	_tail.append(tel)
	# the walking legs (the hexapod's), the first two pairs with little pincers
	_build_legs(leg, leg)
	for i in 4:
		var c := Node3D.new()
		_body.add_child(c)
		for f: float in [-1.0, 1.0]:
			_stick(Vector3.ZERO, Vector3(0.35 * f, 0.0, 2.2), 0.22, tip, c)
		_pincers.append(c)
	# her eggs, when she's in berry: a dark cluster under the abdomen
	var em := MultiMesh.new()
	em.transform_format = MultiMesh.TRANSFORM_3D
	em.mesh = _dots_mesh()
	var ep := PackedVector3Array()
	var er := RandomNumberGenerator.new()
	er.seed = 9
	for k in 160:
		ep.append(Vector3(er.randf_range(-6.0, 6.0), er.randf_range(-11.0, -5.0), er.randf_range(10.0, 40.0)))
	em.instance_count = ep.size()
	for k in ep.size():
		em.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ONE * 2.2), ep[k]))
	_eggs = MultiMeshInstance3D.new()
	_eggs.multimesh = em
	_eggs.material_override = _paint(S.get("egg", Color(0.18, 0.1, 0.06)), 0.2)
	_body.add_child(_eggs)
	_eggs.visible = false
	_colour()


## (A claw on its side: its nodes [shoulder, elbow, wrist, dactyl].)
func _claw(side: float, claw: Material, tuber: Material, tip: Material, shell: Material) -> Array:
	var mr := float(S.get("merus_r", 1.9))
	var pw := float(S.get("palm_w", 3.6))
	var ph := float(S.get("palm_h", 3.0))
	var pl := float(S.get("palm_l", 19.0))
	var fl := float(S.get("finger_l", 20.0))
	var sh := Node3D.new()
	sh.position = Vector3(SHOULDER.x * side, SHOULDER.y, SHOULDER.z)
	_body.add_child(sh)
	_part(Vector3.ZERO, Vector3.ONE * mr * 2.2, shell, sh)
	_mesh_on(_loft([[0.0, 0.0, mr * 0.9, mr], [-6.0, 0.0, mr * 1.1, mr * 1.25], [-18.0, 0.0, mr * 1.05, mr * 1.3], [-23.0, 0.0, mr * 0.9, mr * 1.0]], 2.0), claw, sh)
	var el := Node3D.new()
	el.position = Vector3(0.0, 0.0, -23.0)
	sh.add_child(el)
	_part(Vector3(0.0, 0.0, -4.5), Vector3(mr * 2.3, mr * 2.2, 10.0), claw, el)
	var wr := Node3D.new()
	wr.position = Vector3(0.0, 0.0, -9.0)
	el.add_child(wr)
	var hand := [[0.5, 0.0, pw * 0.55, ph * 0.7], [-4.0, 0.0, pw, ph], [-pl * 0.7, 0.0, pw, ph * 0.95], [-pl, 0.0, pw * 0.8, ph * 0.75]]
	_mesh_on(_loft(hand, 2.0), claw, wr)
	# the fixed finger (outer), the dactyl (inner, hinged)
	var a := Vector3(pw * 0.35 * side, 0.0, -pl + 0.5)
	var b := Vector3(pw * 0.3 * side, 0.0, -pl - fl * 0.6)
	var c := Vector3(pw * 0.05 * side, 0.1, -pl - fl)
	_stick(a, b, ph * 0.55, claw, wr)
	_stick(b, c, ph * 0.3, tip, wr)
	var dc := Node3D.new()
	dc.position = Vector3(-pw * 0.45 * side, 0.0, -pl + 0.5)
	wr.add_child(dc)
	_stick(Vector3.ZERO, Vector3(0.15 * pw * side, 0.0, -fl * 0.6), ph * 0.5, claw, dc)
	_stick(Vector3(0.15 * pw * side, 0.0, -fl * 0.6), Vector3(0.45 * pw * side, 0.1, -fl), ph * 0.28, tip, dc)
	# the tubercles over the hand and fingers (and spines, the red swamp's)
	var pts := PackedVector3Array()
	var rr := RandomNumberGenerator.new()
	rr.seed = 3 + int(side)
	for k in int(S.get("tuber_n", 40)):
		var z := rr.randf_range(-pl * 0.95, -2.0)
		var ang := rr.randf_range(-2.3, 2.3)
		pts.append(Vector3(pw * 0.98 * sin(ang), ph * 0.98 * cos(ang), z))
	for k in 10: # (along the fingers' edges)
		var f := rr.randf()
		pts.append(a.lerp(c, f) + Vector3(0.0, ph * 0.3, 0.0))
	_dots(wr, pts, float(S.get("tuber_r", 0.6)), tuber)
	if S.get("spines", false):
		for k in 4:
			var z := -4.0 - 4.5 * k
			_stick(Vector3(-mr * 0.8 * side, mr * 0.6, z), Vector3(-mr * 1.7 * side, mr * 1.1, z - 1.5), 0.3, tuber, sh)
		_stick(Vector3(-mr * 0.9 * side, mr * 0.8, -3.0), Vector3(-mr * 1.9 * side, mr * 1.4, -5.0), 0.35, tuber, el)
	return [sh, el, wr, dc]


func _mesh_on(m: Mesh, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func _dots_mesh() -> SphereMesh:
	if _dot_mesh == null:
		_dot_mesh = SphereMesh.new()
		_dot_mesh.radius = 0.5
		_dot_mesh.height = 1.0
		_dot_mesh.radial_segments = 6
		_dot_mesh.rings = 3
	return _dot_mesh


## (Little bumps, all one draw: at pts (parent's mm), r round.)
func _dots(parent: Node3D, pts: PackedVector3Array, r: float, mat: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _dots_mesh()
	mm.instance_count = pts.size()
	for k in pts.size():
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(r, r * 0.7, r) * 2.0), pts[k]))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## (A loft's keys' value c at z, straight between them.)
static func _key_at(keys: Array, z: float, c: int) -> float:
	for k in keys.size() - 1:
		var a: Array = keys[k]
		var b: Array = keys[k + 1]
		if z >= float(a[0]) and z <= float(b[0]):
			return lerpf(float(a[c]), float(b[c]), (z - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-4))
	return float((keys[0] if z < float((keys[0] as Array)[0]) else keys[keys.size() - 1])[c])


## Its colours now: a youngster's pale, translucent; just moulted, pale.
func _colour() -> void:
	var pale := 0.0
	if young:
		pale = clampf(1.0 - (size - YOUNG) / 0.2, 0.0, 1.0) * 0.6
	pale = maxf(pale, _soft * 0.55)
	for e: Array in _mats:
		var c: Color = (e[1] as Color).lerp(Color(0.72, 0.68, 0.6), pale)
		if e[0] is StandardMaterial3D:
			(e[0] as StandardMaterial3D).albedo_color = c
		else:
			(e[0] as ShaderMaterial).set_shader_parameter("base", c)


func _pose_legs() -> void:
	# (swum up off the bottom: any leg not posed otherwise tucked, paddling,
	# never reaching down to where its foot was on the floor)
	if _swim_h > 0.002:
		for i in _pose_foot.size():
			if _pose_foot[i] == null:
				var L: Dictionary = legs[i / 2]
				var side := 1.0 if i % 2 == 1 else -1.0
				var hp: Vector3 = L.hip
				var ph := _t * 7.0 + i * 0.8
				_pose_foot[i] = Vector3(hp.x * side * 1.7, hp.y - 7.0 + 1.5 * sin(ph), hp.z + 3.0 * cos(ph))
	super()
	for i in _pincers.size():
		var ts := _leg_mesh[i][2] as MeshInstance3D
		var foot := ts.transform * Vector3(0.0, 0.5, 0.0)
		var along := ts.transform.basis.y.normalized()
		var x := along.cross(Vector3.UP).normalized() if absf(along.y) < 0.95 else Vector3.RIGHT
		var y := x.cross(along).normalized()
		_pincers[i].transform = Transform3D(Basis(x, y, along), foot)


# --- what it does --------------------------------------------------------------

func _begin(m: String) -> void:
	if _mate_role != "": # (mating: given up, both of them; she's turned back up)
		var was := _mate
		_end_mate()
		if is_instance_valid(was) and was.get("_mate_role") != "":
			was.call("_end_mate")
	if _mode == "burrowed" and m != "burrowed": # (out again)
		visible = true
		_lift = 0.0
	_mode = m
	_stage = 0
	_st = 0.0
	_wait = 0.0
	_pace = -1.0
	_turn_to = INF
	if m != "burrowed":
		_lift = 0.0
	if _body:
		_replant()


## (Its legs folded in under it: on its side, its back, going down its
## burrow, thrown back by its tail: its feet not left planted, stretching.)
func _tuck(spread := 1.0) -> void:
	for i in _pose_foot.size():
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		_pose_foot[i] = Vector3(hp.x * side * (1.0 + 0.6 * spread), hp.y - 6.0, hp.z - 2.0)


## (Its feet set down again under it, where they'd stand: after anything
## that moved it without its walking.)
func _replant() -> void:
	for i in _pose_foot.size():
		_pose_foot[i] = null
	for i in _feet.size():
		_feet[i] = _home(i)
		_from[i] = _feet[i]
		_to[i] = _feet[i]
	_swinging = -1


func wander(centre: Vector3, radius: float) -> void:
	_begin("wander")
	_centre = centre
	_radius = radius


func forage(centre: Vector3, radius: float) -> void:
	_begin("forage")
	_centre = centre
	_radius = radius


func eat(food: Node3D) -> void:
	if food == null or not is_instance_valid(food):
		return
	_begin("eat")
	_food = food
	_meal = null


func hunt(prey: Node3D) -> void:
	if prey == null or not is_instance_valid(prey):
		return
	_begin("hunt")
	_prey = prey
	_food = null
	_meal = null


func threat(at: Vector3) -> void:
	_begin("threat")
	_at = at


func flee(from: Vector3) -> void:
	_begin("flee")
	_at = from
	_flips = 3 + rng.randi() % 3


func burrow(at: Vector3) -> void:
	_begin("burrow")
	_at = at


func moult() -> void:
	if _mode == "moult":
		return
	_begin("moult")


func lay() -> void:
	if young or male:
		return
	_begin("lay")


func hatch() -> void:
	if not berried:
		return
	_begin("hatch")


## The ground at (x, z); but never across a drop from where it is (a pond's
## steep bank): a foot reaching over the edge reads its own level, not the
## bank above it nor the floor below (none stretched up or down the wall).
func _ground(x: float, z: float) -> float:
	var h := super(x, z)
	if not height.is_valid():
		return h
	var here := float(height.call(_pos.x, _pos.z))
	return here if absf(h - here) > 0.04 * maxf(size / ADULT, 0.3) else h


## Whether (x, z) is in its pond (off its sloping bank).
func _in_pond(p: Vector3) -> bool:
	return pond.has_area() and pond.has_point(Vector2(p.x, p.z)) and not _on_ramp(p)


func _on_ramp(p: Vector3) -> bool:
	if ramp.is_empty():
		return false
	var f: Vector3 = ramp[0]
	var t: Vector3 = ramp[1]
	return absf(p.z - f.z) < float(ramp[2]) and p.x >= f.x - 0.01 and p.x <= t.x + 0.02


## (Where to make for, on the way to dest: in or out of its pond by the
## ramp, up its middle; dest itself if it's on the same side.)
func _route(dest: Vector3) -> Vector3:
	if ramp.is_empty() or not pond.has_area():
		return dest
	var here_in := _in_pond(_pos)
	var there_in := _in_pond(dest)
	if not here_in and not there_in and not _on_ramp(_pos):
		return _around(dest) # (land to land: round the pond, not across it)
	if here_in == there_in or (_on_ramp(_pos) and _on_ramp(dest)):
		return dest
	var f: Vector3 = ramp[0]
	var t: Vector3 = ramp[1]
	var bottom := Vector3(f.x - 0.04, f.y, f.z)
	var top := Vector3(t.x + 0.06, t.y, t.z)
	if _on_ramp(_pos): # (on it: on up, or down)
		return top if not there_in else bottom
	return bottom if here_in else top


## (On land, for dest on land: dest, if the way there doesn't cross its pond;
## else the corner of the pond's banks that's the shorter way round.)
func _around(dest: Vector3) -> Vector3:
	var box := pond.grow(0.07)
	var a := Vector2(_pos.x, _pos.z)
	var b := Vector2(dest.x, dest.z)
	if not _crosses(a, b, box):
		return dest
	var best := dest
	var bd := INF
	for c: Vector2 in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
		if c.distance_to(a) < 0.02 or _crosses(a, c, box.grow(-0.01)):
			continue
		var d := a.distance_to(c) + c.distance_to(b)
		if d < bd:
			bd = d
			best = Vector3(c.x, 0.0, c.y)
	best.y = _pos.y
	return best


## (Whether the line a to b goes through box.)
static func _crosses(a: Vector2, b: Vector2, box: Rect2) -> bool:
	for k in 9:
		if box.has_point(a.lerp(b, (k + 0.5) / 9.0)):
			return true
	return false


func _walk(dt: float) -> void:
	var dest := _target
	var was := _pos
	_target = _route(dest)
	super(dt)
	_target = dest
	# (a pond's steep wall: not walked over, up or down; in and out by its
	# sloping bank only)
	if height.is_valid() and absf(float(height.call(_pos.x, _pos.z)) - was.y) > 0.03 * maxf(size / ADULT, 0.3):
		_pos = was
		_speed = 0.0
	_unstretch()


## (No planted foot a drop from it, nor out past its leg's reach: set under
## it again at once, never left stretched to where it was.)
func _unstretch() -> void:
	var sc := MM * size
	for i in _feet.size():
		if _pose_foot[i] != null or i in (tripod[_swinging] if _swinging >= 0 else []):
			continue
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hip := _out(Vector3(float(L.hip.x) * side, float(L.hip.y), float(L.hip.z)))
		var reach := (float(L.f) + float(L.t) + float(L.s)) * sc
		# (a drop from it; or out past its leg's reach: shoved along, say)
		if absf(_feet[i].y - _pos.y) > 0.03 * maxf(size / ADULT, 0.3) or hip.distance_to(_feet[i]) > reach * 1.02:
			_feet[i] = _home(i)


func _touch_ok() -> bool:
	return young or _mother != null or _mate_role != "" or _mode in ["burrowed", "moult"]


## (Food up in the water over it, at the surface, say: swum up off the
## bottom, its mouth to its height, its legs tucked and paddling, its
## swimmerets beating; down again after.)
func _swim_up_to(p: Vector3) -> void:
	if _pos.y >= water_y or p.y > water_y + 0.02:
		return
	var up := p.y - _ground(p.x, p.z)
	if up < 0.015 * size / ADULT:
		return
	_swim_want = maxf(p.y - _pos.y - (body_h - absf(MOUTH.y)) * MM * size, 0.0)


func _place() -> void:
	super()
	if _swim_h > 0.0:
		position.y += _swim_h


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	# (swimming: up to what it's after, or back down to the bottom)
	var was_up := _swim_h > 0.002
	_swim_h = move_toward(_swim_h, _swim_want, dt * 0.06)
	_swim_want = 0.0
	if _swim_h > 0.002:
		for i in _pose_foot.size(): # (its legs tucked, paddling)
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			var ph := _t * 7.0 + i * 0.8
			_pose_foot[i] = Vector3(hp.x * side * 1.7, hp.y - 7.0 + 1.5 * sin(ph), hp.z + 3.0 * cos(ph))
	elif was_up: # (down on the bottom again: its feet set under it)
		_replant()
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_cl_ask = [CL_WALK, CL_WALK] if _speed > 0.01 else [CL_REST, CL_REST]
	_cl_rate = 5.0
	_tail_ask = TAIL_BERRY if berried else TAIL_REST
	_tail_rate = 4.0
	_fan = move_toward(_fan, 0.6, dt)
	_crouch = move_toward(_crouch, 0.0, dt)
	_pitch = lerpf(_pitch, _slope(), 1.0 - exp(-3.0 * dt))
	if _mode not in ["moult", "lay"]: # (turned back up, whatever turned it)
		_roll = lerpf(_roll, 0.0, 1.0 - exp(-2.5 * dt))
	if _soft > 0.0:
		_soft = maxf(_soft - dt / 40.0, 0.0)
		_colour()
	elif young:
		_colour()
	match _mode:
		"wander", "forage", "piloted":
			_roam(dt)
		"eat":
			_eat(dt)
		"hunt":
			_hunt(dt)
		"threat":
			_threat(dt)
		"flee":
			_flee(dt)
		"burrow":
			_burrow(dt)
		"burrowed":
			_target = _pos
		"moult":
			_moult(dt)
		"lay":
			_lay(dt)
		"hatch":
			_hatch(dt)
		"idle":
			_target = _pos


## (The ground's slope under it, nose up: up its pond's bank, say.)
func _slope() -> float:
	var f := _forward() * 0.03 * size / ADULT
	var a := _ground(_pos.x + f.x, _pos.z + f.z)
	var b := _ground(_pos.x - f.x, _pos.z - f.z)
	return atan2(a - b, f.length() * 2.0)


func _forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


## (Wandering, or foraging: stopping to pick at the bottom.)
func _roam(dt: float) -> void:
	if _mode == "piloted":
		return
	match _stage:
		0:
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
				_wait = rng.randf_range(3.0, 8.0)
				if rng.randf() < (0.6 if _mode == "forage" else 0.25):
					_stage = 1
					_st = 0.0
					_target = _pos
					_wait = rng.randf_range(3.0, 6.0)
		1: # (stopped: picking at the bottom with its small pincers, bits to its mouth)
			_target = _pos
			_crouch = move_toward(_crouch, 0.45, dt)
			_pitch = lerpf(_pitch, -0.06, 1.0 - exp(-3.0 * dt))
			_cl_ask = [CL_PIN, CL_PIN]
			if _mode == "forage":
				for i in 4:
					var side := 1.0 if i % 2 == 1 else -1.0
					var ph := fmod(_st * 1.4 + (0.5 if i % 2 == 1 else 0.0) + i * 0.25, 1.0)
					var down := Vector3(4.0 * side, -body_h + 0.5, -32.0 - 2.0 * (i / 2))
					var up := MOUTH + Vector3(1.5 * side, -1.0, 1.5)
					_pose_foot[i] = down.lerp(up, smoothstep(0.3, 0.7, ph) - smoothstep(0.8, 1.0, ph))
				_chew = 1.0
			if _wait <= 0.0:
				_replant()
				_stage = 0
				_wait = 0.0


## (Eating its food where it lies: down over it, its mouth on each next
## bite; the food never moved.)
func _eat(dt: float) -> void:
	var f := _food if is_instance_valid(_food) else null
	if f == null:
		_meal = null
		wander(_pos, 0.25)
		return
	var p := f.global_position
	var to := Vector3(p.x - _pos.x, 0.0, p.z - _pos.z)
	var reach := absf(MOUTH.z) * MM * size
	_swim_up_to(p)
	match _stage:
		0: # (to it, its mouth over it: it eats only once it's there)
			_target = p - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			_cl_ask = [CL_REACH, CL_REACH]
			if _st > 30.0: # (can't get to it)
				_food = null
				wander(_pos, 0.25)
				return
			var level := absf(p.y - _out(MOUTH).y) < 0.02 * maxf(size / ADULT, 0.4) # (its mouth at its height: walked to it, or swum up)
			if to.length() < reach * 1.2 and _speed < 0.01 and level:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
				_bite = 0.0
				MealScript.subdue(f)
				_meal = MealScript.of(f, 4)
		1: # (down over it, its claws either side of it, its small legs on it, chewing)
			_target = _pos
			_cl_ask = [CL_PIN, CL_PIN]
			_chew = 1.0
			_crouch = move_toward(_crouch, 0.8, dt)
			var m := _out(MOUTH)
			var na: Vector3 = _meal.call("next_at") if is_instance_valid(_meal) else p
			_bite = clampf(_bite + clampf((na.y - m.y) * 40.0, -1.0, 1.0) * dt, -0.35, 0.25)
			_pitch = _bite
			var off := Vector3(na.x - m.x, 0.0, na.z - m.z)
			if off.length() > 0.0015:
				_pos += off.limit_length(0.06 * dt)
				_target = _pos
			# (its small front legs on the bite, picking at it, if it's in their
			# reach; else down on the ground before it)
			var on := (_body.global_transform.affine_inverse()) * na
			for i in 4:
				var L: Dictionary = legs[i / 2]
				var side := 1.0 if i % 2 == 1 else -1.0
				var ph := _st * 1.6 + i * 0.7
				var hip := Vector3(float(L.hip.x) * side, float(L.hip.y), float(L.hip.z))
				var lim := (float(L.f) + float(L.t) + float(L.s)) * 0.92
				var want := on + Vector3(2.5 * side * (1.0 + 0.3 * sin(ph)), 1.0 + 0.8 * sin(ph), 2.0 + 1.5 * cos(ph))
				if want.distance_to(hip) > lim:
					_pose_foot[i] = null # (out of its reach: on the ground, walking)
				else:
					_pose_foot[i] = want
			if is_instance_valid(_meal):
				_meal.call("tear", clampf((_st - 1.0) / 14.0, 0.0, 1.0), m)
			if _st > 16.0 or not is_instance_valid(f):
				if is_instance_valid(f):
					f.queue_free()
				_food = null
				_meal = null
				wander(_pos, 0.25)


## (Creeping up on it; the lunge, its claws snapped shut on it; eaten.)
func _hunt(dt: float) -> void:
	if not is_instance_valid(_prey):
		wander(_pos, 0.25)
		return
	var p := _prey.global_position
	var to := Vector3(p.x - _pos.x, 0.0, p.z - _pos.z)
	var reach := (absf(SHOULDER.z) + 50.0) * MM * size
	match _stage:
		0: # (creeping, its claws open before it; swimming up, if it's up in the water)
			_swim_up_to(p)
			_target = p - to.normalized() * reach * 1.4
			_pace = walk_speed * 0.4
			_cl_ask = [CL_REACH, CL_REACH]
			_sweep = 1.0
			if to.length() < reach * 1.6 or _st > 12.0:
				_stage = 1
				_st = 0.0
				_turn_to = atan2(-to.x, -to.z)
		1: # (the lunge, the claws shut on it)
			_swim_up_to(p)
			_pace = walk_speed * 2.5
			_target = p - to.normalized() * reach * 0.8
			_cl_ask = [CL_REACH, CL_REACH] if _st < 0.25 else [CL_PIN, CL_PIN]
			_cl_rate = 25.0
			if _st > 0.45:
				MealScript.subdue(_prey) # (pinned where it is: not lifted)
				_food = _prey
				_prey = null
				_mode = "eat"
				_stage = 0
				_st = 0.0


## (Reared up, its claws raised high and open, snapping; then down.)
func _threat(dt: float) -> void:
	var to := Vector3(_at.x - _pos.x, 0.0, _at.z - _pos.z)
	_target = _pos
	if _stage == 0:
		_turn_to = atan2(-to.x, -to.z)
		_stage = 1
	_lift = move_toward(_lift, 9.0, dt * 25.0)
	_pitch = lerpf(_pitch, 0.4, 1.0 - exp(-5.0 * dt))
	var snap := fmod(_st, 1.6) > 1.3
	var ask := CL_THREAT.duplicate()
	ask[5] = 0.1 if snap else 1.0
	_cl_ask = [ask, ask]
	_cl_rate = 14.0 if snap else 6.0
	_tail_ask = [0.25, 0.25, 0.25, 0.2, 0.15, 0.1]
	_sweep = 1.0
	if _st > 6.0:
		_lift = 0.0
		wander(_pos, 0.25)


## (The tail flip: snapped under it, darting it back; again; then settled.)
func _flee(dt: float) -> void:
	_target = _pos
	_cl_ask = [CL_FLIP, CL_FLIP]
	_cl_rate = 18.0
	var wet := _pos.y < water_y
	var ph := fmod(_st, 0.42)
	if _flips > 0:
		_tail_ask = TAIL_FLIP if ph < 0.12 else TAIL_REST
		_tail_rate = 40.0 if ph < 0.12 else 12.0
		_fan = 1.0
		if ph < dt: # (a flip: thrown back)
			_flip_v = (0.55 if wet else 0.2) * (0.6 + 0.4 * size / ADULT)
			_flips -= 1
		for i in _pose_foot.size(): # (its legs trailing forward)
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			_pose_foot[i] = Vector3(hp.x * side * 1.4, hp.y - 2.0, hp.z - 14.0)
		_lift = move_toward(_lift, 8.0 if wet else 2.0, dt * 40.0)
	else:
		_lift = move_toward(_lift, 0.0, dt * 20.0)
		if _st > 0.5 and _flip_v < 0.02:
			_replant()
			var to := Vector3(_at.x - _pos.x, 0.0, _at.z - _pos.z)
			if to.length() > 0.01:
				_turn_to = atan2(-to.x, -to.z)
			_mode = "threat" if rng.randf() < 0.3 else "wander"
			_stage = 0
			_st = 0.0
			_centre = _pos
	if _flip_v > 0.0:
		var np := _pos - _forward() * _flip_v * dt
		if height.is_valid() and absf(float(height.call(np.x, np.z)) - _pos.y) > 0.03: # (a drop behind it: stopped at its edge, not thrown over)
			_flip_v = 0.0
		else:
			_pos = np
			_pos.y = _ground(_pos.x, _pos.z)
		_flip_v = maxf(_flip_v - dt * (2.2 if wet else 3.0), 0.0)


## (A burrow at _at: dug; the chimney built up round its mouth, pellet by
## pellet; then in, out of sight.)
func _burrow(dt: float) -> void:
	var to := Vector3(_at.x - _pos.x, 0.0, _at.z - _pos.z)
	var reach := 30.0 * MM * size
	match _stage:
		0: # (to it)
			_target = _at - to.normalized() * reach if to.length() > reach else _pos
			if (to.length() < reach * 1.15 and _speed < 0.01) or _st > 20.0:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
				_dig()
		1: # (digging: its claws scooping the mud out, its legs scrabbling)
			_target = _pos
			var sc := fmod(_st, 1.0) < 0.5
			_cl_ask = [CL_SCOOP, CL_FLIP] if sc else [CL_FLIP, CL_SCOOP]
			_cl_rate = 8.0
			_crouch = move_toward(_crouch, 0.6, dt)
			_hole.scale = Vector3.ONE * clampf(_st / 4.0, 0.1, 1.0)
			if _st > 4.0:
				_stage = 2
				_st = 0.0
		2: # (the chimney: a pellet of mud at a time, pressed on with its claws)
			_target = _pos
			_cl_ask = [CL_SCOOP, CL_SCOOP] if fmod(_st, 0.44) < 0.22 else [CL_PIN, CL_PIN]
			_cl_rate = 8.0
			var want := int(_st / 0.22)
			while _pellets < mini(want, _chimney.multimesh.instance_count):
				_pellets += 1
			_chimney.multimesh.visible_instance_count = _pellets
			if _pellets >= _chimney.multimesh.instance_count or not bool(S.get("chimney", true)):
				_stage = 3
				_st = 0.0
		3: # (in: over the hole, backing down out of sight)
			var c := Vector3(_at.x, _pos.y, _at.z)
			_pos = _pos.lerp(c, 1.0 - exp(-3.0 * dt))
			_target = _pos
			_lift = move_toward(_lift, -60.0, dt * 25.0)
			_cl_ask = [CL_FLIP, CL_FLIP]
			_tuck(0.2)
			if _lift <= -45.0:
				_mode = "burrowed"
				visible = false
				burrow_at = _at


## (Its burrow's mouth at _at, and its chimney's pellets, none shown yet.)
func _dig() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var g := _ground(_at.x, _at.z)
	if _hole == null or not is_instance_valid(_hole):
		_hole = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.022
		cm.bottom_radius = 0.022
		cm.height = 0.002
		cm.radial_segments = 14
		_hole.mesh = cm
		_hole.material_override = _mat(Color(0.03, 0.025, 0.02), 1.0)
		parent.add_child(_hole)
	_hole.position = Vector3(_at.x, g + 0.0006, _at.z)
	if _chimney != null and is_instance_valid(_chimney):
		_chimney.queue_free()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _dots_mesh()
	var rings := 8 if bool(S.get("chimney", true)) else 1
	var per := 9
	mm.instance_count = rings * per
	var rr := RandomNumberGenerator.new()
	rr.seed = int(_at.x * 1000.0) ^ int(_at.z * 1000.0)
	for k in rings:
		var r := 0.03 - 0.0012 * k
		for j in per:
			var a := TAU * (j + 0.5 * (k % 2)) / per + rr.randf_range(-0.1, 0.1)
			var p := Vector3(cos(a) * r, 0.005 + k * 0.0075, sin(a) * r)
			var s := rr.randf_range(0.009, 0.012)
			mm.set_instance_transform(k * per + j, Transform3D(Basis(Vector3.UP, rr.randf() * TAU).scaled(Vector3(s, s * 0.75, s)), p))
	mm.visible_instance_count = 0
	_chimney = MultiMeshInstance3D.new()
	_chimney.multimesh = mm
	var mud := _mat(Color(0.32, 0.24, 0.15), 0.95)
	_chimney.material_override = mud
	parent.add_child(_chimney)
	_chimney.position = Vector3(_at.x, g, _at.z)
	_pellets = 0


## (The moult: over on its side, working; the shell split; out of it
## backward; the cast shell left; soft and pale a while.)
func _moult(dt: float) -> void:
	_target = _pos
	match _stage:
		0: # (over on its side, working, flexing)
			_roll = lerpf(_roll, 1.25, 1.0 - exp(-2.0 * dt))
			_tuck(0.5)
			_tail_ask = [0.3 * sin(_st * 3.0), 0.3 * sin(_st * 3.0 + 0.5), 0.3, 0.2, 0.1, 0.1]
			_tail_rate = 6.0
			_cl_ask = [CL_FLIP, CL_FLIP]
			if _st > 3.5:
				_stage = 1
				_st = 0.0
				_cast()
		1: # (pulled out of it backward)
			_cl_ask = [CL_FLIP, CL_FLIP]
			_tuck(0.5)
			_pos -= _forward() * 0.035 * size / ADULT * dt / 2.5
			if _st > 2.5:
				_stage = 2
				_st = 0.0
				_soft = 1.0
				_colour()
		2: # (soft, still, turning back up; a little bigger)
			_roll = lerpf(_roll, 0.0, 1.0 - exp(-1.5 * dt))
			if _st > 4.0:
				_roll = 0.0
				_replant()
				grow(minf(size * (1.35 if young else 1.08), ADULT * float(S.get("size", 1.0)) * (1.1 if male else 1.0)), 6.0)
				wander(_pos, 0.25)


## (Its cast shell: a copy of it as it lies, pale, hollow, left there.)
func _cast() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var ex := _body.duplicate() as Node3D
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.76, 0.66, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.5
	for n in ex.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).material_override = m
	parent.add_child(ex)
	ex.global_transform = _body.global_transform
	_exuvia = ex
	get_tree().create_timer(120.0).timeout.connect(func() -> void:
		if is_instance_valid(ex):
			ex.queue_free())


## (Her eggs laid: on her back a while, her tail curled, then turned up,
## in berry, the eggs under her abdomen.)
func _lay(dt: float) -> void:
	_target = _pos
	match _stage:
		0: # (on her back, her tail curled up over: the eggs out, onto the swimmerets)
			_roll = lerpf(_roll, PI, 1.0 - exp(-2.0 * dt))
			_lift = move_toward(_lift, -2.0, dt * 4.0)
			_tail_ask = [0.4, 0.45, 0.45, 0.4, 0.35, 0.3]
			_cl_ask = [CL_FLIP, CL_FLIP]
			_tuck(0.6)
			if _st > 6.0:
				berried = true
				_eggs.visible = true
				_stage = 1
				_st = 0.0
		1: # (turned back up)
			_roll = lerpf(_roll, 0.0, 1.0 - exp(-2.0 * dt))
			_lift = move_toward(_lift, 0.0, dt * 4.0)
			if _st > 2.5:
				_roll = 0.0
				wander(_pos, 0.15) # (its feet set under it again: _begin)


## (The young out of her eggs, clinging under her a while; then off.)
func _hatch(_dt: float) -> void:
	_target = _pos
	if _stage == 0:
		berried = false
		_eggs.visible = false
		var parent := get_parent() as Node3D
		if parent:
			for k in 14:
				var y: Node3D = (get_script() as Script).new(true)
				y.set("height", height)
				y.set("water_y", water_y)
				parent.add_child(y)
				y.call("place", _pos, _yaw)
				y.call("ride", self, rng.randf_range(30.0, 45.0))
				brood.append(y)
		_stage = 1
	if _st > 3.0:
		wander(_pos, 0.15)


## (A hatchling) clinging under her abdomen, to her swimmerets; then off.
func ride(mother: Node3D, secs := 40.0) -> void:
	_mother = mother
	_ride_t = secs
	_ride_at = Vector3(rng.randf_range(-5.0, 5.0), -9.0, rng.randf_range(12.0, 40.0))


func _process(dt: float) -> void:
	if _mother != null:
		_ride(dt)
		return
	super(dt)


func _ride(dt: float) -> void:
	_t += dt
	_ride_t -= dt
	if not is_instance_valid(_mother) or _ride_t <= 0.0:
		var m := _mother
		_mother = null
		for i in _pose_foot.size():
			_pose_foot[i] = null
		if is_instance_valid(m):
			var p: Vector3 = m.get("_pos")
			var a := rng.randf() * TAU
			pond = m.get("pond")
			ramp = m.get("ramp")
			var at := p + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.02, 0.05)
			at.y = float(height.call(at.x, at.z)) if height.is_valid() else p.y
			if absf(at.y - p.y) > 0.03:
				at = p
			place(at, a)
			wander(p, 0.2)
			grow(YOUNG * 2.5, 300.0)
		return
	var g: Vector3 = _mother.call("_out", _ride_at)
	var mb: Basis = (_mother as Node3D).transform.basis
	transform = Transform3D(mb * Basis(Vector3.RIGHT, PI), g)
	_body.scale = Vector3.ONE * MM * size
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var sd := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		_pose_foot[i] = Vector3(hp.x * sd * 1.3, hp.y - 4.0, hp.z)
	_pose(dt)
	_pose_legs()


# --- mating: he turns her over, and lies on her ---------------------------------

func _mating(dt: float) -> void:
	_mate_t += dt
	if _mate == null or not is_instance_valid(_mate):
		_end_mate()
		return
	var her: Node3D = _mate
	if _mate_role == "female": # (her part his to set: she faces him, then is turned over)
		_target = _pos
		_cl_ask = [CL_GRIP, CL_GRIP] if _mate_stage in ["grip", "turn", "hold"] else [CL_REST, CL_REST]
		if _mate_stage == "spar":
			_cl_ask = [CL_THREAT, CL_THREAT]
			_lift = move_toward(_lift, 5.0, dt * 10.0)
		var on_back := _mate_stage in ["turn", "hold"]
		_roll = lerpf(_roll, PI if on_back else 0.0, 1.0 - exp(-2.5 * dt))
		_lift = move_toward(_lift, -1.0 if on_back else 0.0, dt * 10.0)
		_tail_ask = TAIL_REST
		if on_back:
			for i in _pose_foot.size(): # (her legs folded up over her, now she's on her back)
				var L: Dictionary = legs[i / 2]
				var side := 1.0 if i % 2 == 1 else -1.0
				var hp: Vector3 = L.hip
				_pose_foot[i] = Vector3(hp.x * side * 1.6, hp.y - 7.0, hp.z)
		elif _roll < 0.2 and _pose_foot[0] != null:
			_replant()
		if her.get("_mate_role") != "male":
			_end_mate()
		return
	if _mate_stage == "seek" and _mate_t > 40.0: # (can't get to her)
		var was := _mate
		_end_mate()
		if is_instance_valid(was) and was.get("_mate_role") != "":
			was.call("_end_mate")
		return
	var hp: Vector3 = her.get("_pos")
	var hy: float = her.get("_yaw")
	var hf := Vector3(-sin(hy), 0.0, -cos(hy))
	match _mate_stage:
		"seek": # (before her, face to face)
			var spot := hp + hf * 0.1 * size / ADULT
			_target = spot
			if Vector2(spot.x - _pos.x, spot.z - _pos.z).length() < 0.012:
				_target = _pos
				_turn_to = atan2(-(hp.x - _pos.x), -(hp.z - _pos.z))
				_mate_stage = "spar"
				_mate_t = 0.0
		"spar": # (their claws raised, touching, feeling with their antennae)
			_target = _pos
			_cl_ask = [CL_THREAT, CL_THREAT]
			_lift = move_toward(_lift, 5.0, dt * 10.0)
			_sweep = 1.0
			if _mate_t > 3.0:
				_mate_stage = "grip"
				_mate_t = 0.0
		"grip": # (her claws in his)
			_target = _pos
			_lift = move_toward(_lift, 0.0, dt * 10.0)
			_cl_ask = [CL_GRIP, CL_GRIP]
			if _mate_t > 1.5:
				_mate_stage = "turn"
				_mate_t = 0.0
		"turn": # (she's turned over; he comes round over her, the way she lies)
			_cl_ask = [CL_GRIP, CL_GRIP]
			_turn_to = INF
			_yaw = lerp_angle(_yaw, hy, 1.0 - exp(-2.0 * dt))
			var over := Vector3(hp.x, _pos.y, hp.z) - hf * 0.004
			_pos = _pos.lerp(over, 1.0 - exp(-1.5 * dt))
			_target = _pos
			_lift = move_toward(_lift, 11.0, dt * 8.0)
			_tuck(0.8)
			if _mate_t > 3.0:
				_mate_stage = "hold"
				_mate_t = 0.0
		"hold": # (lying over her, holding her claws, still)
			_cl_ask = [CL_GRIP, CL_GRIP]
			_yaw = lerp_angle(_yaw, hy, 1.0 - exp(-3.0 * dt))
			var over := Vector3(hp.x, _pos.y, hp.z) - hf * 0.004
			_pos = _pos.lerp(over, 1.0 - exp(-3.0 * dt))
			_target = _pos
			_lift = 11.0
			for i in _pose_foot.size(): # (his legs down round her)
				var L: Dictionary = legs[i / 2]
				var side := 1.0 if i % 2 == 1 else -1.0
				var hpp: Vector3 = L.hip
				_pose_foot[i] = Vector3(hpp.x * side * 1.5, hpp.y - 14.0, hpp.z)
			if _mate_t > mate_secs:
				_mate_stage = "release"
				_mate_t = 0.0
				_tuck(0.8)
		"release": # (off her, and away; she turns back up)
			_lift = move_toward(_lift, 0.0, dt * 12.0)
			if _lift < 0.5 and _pose_foot[0] != null:
				_replant()
			_target = _pos - _forward() * 0.1
			if _mate_t > 1.5:
				var was := _mate
				_mate_stage = "done"
				if is_instance_valid(was):
					was.set("_mate_stage", "done")
				if _mate_t > 3.5:
					_end_mate()
					if is_instance_valid(was) and was.get("_mate_role") != "":
						was.call("_end_mate")
					wander(_pos, 0.25)
		"done":
			_end_mate()
			wander(_pos, 0.25)
	# her stage follows his
	if is_instance_valid(her) and her.get("_mate_role") == "female":
		her.set("_mate_stage", _mate_stage if _mate_stage != "seek" else "wait")


func _after_mate() -> void:
	_lift = 0.0
	_replant()
	if not male:
		wander(_pos, 0.2)


# --- the pose -----------------------------------------------------------------

func _pose(dt: float) -> void:
	if _mother == null and not dead and _mate_role == "female" and _mate_stage == "done":
		_roll = lerpf(_roll, 0.0, 1.0 - exp(-2.5 * dt))
	# the claws
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		var now: Array = _cl_now[s]
		var ask: Array = _cl_ask[s]
		for j in 6:
			now[j] = lerpf(float(now[j]), float(ask[j]), 1.0 - exp(-_cl_rate * dt))
		var c: Array = _claws[s]
		(c[0] as Node3D).rotation = Vector3(float(now[1]), -float(now[0]) * side, 0.0)
		(c[1] as Node3D).rotation = Vector3(0.0, float(now[2]) * side, 0.0)
		(c[2] as Node3D).rotation = Vector3(float(now[4]), float(now[3]) * side, 0.0)
		(c[3] as Node3D).rotation = Vector3(0.0, float(now[5]) * 0.6 * side, 0.0)
	# the abdomen, its joints curling under; the tail fan
	for j in 6:
		_tail_now[j] = lerpf(float(_tail_now[j]), float(_tail_ask[j]), 1.0 - exp(-_tail_rate * dt))
		_tail[j].rotation = Vector3(float(_tail_now[j]), 0.0, 0.0)
	_tail[6].rotation = Vector3(float(_tail_now[5]) * 0.6, 0.0, 0.0)
	for u in _uropods:
		var side: float = u.get_meta("side")
		var k: int = u.get_meta("k")
		u.rotation = Vector3(0.0, -side * (0.15 + 0.35 * k) * _fan, 0.0)
	# the swimmerets: fanning (her eggs; swimming), else still
	var fanning := berried or _mode == "flee" or _swim_h > 0.002
	for k in _swimmerets.size():
		_swimmerets[k].rotation = Vector3(0.35 * sin(_t * 9.0 + k * 0.6) if fanning else 0.0, 0.0, 0.0)
	# the antennae sweeping; the antennules flicking; the mouthparts working
	_sweep = move_toward(_sweep, 0.0, dt * 0.5)
	for a in _antennae:
		var side: float = a.get_meta("side")
		a.rotation = Vector3(0.12 * sin(_t * 0.7 + side), side * (0.25 * sin(_t * (0.5 + _sweep) + side * 1.3) + 0.15 * _sweep), 0.0)
	_flick = 1.0 if fmod(_t, 2.3) < 0.15 else move_toward(_flick, 0.0, dt * 6.0)
	for a in _antennules:
		var side: float = a.get_meta("side")
		a.rotation = Vector3(0.25 * _flick + 0.1 * sin(_t * 1.3), 0.1 * side * sin(_t * 0.9), 0.0)
	for m in _maxillipeds:
		var side: float = m.get_meta("side")
		m.rotation = Vector3(0.25 * _chew * sin(_t * 10.0), side * 0.2 * _chew * sin(_t * 10.0 + 1.0), 0.0)


# --- steering (pilot.gd) --------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var out := PackedStringArray(["forage", "eat", "hunt", "threat", "flee", "burrow", "moult"])
	if not young:
		out.append("mate")
		if not male:
			out.append_array(PackedStringArray(["lay", "hatch"]))
	return out


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"forage":
			forage(args.get("centre", _pos), float(args.get("radius", 0.3)))
		"eat":
			var f: Node3D = args.get("food")
			if f == null:
				return false
			eat(f)
		"hunt":
			var p: Node3D = args.get("prey")
			if p == null:
				return false
			hunt(p)
		"threat":
			threat(args.get("at", _pos + _forward() * 0.1))
		"flee":
			flee(args.get("from", _pos + _forward() * 0.1))
		"burrow":
			burrow(args.get("at", _pos + _forward() * 0.06))
		"moult":
			moult()
		"lay":
			if young or male:
				return false
			lay()
		"hatch":
			if not berried:
				return false
			hatch()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"forage":
			return _mode != "forage"
		"eat", "hunt":
			return _mode not in ["eat", "hunt"]
		"threat", "flee", "moult", "lay", "hatch":
			return _mode != name
		"burrow":
			return _mode not in ["burrow"]
	return false


func _p_mobile() -> bool:
	return _mother == null and _mode not in ["moult", "lay", "burrowed"]


func _piloted() -> void:
	if _mode in ["wander", "idle", "forage"]:
		_mode = "piloted"
