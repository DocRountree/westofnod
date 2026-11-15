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
## finished (ok) or failed.
## Breeding: a male, fed and rested, goes to a female of his kind who'd have
## him, and mates (their bodies' own mating, if they have them); she
## carries her young for her kind's time (a state on her record: nothing of
## it shows), then they're born (her body's own birth, if it has one);
## they're hers till they're grown (young()), then their own.

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
		if a.body and not a.held and a.doing != "go_to" and sim.now > a.until + 25.0: # (its body never said it was done)
			sim.halt(a)
		else:
			if a.state == &"hunt" and a.body == null:
				_chase(sim, a)
				return
			var look := (LOOK_ASLEEP if a.doing == "sleep" else LOOK) if sim.hunted(a) else 6.0
			sim.wake(a, minf(a.until, sim.now + look) if (a.body == null or a.held) else sim.now + look)
			return
	a.target = 0
	if a.pregnant_until > 0.0 and sim.now >= a.pregnant_until: # (her time's come)
		_birth(sim, a)
		if a.doing != "":
			return
	var sleepy := a.tired > SLEEPY or not _its_hour(sim, a) # (out of its hour: one sleep after another till it comes round)
	if a.hunger > HUNGRY and not (sleepy and a.hunger < STARVING):
		_feed(sim, a)
	elif sleepy:
		_rest(sim, a)
	elif not _breed(sim, a):
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
		&"court":
			if what == "go_to": # (by her: if she'll still have him)
				var f: FaunaSim.Agent = sim.agents.get(a.target)
				if ok and f != null and _receptive(sim, f) and sim.where(f).distance_to(sim.where(a)) < float(a.sp.len) * 3.0 + 2.0:
					_mate(sim, a, f)
					return
				a.target = 0
		&"mate":
			if what == "mate":
				var f: FaunaSim.Agent = sim.agents.get(a.target)
				a.target = 0
				if f != null and f.alive:
					if f.state == &"mated": # (hers over too)
						f.doing = ""
						f.held = false
						f.state = &"idle"
						sim.wake(f, sim.now + randf_range(0.5, 1.5))
					if ok and f.pregnant_until <= 0.0:
						_conceive(sim, f, a)
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
			sim.hold(a, "eat", float(a.sp.meal))
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
		sim.hold(a, "sleep", float(a.sp.nap))


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


# --- breeding ---------------------------------------------------------------------
# (Carrying young is a state on her record and nothing else: nothing of it
# shows on her, with a body or without.)

## Whether she'd mate now: grown, not carrying, none at her side, long
## enough since her last, not too many of her kind about her.
static func _receptive(sim: FaunaSim, f: FaunaSim.Agent) -> bool:
	if f.male or f.young or not f.alive or f.pregnant_until > 0.0 or not f.brood.is_empty() or f.state == &"flee" or f.state == &"mated":
		return false
	if (sim.now - f.bred_at) * Fauna.life_rate < float(f.sp.breed_gap):
		return false
	var n := 0
	for o: FaunaSim.Agent in sim.near(sim.where(f), float(f.sp.range) * 2.0):
		if o.key == f.key:
			n += 1
	return n <= int(f.sp.crowd)


## A male, fed and rested, now and then: to a female of his kind near who'd
## have him. True: he's on his way.
static func _breed(sim: FaunaSim, a: FaunaSim.Agent) -> bool:
	if not a.male or a.young or a.hunger > 0.5 or a.tired > 0.6 or randf() > 0.35:
		return false
	var p := sim.where(a)
	var best: FaunaSim.Agent = null
	var bd := INF
	for o: FaunaSim.Agent in sim.near(p, float(a.sp.sense)):
		if o.key != a.key or not _receptive(sim, o):
			continue
		var d := sim.where(o).distance_to(p)
		if d < bd:
			bd = d
			best = o
	if best == null:
		return false
	a.state = &"court"
	a.target = best.id
	var to := sim.where(best)
	var off := (p - to)
	off.y = 0.0
	sim.go_to(a, to + (off.normalized() if off.length() > 0.01 else Vector3.RIGHT) * (float(a.sp.len) * 0.8 + 0.3), false)
	return true


static func _mate(sim: FaunaSim, a: FaunaSim.Agent, f: FaunaSim.Agent) -> void:
	var secs := float(a.sp.mate)
	if (a.body != null or f.body != null) and sim.space != null: # (one with a body: both)
		sim.embody(a)
		sim.embody(f)
		a.pinned = sim.now + secs + 30.0
		f.pinned = sim.now + secs + 30.0
	a.state = &"mate"
	a.target = f.id
	if f.doing != "":
		sim.halt(f)
	f.state = &"mated"
	f.doing = "mate"
	f.doing_name = "mate"
	f.until = sim.now + secs + 6.0
	f.held = true
	var with_bodies := a.body != null and f.body != null
	if not (with_bodies and sim.act(a, "mate", secs, {"partner": f.body})):
		# (no bodies, or bodies with no mating of their own: by her, its time kept here)
		if a.body:
			sim.halt(a)
		sim.hold(a, "mate", secs)
	sim.wake(f, f.until)


static func _conceive(sim: FaunaSim, f: FaunaSim.Agent, by: FaunaSim.Agent) -> void:
	f.pregnant_until = sim.now + float(f.sp.gest) / maxf(Fauna.life_rate, 0.001)
	f.sire = by.id


## Her young born: her body's own birth if it has one (they come to
## FaunaSim as they're born), else there by her.
static func _birth(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	var lit: Array = a.sp.litter
	var n := randi_range(int(lit[0]), int(lit[1]))
	a.pregnant_until = 0.0
	a.bred_at = sim.now
	a.state = &"birth"
	if a.body and sim.act(a, "birth", 30.0, {"n": n}):
		return
	sim.bear(a, n)
	sim.act(a, "alert", 4.0)


## A young one's clock: grown at its time; its mother lost while it's
## small, it dies.
static func young(sim: FaunaSim, a: FaunaSim.Agent) -> void:
	if sim.now >= a.grow_at:
		sim.grow_up(a)
		return
	if a.mother != 0 and not sim.agents.has(a.mother):
		if sim.now - a.born_at < (a.grow_at - a.born_at) * 0.5:
			sim.kill(a)
			return
		a.mother = 0 # (old enough: on its own where it is, till it's grown)
		var p := sim.where(a)
		a.p0 = p
		a.p1 = p
	sim.wake(a, minf(a.grow_at, sim.now + 10.0))


## A place in its range (k: so many times as wide).
static func _somewhere(_sim: FaunaSim, a: FaunaSim.Agent, k: float) -> Vector3:
	var ang := randf() * TAU
	return a.home + Vector3(cos(ang), 0.0, sin(ang)) * sqrt(randf()) * float(a.sp.range) * k
