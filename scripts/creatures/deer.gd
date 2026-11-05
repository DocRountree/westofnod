class_name Deer
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## A white-tailed deer (Odocoileus virginianus), life size (a doe 1.6 m
## long, 90 cm at the shoulder; a buck a little bigger), on the four-legged
## make the hunters share (Carnivore: its gaits, its legs, its head and
## tail), but a browser's ways: a slender deep-chested body on long thin
## legs, small cloven black hooves; a long neck carried high, the head
## narrow, tapering to a black nose; big dark eyes on its sides, their
## pupils bars; big ears, mobile; the tail long and broad, brown above and
## white beneath, raised as a white flag in flight. Its coat by its season
## (season): "summer" red brown; "winter" grey brown, thicker; either way
## its belly, the insides of its legs, its chin, a band behind its nose, a
## ring round each eye and the patch on its throat white. A buck's antlers
## (antlers: points a side, 0 none): the main beams sweeping out, back, then
## forward and in, the tines rising off them, a brow tine at each base; in
## summer in velvet, thick and brown, in winter hard and pale, polished. A
## fawn (Deer.new(true)): red, white spotted in rows down its back and sides
## (its summer coat), no antlers; up soon after it's born, hidden flat in
## the grass, nursing.
##
## - wander(centre, radius), graze(centre, radius), browse(centre, radius):
##   head down cropping, or up to the twigs; stepping on, ears turning, now
##   and then its head up, chewing, looking round
## - bed(secs) (sleep, sit): lying, its legs folded under it, chewing its
##   cud, its head up; dozing, its head laid back along its flank
## - alert(): head high, ears forward, stamping a forefoot, the tail half up
## - flee(from) (alarm): away in long bounds, the white flag up and waving
## - groom(): licking its flank, its legs, scratching its neck with a hind hoof
## - mark(): (a buck's) a rub (antlers on a sapling) and a scrape (pawing
##   the ground bare, then up at the branch over it)
## - snort(): (a buck's display) the snort wheeze: ears back, hair up, its
##   head low, then the lip curl, its head up
## - spar(him): (a buck's) heads down, antlers locked, twisting and pushing
## - birth(): (a doe's) twin fawns, licked; up on their feet; then hidden
##   (lie_hidden(at): a fawn's, flat in the grass, still)
## - nurse(): (a doe's) her fawns come, butting and suckling, tails wagging,
##   licked; then back into hiding
## - mate(her): the buck tending her (following her, his head low and out),
##   then on her, on his hind legs, briefly
## Steering (pilot.gd): act graze {centre, radius}, browse {centre,
## radius}, bed {seconds}, alert, flee {from}, groom, mark, snort, spar
## {with}, birth (a doe's), nurse, play (a fawn's), mate {partner}.

const SPEC := {
	"brace": 0.74, # (mounted, his hind feet nearer under his rump)
	"species": 7, "hooves": true,
	"body": [[-540.0, 30.0, 112.0, 150.0], [-450.0, 0.0, 160.0, 215.0], [-260.0, -12.0, 175.0, 226.0], [-30.0, 0.0, 168.0, 204.0],
			[200.0, 18.0, 160.0, 188.0], [390.0, 42.0, 156.0, 178.0], [500.0, 55.0, 110.0, 124.0], [545.0, 60.0, 46.0, 48.0]],
	"body_h": 760.0, "body_len": 1090.0, "body_w": 170.0,
	"neck_at": Vector3(0.0, 70.0, -480.0), "neck": [[40.0, 0.0, 92.0, 140.0], [-140.0, -10.0, 66.0, 100.0], [-300.0, -10.0, 54.0, 76.0], [-360.0, -8.0, 52.0, 70.0]], "neck_pitch": 0.85,
	"head_at": Vector3(0.0, 8.0, -360.0),
	"head": [[50.0, 0.0, 66.0, 74.0], [-20.0, 12.0, 76.0, 82.0], [-100.0, 2.0, 62.0, 66.0], [-190.0, -18.0, 42.0, 48.0], [-262.0, -28.0, 30.0, 36.0], [-292.0, -30.0, 20.0, 22.0]],
	"jaw_at": Vector3(0.0, -54.2, -64.0), "jaw": [[0.0, 0.0, 28.9, 18.1], [-89.6, 2.9, 23.0, 16.2], [-179.2, 5.6, 12.8, 11.3]], "mouth": 1.3,
	"mouth_z": -1150.0,
	"eye": {"at": Vector3(60.0, 22.0, -55.0), "size": Vector3(30.0, 28.0, 34.0), "color": Color(0.07, 0.045, 0.03), "slit": 0.26},
	"nose": {"at": Vector3(0.0, -26.0, -290.0), "size": Vector3(40.0, 30.0, 24.0), "color": Color(0.04, 0.035, 0.035)},
	"whisker": 35.0,
	"ear": {"at": Vector3(46.0, 62.0, 14.0), "len": 160.0, "width": 92.0, "point": 0.7, "tilt_back": 0.25, "spread": 0.75},
	"tail": {"base": Vector3(0.0, 70.0, 540.0), "n": 5, "seg": 52.0, "radii": [40.0, 56.0, 62.0, 56.0, 36.0], "carry": [1.35, 0.06], "wrap": 0.3},
	"fore": {"hip": Vector3(90.0, -100.0, -390.0), "a": 200.0, "b": 280.0, "m": 300.0, "p": 70.0, "home": Vector2(94.0, -410.0), "r": 28.0},
	"hind": {"hip": Vector3(80.0, 20.0, 400.0), "a": 260.0, "b": 350.0, "m": 380.0, "p": 70.0, "home": Vector2(90.0, 440.0), "r": 32.0},
	"fur": 10.0, "tail_fur": 30.0,
	"walk": 1.3, "trot": 3.6, "run": 16.0,
	"stalk_from": 6.0, "spring": 2.5, "stalk_crouch": 0.1, "stalk_neck": 0.0, "eat_crouch": 0.0,
	"sit_drop": 300.0, "sit_pitch": 0.2, "lie_h": 300.0,
	"mate_secs": 4.0,
	# its head sculpted (SculptHead), from photographs: a long wedge, its forehead flat, its muzzle tapering to its broad black nose; its eyes big, set on its head's sides, looking out; no whisker pads
	"sculpt": {
		"z": [50.0, 25.0, 0.0, -30.0, -60.0, -95.0, -130.0, -170.0, -210.0, -250.0, -285.0],
		"top": [40.0, 70.0, 78.0, 76.0, 69.0, 58.0, 47.0, 36.0, 26.0, 16.0, 4.0],
		"bot": [-40.0, -62.0, -68.0, -66.0, -62.0, -57.0, -52.0, -48.0, -46.0, -45.0, -40.0],
		"w": [40.0, 66.0, 72.0, 68.0, 58.0, 46.0, 36.0, 30.0, 25.0, 21.0, 15.0],
		"wl": [44.0, 70.0, 76.0, 72.0, 60.0, 46.0, 36.0, 30.0, 26.0, 22.0, 15.0],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.5, 2.5, 2.4, 2.2],
		"eye": Vector3(56.0, 24.0, -62.0), "eye_r": 17.5, "socket": 1.6, "lid": 1.6,
		"brow": 2.4, "cheek": 2.0, "stop": 1.2, "pads": 0.6, "flews": 0.40, "nose_r": 19.0,
		"almond": 0.62, "slant": 0.08, "look_fwd": 0.35, "pupil": Vector2(0.35, 0.90),
	},
}
const SEASONS := {"summer": 0, "winter": 1}

var season := 0 ## its coat: 0 summer (red, a buck's antlers in velvet), 1 winter (grey brown, the antlers hard)
var antlers := 4 ## a buck's points a side (with the brow tine; 0 none: a "button buck")
var _rival: Node3D
var _rub_at := Vector3.INF # (a buck's sapling, to rub)
var _fawn_t := -1.0 # (a newborn fawn: s since it was born; -1 up and about)
var _hide_at := Vector3.ZERO # (a fawn's hiding place)
var _flag_up := 0.0 # (the white flag)
var _mats: Array[ShaderMaterial] = []
var _part_m: Dictionary = {}


func _init(young_ := false, season_ := "summer") -> void:
	S = SPEC
	young = young_
	season = int(SEASONS.get(season_, 0))
	super(young_, 0.22 if young_ else 0.5)
	_setup()


func _male_size() -> float:
	return 1.15 # (a buck bigger than a doe, his neck thicker in the rut)


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := super(part, along)
	m.set_shader_parameter("phase", season)
	m.set_shader_parameter("muzzle_z", -245.0) # (the white band behind its nose)
	_mats.append(m)
	return m


## Its coat's season now (its antlers too: velvet, or hard).
func set_season(s: String) -> void:
	season = int(SEASONS.get(s, 0))
	for m in _mats:
		m.set_shader_parameter("phase", season)


## (Its neck: its own, the white throat patch there.)
func _part_coat(name: String, m: ShaderMaterial) -> ShaderMaterial:
	if name != "neck":
		return m
	if not _part_m.has(name):
		var nm := _coat(8)
		_part_m[name] = nm
	return _part_m[name]


func _build_extra() -> void:
	# its hooves: small, cloven, pointed (the walker's paw's pads: two halves)
	for i in 4:
		var pw := _legx[i][1] as MeshInstance3D
		for c in pw.get_children():
			c.queue_free()
		for side: float in [-1.0, 1.0]:
			_part(Vector3(0.17 * side, -0.05, 0.28), Vector3(0.36, 0.85, 0.78), _coat(4), pw)
		# (the dewclaws, up behind)
		for side: float in [-1.0, 1.0]:
			_part(Vector3(0.3 * side, 0.9, -0.55), Vector3(0.16, 0.22, 0.16), _coat(4), pw)
	# the metatarsal glands' tufts (outside each hind cannon): left to the coat
	if male and not young and antlers > 0:
		_grow_antlers()


## A buck's antlers: each main beam from its pedicle up, out and back, then
## sweeping forward and in, the tines rising off its top; the brow tine
## near its base. (In velvet, summer: thicker, the tips blunt.)
func _grow_antlers() -> void:
	var m := _coat(7)
	var thick := 1.25 if season == 0 else 1.0
	for side: float in [-1.0, 1.0]:
		var base := Vector3(40.0 * side, 78.0, 10.0)
		_part(base, Vector3(30.0, 18.0, 30.0) * thick, m, _head) # (the burr)
		var p := base
		var d := Vector3(0.65 * side, 0.5, 0.55).normalized()
		var r := 14.0 * thick
		var n := 8
		var tine_at := {0: 70.0, 3: 130.0, 5: 110.0, 6: 75.0}
		var tines := 0
		for k in n:
			var q := p + d * 56.0
			_stick(p, q, r, m, _head)
			if tine_at.has(k) and tines < antlers - 1:
				var tl: float = tine_at[k]
				var td := (Vector3(-0.15 * side, 1.0, -0.15 if k > 1 else -0.45)).normalized()
				var tp := q
				var tr := r * 0.8
				for j in 3: # (curving a little in, at its tip)
					var tq := tp + td * (tl / 3.0)
					_stick(tp, tq, tr, m, _head)
					tp = tq
					tr *= 0.72
					td = (td + Vector3(-0.12 * side, 0.0, -0.08)).normalized()
				tines += 1
			p = q
			# (the beam sweeping round: out and back, then forward and in)
			d = (d + Vector3(-0.12 * side, -0.14, -0.42)).normalized()
			r *= 0.9


# --- its ways ----------------------------------------------------------------------

func graze(centre: Vector3, radius: float) -> void:
	_mode = "graze"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_stage = 0
	_st = 0.0


func browse(centre: Vector3, radius: float) -> void:
	graze(centre, radius)
	_stage = 1 # (up at the twigs)


func wander(centre: Vector3, radius: float) -> void:
	super(centre, radius)
	if not young:
		graze(centre, radius)


func bed(secs := 20.0) -> void:
	_mode = "bed"
	_wait = secs
	_st = 0.0


## (Its sleep, its rest: bedded down.)
func sleep(secs := 20.0) -> void:
	bed(secs)


func sit(secs := 8.0) -> void:
	bed(secs)


func alert() -> void:
	_mode = "alert"
	_st = 0.0


func flee(from: Vector3) -> void:
	_mode = "flee"
	_st = 0.0
	_wait = 0.0
	_centre = from


func groom() -> void:
	_mode = "groom"
	_st = 0.0


## (A buck's: a rub, then a scrape.) at: the sapling (else where he is).
func mark(at := Vector3.INF) -> void:
	_mode = "mark"
	_rub_at = at
	_stage = 0 if at != Vector3.INF else 1
	_st = 0.0


func snort() -> void:
	_mode = "snort"
	_st = 0.0


func spar(rival: Node3D) -> void:
	if rival == null or rival == self:
		return
	_mode = "spar"
	_rival = rival
	_stage = 0
	_st = 0.0


## (A doe's.) Twin fawns.
func birth(n := 2, _den: Node3D = null) -> void:
	if young or male:
		return
	_mode = "birth"
	_born_left = n
	home_den = null
	_stage = 0
	_st = 0.0


func nurse() -> void:
	if young_ones.is_empty():
		return
	_mode = "nurse"
	_stage = 0
	_st = 0.0


## (A fawn's: a burst of running in circles, bucking, kicking up its heels.)
func play() -> void:
	if not young or _fawn_t >= 0.0:
		return
	_mode = "play"
	_stage = 0
	_st = 0.0


## (A fawn's: flat in the grass, still, its head down on the ground.)
func lie_hidden(at := Vector3.INF) -> void:
	_hide_at = at if at != Vector3.INF else _pos
	_mode = "hide"
	_st = 0.0


func _think(dt: float) -> void:
	if young and _fawn_t >= 0.0:
		_newborn(dt)
		return
	match _mode:
		"graze":
			_common(dt)
			_graze(dt)
			return
		"bed":
			_common(dt)
			_target = _pos
			_lie_to = 1.0
			if _lie > 0.8 and fmod(_st, 30.0) > 18.0: # (dozing: its head back along its flank)
				_neck_to = Vector2(-0.6, 1.8)
				_ears_to = -0.3
			else: # (chewing its cud, its head up, its ears turning)
				_chew = 1.0
				_jaw_to = 0.07 * maxf(sin(_st * 2.4), 0.0)
				_neck_to = Vector2(0.1, 0.25 * sin(_st * 0.15))
			if _wait <= 0.0:
				_lie_to = 0.0
				if _lie < 0.05:
					_after_rest()
			return
		"hide":
			_common(dt)
			_target = _hide_at if _pos.distance_to(_hide_at) > 0.1 else _pos
			if _target == _pos:
				_lie_to = 1.0
				_neck_to = Vector2(-0.9, 0.35) # (its chin flat on the ground)
				_ears_to = -0.8
			return
		"alert":
			_common(dt)
			_alert(dt)
			if _st > 7.0:
				graze(_pos, 2.0)
			return
		"flee":
			_common(dt)
			_flee(dt)
			return
		"groom":
			_common(dt)
			_groom(dt)
			return
		"mark":
			_common(dt)
			_rub_scrape(dt)
			return
		"snort":
			_common(dt)
			_snort(dt)
			return
		"spar":
			_common(dt)
			_spar(dt)
			return
		"suckle":
			_common(dt)
			_suckle(dt)
			return
	super(dt)


func _common(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_lick = move_toward(_lick, 0.0, dt * 2.0)
	_ears_to = 0.0
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_tail_mode = "carry"
	_sit_to = 0.0
	_crouch = move_toward(_crouch, 0.0, dt)
	if _mode not in ["bed", "hide"]:
		_lie_to = 0.0
	if _mode not in ["graze", "flee", "spar", "play"]:
		_pace = -1.0
	if _mode not in ["mark", "groom", "alert"]:
		for i in 4:
			_pose_foot[i] = null


## (Grazing, browsing: cropping as it steps on; its head up now and then,
## chewing, its ears turning, looking round; its tail flicking.)
func _graze(dt: float) -> void:
	var up := fmod(_st, 14.0) > 11.0 # (head up: a look round)
	if up:
		_neck_to = Vector2(0.15, 0.6 * sin(_st * 0.7))
		_chew = 1.0
		_jaw_to = 0.06 * maxf(sin(_st * 6.0), 0.0)
		_ears_to = 0.5
		_target = _pos
	elif _stage == 1: # (browsing: up at the twigs, nipping them off)
		_neck_to = Vector2(0.35, 0.3 * sin(_st * 0.4))
		_jaw_to = 0.12 * maxf(sin(_st * 4.0), 0.0)
		_chew = 0.6
	else:
		_neck_to = Vector2(-1.25, 0.15 * sin(_st * 0.5))
		_jaw_to = 0.08 * maxf(sin(_st * 5.0), 0.0)
		_chew = 0.8
	_tail_mode = "wag" if fmod(_st, 5.0) < 0.6 else "carry" # (a flick)
	if _wait <= 0.0 and not up:
		var a := rng.randf() * TAU
		_target = _pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.3, 0.9) * size / 0.5
		if _target.distance_to(_centre) > _radius:
			_target = _centre + (_target - _centre).normalized() * _radius * 0.8
		_pace = float(S.walk) * 0.35
		_wait = rng.randf_range(3.0, 7.0)


## (Head high, ears forward, staring; a forefoot stamped; the tail half up,
## twitching.)
func _alert(_dt: float) -> void:
	_target = _pos
	_neck_to = Vector2(0.45, 0.3 * sin(_st * 0.4))
	_ears_to = 1.0
	_tail_mode = "half"
	var L: Dictionary = legs[0]
	var hm: Vector2 = L.home
	var k := fmod(_st, 2.2)
	if k < 0.6:
		var lift := sin(k / 0.6 * PI)
		_pose_foot[1] = _ground_at(Vector3(hm.x, 0.0, hm.y - 30.0 * lift)) + Vector3(0.0, 140.0 * lift, 0.0)
	else:
		_pose_foot[1] = null


## (In long bounds away from it, its flag up and waving: now and then a
## great leap.)
func _flee(dt: float) -> void:
	_tail_mode = "flag"
	_ears_to = -0.3
	if _wait <= 0.0:
		var away := _pos - _centre
		away.y = 0.0
		away = (away.normalized() if away.length() > 0.01 else Vector3.FORWARD).rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
		_target = _pos + away * 8.0
		_wait = 2.0
	_pace = float(S.run) * 0.6 * lerpf(0.4, 1.0, size)
	if not airborne and _speed > 2.0 * size / 0.5 and fmod(_st, 1.6) < dt:
		var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
		_leap(_pos + fwd * 3.2 * size / 0.5, 0.35)
	if _st > 6.0:
		_pace = -1.0
		alert() # (stopping: looking back)


## (Licking its flank, its foreleg; a hind hoof up scratching its neck.)
func _groom(_dt: float) -> void:
	_target = _pos
	var ph := fmod(_st, 12.0)
	if ph < 4.0: # (its flank)
		_neck_to = Vector2(-0.3, 1.6)
		_lick = 1.0
	elif ph < 7.0: # (its foreleg)
		_neck_to = Vector2(-1.1, 0.4)
		_lick = 1.0
	else: # (its neck scratched, the hind hoof up to it, its head tipped)
		_neck_to = Vector2(-0.1, 0.7)
		var neck := _neck.transform * Vector3(-60.0, -40.0, -200.0)
		var at := neck + Vector3(-20.0 * sin(_t * 12.0), 15.0 * sin(_t * 12.0), 0.0)
		_pose_foot[2] = at
	if ph < 7.0:
		_pose_foot[2] = null
	if _st > 12.0:
		_pose_foot[2] = null
		graze(_pos, 2.0)


## (A buck's rub: to the sapling, his head down, his antlers rubbed up and
## down its bark, side to side; then his scrape: pawing the ground bare
## with a forehoof, then his head up at the branch over it, licking,
## chewing it.)
func _rub_scrape(_dt: float) -> void:
	match _stage:
		0:
			var to := _rub_at - _pos
			to.y = 0.0
			var reach := 0.55 * size / 0.5
			if to.length() > reach * 1.15:
				_target = _rub_at - to.normalized() * reach
				_st = 0.0
			else:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_neck_to = Vector2(-0.7 + 0.35 * sin(_st * 3.0), 0.25 * sin(_st * 1.7)) # (up and down, side to side)
				_ears_to = -0.4
				if _st > 6.0:
					_stage = 1
					_st = 0.0
		1:
			_target = _pos
			var L: Dictionary = legs[0]
			var hm: Vector2 = L.home
			if _st < 4.0: # (pawing: back and back, the forehoof raking)
				var k := sin(_st * 6.0)
				var i := 0 if fmod(_st, 2.0) < 1.0 else 1
				var side := 1.0 if i == 1 else -1.0
				_pose_foot[i] = _ground_at(Vector3(hm.x * side, 0.0, hm.y - 60.0 + 90.0 * k)) + Vector3(0.0, maxf(-k, 0.0) * 60.0, 0.0)
				_pose_foot[1 - i] = null
				_neck_to = Vector2(-0.9, 0.0)
			else: # (the licking branch: his head up to it)
				_pose_foot[0] = null
				_pose_foot[1] = null
				_neck_to = Vector2(0.9, 0.0)
				_jaw_to = 0.15 * maxf(sin(_st * 5.0), 0.0)
				_lick = 0.6
			if _st > 8.0:
				graze(_pos, 2.0)


## (The snort wheeze: his ears laid back, head low, stiff legged, sidling;
## then the lip curl, his head up, his upper lip lifted, testing the air.)
func _snort(_dt: float) -> void:
	_target = _pos
	if _st < 4.0:
		_ears_to = -1.0
		_neck_to = Vector2(-0.35, 0.0)
		_crouch = 0.1
		_jaw_to = 0.08 if fmod(_st, 1.3) < 0.4 else 0.0
		_tail_mode = "half"
	else: # (flehmen)
		_neck_to = Vector2(0.75, 0.0)
		_jaw_to = 0.2
		_ears_to = -0.2
	if _st > 8.0:
		graze(_pos, 2.0)


func _spar(dt: float) -> void:
	if not is_instance_valid(_rival):
		graze(_pos, 2.0)
		return
	var rp: Vector3 = _rival.get("_pos")
	var to := rp - _pos
	to.y = 0.0
	var gap := 2000.0 * MM * size # (head to head)
	match _stage:
		0: # (to him, facing him, his ears back)
			_target = rp - to.normalized() * gap
			_ears_to = -0.8
			if to.length() < gap * 1.15:
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
				if _rival.get("_mode") != "spar":
					_rival.call("spar", self)
		1: # (heads down, antlers locked; twisting, pushing back and forth)
			_neck_to = Vector2(-1.05, 0.35 * sin(_st * 2.2))
			_ears_to = -0.8
			_crouch = 0.25
			_turn_to = atan2(-to.x, -to.z)
			var push := sin(_st * 1.3) * 0.12 * size / 0.5
			_target = rp - to.normalized() * (gap * 0.92) + to.normalized() * push
			_pace = float(S.walk) * 0.5
			if _st > 10.0:
				_crouch = 0.0
				_pace = -1.0
				graze(_pos, 2.0)


func _birth(_dt: float) -> void:
	match _stage:
		0: # (lying, labouring; each born, licked)
			_target = _pos
			_lie_to = 1.0
			_neck_to = Vector2(-0.3, 1.4)
			if _st > 4.0 and _born_left > 0:
				_born_left -= 1
				_young_one()
				_st = 0.0
			if _born_left <= 0 and _st > 3.0:
				_stage = 1
				_st = 0.0
		1: # (up, licking them)
			_lie_to = 0.0
			_neck_to = Vector2(-1.0, 0.6 * sin(_st * 0.5))
			_lick = 1.0
			if _st > 22.0: # (the fawns, each hidden its own place; she away, grazing)
				var k := 0
				for y in young_ones:
					if is_instance_valid(y) and float(y.get("_fawn_t")) < 0.0:
						var a := float(k) * 2.4 + rng.randf()
						y.call("lie_hidden", _pos + Vector3(cos(a), 0.0, sin(a)) * 1.4 * size / 0.5)
						k += 1
				graze(_pos + Vector3(2.0, 0.0, 0.0) * size / 0.5, 1.5)


func _young_one() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true, "summer")
	parent.add_child(y)
	var k := young_ones.size()
	var at := _out(Vector3(-float(S.body_w) * 2.0, -body_h, 450.0 - 250.0 * k))
	y.call("place", Vector3(at.x, _pos.y, at.z), _yaw + 1.2 + k)
	y.set("height", height)
	y.set("_mother", self)
	y.set("_fawn_t", 0.0)
	y.call("grow", 0.5, 600.0)
	young_ones.append(y)


## (A newborn fawn: lying, wet, licked; struggling up, its hind end first,
## wobbling on its long legs; then to her udder.)
func _newborn(dt: float) -> void:
	_fawn_t += dt
	_st += dt
	_target = _pos
	if _fawn_t < 6.0:
		_lie_to = 1.0
		_neck_to = Vector2(0.1 * sin(_fawn_t * 2.0), 0.3 * sin(_fawn_t * 0.8))
		_ears_to = -0.6
	elif _fawn_t < 14.0:
		_lie_to = 0.0
		_roll = 0.1 * sin(_fawn_t * 8.0) * (14.0 - _fawn_t) / 8.0
	else:
		_roll = 0.0
		_fawn_t = -1.0
		_mode = "suckle"
		_st = 0.0


## (Hers: standing for them, licking them; her fawns come out of hiding
## to her, at her udder.)
func _nurse(_dt: float) -> void:
	_target = _pos
	_neck_to = Vector2(-0.6, 1.2 * sin(_st * 0.3))
	_lick = 0.6
	for y in young_ones:
		if is_instance_valid(y) and float(y.get("_fawn_t")) < 0.0 and y.get("_mode") != "suckle":
			y.set("_mode", "suckle")
			y.set("_st", 0.0)
	if _st > 15.0:
		for y in young_ones:
			if is_instance_valid(y) and y.get("_mode") == "suckle":
				y.call("lie_hidden", (y.get("_pos") as Vector3) + Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)) * size / 0.5)
		graze(_pos, 2.0)


## (A fawn's: to her udder, under her, butting, its tail wagging hard.)
func _suckle(_dt: float) -> void:
	if not is_instance_valid(_mother):
		wander(_pos, 1.0)
		return
	var side := 1.0 if (get_instance_id() % 2) == 0 else -1.0
	var udder: Vector3 = _mother.call("_out", Vector3(float(S.body_w) * 1.2 * side, -float(_mother.get("body_h")), 330.0))
	_target = udder
	if _pos.distance_to(udder) < 0.2:
		_target = _pos
		var mp: Vector3 = _mother.call("_out", Vector3(0.0, -float(_mother.get("body_h")), 420.0))
		var to := mp - _pos
		_turn_to = atan2(-to.x, -to.z)
		_neck_to = Vector2(0.35 + 0.1 * sin(_st * 5.0), 0.0) # (its head up under her, butting)
		_jaw_to = 0.08
		_tail_mode = "wag"
	if _st > 14.0:
		_mode = "follow"
		_st = 0.0


func _play(dt: float) -> void:
	# (a fawn's: running in circles, bucking, kicking up its heels)
	match _stage:
		0:
			_centre = _pos
			_stage = 1
			_st = 0.0
		1:
			var a := _st * 1.6
			_target = _centre + Vector3(cos(a), 0.0, sin(a)) * 1.2 * size / 0.5
			_pace = float(S.trot) * 0.9
			_tail_mode = "flag"
			if fmod(_st, 1.3) < dt and not airborne:
				var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
				_leap(_pos + fwd * 0.6, 0.9)
			if _st > 6.0:
				_pace = -1.0
				_mode = "follow" if is_instance_valid(_mother) else "wander"


func _after_rest() -> void:
	if young and is_instance_valid(_mother):
		_mode = "follow"
	else:
		graze(_pos, 2.0)


func _pose_tail(dt: float) -> void:
	# the flag: up, its white beneath showing, waving side to side; half up
	# alert, twitching
	var raise := 1.0 if _tail_mode == "flag" else (0.45 if _tail_mode == "half" else 0.0)
	_flag_up = move_toward(_flag_up, raise, dt * 4.0)
	if _flag_up <= 0.001:
		super(dt)
		return
	var mode := _tail_mode
	_tail_mode = "carry"
	super(dt)
	_tail_mode = mode
	var n := _tail.size()
	for k in n:
		var u := float(k) / maxf(n - 1, 1)
		var r: Vector3 = _tail[k].rotation
		var up := (-1.5 if k == 0 else -0.08) # (straight up from the rump)
		var wave := (0.35 * sin(_t * 9.0) * u) if _tail_mode == "flag" else 0.08 * sin(_t * 14.0) * u
		_tail[k].rotation = Vector3(lerpf(r.x, up, _flag_up), lerpf(r.y, wave, _flag_up), 0.0)


# --- mating ------------------------------------------------------------------------

func _court_secs() -> float:
	return 8.0 # (tending her: following her, his head low and out, grunting)


func _mount() -> Dictionary:
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var w: Vector3 = _mate.call("_out", Vector3(float(S.body_w) * 0.7 * side, -body_h, float(S.body_len) * 0.64))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	return {"at": Vector3(0.0, float(S.body_h) * 0.55, float(S.body_len) * 0.44), "basis": Basis(Vector3.RIGHT, 0.62), "grips": {
		0: Vector3(-float(S.body_w) * 1.05, -40.0, 200.0), 1: Vector3(float(S.body_w) * 1.05, -40.0, 200.0)}, "free": free}


func _mating(dt: float) -> void:
	super(dt)
	if _mate_role == "male" and _mate_stage == "court":
		var rump: Vector3 = _mate.call("_out", _behind_her(0.9))
		_target = Vector3(rump.x, _pos.y, rump.z)
		_neck_to = Vector2(-0.35, 0.0) # (his head low and out)
		_ears_to = -0.4
	elif _mate_role == "female" and _mate_stage == "court":
		_tail_mode = "out" # (her tail held out)


func _after_mate() -> void:
	graze(_pos, 2.0)


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["graze", "browse", "bed", "alert", "flee", "groom"])
	if young:
		b.append_array(PackedStringArray(["play", "hide"]))
		return b
	b.append("mate")
	if male:
		b.append_array(PackedStringArray(["mark", "snort", "spar"]))
	else:
		b.append_array(PackedStringArray(["birth", "nurse"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"graze":
			graze(args.get("centre", _pos), float(args.get("radius", 2.0)))
		"browse":
			browse(args.get("centre", _pos), float(args.get("radius", 2.0)))
		"bed":
			bed(float(args.get("seconds", 20.0)))
		"alert":
			alert()
		"flee":
			flee(args.get("from", _pos + _p_heading()))
		"groom":
			groom()
		"mark":
			mark(args.get("at", Vector3.INF))
		"snort":
			snort()
		"spar":
			var w: Node3D = args.get("with")
			if w == null:
				return false
			spar(w)
		"birth":
			birth()
		"nurse":
			nurse()
		"play":
			play()
		"hide":
			lie_hidden()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	if name in ["graze", "browse", "bed", "alert", "flee", "groom", "mark", "snort", "spar", "birth", "nurse", "play"]:
		return _mode != name
	return false
