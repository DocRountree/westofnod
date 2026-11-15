class_name Brain
extends RefCounted
## An animal's mind: what it does next, from how hungry and tired it is,
## the hour, and what's about. The same for one with a body and one with
## none (FaunaSim: its records; it only ever asks FaunaSim to go_to() and
## act(), and is told by done() how each came out).
##
## Three layers:
## - its drives (hunger, tiredness: creeping up with time, Fauna.life_rate),
##   weighed whenever it has nothing in hand: asleep at its hour or worn
##   out; feeding when hungry (a hunter after what it hunts, if any's
##   within its sense; a grazer where it stands; the rest looking about for
##   what they eat); else idling (wandering its range, back to its own kind
##   if it keeps with them, grooming, standing alert, its own calls and marks)
## - what it's about (state: "eat", "hunt", "seek", "sleep", "home",
##   "wander", "idle", "flee"), an order at a time
## - its reflex: a hunter of its kind near, it runs (whatever it was at),
##   and what it was at is dropped.
## think(): when its clock comes round (FaunaSim.wake). done(): its order's
## finished (ok) or failed. Mating and young aren't a brain's yet.

const HUNGRY := 0.6
const STARVING := 0.9
const SLEEPY := 0.8
const LOOK := 1.6 ## s between a hunted animal's looks about, awake
const LOOK_ASLEEP := 4.0


static func _drives(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	var dt := (sim.now - a.drives_at) * Fauna.life_rate
	a.drives_at = sim.now
	if dt <= 0.0:
		return
	a.hunger = minf(a.hunger + dt / float(a.sp.fast), 1.0)
	if a.doing == "sleep":
		a.tired = maxf(a.tired - dt / float(a.sp.nap), 0.0)
	else:
		a.tired = minf(a.tired + dt / float(a.sp.awake), 1.0)


static func _its_hour(sim: FaunaSim, a: FaunaSim.Agent) -> bool:
	match String(a.sp.active):
		"day":
			return sim.daylight > 0.3
		"night":
			return sim.daylight < 0.6
	return true


## What hunts a, nearest, within its wariness (null: nothing). A hunter
## asleep, or one that's just fed, is no threat unless it's almost on it.
static func threat(sim: FaunaSim, a: FaunaSim.Agent) -> FaunaSim.Agent:
	if not sim.hunted(a):
		return null
	var p := sim.where(a)
	var wary := float(a.sp.wary) * (0.5 if a.doing == "sleep" else 1.0)
	var best: FaunaSim.Agent = null
	var bd := INF
	for o: FaunaSim.Agent in sim.near(p, wary):
		if o == a or Species.hunts(o.key, a.key, a.young) <= 0.0:
			continue
		var d := sim.where(o).distance_to(p)
		var idle := o.doing == "sleep" or (o.hunger < 0.3 and o.target != a.id)
		if idle and d > wary * 0.35:
			continue
		if d < bd:
			bd = d
			best = o
	return best


static func think(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	_drives(sim, a)
	# its reflex: what hunts it, near
	var th := threat(sim, a)
	if th != null:
		if a.state != &"flee" or a.doing == "":
			_flee(sim, a, th)
		else:
			sim.wake(a, sim.now + LOOK * 0.5)
		return
	if a.doing != "": # (something in hand: only looking about)
		if a.body and a.doing != "go_to" and sim.now > a.until + 25.0: # (its body never said it was done)
			sim.halt(a)
		else:
			if a.state == &"hunt" and a.body == null:
				_chase(sim, a)
				return
			var look := (LOOK_ASLEEP if a.doing == "sleep" else LOOK) if sim.hunted(a) else 6.0
			sim.wake(a, minf(a.until, sim.now + look) if a.body == null else sim.now + look)
			return
	a.target = 0
	var sleepy := a.tired > SLEEPY or not _its_hour(sim, a) # (out of its hour: one sleep after another till it comes round)
	if a.hunger > HUNGRY and not (sleepy and a.hunger < STARVING):
		_feed(sim, a)
	elif sleepy:
		_rest(sim, a)
	else:
		_idle(sim, a)
	if a.doing == "": # (nothing came of it: again in a while)
		a.state = &"idle"
		sim.wake(a, sim.now + randf_range(1.0, 3.0))


## Its order's done (ok), or came to nothing.
static func done(sim: FaunaSim, a: FaunaSim.Agent, what: String, ok: bool) -> void:
	_drives(sim, a)
	match a.state:
		&"eat":
			if ok and what == "eat":
				a.hunger = 0.0
				a.misses = 0
		&"hunt":
			if what == "hunt": # (with a body: run down, killed, eaten, all its own)
				if ok:
					a.hunger = 0.0
				else:
					a.tired = minf(a.tired + 0.1, 1.0)
				a.target = 0
			elif what == "go_to" and a.body == null: # (with none: there; caught, or not)
				_strike(sim, a)
				return
		&"seek":
			if what == "go_to": # (somewhere new: what's here to eat?)
				a.state = &"idle"
				_feed(sim, a)
				if a.doing != "":
					return
		&"home":
			if what == "go_to" and ok:
				_sleep(sim, a)
				return
		&"sleep":
			if what == "sleep":
				a.tired = minf(a.tired, 0.15)
	a.state = &"idle"
	sim.wake(a, sim.now + randf_range(0.3, 1.2))


# --- what it does -----------------------------------------------------------------

static func _flee(sim: FaunaSim, a: FaunaSim.Agent, th: FaunaSim.Agent) -> void:
	var p := sim.where(a)
	var from := sim.where(th)
	var away := p - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU)
	away = away.rotated(Vector3.UP, randf_range(-0.5, 0.5))
	a.state = &"flee"
	a.target = th.id
	a.tired = minf(a.tired + 0.03, 1.0)
	if a.doing != "":
		sim.halt(a)
	if not sim.act(a, "flee", 6.0, {"from": from}): # (its own flight, if its body has one)
		sim.go_to(a, p + away * float(a.sp.wary) * 1.6, true)
	sim.wake(a, sim.now + LOOK)


static func _feed(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	# a hunter: what it hunts, within its sense
	if not (a.sp.prey as Array).is_empty():
		var prey := _prey(sim, a)
		if prey != null:
			_hunt(sim, a, prey)
			return
	if bool(a.sp.anywhere): # (what's always under it)
		a.state = &"eat"
		if not sim.act(a, "eat", float(a.sp.meal), {"centre": sim.where(a), "radius": 2.0}):
			# (a body with no doing for it: stood there, as eating)
			sim.halt(a)
			a.doing = "eat"
			a.doing_name = "eat"
			a.until = sim.now + float(a.sp.meal)
			sim.wake(a, sim.now + LOOK)
		return
	if a.body:
		# what's really there (its steering finds it: Diet.find), or on to look elsewhere
		a.state = &"eat"
		if _body_eat(sim, a):
			return
	elif a.misses > 0 and randf() < 0.5: # (with no body, its food's not kept count of: found, as often as not, where it's looked)
		a.state = &"eat"
		sim.act(a, "eat", float(a.sp.meal))
		return
	a.misses += 1
	a.state = &"seek"
	sim.go_to(a, _somewhere(sim, a, 1.0 + 0.3 * minf(a.misses, 4)), false)


## (A body, to eat what's by it: each of its eating doings tried, its
## steering finding the food; false if there's nothing.)
static func _body_eat(sim: FaunaSim, a: FaunaSim.Agent) -> bool:
	var has := a.body.behaviours()
	for n: String in Species.VERBS.eat:
		if not has.has(n):
			continue
		a.issuing = true
		var ok := a.body.act(n, {"seconds": float(a.sp.meal)})
		a.issuing = false
		if ok:
			a.doing = "eat"
			a.doing_name = n
			a.until = sim.now + float(a.sp.meal)
			sim.wake(a, sim.now + LOOK)
			return true
	return false


static func _prey(sim: FaunaSim, a: FaunaSim.Agent) -> FaunaSim.Agent:
	var p := sim.where(a)
	var best: FaunaSim.Agent = null
	var bs := INF
	for o: FaunaSim.Agent in sim.near(p, float(a.sp.sense)):
		if o == a or not o.alive:
			continue
		var like := Species.hunts(a.key, o.key, o.young)
		if like <= 0.0:
			continue
		var s := sim.where(o).distance_to(p) / maxf(like, 0.05) # (as Diet.find: a staple further off before a rare meal near)
		if s < bs:
			bs = s
			best = o
	return best


static func _hunt(sim: FaunaSim, a: FaunaSim.Agent, prey: FaunaSim.Agent) -> void:
	a.state = &"hunt"
	a.target = prey.id
	# (one of them with a body: both, so it's seen whole)
	if (a.body != null or prey.body != null) and sim.space != null:
		sim.embody(a)
		sim.embody(prey)
		a.pinned = sim.now + 90.0
		prey.pinned = sim.now + 90.0
	if a.body != null and prey.body != null:
		if sim.act(a, "hunt", 90.0, {"target": prey.body}):
			sim.wake(prey, sim.now + 0.3) # (it's seen)
			return
	_chase(sim, a)
	sim.wake(prey, sim.now + 0.5)


## (With no body: after its prey where it is now, at a run.)
static func _chase(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	var prey: FaunaSim.Agent = sim.agents.get(a.target)
	if prey == null or not prey.alive or sim.where(prey).distance_to(sim.where(a)) > float(a.sp.sense) * 2.0:
		sim.halt(a)
		a.target = 0
		a.state = &"idle"
		a.tired = minf(a.tired + 0.08, 1.0)
		sim.wake(a, sim.now + 1.0)
		return
	sim.go_to(a, sim.where(prey), true)
	sim.wake(a, minf(a.until, sim.now + 1.0)) # (its prey moves: after it again)


## (With no body: on its prey. Caught if it's still within reach.)
static func _strike(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	var prey: FaunaSim.Agent = sim.agents.get(a.target)
	a.target = 0
	if prey != null and prey.alive and sim.where(prey).distance_to(sim.where(a)) < float(a.sp.len) + float(prey.sp.len) + 0.5:
		var like := Species.hunts(a.key, prey.key, prey.young)
		if randf() < 0.35 + 0.5 * like:
			sim.kill(prey, a)
			a.state = &"eat"
			sim.act(a, "eat", float(a.sp.meal) * 2.0)
			return
	elif prey != null and prey.alive and a.tired < 0.9: # (not yet: on after it)
		a.target = prey.id
		a.tired = minf(a.tired + 0.02, 1.0)
		_chase(sim, a)
		return
	a.tired = minf(a.tired + 0.1, 1.0)
	a.state = &"idle"
	sim.wake(a, sim.now + randf_range(1.0, 2.0))


static func _rest(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	var p := sim.where(a)
	if p.distance_to(a.home) > float(a.sp.range) * 0.5: # (back toward its own place first)
		a.state = &"home"
		sim.go_to(a, a.home + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * float(a.sp.range) * 0.2, false)
		return
	_sleep(sim, a)


static func _sleep(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	a.state = &"sleep"
	if not sim.act(a, "sleep", float(a.sp.nap) * randf_range(0.8, 1.2)):
		sim.halt(a) # (a body with no sleep of its own: still, a while)
		a.doing = "sleep"
		a.doing_name = "sleep"
		a.until = sim.now + float(a.sp.nap)
		sim.wake(a, sim.now + LOOK_ASLEEP)


static func _idle(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	var r := randf()
	if bool(a.sp.herd): # (too far from its own kind: back to them)
		var p := sim.where(a)
		var mid := Vector3.ZERO
		var n := 0
		var nearest := INF
		for o: FaunaSim.Agent in sim.near(p, float(a.sp.range) * 2.0):
			if o != a and o.key == a.key:
				var q := sim.where(o)
				mid += q
				n += 1
				nearest = minf(nearest, q.distance_to(p))
		if n > 0 and nearest > float(a.sp.len) * 4.0 + 2.0:
			a.state = &"wander"
			sim.go_to(a, (mid / n).lerp(p, 0.3), false)
			return
	if r < 0.5:
		a.state = &"wander"
		sim.go_to(a, _somewhere(sim, a, 1.0), false)
	elif r < 0.65 and a.hunger > 0.3 and bool(a.sp.anywhere): # (a bite as it goes)
		a.state = &"eat"
		if not sim.act(a, "eat", float(a.sp.meal) * 0.5, {"centre": sim.where(a), "radius": 2.0}):
			a.state = &"idle"
	elif r < 0.8:
		a.state = &"idle"
		sim.act(a, "groom", randf_range(5.0, 10.0))
	elif r < 0.92:
		a.state = &"idle"
		sim.act(a, "alert", randf_range(3.0, 6.0))
	else:
		a.state = &"idle"
		sim.act(a, "social", randf_range(4.0, 8.0))


## A place in its range (k: so many times as wide).
static func _somewhere(_sim: FaunaSim, a: FaunaSim.Agent, k: float) -> Vector3:
	var ang := randf() * TAU
	return a.home + Vector3(cos(ang), 0.0, sin(ang)) * sqrt(randf()) * float(a.sp.range) * k
