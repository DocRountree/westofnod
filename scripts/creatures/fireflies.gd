class_name Fireflies
extends "res://scripts/creatures/beetles.gd" # (by path: found whether or not the editor has seen the class yet)
## Common eastern fireflies (Photinus pyralis, the "big dipper"), drawn at
## twice life size (about 24 mm long): soft-bodied beetles, long and
## flattish, parallel-sided; the wing cases dull, finely hairy, blackish
## grey, edged pale yellow along their sides and down the seam between
## them; the pronotum a broad rounded shield hiding the head from above,
## rose pink with a black spot in its middle, rimmed pale yellow; the head
## small and black, the eyes big; long slender antennae; slender dark legs.
## Under the tip of the belly, the lantern: its last segments a pale
## cream, and lit, a yellow-green glow (ant.gdshader's part 27: flashed on
## and off here, each instant, the GPU drawing it). Made and moved as the
## other beetles are (Beetles, AntColony: one mesh, every firefly an
## instance, walking on the GPU); flying, the elytra held out and up to
## the sides, the dusky hind wings beating, the legs hanging.
##
## Their ways, at dusk (dark: OakTree's night past DUSK, or court on):
## - the males up and flying, slow and low over the grass, each flashing
##   every PERIOD s or so: a half-second flash as he swoops down and up
##   again, a J of light (the "big dipper")
## - the females on the ground (in the grass), watching; one that sees a
##   male flash near answers him, DELAY s after his flash, with a flash of
##   her own
## - a male answered flies to her, lower and nearer at each exchange; down
##   by her he walks to her and they mate (Beetles.mate); then she lays,
##   a few eggs in the soil (Brood's "firefly": they glow faintly)
## By day they rest (wander: walking a little about). Every call the other
## beetles take (wander, feed, fly, mate, lay, member) theirs too.
## Not yet in the game (tools/creatures/ecology_demo.tscn).

const PERIOD := 5.6 ## s between a male's flashes (at about 25 C)
const FLASH := 0.5 ## s a flash lasts
const DELAY := 2.1 ## s after a male's flash a female answers
const SEE := 3.0 ## m: how far off a flash is seen
const DUSK := 0.3 ## OakTree's night past which they court
const LIGHTS := 6 ## lights cast at once (the brightest flashes'), on the grass round them
const EGGS_LAID := 12 ## eggs a female lays after mating

## Courting whatever the hour (the sandbox's display), not only at dusk.
var court := false
## m over the ground the males fly, courting
var court_height := 0.5
## Where they fly about, courting (its own space), and how far round it.
var home := Vector3.ZERO
var home_r := 0.6

# each: its lantern now (0..1); how far into its flash (s; -1: not
# flashing); s till a male's next flash; a female's answer due in (s; -1
# none) and to whom; a male's chosen female (or her chosen male) and how
# many flashes they've traded; his swoop's height (m) now; whether she's
# mated; eggs she's still to lay
var light := PackedFloat32Array()
var flash_t := PackedFloat32Array()
var next_flash := PackedFloat32Array()
var answer_in := PackedFloat32Array()
var answer_to := PackedInt32Array()
var suitor := PackedInt32Array()
var traded := PackedInt32Array()
var dip := PackedFloat32Array()
var mated := PackedByteArray()
var to_lay := PackedInt32Array()
var _enc := PackedFloat32Array()
var _lights: Array[OmniLight3D] = []


func _init() -> void:
	body_h = 1.6
	top_speed = 0.03
	reach = 3.4
	lays = true
	egg_kind = "firefly"
	egg_back = 6.0
	lay_tilt = 0.2
	fly_speed = 0.3 # (slow, drifting)
	fly_pitch = 0.55 # (flying steeply, the belly hanging)
	apart = 9.0
	mate_secs = 40.0
	pronotum_part = 18 # (rose pink: mark_b)
	colors = {
		"black": Color(0.07, 0.055, 0.05), # (the head, the underside)
		"leg_color": Color(0.16, 0.1, 0.07),
		"shell_a": Color(0.075, 0.072, 0.07), # (dull, finely hairy)
		"shell_b": Color(0.2, 0.19, 0.17),
		"iridescence": 0.6,
		"shell_metal": 0.0,
		"shell_gloss": 0.22,
		"mark_a": Color(0.86, 0.72, 0.36), # (the pale yellow rims)
		"mark_b": Color(0.93, 0.44, 0.44), # (the pronotum's rose)
		"stride_hz": 5.0,
		"sweep": 0.55,
		# flying: the elytra held out and up to the sides, the legs hanging
		"elytra_open": Vector3(1.0, -0.3, 0.55),
		"fly_tuck": Vector2(0.35, 0.2),
		"fly_hz": 16.0,
		"wing_color": Color(0.24, 0.22, 0.21),
		"lantern": Color(0.95, 0.91, 0.66),
		"lantern_light": Color(0.75, 1.0, 0.2),
	}
	shape = {
		"under": [Vector3(0.0, -0.45, 2.2), Vector3(3.3, 1.35, 9.6)],
		# the pronotum: a broad flat shield, out over the head
		"pronotum": [Vector3(0.0, 0.3, -2.3), Vector3(4.4, 1.15, 3.6)],
		"elytra": [Vector3(0.0, 0.25, 2.95), Vector3(4.5, 1.55, 8.4)],
		"scutellum": [Vector3(0.0, 0.85, -0.95), Vector3(0.7, 0.3, 0.6)],
		"neck": Vector3(0.0, -0.25, -3.0),
		"head": [Vector3(0.0, -0.1, -0.35), Vector3(1.7, 1.25, 1.3)],
		"clypeus": [Vector3(0.0, -0.4, -0.9), Vector3(0.9, 0.45, 0.5)],
		"eye": [Vector3(0.72, -0.05, -0.45), Vector3(0.75, 1.0, 0.95)],
		"antenna": "filiform",
		"antenna_at": Vector3(0.32, 0.0, -1.0),
		"antenna_len": 5.4,
		"legs": [
			{"hip": Vector3(0.55, -0.7, -1.7), "f": 2.0, "t": 1.9, "s": 1.5, "home": Vector2(2.9, -3.7)},
			{"hip": Vector3(0.75, -0.75, -0.4), "f": 2.2, "t": 2.1, "s": 1.6, "home": Vector2(3.5, 0.0)},
			{"hip": Vector3(0.85, -0.75, 0.8), "f": 2.5, "t": 2.4, "s": 1.8, "home": Vector2(3.3, 3.8)},
		],
		"leg_r": 0.14,
		"hind_wing": 1.05,
	}


## The yellow rims (the elytra's sides and their seam; the pronotum's
## edge), the black spot on the pronotum, and the lantern under the belly.
func _marks(ball: Callable) -> void:
	var c: Vector3 = shape.elytra[0]
	var size: Vector3 = shape.elytra[1]
	var pc: Vector3 = shape.pronotum[0]
	var ps: Vector3 = shape.pronotum[1]
	for side: float in [-1.0, 1.0]:
		var m := _el_mark(side)
		_spot(ball, c, size, 2.0 * side, c.z + 0.2, Vector2(0.2, 4.0), m) # (the side's rim)
		_spot(ball, c, size, 0.05 * side, c.z, Vector2(0.05, 4.1), m) # (along the seam)
		# the pronotum's rim: its sides, and round its front
		_spot(ball, pc, ps, 2.0 * side, pc.z + 0.2, Vector2(0.24, 1.5), 17)
		_spot(ball, pc, ps, 1.35 * side, pc.z - 1.35, Vector2(0.55, 0.3), 17, 0.7 * side)
	_spot(ball, pc, ps, 0.0, pc.z - 1.62, Vector2(0.75, 0.2), 17)
	_spot(ball, pc, ps, 0.0, pc.z + 0.15, Vector2(0.48, 0.85), 0) # (its black spot)
	# the lantern: the belly's last two segments, cream (lit: glowing)
	ball.call(Vector3(0.0, -0.62, 5.35), Vector3(3.15, 0.95, 1.5), 27)
	ball.call(Vector3(0.0, -0.55, 6.45), Vector3(2.5, 0.85, 1.25), 27)


func setup(n: int, c: Vector3, r: float) -> void:
	home = c
	home_r = maxf(r * 6.0, 0.3)
	super(n, c, r)


func _resize(n: int) -> void:
	var was := light.size()
	super(n)
	light.resize(n)
	flash_t.resize(n)
	next_flash.resize(n)
	answer_in.resize(n)
	dip.resize(n)
	_enc.resize(n)
	answer_to.resize(n)
	suitor.resize(n)
	traded.resize(n)
	to_lay.resize(n)
	mated.resize(n)
	for i in range(was, n):
		flash_t[i] = -1.0
		answer_in[i] = -1.0
		answer_to[i] = -1
		suitor[i] = -1
		next_flash[i] = rng.randf_range(0.5, PERIOD)


func _process(dt: float) -> void:
	if multimesh != null and dt > 0.0:
		_court(minf(dt, 0.05))
	super(dt)
	_cast_light()


## Whether it's dusk enough to court (or they're told to).
func courting() -> bool:
	return court or OakTree._night > DUSK


## Each one's flashing and answering, its lantern lit for the shader.
func _court(dt: float) -> void:
	var on := courting()
	var n := pos.size()
	for i in n:
		var male := males[i] == 1
		if flash_t[i] >= 0.0:
			flash_t[i] += dt
			if flash_t[i] > (1.2 if male else FLASH):
				flash_t[i] = -1.0
		var u := flash_t[i] / FLASH
		var lit := 0.0
		if flash_t[i] >= 0.0:
			if male: # (his swoop: down, then up, lit as he comes up: the J)
				var su := flash_t[i] / 1.2
				dip[i] = -0.05 * sin(PI * clampf(su / 0.6, 0.0, 1.0)) + 0.03 * sin(PI * clampf((su - 0.35) / 0.65, 0.0, 1.0))
				u = (flash_t[i] - 0.3) / FLASH
			if u >= 0.0 and u <= 1.0:
				lit = smoothstep(0.0, 0.18, u) * (1.0 - smoothstep(0.55, 1.0, u))
		else:
			dip[i] = move_toward(dip[i], 0.0, dt * 0.05)
		light[i] = lit
		_enc[i] = fly_k[i] + 2.0 * roundf(lit * 31.0)
		if not on or partner[i] >= 0:
			continue
		if male:
			# flying, flashing every PERIOD or so (a little irregular)
			if task[i] == 2 and fly_k[i] > 0.95:
				next_flash[i] -= dt
				if next_flash[i] <= 0.0:
					next_flash[i] = PERIOD * rng.randf_range(0.9, 1.12)
					flash_t[i] = 0.0
					_seen(i)
		elif answer_in[i] >= 0.0:
			answer_in[i] -= dt
			if answer_in[i] < 0.0:
				flash_t[i] = 0.0
				_answered(i, answer_to[i])


## Male m's flash: the females on the ground near enough to see it, and
## not spoken for, answer (most of them) in DELAY s.
func _seen(m: int) -> void:
	var at := _lantern_at(m)
	for j in pos.size():
		if males[j] == 1 or mated[j] == 1 or partner[j] >= 0 or alt[j] > 0.0 or answer_in[j] >= 0.0:
			continue
		if suitor[j] >= 0 and suitor[j] != m:
			continue # (she's answering another)
		if _lantern_at(j).distance_to(at) < SEE and rng.randf() < 0.85:
			answer_in[j] = DELAY * rng.randf_range(0.95, 1.05)
			answer_to[j] = m


## Female f's answer to male m: he's coming, nearer and lower each time;
## near enough, he comes down by her, to walk to her.
func _answered(f: int, m: int) -> void:
	if m < 0 or m >= pos.size() or partner[m] >= 0 or (suitor[m] >= 0 and suitor[m] != f):
		return
	suitor[m] = f
	suitor[f] = m
	traded[m] += 1
	var her := pos[f]
	var d := Vector2(pos[m].x - her.x, pos[m].z - her.z).length()
	if traded[m] >= 3 or d < 0.25:
		# down: in the grass by her (his landing spot: round her)
		task[m] = 0
		centre[m] = her
		radius[m] = 0.03
		landing[m] = 0
	else:
		var r := maxf(d * 0.4, 0.1)
		fly(m, her, r, maxf(court_height * (0.6 - 0.15 * traded[m]), 0.12))


## (Where its lantern is: its own space.)
func _lantern_at(i: int) -> Vector3:
	return pos[i] + Vector3.UP * (alt[i] + dip[i] + body_h * MM)


func _think(i: int, dt: float) -> void:
	if task[i] == MATING:
		super(i, dt)
		return
	var on := courting()
	if males[i] == 1:
		var f := suitor[i]
		if f >= 0 and on and partner[f] < 0 and alt[i] <= 0.0 and task[i] != 2:
			# down by her: walking to her, and mating
			target[i] = pos[f]
			if Vector2(pos[i].x - pos[f].x, pos[i].z - pos[f].z).length() < 0.012:
				if mate(i, f):
					traded[i] = 0
					suitor[f] = -1
					suitor[i] = -1
			return
		if on and task[i] == 0 and rng.randf() < dt * 0.25:
			# up, to court: slow and low over the grass about home
			fly(i, home, home_r, court_height)
	elif to_lay[i] > 0 and task[i] != 3:
		lay(i, pos[i] + Vector3(rng.randf_range(-0.01, 0.01), 0.0, rng.randf_range(-0.01, 0.01)))
	super(i, dt)


## (Flying: the males down once it's no longer dusk.)
func _air(i: int, dt: float) -> bool:
	if task[i] == 2 and not courting() and males[i] == 1 and not court and rng.randf() < dt * 0.1:
		wander(i, centre[i], 0.06)
	return super(i, dt)


func _end_mate(i: int) -> void:
	var j := partner[i]
	super(i)
	for k: int in ([i, j] if j >= 0 else [i]):
		mated[k] = 1
		if males[k] == 0:
			to_lay[k] = EGGS_LAID


func _drop_egg(i: int) -> void:
	super(i)
	to_lay[i] -= 1
	if to_lay[i] <= 0 and task[i] == 3:
		to_lay[i] = 0
		wander(i, pos[i], 0.05)


func _fly_array() -> PackedFloat32Array:
	if _enc.size() != pos.size():
		_enc.resize(pos.size())
	return _enc


func _fly_of(i: int) -> float:
	return _enc[i]


## Drawn flying: as the others, his swoop added, his lantern lit.
func _place(i: int, p: Vector3, a: float) -> void:
	super(i, p, maxf(a + dip[i] * clampf(a / 0.05, 0.0, 1.0), 0.0))
	multimesh.set_instance_custom_data(i, Color(0.0, feed_k[i], seed[i], fly_k[i] + 2.0 * roundf(light[i] * 31.0)))


## A few small lights, from the brightest flashes now: their glow on the
## grass round them.
func _cast_light() -> void:
	if _lights.is_empty():
		for k in LIGHTS:
			var l := OmniLight3D.new()
			l.light_color = Color(0.75, 1.0, 0.25)
			l.omni_range = 0.16
			l.omni_attenuation = 1.2
			l.shadow_enabled = false
			l.visible = false
			add_child(l)
			_lights.append(l)
	var lit: Array = []
	for i in light.size():
		if light[i] > 0.15:
			lit.append(i)
	if lit.size() > LIGHTS:
		lit.sort_custom(func(a: int, b: int) -> bool: return light[a] > light[b])
	for k in LIGHTS:
		var l := _lights[k]
		if k < lit.size():
			var i: int = lit[k]
			l.visible = true
			l.position = _lantern_at(i) + Vector3.UP * 0.008 # (a little over it: no hot spot on the ground under it)
			l.light_energy = light[i] * 0.012
		else:
			l.visible = false
