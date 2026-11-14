class_name BlueJay
extends "res://scripts/creatures/thrush.gd"
## A blue jay (Cyanocitta cristata), life size: 27 cm long, 38 cm across,
## 85 g; the sexes alike. The songbird's make (Thrush: perching, hopping,
## flying, nesting, its young raised on insects); a corvid's stout straight
## black bill, a bushy crest, a long rounded tail. Its own ways:
## - its crest: down and bushy about its business, flat flying, up when
##   it's roused (calling, mobbing, displaying, alarmed)
## - acorns (forage, hunt: its staple; walnuts too): hopping to one on the
##   ground, picked up in its bill; hungry, it's eaten: held down under its
##   feet and hammered open with its bill, the shell's bits flying, the
##   kernel taken a bite at a time. Not: it's cached: swallowed into its
##   throat (its gular pouch: up to three there and one more in its bill),
##   flown off a way, each brought up again where it lands, pushed into the
##   ground with its bill, hammered down, a leaf or a bit of litter laid over
##   it, then the next a hop or two off; each remembered (caches) and dug
##   up again when it's hungry and there's none lying about. (Those it
##   never comes back to are the oaks it plants.) Insects, caterpillars,
##   grasshoppers, beetles, snails too, on the ground (Thrush)
## - mobbing (mob): a hawk, an owl, a snake, a fox or a bobcat near: flown
##   to within a few metres of it, its crest up, puffed, bobbing, its wings
##   and tail flicked, jeering (jay! jay!), moving round it; the other jays
##   near join in; then off
## - calls (call_out): its jeers, harsh, two or three at a time; now and
##   then a red-shouldered hawk's kee-yer (its bill wide, its head
##   stretched up and forward, held, falling)
## - display: the pump-handle: bobbing up and down from its legs, its crest
##   up, a soft squeaky bell call at the top of each bob
## - courting (mate): he bobs before her, then feeds her, bill to bill, food
##   brought up as she begs; then on her back
## - alarm (fly_off): a jeer, crest up, off
## - flight: steady, rowing, its wings beating evenly, gliding in to land
## - nesting (lay): a cup of twigs lined with rootlets in a fork; four or
##   five eggs blue green, spotted brown
##
## Above lavender blue, its crest and crown bright blue; its face and throat
## greyish white; a black line from its bill through its eye back to its
## nape, joined to a black necklace across its throat; its underparts grey
## white; its wings bright blue, barred black across, a white bar and the
## secondaries tipped white; its tail blue barred black, its corners
## white; its bill, legs and eye black. The juvenile greyer, duller.

const NUTS := ["acorn", "walnut"]
const THREATS := ["coopers_hawk.gd", "peregrine_falcon.gd", "barn_owl.gd", "great_horned_owl.gd", "eastern_screech_owl.gd", "bald_eagle.gd",
		"golden_eagle.gd", "snake.gd", "red_fox.gd", "bobcat.gd", "gila_monster.gd"]
const POUCH := 3 ## (acorns it can hold in its throat, one more in its bill)

var caches: Array[Node3D] = [] ## (its acorns buried: where it can find them again)
var pouch: Array[Node3D] = [] # (in its throat)
var _nut: Node3D # (in its bill, or under its feet)
var _caching := false
var _threat: Node3D
var _then_mob := false
var _mobbed := -60.0 # (when it last mobbed: not every minute)
var _mob_left := 0.0 # (s of mobbing left, flying round it)
var _cover: MeshInstance3D # (the bit of litter in its bill)
var _cache_spot := Vector3.ZERO


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.02
	body_k = 0.56
	walks = false
	flaps_glide = false
	cruise = 8.5
	nest_style = "cup"
	site_style = "fork"
	nest_height = 2.2
	nest_scale = 0.42
	clutch = 4
	egg_size = Vector2(0.028, 0.021)
	egg_colors = [Color(0.62, 0.72, 0.64), Color(0.4, 0.31, 0.22)]
	cup_colors = [Color(0.36, 0.3, 0.24), Color(0.3, 0.24, 0.18)] # (twigs; rootlets)
	eyas_scale = 0.58
	stand_pitch = 0.36
	tail_rest = -1.0
	song_notes = 3
	song_hz = 3.0
	feather_cm = 1.0
	grow_secs = 150.0


func mass_of() -> Vector3:
	return Vector3(0.087, 0.38, 0.022)


func _shape() -> Dictionary:
	var S := thrush_shape(0.56, 1.22, 1.2, 0.86, 12.5, 1.1, 1.12, 1.45, 0.12)
	S.crest = crest_of(S, 2.4, 0.05, 0.9, 0.75, 0.62, 9, 0.9)
	return S


func _plumage(stage: String, _male: bool) -> Dictionary:
	var juv := stage == "juvenile"
	var blue := Color(0.3, 0.47, 0.82) if not juv else Color(0.38, 0.47, 0.66)
	var back := Color(0.36, 0.45, 0.67) if not juv else Color(0.42, 0.46, 0.56)
	var bright := Color(0.16, 0.45, 0.92) if not juv else Color(0.26, 0.45, 0.78)
	var white := Color(0.93, 0.93, 0.92)
	var black := Color(0.03, 0.03, 0.04)
	return {
		"back_color": back, "back_edge": back.lightened(0.08), "back_bar": back.darkened(0.3), "back_bars": 0.0, "back_from": 0.26, "back_from_hi": 0.16,
		"cap_color": blue, "hood_low": -0.0012, "hood_nape": 1.0, "cap_back": 1.0, "cheek": 0.0, "malar": 0.0,
		"under_color": white, "breast_wash": Color(0.76, 0.77, 0.8), "wash_from": -0.2, "wash_to": 0.64, "vent_to": -1.0,
		"under_mark": white, "under_pattern": 0, "throat_clean": 0.9,
		"throat_color": Color(white.r, white.g, white.b, 1.0), "throat_from": 0.66,
		"mask": Color(black.r, black.g, black.b, 1.0 if not juv else 0.7), "mask_at": Vector3(0.0016, 0.0, 0.012), "mask_low": 0.0018,
		"collar": Color(black.r, black.g, black.b, 1.0 if not juv else 0.65), "collar_at": Vector4(0.006, 0.004, 0.0175, 0.0024),
		"crest_color": Color(blue.r, blue.g, blue.b, 1.0), "crest_lay": 1.2,
		"cov_color": Color(bright.r, bright.g, bright.b, 1.0), "cov_bars": 0.9 if not juv else 0.5, "cov_bar_n": 3.0,
		"wing_bars": Color(white.r, white.g, white.b, 1.0), "wing_bar_at": Vector2(2.0, 0.86), "wing_bar_fl": Vector2(0.06, 0.16),
		"fl_top": bright, "fl_pale": Color(0.62, 0.63, 0.67), "fl_dark": Color(0.28, 0.29, 0.33), "fl_bars": 9.0, "fl_top_bars": 1.0 if not juv else 0.6, "fl_trail": 0.0,
		"fl_tip": Color(white.r, white.g, white.b, 0.17), "fl_prim_dark": 0.25,
		"tail_color": Color(0.22, 0.45, 0.85) if not juv else Color(0.3, 0.44, 0.7), "tail_band": black, "tail_bands": 11.0, "tail_band_w": 0.14,
		"tail_tip_r": white, "tail_tip_w": 0.2, "tail_tip_grad": 1.0, "tail_under": 0.45,
		"tail_cov": Color(0.0, 0.0, 0.0, 0.0), "trouser": Color(0.86, 0.86, 0.87, 1.0),
		"cere_color": Color(0.05, 0.05, 0.06), "bill_color": Color(0.06, 0.06, 0.07), "bill_tip": Color(0.04, 0.04, 0.05), "iris": Color(0.03, 0.025, 0.02),
		"leg_color": Color(0.08, 0.08, 0.09), "down_white": Color(0.45, 0.44, 0.45), "gape": Color(0.98, 0.9, 0.5), "young_legs": Color(0.72, 0.62, 0.55),
		"lid_color": black,
	}


# --- what it eats ---------------------------------------------------------------------------

## Acorns, walnuts and its prey on the ground; with nestlings, their insects
## only.
func _meal_kinds() -> Array:
	var prey := Diet.prey_of(self)
	if not young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young")).is_empty():
		return prey
	return prey + NUTS.filter(func(k: String) -> bool: return Diet.of(self).has(k))


## Its own caches it can still dig up (nearest first).
func _own_caches() -> Array:
	caches = caches.filter(func(n: Node3D) -> bool: return is_instance_valid(n) and n.get_meta("buried", null) == self)
	var p := _pos
	var out: Array = caches.duplicate()
	out.sort_custom(func(a: Node3D, b: Node3D) -> bool: return Diet._at(a).distance_to(p) < Diet._at(b).distance_to(p))
	return out


## Down to the ground to forage; hungry with nothing lying about, to one of
## its caches.
func forage() -> void:
	if young or dead:
		return
	if hunger > 0.6 and Diet.find(self, 25.0, NUTS) == null:
		var own := _own_caches()
		if not own.is_empty():
			hunt(own[0])
			return
	super()


func _watch(dt: float) -> void:
	super(dt)
	if young or _mode != "perch":
		return
	if _st < 0.05: # (each look round: a threat near to mob, an acorn below to fetch)
		var th := _threat_near(22.0)
		if th and _mt - _mobbed > 40.0:
			mob(th)
			return
		if _live_young_none() and rng.randf() < 0.45:
			var nut := Diet.find(self, 25.0, NUTS)
			if nut and nut != self:
				hunt(nut as Node3D)


func _live_young_none() -> bool:
	return young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young")).is_empty()


## (On the ground, foraging: a threat near, mobbed; an acorn near, gone for.)
func _forage(dt: float) -> void:
	if _st < 0.02 and _mt - _mobbed > 40.0:
		var th := _threat_near(18.0)
		if th:
			mob(th)
			return
	super(dt)


# (its bill on it: a nut picked up (eaten, or into its throat to cache);
# else, whatever it is, Thrush's)
func _seize() -> void:
	var p := _prey
	if p == null or not is_instance_valid(p) or Diet.kind_of(p) not in NUTS:
		super()
		return
	_prey = null
	head_point = Vector3.INF
	if p.has_meta("hunted"):
		p.remove_meta("hunted")
	if p.has_meta("buried"): # (dug up: its own cache)
		p.remove_meta("buried")
		caches.erase(p)
		p.visible = true
		p.position.y = super._ground(p.position.x, p.position.z)
	_nut = p
	p.set_meta("taken", true)
	if hunger > 0.55 or not _live_young_none():
		_to("hammer")
		return
	# (not hungry: into its throat; another near, gone for; else off to cache them)
	if pouch.size() < POUCH:
		_nut.visible = false
		pouch.append(_nut)
		_nut = null
		want.puff = 0.0
		_beg = 0.0
		var more := Diet.find(self, 5.0, NUTS)
		if more and more != self:
			hunt(more as Node3D)
			return
	_go_cache()


## Off a way with what it holds, to bury it.
func _go_cache() -> void:
	if _nut == null and not pouch.is_empty(): # (one in its bill to carry, too)
		_nut = pouch.pop_back()
		_nut.visible = true
	var a := rng.randf() * TAU
	var to := _pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(7.0, 16.0)
	to.y = super._ground(to.x, to.z)
	_caching = true
	_to("fly")
	_take_off("go", to, true)


func _land(at: Vector3) -> void:
	var c := _caching
	var m := _then_mob
	super(at)
	if c:
		_to("cache", "push" if _nut else "bring")
	elif m:
		_then_mob = false
		_to("mob")
		_secs = _mob_left if _mob_left > 0.0 else rng.randf_range(10.0, 16.0)
		_mob_left = 0.0


func _think(dt: float) -> void:
	super(dt)
	if young:
		return
	if not _air and not dead:
		match _mode:
			"hammer":
				_hammer(dt)
			"cache":
				_cache(dt)
			"mob":
				_mob(dt)
			"pump":
				_pump(dt)
	# its crest: by its mood
	var up := 0.3
	match _mode:
		"mob", "pump", "court_g", "courted", "mount":
			up = 1.0
		"call":
			up = 0.85
		"hammer", "cache", "forage", "hunt", "swallow", "feed_young":
			up = 0.15
		"incubate", "brood", "sleep":
			up = 0.0
	if _air:
		up = 0.0 if not _then_mob else 0.6
	if _beg > 0.0 and not _air:
		up = 1.0
	want.crest = up
	rate["crest"] = 4.0


func _process(dt: float) -> void:
	super(dt)
	if _nut and is_instance_valid(_nut) and _mode != "hammer" and not (_mode == "cache" and _sub in ["push", "cover"] and _st > 0.0 and _nut.has_meta("in_ground")):
		_nut.global_position = bill_tip() - Vector3(0.0, Thrush._mid_y(_nut), 0.0) # (in its bill)
	if _cover and is_instance_valid(_cover) and _mode == "cache" and _sub == "cover":
		_cover.global_position = bill_tip()


# --- an acorn eaten: under its feet, hammered open ---------------------------------------

func _hammer(dt: float) -> void:
	if _nut == null or not is_instance_valid(_nut):
		_nut = null
		forage()
		return
	var bk := body_k / 0.55
	var at := _pos + _fwd() * 0.025 * bk # (held down between its feet)
	at.y = super._ground(at.x, at.z)
	if _st < 0.05:
		_nut.position = at
	halt()
	want.pitch = 1.05
	want.crouch = 0.4
	rate["pitch"] = 10.0
	want.tail_up = tail_rest + 0.2
	head_rate = 30.0
	var w: Vector3 = get_parent().to_global(at + Vector3(0.0, Thrush._mid_y(_nut) * 1.6, 0.0))
	var beat := fmod(_st, 0.42)
	head_point = w if beat < 0.14 else w + Vector3(0.0, 0.035 * bk, 0.0) # (a blow, the bill raised again)
	want.jaw = 0.0 if beat < 0.14 else 0.1
	if beat < dt and _st > 0.3: # (each blow: a chip of shell off)
		_n += 1
		_chip(get_parent().to_global(at + Vector3(0.0, Thrush._mid_y(_nut) * 2.0, 0.0)))
		var k := clampf(1.0 - _n / 16.0, 0.25, 1.0)
		_nut.scale = Vector3.ONE * k
	if _n >= 14:
		_nut.queue_free()
		_nut = null
		head_point = Vector3.INF
		hunger = maxf(hunger - 0.55, 0.0)
		forage()


## A bit of shell, flung off, falling, lying a while.
func _chip(at: Vector3) -> void:
	var h := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.004, 0.005, 0.001)
	h.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.36, 0.2) if rng.randf() < 0.6 else Color(0.82, 0.72, 0.5)
	m.roughness = 0.8
	h.material_override = m
	h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(h)
	h.global_position = at
	var v := Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.3, 0.7), rng.randf_range(-0.5, 0.5))
	var spin := Vector3(rng.randf_range(-15.0, 15.0), rng.randf_range(-15.0, 15.0), 0.0)
	var t := 0.0
	var tree := get_tree()
	while is_instance_valid(h) and t < 20.0:
		await tree.process_frame
		var dt := minf(get_process_delta_time(), 0.05) if is_inside_tree() else 0.033
		t += dt
		var lp: Vector3 = h.position
		var gy := super._ground(lp.x, lp.z) if is_inside_tree() else 0.0
		if lp.y > gy + 0.0005:
			v.y -= 9.8 * dt
			h.position += v * dt
			h.rotation += spin * dt
		else:
			h.position.y = gy + 0.0005
			h.rotation.x = PI * 0.5
			v = Vector3.ZERO
	if is_instance_valid(h):
		h.queue_free()


# --- caching -------------------------------------------------------------------------------

func _cache(dt: float) -> void:
	var bk := body_k / 0.55
	if _sub != "hop":
		halt()
	match _sub:
		"bring": # (one brought up from its throat into its bill: its head pumping)
			want.pitch = stand_pitch + 0.2
			head_want = Vector3(0.0, 0.004 * sin(_st * 22.0), -0.002) * bk
			want.jaw = 0.3
			if _st > 0.9:
				head_want = Vector3.ZERO
				want.jaw = 0.0
				if pouch.is_empty():
					_end_cache()
					return
				_nut = pouch.pop_back()
				_nut.visible = true
				_sub = "push"
				_st = 0.0
		"push": # (pushed into the ground before it, hammered down)
			if _nut == null or not is_instance_valid(_nut):
				_end_cache()
				return
			if _st < 0.02:
				_cache_spot = _pos + _fwd() * 0.065 * bk
				_cache_spot.y = super._ground(_cache_spot.x, _cache_spot.z)
				_n = 0
			want.pitch = 1.1
			want.crouch = 0.35
			rate["pitch"] = 12.0
			head_rate = 26.0
			var w: Vector3 = get_parent().to_global(_cache_spot + Vector3(0.0, Thrush._mid_y(_nut) * 0.6, 0.0))
			var beat := fmod(_st, 0.5)
			head_point = w if beat < 0.18 else w + Vector3(0.0, 0.03 * bk, 0.0)
			if bill_tip().distance_to(w) < 0.01 * maxf(bk, 0.7) and beat < 0.18 and not _nut.has_meta("in_ground"):
				_nut.set_meta("in_ground", true) # (let go: in the ground)
			if _nut.has_meta("in_ground"):
				if beat < dt:
					_n += 1
				var depth := Thrush._mid_y(_nut) * 2.0 * clampf(_n / 5.0, 0.0, 1.0)
				_nut.position = _cache_spot - Vector3(0.0, depth * 0.85, 0.0)
				if _n >= 5:
					_sub = "cover"
					_st = 0.0
			elif _st > 4.0: # (couldn't get it there: dropped where it is)
				_nut.set_meta("in_ground", true)
		"cover": # (a bit of litter picked up beside it, laid over the spot)
			var side := _pos + _right() * 0.06 * bk + _fwd() * 0.04 * bk
			side.y = super._ground(side.x, side.z)
			want.pitch = 1.0
			head_rate = 16.0
			if _st < 0.7:
				head_point = get_parent().to_global(side)
				want.jaw = 0.25 if _st < 0.45 else 0.0
				if _st > 0.45 and _cover == null:
					_cover = _leaf()
			else:
				head_point = get_parent().to_global(_cache_spot + Vector3(0.0, 0.004, 0.0))
				if _st > 1.3:
					if _cover and is_instance_valid(_cover):
						_cover.global_position = get_parent().to_global(_cache_spot + Vector3(0.0, 0.001, 0.0))
						_cover.rotation = Vector3(0.0, rng.randf() * TAU, 0.0)
						_fade(_cover, 90.0)
					_cover = null
					_bury(_nut)
					_nut = null
					head_point = Vector3.INF
					if pouch.is_empty():
						_end_cache()
						return
					_sub = "hop" # (the next a hop or two off)
					_st = 0.0
					var a := _yaw + rng.randf_range(-1.5, 1.5)
					walk_to(_pos + Vector3(-sin(a), 0.0, -cos(a)) * rng.randf_range(0.4, 1.2) * bk, run_speed)
		"hop":
			if arrived() or _st > 2.5:
				_sub = "bring"
				_st = 0.0
		_:
			_sub = "bring"


func _bury(n: Node3D) -> void:
	if n == null or not is_instance_valid(n):
		return
	n.remove_meta("in_ground")
	n.remove_meta("taken")
	n.set_meta("buried", self)
	n.visible = false
	n.scale = Vector3.ONE
	caches.append(n)


func _end_cache() -> void:
	_caching = false
	head_point = Vector3.INF
	head_want = Vector3.ZERO
	if _nut and is_instance_valid(_nut) and not _nut.has_meta("buried"): # (one left: dropped)
		_nut.remove_meta("taken")
		_nut.remove_meta("in_ground")
		_nut.position.y = super._ground(_nut.position.x, _nut.position.z)
	_nut = null
	if home_perch != Vector3.INF and rng.randf() < 0.5:
		perch_on(home_perch)
	else:
		_to("forage")


## A dead leaf (a bit of litter), small and brown.
func _leaf() -> MeshInstance3D:
	var lf := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.045)
	q.orientation = PlaneMesh.FACE_Y
	lf.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.3, 0.17).lerp(Color(0.55, 0.42, 0.25), rng.randf())
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	lf.material_override = m
	lf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(lf)
	lf.global_position = bill_tip()
	return lf


func _fade(n: Node3D, secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	if is_instance_valid(n):
		n.queue_free()


# --- mobbing --------------------------------------------------------------------------------

## A threat near it (THREATS), within r m; or null.
func _threat_near(r: float) -> Node3D:
	var best: Node3D = null
	var bd := r
	for o in get_parent().get_children():
		if o == self or not (o is Node3D) or o.get_script() == null or o.get("dead") == true:
			continue
		if (o.get_script() as Script).resource_path.get_file() not in THREATS:
			continue
		var d := Diet._at(o as Node3D).distance_to(_pos)
		if d < bd:
			bd = d
			best = o
	return best


## To within a few metres of it, and there jeering, bobbing, its crest up;
## the jays near called in.
func mob(threat: Node3D) -> void:
	if young or dead or threat == null or not is_instance_valid(threat):
		return
	_threat = threat
	_mobbed = _mt
	_drop_held()
	var tp := Diet._at(threat)
	var from := Vector3(_pos.x - tp.x, 0.0, _pos.z - tp.z)
	from = from.normalized() if from.length() > 0.05 else Vector3(cos(rng.randf() * TAU), 0.0, sin(rng.randf() * TAU))
	var at := tp + from.rotated(Vector3.UP, rng.randf_range(-0.7, 0.7)) * rng.randf_range(2.2, 3.6)
	at.y = super._ground(at.x, at.z)
	_then_mob = true
	_to("fly")
	_take_off("go", at, true)
	for o in get_parent().get_children(): # (the others near: in too)
		if o != self and o is BlueJay and not o.young and not o.dead and o.get("_threat") != threat and String(o.get("_mode")) not in ["mob", "incubate", "brood"] and (o as Node3D).position.distance_to(position) < 30.0:
			(o as BlueJay).call_deferred("mob", threat)


func _mob(dt: float) -> void:
	if _threat == null or not is_instance_valid(_threat) or _threat.get("dead") == true or _mt > _secs:
		_threat = null
		_mobbed = _mt
		if home_perch != Vector3.INF:
			perch_on(home_perch)
		else:
			fly_off(_pos + _fwd())
		return
	var tp := Diet._at(_threat)
	var to := tp - _pos
	turn_to(to)
	var bk := body_k / 0.55
	want.puff = 0.35
	want.tail_spread = 0.3 + 0.3 * float(fmod(_mt, 0.9) < 0.15)
	want.tail_up = tail_rest + 0.35 * maxf(0.0, sin(_mt * 9.0)) # (flicked)
	rate["tail_up"] = 25.0
	var bob := sin(_mt * 6.5)
	want.crouch = 0.15 + 0.2 * maxf(bob, 0.0)
	want.pitch = stand_pitch + 0.15 * bob
	var jeer := fmod(_mt, 0.65) # (jay! jay!: harsh, its bill wide)
	want.jaw = 0.6 if jeer < 0.22 else 0.0
	rate["jaw"] = 35.0
	want.head_pitch = -0.2 if jeer < 0.22 else 0.05
	var flick := fmod(_mt, 1.7) < 0.18
	set_wings(-1.3 if flick else -1.58, 0.0, 0.0, 0.18 if flick else 0.0)
	if _st > rng.randf_range(3.5, 5.0): # (round it to another spot: hopped, or a short flight)
		_st = 0.0
		var from := Vector3(_pos.x - tp.x, 0.0, _pos.z - tp.z).normalized()
		var at := tp + from.rotated(Vector3.UP, rng.randf_range(-1.2, 1.2)) * rng.randf_range(2.0, 3.5) * maxf(bk, 1.0)
		at.y = super._ground(at.x, at.z)
		if at.distance_to(_pos) > 0.8:
			_then_mob = true
			_mob_left = maxf(_secs - _mt, 0.5) # (_land puts it back to mobbing; its time carried)
			_to("fly")
			_take_off("go", at, true)
		else:
			walk_to(at, run_speed)


func _drop_held() -> void:
	if _nut and is_instance_valid(_nut) and not _nut.has_meta("buried"):
		_nut.remove_meta("taken")
		_nut.remove_meta("in_ground")
		_nut.visible = true
		_nut.position.y = super._ground(_nut.position.x, _nut.position.z)
	_nut = null
	if _cover and is_instance_valid(_cover):
		_cover.queue_free()
	_cover = null
	_caching = false


# --- calls, display ------------------------------------------------------------------------

## Its jeers, two or three at a time; now and then a hawk's kee-yer.
func call_out(secs := 3.0) -> void:
	super(secs)
	_n = 1 if rng.randf() < 0.3 else 0 # (1: the hawk's scream)


func _sing(_dt: float) -> void:
	if _n == 1: # (kee-yer: its head up and forward, its bill wide, held, falling off)
		var ph := fmod(_mt, 3.2)
		var on := ph < 1.3
		want.head_pitch = -0.55 if on else -0.1
		head_want = Vector3(0.0, 0.01, -0.012) * body_k / 0.55 if on else Vector3.ZERO
		want.jaw = (0.75 * (1.0 - 0.45 * smoothstep(0.4, 1.3, ph))) if on else 0.0
		want.puff = 0.3 if on else 0.1
	else: # (jay jay jay: harsh, quick, its tail flicked with each)
		var ph := fmod(_mt, 2.4)
		var k := int(ph / 0.32)
		var on := ph < 0.96
		want.jaw = 0.55 * maxf(0.0, sin(PI * fmod(ph, 0.32) / 0.22)) if on and fmod(ph, 0.32) < 0.22 else 0.0
		want.head_pitch = -0.2
		want.tail_up = tail_rest + (0.25 if on and k % 2 == 0 else 0.0)
		rate["tail_up"] = 25.0
		want.puff = 0.2
	rate["jaw"] = 35.0
	if _mt > _secs:
		want.jaw = 0.0
		want.puff = 0.0
		head_want = Vector3.ZERO
		perch()


## Its pump-handle display: bobbing up and down from its legs, its crest up,
## a soft squeaky bell call at the top of each bob.
func display(_with: Node3D = null) -> void:
	if young or dead or _air:
		return
	_to("pump")
	_secs = rng.randf_range(6.0, 10.0)


func _pump(_dt: float) -> void:
	var b := sin(_mt * 5.5)
	want.crouch = 0.35 * maxf(-b, 0.0)
	lift_y = 0.012 * body_k / 0.55 * maxf(b, 0.0)
	want.pitch = stand_pitch - 0.1 * b
	want.head_pitch = -0.2 - 0.15 * b
	want.jaw = 0.3 if b > 0.85 else 0.0
	rate["jaw"] = 30.0
	set_wings(-1.45, 0.0, 0.0, 0.08 * maxf(b, 0.0))
	if _mt > _secs:
		lift_y = 0.0
		fold_wings()
		perch()


## A jeer, its crest up; off.
func fly_off(from: Vector3) -> void:
	if not _air and not young and not dead:
		_beg = 0.35
		want.crest = 1.0
	_drop_held()
	super(from)


# --- courting: bobbing, then courtship feeding --------------------------------------------

func _court(dt: float) -> void:
	if _partner == null or not is_instance_valid(_partner):
		perch()
		return
	var to: Vector3 = (_partner.get("_pos") as Vector3) - _pos
	var bk := body_k / 0.55
	turn_to(to)
	if _mt < _secs - 3.0: # (bobbing before her, puffed)
		var b := sin(_mt * 5.0)
		want.crouch = 0.3 * maxf(-b, 0.0)
		lift_y = 0.01 * bk * maxf(b, 0.0)
		want.puff = 0.4
		want.jaw = 0.25 if b > 0.85 else 0.0
	else: # (his bill to hers, food brought up; she begs, her wings quivering)
		lift_y = 0.0
		want.crouch = 0.15
		want.puff = 0.2
		var hers: Vector3 = _partner.call("bill_tip")
		var gap := Vector2(to.x, to.z).length()
		if gap > 0.06 * bk:
			_pos += Vector3(to.x, 0.0, to.z).normalized() * minf(0.08 * bk * dt, gap - 0.06 * bk)
		head_rate = 9.0
		head_point = hers + Vector3(0.0, 0.003 + 0.002 * sin(_mt * 11.0), 0.0)
		want.jaw = 0.2
		_partner.set("head_point", bill_tip())
		_partner.call("turn_to", -to)
		_partner.call("set_wings", -1.3, 0.0, 0.0, 0.2 + 0.12 * sin(_mt * 40.0))
		(_partner.get("want") as Dictionary)["jaw"] = 0.45 # (her bill open to his)
	if _mt > _secs:
		lift_y = 0.0
		head_point = Vector3.INF
		want.jaw = 0.0
		_partner.set("head_point", Vector3.INF)
		_partner.call("fold_wings")
		_to("mount")
		_secs = 3.0


func _to(mode: String, sub := "") -> void:
	if _mode == "pump" or _mode == "court_g":
		lift_y = 0.0
	if mode in ["fly", "hammer", "cache", "mob", "forage", "hunt", "swallow"] or mode == _mode:
		pass
	elif _caching and mode != "cache": # (called off caching: what it held dropped)
		_drop_held()
	super(mode, sub)


func test_mode(mode: String) -> void:
	if mode.contains("pump"):
		display()
	elif mode.contains("mob"):
		_threat = self
		_to("mob")
		_secs = 60.0
	else:
		super(mode)
