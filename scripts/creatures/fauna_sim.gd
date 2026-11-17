class_name FaunaSim
extends Node
## The animals of a place as records (Agent), each with or without a body,
## and their brains' clock (Brain: brain.gd). A record is the animal: what
## kind, where, how hungry, how tired, what it's doing. Near the focus (the
## player, the camera) it has a body (a Creature, made when it comes within
## its ring, freed when it's left well outside: the bigger the animal the
## further its ring), and what its brain decides is told to that body by
## its steering (pilot.gd: go_to, act). Away from it there's no body: the
## same orders are carried out here on the record alone (a walk: a line
## and a time; an act: a time, and what comes of it), nothing each frame.
## Either way its brain sees the same two calls, go_to() and act(), and is
## told when each is done (Brain.done).
##
## A brain thinks only when something's happened: its order's done, a time
## it set has come, a hunter's near (wake()). So a thousand records cost a
## few thinks a frame, within budget_ms.
##
##   var sim := FaunaSim.new()
##   sim.space = holder          # the bodies' parent (its space: the records')
##   sim.height = Callable       # (x, z) -> the ground's y there
##   add_child(sim)
##   sim.add("deer", at)         # a record (a body when it's near the focus)
##   sim.adopt(creature)         # a record for a body already there (the sandbox's)
##   sim.focus = camera's place (the space's)   # INF: bodies left as they are
## For the game: FaunaSim.for_world(world, holder) (the land seeded round
## the focus, the sea and cliffs kept off), prime(), to_dict() / from_dict().
## signal died(agent, by): one's dead (hunted down: by its hunter's record);
## born(agent, mother); grown(agent): a young one's come of age.

signal died(agent: Agent, by: Agent)
signal born(agent: Agent, mother: Agent)
signal grown(agent: Agent)

const SLOT := 0.2 ## s: the clock's grain
const CELL := 16.0 ## m: the records' own cells
const RING_PER_M := 45.0 ## a body's ring: so many metres for each of its length
const RING_MIN := 18.0
const RING_MAX := 260.0
const RING_OUT := 1.35 ## freed again past its ring by this much
const SEED_CELL := 128.0 ## m

class Agent:
	var id := 0
	var key := ""
	var sp := {}
	var male := false
	var young := false
	var alive := true
	var body: Creature
	var kept := false ## its body's not the sim's to free (adopted: the sandbox's)
	var pinned := 0.0 ## its body kept till then at the least (a hunt under way)
	# where it is with no body: from p0 at t0 to p1 at t1, a straight line
	var p0 := Vector3.ZERO
	var p1 := Vector3.ZERO
	var t0 := 0.0
	var t1 := 0.0
	var yaw := 0.0
	var home := Vector3.ZERO
	# its drives (0 .. 1)
	var hunger := 0.3
	var tired := 0.2
	var drives_at := 0.0
	# what it's doing: its state (the brain's), its order (the back end's)
	var state := &"idle"
	var doing := "" ## "go_to", or a verb ("eat", "sleep", ...); "": nothing
	var doing_name := "" ## (with a body: its own name for it)
	var until := 0.0
	var target := 0 ## another's id (its prey; what it runs from)
	var misses := 0
	var stamp := 0 # (its latest waking: older ones in the clock are let go)
	var cell := Vector2i.MAX
	var issuing := false
	var held := false ## (with a body: its order's only its time, kept here; the body stood still)
	# breeding: carrying young is a state (till pregnant_until), nothing more
	var pregnant_until := 0.0 ## (0: not)
	var sire := 0
	var bred_at := -1e9 ## when she last gave birth
	var brood: Array[int] = [] ## her young, still with her (ids)
	var mother := 0 ## a young one's
	var born_at := 0.0
	var grow_at := 0.0 ## a young one's: when it's grown
	var slot := 0 # (a young one's place by its mother, with no body)
	var site := Vector3.INF ## what it lives on (its perch, its roost, its web, its flowers): where it rests
	var far := -1 # (FarFauna's: its place among those drawn far off; -1 none)
	var prop: Node3D ## a young insect's still thing, in place of a body: its egg, its chrysalis
	var stage := "" ## a young insect's: "egg", "larva", "pupa" (Species' "larva"); a sea animal's "plankton" (Species' "plankton")
	var dies_at := 0.0 ## (0: not yet) when it dies of itself (an octopus, his life spent once he's mated)
	var on_finished: Callable
	var on_gone: Callable

var space: Node3D ## the bodies' parent
var height: Callable ## (x, z) -> the ground's y
var walkable: Callable ## (x, z) -> whether one can stand there (not the sea, not a cliff); none: anywhere
var water: Callable ## (x, z) -> Vector3 (the water's surface y there, its depth, 1 fresh / 0 salt); depth 0: none. None: no water anywhere
## (kind, at, r) -> Array[Vector3]: the places of a kind within r of at
## that an animal can live on: "perch" (a tree's top, a snag, a crag),
## "roost" (under a limb, in a hollow), "flower" (flowers), "web" (stems
## to spin between). None: anywhere will do.
var sites: Callable
## Seeding (the land's animals put there as records, once, as the focus
## comes near; none: nothing's seeded): {density: Callable (key, x, z) ->
## how many to the square kilometre there, inner: m (nearer the focus than
## this nothing's seeded: it would be seen to appear), outer: m (as far as
## it's seeded), seed: int}. Each SEED_CELL square is seeded once (the same
## animals in the same places for the same seed), when it first lies
## between inner and outer; never again (seeded: kept by to_dict()).
## prime(): everything within outer now, inner or not (a game beginning,
## behind its loading screen).
var seeding := {}
var far: FarFauna ## those with no body drawn far off (for_world makes one; none: not drawn)
var bounds := Rect2() ## where they keep to (x, z; none: anywhere)
var focus := Vector3.INF ## bodies made within their rings of this (the space's); INF: none made, none freed
var ring_scale := 1.0
var daylight := 1.0 ## 0 the night .. 1 the day
var budget_ms := 1.5 ## thinking a frame, at most
var pacing := true ## Fauna.pace() called for the bodies (from focus)
var now := 0.0
var agents := {} # id -> Agent
var thinks := 0 ## (counted: how many a brain's had)
var _by_body := {} # a body's fauna_id -> Agent
var _next := 1
var _clock := {} # slot -> Array of [Agent, stamp]
var _slot := 0
var _grid := {} # Vector2i -> Array[Agent]
var _sweep: Array = []
var _sweep_at := 0
var _pace_t := 0.0
var seeded := {} # Vector2i -> true: the cells seeded already
var _seed_ring: Array = []
var _seed_from := Vector2i.MAX
var _seed_at := 0
var _hunters := {} # a kind's key -> whether anything here hunts it (looked up as they're added)


func _ready() -> void:
	Fauna.listen(_told)


func _exit_tree() -> void:
	Fauna.unlisten(_told)


# --- the records ---------------------------------------------------------------

## A record of a `key` (Species.TABLE) at `at`. Null: no such kind.
func add(key: String, at: Vector3, male := false, young := false) -> Agent:
	var sp := Species.of(key)
	if sp.is_empty():
		return null
	var a := Agent.new()
	a.id = _next
	_next += 1
	a.key = key
	a.sp = sp
	a.male = male
	a.young = young
	a.p0 = _put(sp, at)
	a.p1 = a.p0
	a.home = a.p0
	if String(sp.site) != "" and not young:
		a.site = site_for(sp, a.p0)
		if a.site != Vector3.INF:
			a.home = _put(sp, a.site)
			a.p0 = a.home
			a.p1 = a.home
	a.t0 = now
	a.t1 = now
	a.yaw = randf() * TAU
	a.hunger = randf_range(0.1, 0.6)
	a.tired = randf_range(0.0, 0.5)
	a.drives_at = now
	agents[a.id] = a
	_hunters.clear()
	_file(a)
	wake(a, now + randf_range(0.2, 1.5))
	return a


## A record for a body already here (one of a kind in Species.TABLE, grown,
## alive): its brain its own from now. Its body isn't freed when it's far.
func adopt(c: Creature) -> Agent:
	var key := Species.key_of(c)
	var y: Variant = c.get("young")
	var d: Variant = c.get("dead")
	if key == "" or (y is bool and y) or (d is bool and d) or _by_body.has(c.fauna_id):
		return null
	var a := add(key, c.where(), c.get("male") == true, false)
	a.kept = true
	_attach(a, c)
	return a


func remove(a: Agent) -> void:
	if a.prop != null:
		_unbody(a)
	if a.body:
		_detach(a)
	a.alive = false
	if far:
		far.release(a)
	a.stamp += 1
	agents.erase(a.id)
	_unfile(a)
	var m: Agent = agents.get(a.mother) if a.mother != 0 else null
	if m != null:
		m.brood.erase(a.id)


## n young born to m, where she is (with bodies, if she has one: hers to
## follow). Her body's own birth, where it has one, is Brain's to ask for:
## those young come here as they're born (Fauna's "born").
func bear(m: Agent, n: int) -> void:
	var p := where(m)
	for i in n:
		var y := _young(m, p + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)) * float(m.sp.len) * 0.5)
		if m.body:
			embody(y)


func _young(m: Agent, at: Vector3) -> Agent:
	var y := add(m.key, at, randf() < 0.5, true)
	y.born_at = now
	y.grow_at = now + Species.days(float(m.sp.wean_days))
	y.hunger = 0.0
	if String(m.sp["class"]) == "arthropod" or m.sp.has("plankton") or bool(m.sp.get("plant", false)): # (an insect's, a spider's, those that go off in the plankton: laid and left, on their own from the first)
		y.stage = stage_of(y)
	else:
		y.mother = m.id
		y.slot = m.brood.size()
		m.brood.append(y.id)
	wake(y, minf(y.grow_at, now + 10.0))
	born.emit(y, m)
	return y


## A young insect's stage now, by how far through its youth it is: its
## egg (the first fifth), its caterpillar (to seven tenths), its chrysalis
## or cocoon. "": a kind with no such stages.
func stage_of(a: Agent) -> String:
	if not a.young or not (a.sp.has("larva") or a.sp.has("plankton")):
		return ""
	var f := (now - a.born_at) / maxf(a.grow_at - a.born_at, 0.001)
	if a.sp.has("plankton"): # (adrift, a cloud of them; then settled on the bottom)
		return "plankton" if f < float(a.sp.get("plankton_frac", 0.4)) else ""
	return "egg" if f < 0.2 else ("larva" if f < 0.7 else "pupa")


## (A young insect come to its next stage: what's there for it changed, if
## anything's there.)
func restage(a: Agent) -> void:
	var st := stage_of(a)
	if st == a.stage:
		return
	var was := a.stage
	a.stage = st
	var had := a.body != null or a.prop != null
	var p := where(a)
	if was == "plankton": # (come down somewhere the current took it)
		for k in 6:
			var ang := randf() * TAU
			var q := _put(a.sp, p + Vector3(cos(ang), 0.0, sin(ang)) * randf() * float(a.sp.range) * 2.0)
			if can_be(a.sp, q):
				p = q
				break
		a.home = p
	_unbody(a)
	a.p0 = p
	a.p1 = p
	a.t1 = now
	if had:
		embody(a)


## (Whatever a has in the world freed: its body, its still thing.)
func _unbody(a: Agent) -> void:
	if a.body:
		var c := a.body
		_detach(a)
		if is_instance_valid(c):
			c.queue_free()
	if a.prop != null:
		if is_instance_valid(a.prop):
			a.prop.queue_free()
		a.prop = null


## A young one grown: its own from now (its body, if it has one, a grown one's).
func grow_up(a: Agent) -> void:
	var p := where(a)
	var m: Agent = agents.get(a.mother)
	if m != null:
		m.brood.erase(a.id)
	a.young = false
	a.mother = 0
	a.home = p
	a.p0 = p
	a.p1 = p
	a.t1 = now
	a.hunger = 0.4
	_hunters.clear()
	a.stage = ""
	if a.body or a.prop != null:
		var kept := a.kept
		_unbody(a)
		a.kept = false
		if not embody(a):
			a.kept = kept
	grown.emit(a)
	wake(a, now + randf_range(0.2, 1.0))


## The record of a body (null: it has none).
func agent_of(c: Creature) -> Agent:
	return _by_body.get(c.fauna_id) if c else null


## Where it is now (the space's).
func where(a: Agent) -> Vector3:
	if a.body:
		return a.body.where()
	if a.young and a.mother != 0: # (with no body: by its mother)
		var m: Agent = agents.get(a.mother)
		if m != null:
			var ang := float(a.slot) * 2.4
			return where(m) + Vector3(cos(ang), 0.0, sin(ang)) * float(m.sp.len) * 0.6
	if now >= a.t1 or a.t1 <= a.t0:
		return a.p1
	return a.p0.lerp(a.p1, (now - a.t0) / (a.t1 - a.t0))


## Whether one can stand at p (the land's: not the sea, not a cliff).
func can_stand(p: Vector3) -> bool:
	return not walkable.is_valid() or bool(walkable.call(p.x, p.z))


## The water at p: Vector3 (its surface's y, its depth, 1 fresh / 0 salt); depth 0: none.
func water_at(p: Vector3) -> Vector3:
	return water.call(p.x, p.z) if water.is_valid() else Vector3.ZERO


## Whether one of a kind (sp: its Species entry) can be at p: the land's on
## land, the sea's in water deep enough (and not too deep) for it, fresh
## water's in that, the shore's on land by water or in it.
func can_be(sp: Dictionary, p: Vector3) -> bool:
	if not water.is_valid(): # (no water told of: the sandbox's, each where it was put)
		return can_stand(p)
	var w := water_at(p)
	match String(sp.medium):
		"sea":
			return w.y >= float(sp.depth) and w.y <= float(sp.max_depth) and w.z < 0.5
		"fresh":
			return w.y >= float(sp.depth) and w.y <= float(sp.max_depth) and (w.z > 0.5 or not water.is_valid())
		"shore":
			if w.y > 0.0:
				return w.y < 3.0
			if not can_stand(p):
				return false
			if not water.is_valid():
				return true
			for k in 6: # (water within a dozen metres)
				var a := TAU * k / 6.0
				if water_at(p + Vector3(cos(a), 0.0, sin(a)) * 12.0).y > 0.0:
					return true
			return false
	return w.y <= 0.0 and can_stand(p)


## (As far toward `to` from `from` as one of sp's kind can go: a walk never
## set across the sea, a swim never up the beach. One that flies: there,
## if it can be there.)
func _reach(sp: Dictionary, from: Vector3, to: Vector3) -> Vector3:
	if not walkable.is_valid() and not water.is_valid():
		return to
	if bool(sp.flies):
		return to if can_be(sp, to) else from
	var d := Vector2(to.x - from.x, to.z - from.z).length()
	var n := clampi(int(ceilf(d / 6.0)), 1, 16)
	var last := from
	for k in range(1, n + 1):
		var q := from.lerp(to, float(k) / n)
		if not can_be(sp, q):
			return last
		last = q
	return to


## p as one of sp's kind is there: within the bounds; on the ground, or in
## the water (at its floor, or a little under its surface).
func _put(sp: Dictionary, p: Vector3) -> Vector3:
	p = _on_ground(p)
	var w := water_at(p)
	if w.y > 0.0 and String(sp.medium) != "land":
		p.y = w.x - w.y if bool(sp.floor) else w.x - minf(w.y * 0.5, float(sp.len) * 0.6 + 0.3)
	return p


## The nearest place of the kind sp lives on, round at (INF: none there).
func site_for(sp: Dictionary, at: Vector3) -> Vector3:
	if not sites.is_valid() or String(sp.site) == "":
		return Vector3.INF
	var best := Vector3.INF
	var bd := INF
	for q: Vector3 in sites.call(String(sp.site), at, maxf(float(sp.range), 10.0)):
		var d := q.distance_to(at)
		if d < bd:
			bd = d
			best = q
	return best


func _on_ground(p: Vector3) -> Vector3:
	if bounds.size != Vector2.ZERO:
		p.x = clampf(p.x, bounds.position.x, bounds.end.x)
		p.z = clampf(p.z, bounds.position.y, bounds.end.y)
	if height.is_valid():
		p.y = float(height.call(p.x, p.z))
	return p


func _file(a: Agent) -> void:
	var p := where(a)
	var c := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
	if c == a.cell:
		return
	_unfile(a)
	a.cell = c
	if _grid.has(c):
		(_grid[c] as Array).append(a)
	else:
		_grid[c] = [a]


func _unfile(a: Agent) -> void:
	if a.cell == Vector2i.MAX:
		return
	var l: Array = _grid.get(a.cell, [])
	l.erase(a)
	if l.is_empty():
		_grid.erase(a.cell)
	a.cell = Vector2i.MAX


## The records within r of p (level), nearest first not promised. (Those
## walking with no body are filed where they were last looked at: they're
## woken every cell they cross, so never more than a cell out.)
func near(p: Vector3, r: float) -> Array:
	var out := []
	var c0 := Vector2i(floori((p.x - r) / CELL) - 1, floori((p.z - r) / CELL) - 1)
	var c1 := Vector2i(floori((p.x + r) / CELL) + 1, floori((p.z + r) / CELL) + 1)
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var l: Variant = _grid.get(Vector2i(cx, cy))
			if l == null:
				continue
			for a: Agent in l:
				var q := where(a)
				if Vector2(q.x - p.x, q.z - p.z).length() <= r:
					out.append(a)
	return out


## Whether anything here hunts a's kind.
func hunted(a: Agent) -> bool:
	var id := a.key + ("y" if a.young else "")
	if not _hunters.has(id):
		var any := false
		for o: Agent in agents.values():
			if Species.hunts(o.key, a.key, a.young) > 0.0:
				any = true
				break
		_hunters[id] = any
	return _hunters[id]


# --- the clock -------------------------------------------------------------------

## a's brain to think at `at` (sooner than any waking it has: that one let go).
func wake(a: Agent, at: float) -> void:
	a.stamp += 1
	var s := maxi(int(ceilf(at / SLOT)), _slot + 1)
	if _clock.has(s):
		(_clock[s] as Array).append([a, a.stamp])
	else:
		_clock[s] = [[a, a.stamp]]


func _process(dt: float) -> void:
	now += dt
	if pacing and focus != Vector3.INF and space != null:
		_pace_t -= dt
		if _pace_t <= 0.0:
			_pace_t = 0.5
			Fauna.pace(space.to_global(focus), get_viewport().get_camera_3d() if is_inside_tree() else null)
	_tiers()
	_seed_tick()
	var t0 := Time.get_ticks_usec()
	var top := int(floorf(now / SLOT))
	while _slot <= top:
		var l: Variant = _clock.get(_slot)
		if l != null:
			var todo: Array = l
			while not todo.is_empty():
				var e: Array = todo.pop_back()
				var a: Agent = e[0]
				if a.alive and a.stamp == int(e[1]):
					_woken(a)
				if Time.get_ticks_usec() - t0 > budget_ms * 1000.0 and not todo.is_empty():
					return # (the rest next frame)
			_clock.erase(_slot)
		_slot += 1


func _woken(a: Agent) -> void:
	_file(a)
	if a.young:
		Brain.young(self, a)
		return
	if (a.body == null or a.held) and a.doing != "" and now >= a.until - 1e-3: # (with no body, or one only held still: its order's time is up)
		var d := a.doing
		a.doing = ""
		a.held = false
		Brain.done(self, a, d, true)
		return
	thinks += 1
	Brain.think(self, a)


# --- bodies: made near the focus, freed far from it -------------------------------

func ring(a: Agent) -> float:
	return clampf(float(a.sp.len) * RING_PER_M, RING_MIN, RING_MAX) * ring_scale


## (A few records looked at each frame: one come within its ring a body,
## one left well outside it none. One body made a frame at the most.)
func _tiers() -> void:
	if focus == Vector3.INF or space == null:
		return
	if _sweep_at >= _sweep.size():
		_sweep = agents.values()
		_sweep_at = 0
	var made := false
	for k in mini(48, _sweep.size() - _sweep_at):
		var a: Agent = _sweep[_sweep_at]
		_sweep_at += 1
		if not a.alive or (a.young and agents.has(a.mother)): # (a young one: as its mother)
			continue
		var p := where(a)
		var d := Vector2(p.x - focus.x, p.z - focus.z).length()
		var r := ring(a)
		if a.prop != null:
			if d > r * RING_OUT:
				_unbody(a)
		elif a.body == null:
			if d < r and not made:
				made = embody(a)
		elif not a.kept and d > r * RING_OUT and now > a.pinned:
			disembody(a)


## a given a body where it is (true: it has one now).
func embody(a: Agent) -> bool:
	if a.body:
		return true
	if space == null or not a.alive:
		return false
	var p := where(a)
	if a.prop != null:
		return true
	if a.young and not bool(a.sp.young_body):
		return false # (a wasp's young, a bee's: in their comb; none shown)
	if a.young and a.sp.has("larva"): # (a butterfly's, a moth's: its egg, its caterpillar, its chrysalis)
		return _embody_stage(a)
	if a.young and a.sp.has("plankton") and stage_of(a) == "plankton": # (a cloud of them, adrift above the bottom)
		a.stage = "plankton"
		var pl: Plankton = Plankton.new(String(a.sp.plankton), 30)
		space.add_child(pl)
		pl.position = p + Vector3(0.0, 0.3, 0.0)
		var w := water_at(p)
		if w.y > 0.0:
			pl.set_water(w.x - w.y, w.x)
			pl.position.y = minf(pl.position.y, w.x - 0.2)
		a.prop = pl
		return true
	if String(a.sp.site) != "" and not a.young: # (what's really there to live on, now it's near)
		var st := site_for(a.sp, p)
		if st != Vector3.INF:
			a.site = st
	var c := Species.make(a.key, space, p, a.yaw, a.male, a.young, {"height": height, "water": water, "site": a.site})
	if c == null:
		return false
	a.p0 = p
	a.p1 = p
	if far:
		far.release(a)
	_attach(a, c)
	if c.has_method("set_home"): # (its den, its own place: its record's, whichever body it has)
		c.call("set_home", a.home)
	a.doing = ""
	wake(a, now + 0.1)
	var m: Agent = agents.get(a.mother) if a.young else null
	if m != null and m.body:
		Species.link(m.body, c)
	for id: int in a.brood: # (her young with her)
		var y: Agent = agents.get(id)
		if y != null and y.body == null:
			embody(y)
	return true


func _embody_stage(a: Agent) -> bool:
	var kind := String(a.sp.larva)
	var p := where(a)
	a.stage = stage_of(a)
	if a.stage == "larva":
		var lv: Creature = (load("res://scripts/creatures/larva.gd") as GDScript).new(kind)
		if height.is_valid():
			lv.set("height", height)
		space.add_child(lv)
		lv.call("place", p, Vector3(-sin(a.yaw), 0.0, -cos(a.yaw)))
		_attach(a, lv)
		return true
	var n: Node3D = null
	if a.stage == "egg":
		var ES: GDScript = load("res://scripts/creatures/egg.gd")
		if (ES.get("EGGS") as Dictionary).has(kind):
			n = ES.new(kind)
	else:
		n = (load("res://scripts/creatures/pupa.gd") as GDScript).new(kind)
	if n == null:
		return false
	space.add_child(n)
	n.position = p
	n.rotation.y = a.yaw
	n.set_process(false) # (its time's the record's: it hatches, it emerges, when its stage is up)
	a.prop = n
	return true


## a's body freed (it goes on from where it was, with none).
func disembody(a: Agent) -> void:
	if a.body == null:
		return
	var c := a.body
	var p := c.where()
	var h := c._p_heading()
	_detach(a)
	c.queue_free()
	a.p0 = p
	a.p1 = p
	a.t0 = now
	a.t1 = now
	a.yaw = atan2(-h.x, -h.z)
	a.doing = ""
	wake(a, now + 0.1)
	for id: int in a.brood:
		var y: Agent = agents.get(id)
		if y != null and y.body and not y.kept:
			disembody(y)


func _attach(a: Agent, c: Creature) -> void:
	a.body = c
	_by_body[c.fauna_id] = a
	a.on_finished = _finished.bind(a)
	a.on_gone = _body_gone.bind(a, c)
	c.action_finished.connect(a.on_finished)
	c.tree_exiting.connect(a.on_gone)
	c.set_meta("sim", true) # (its young, its death: the record's to say)


func _detach(a: Agent) -> void:
	var c := a.body
	if c == null:
		return
	a.body = null
	_by_body.erase(c.fauna_id)
	if is_instance_valid(c):
		c.remove_meta("sim")
		if c.action_finished.is_connected(a.on_finished):
			c.action_finished.disconnect(a.on_finished)
		if c.tree_exiting.is_connected(a.on_gone):
			c.tree_exiting.disconnect(a.on_gone)


## (Its body's been taken out of the world by something else: deleted,
## eaten up. The record goes with it.)
func _body_gone(a: Agent, c: Creature) -> void:
	if a.body == c and a.alive:
		a.body = null
		_by_body.erase(c.fauna_id)
		remove(a)


func _finished(name: String, ok: bool, a: Agent) -> void:
	if a.issuing or not a.alive or a.doing == "" or (name != a.doing_name and name != a.doing):
		return
	var d := a.doing
	a.doing = ""
	Brain.done(self, a, d, ok)


## (Fauna's: what the bodies do that changes the numbers.)
func _told(what: StringName, who: Node, data: Dictionary) -> void:
	if what == &"died" and who is Creature:
		var a: Agent = _by_body.get((who as Creature).fauna_id)
		if a != null:
			var by: Variant = data.get("by")
			_dead(a, _by_body.get((by as Creature).fauna_id) if by is Creature else null)
	elif (what == &"born" or what == &"hatched") and who is Creature and data.get("young") is Creature:
		var m: Agent = _by_body.get((who as Creature).fauna_id)
		var yc: Creature = data["young"]
		if m != null and not _by_body.has(yc.fauna_id) and Species.key_of(yc) == m.key:
			var y := _young(m, yc.where())
			_attach(y, yc)
	elif what == &"killed" and data.get("prey") is Creature:
		var a: Agent = _by_body.get((data["prey"] as Creature).fauna_id)
		if a != null:
			_dead(a, _by_body.get((who as Creature).fauna_id) if who is Creature else null)


## a's dead (its body, if it has one, left as it lies: its hunter's to eat).
func _dead(a: Agent, by: Agent) -> void:
	if not a.alive:
		return
	_detach(a)
	if a.prop != null:
		_unbody(a)
	a.alive = false
	if far:
		far.release(a)
	a.stamp += 1
	agents.erase(a.id)
	_unfile(a)
	_hunters.clear()
	var m: Agent = agents.get(a.mother) if a.mother != 0 else null
	if m != null:
		m.brood.erase(a.id)
	died.emit(a, by)


## a killed (by: its hunter's record, or null): its body dies, if it has one.
func kill(a: Agent, by: Agent = null) -> void:
	if not a.alive:
		return
	var c := a.body
	_dead(a, by)
	if c != null and is_instance_valid(c):
		if c.has_method("die"):
			c.call("die")
		elif not a.kept:
			c.queue_free()


# --- orders: the same with a body or none ----------------------------------------

## a to go to point (running: its fastest). Done: Brain.done(a, "go_to", ok).
func go_to(a: Agent, point: Vector3, running := false, exact := false) -> void:
	var as_given := point
	point = _put(a.sp, _reach(a.sp, where(a), point))
	if exact and Vector2(point.x - as_given.x, point.z - as_given.z).length() < 0.01:
		point = as_given # (its perch itself: up where it is)
	a.held = false
	a.doing = "go_to"
	a.doing_name = "go_to"
	if a.body:
		a.issuing = true
		# (one that flies, with a flight of its own: flown there, if it's any way off)
		if bool(a.sp.flies) and a.body.behaviours().has("fly") and a.body.where().distance_to(point) > 2.5 and a.body.act("fly", {"at": point}):
			a.doing_name = "fly"
		else:
			a.body.go_to(point, a.body._p_speed() * (float(a.sp.run) / maxf(float(a.sp.walk), 0.01)) if running else -1.0)
		a.issuing = false
		a.until = now + a.body.where().distance_to(point) / maxf(a.body._p_speed(), 0.005) * 1.5 + 5.0 # (its time to get there: a slow one's long)
		wake(a, now + 4.0) # (to look about as it goes)
		return
	var from := where(a)
	var sp := float(a.sp.run if running else a.sp.walk)
	if FarFauna._winged(a.sp) and from.distance_to(point) > 12.0: # (a bird going any way: flown)
		sp = maxf(sp, float(a.sp.get("fly", 9.0)))
	a.p0 = from
	a.p1 = point
	a.t0 = now
	a.t1 = now + from.distance_to(point) / maxf(sp, 0.01)
	a.until = a.t1
	var d := point - from
	if Vector2(d.x, d.z).length() > 0.01:
		a.yaw = atan2(-d.x, -d.z)
	# (woken each cell it crosses, to be filed there; and when it's there)
	wake(a, minf(a.t1, now + CELL / maxf(sp, 0.01)))


## a to do a verb (Species.VERBS: "eat", "sleep", "groom", ...) for secs;
## args: its body's (from, target: another record's body). False: with a
## body, and its body has no such doing, or couldn't (nothing to eat).
func act(a: Agent, verb: String, secs: float, args := {}) -> bool:
	a.held = false
	if a.body:
		var n := Species.verb(a.body, verb)
		if n == "":
			return false
		var full := args.duplicate()
		full["seconds"] = secs
		a.issuing = true
		var ok := a.body.act(n, full)
		a.issuing = false
		if not ok:
			return false
		a.doing = verb
		a.doing_name = n
		a.until = now + secs
		wake(a, now + minf(secs + 2.0, 4.0))
		return true
	var p := where(a)
	a.p0 = p
	a.p1 = p
	a.t0 = now
	a.t1 = now
	a.doing = verb
	a.doing_name = verb
	a.until = now + secs
	wake(a, minf(a.until, now + 4.0) if hunted(a) else a.until)
	return true


## a kept at verb for secs, its time kept here (a body that has no doing
## of its own for it: stood still the while). Done as any order.
func hold(a: Agent, verb: String, secs: float) -> void:
	a.doing = verb
	a.doing_name = verb
	a.held = true
	a.until = now + secs
	wake(a, minf(a.until, now + 4.0) if hunted(a) else a.until)


## a to stop what it's doing (nothing told of it).
func halt(a: Agent) -> void:
	if a.body:
		a.issuing = true
		a.body.stop()
		a.issuing = false
	else:
		var p := where(a)
		a.p0 = p
		a.p1 = p
		a.t1 = now
	a.doing = ""
	a.held = false


# --- the land seeded, round the focus ---------------------------------------------

static func for_world(world: WorldData, holder: Node3D, seed_ := 1, population: Node = null) -> FaunaSim:
	## A FaunaSim for the game's land and its sea: its bodies under holder (a
	## node under Origin.root, unmoved: its space the map's), the ground
	## WorldData's (its floor under the sea, too), the water wherever the
	## ground's under sea level (the swamps' fresh, the rest salt), each
	## kind kept to its own (the land's off the sea and the cliffs; the
	## sea's in water deep enough for it), the land and the sea seeded by
	## each kind's density (Species.TABLE: by biome; "sea" the sea). What
	## they live on: perches and roosts in the trees there (population's,
	## where its trees are made: near the player; else up where a tree
	## would stand, in the wooded biomes; on the rock elsewhere), flowers
	## and webs anywhere on the land. To be added to the tree; each frame:
	## focus = the player's place (the map's), daylight = 1 - night. Once:
	## Fauna.day_secs = the game's day, in seconds.
	var sim := FaunaSim.new()
	sim.space = holder
	sim.height = world.height_at
	sim.walkable = func(x: float, z: float) -> bool:
		var sf := world.surface_at(x, z) # (its height, its normal)
		return sf.x > 0.3 and sf.z > 0.6
	var swamp := world.swamp
	sim.water = func(x: float, z: float) -> Vector3:
		var h := world.height_at(x, z)
		if h >= 0.0:
			return Vector3.ZERO
		return Vector3(0.0, -h, 1.0 if world.biome_index_at(x, z) == swamp and swamp >= 0 else 0.0)
	sim.sites = func(kind: String, at: Vector3, r: float) -> Array:
		var g := world.height_at(at.x, at.z)
		if kind == "perch" or kind == "roost":
			if population != null and population.has_method("climbs_near"):
				var out := []
				for c: Array in population.call("climbs_near", Vector3(at.x, g + 2.0, at.z), r):
					var line: PackedFloat32Array = c[0]
					var top := Vector3(line[0], line[1], line[2])
					for k in range(0, line.size() - 3, 4):
						if line[k + 1] > top.y:
							top = Vector3(line[k], line[k + 1], line[k + 2])
					out.append(top if kind == "perch" else top.lerp(Vector3(line[0], line[1], line[2]), 0.4))
				if not out.is_empty():
					return out
			var wooded := world.biome_at(at.x, at.z) in ["forest", "taiga", "swamp"]
			return [Vector3(at.x, g + (8.0 if wooded else 0.6), at.z)]
		return [Vector3(at.x, g, at.z)]
	sim.seeding = {"density": func(key: String, x: float, z: float) -> float:
				var b := world.biome_at(x, z)
				if world.height_at(x, z) < 0.0 and world.biome_index_at(x, z) != swamp:
					b = "sea"
				return Species.density_in(key, b),
			"inner": 150.0, "outer": 420.0, "seed": seed_}
	sim.far = FarFauna.new() # (those with no body, drawn far off)
	sim.add_child(sim.far)
	return sim


## Every cell within the seeding's outer of the focus seeded now, near or
## not (a game beginning: behind its loading screen).
func prime() -> void:
	if seeding.is_empty() or focus == Vector3.INF:
		return
	var outer := float(seeding.get("outer", 400.0))
	var c := Vector2i(floori(focus.x / SEED_CELL), floori(focus.z / SEED_CELL))
	var r := int(ceilf(outer / SEED_CELL))
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var k := c + Vector2i(dx, dz)
			if not seeded.has(k) and Vector2(dx, dz).length() * SEED_CELL <= outer:
				_seed_cell(k)


## (A few cells looked at a frame: one not yet seeded, between inner and
## outer of the focus, seeded.)
func _seed_tick() -> void:
	if seeding.is_empty() or focus == Vector3.INF:
		return
	var c := Vector2i(floori(focus.x / SEED_CELL), floori(focus.z / SEED_CELL))
	var inner := float(seeding.get("inner", 150.0))
	var outer := float(seeding.get("outer", 400.0))
	if c != _seed_from:
		_seed_from = c
		_seed_ring.clear()
		_seed_at = 0
		var r := int(ceilf(outer / SEED_CELL))
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if not seeded.has(c + Vector2i(dx, dz)):
					_seed_ring.append(c + Vector2i(dx, dz))
	for n in mini(2, _seed_ring.size() - _seed_at):
		var k: Vector2i = _seed_ring[_seed_at]
		_seed_at += 1
		if seeded.has(k):
			continue
		var mid := Vector2((k.x + 0.5) * SEED_CELL, (k.y + 0.5) * SEED_CELL)
		var d := mid.distance_to(Vector2(focus.x, focus.z))
		if d >= inner + SEED_CELL * 0.71 and d <= outer:
			_seed_cell(k)
	if _seed_at >= _seed_ring.size() and not _seed_ring.is_empty():
		_seed_from = Vector2i.MAX # (round again: those too near then may be far enough now)


func _seed_cell(k: Vector2i) -> void:
	seeded[k] = true
	var dens: Callable = seeding.get("density", Callable())
	if not dens.is_valid():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(seeding.get("seed", 1)), k.x, k.y])
	var x0 := k.x * SEED_CELL
	var z0 := k.y * SEED_CELL
	var area := SEED_CELL * SEED_CELL / 1e6 # km2
	for key: String in Species.keys():
		var sp := Species.of(key)
		var per := float(dens.call(key, x0 + SEED_CELL * 0.5, z0 + SEED_CELL * 0.5))
		if per <= 0.0:
			continue
		var group := 4.0 if bool(sp.herd) else 1.0 # (those that keep together: put down together)
		var want := per * area / group
		var groups := int(want) + (1 if rng.randf() < want - int(want) else 0)
		for g in groups:
			var at := Vector3(x0 + rng.randf() * SEED_CELL, 0.0, z0 + rng.randf() * SEED_CELL)
			if not can_be(sp, at):
				continue
			var n := rng.randi_range(2, 6) if bool(sp.herd) else 1
			for i in n:
				var p := at + Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)) * float(sp.len) * 3.0 * (0.0 if n == 1 else 1.0)
				if can_be(sp, p):
					add(key, p, rng.randf() < 0.5)


# --- kept, and brought back --------------------------------------------------------

## Everything of it to keep (a saved game's): its records (not those
## adopted: bodies someone else's), the cells seeded, its clock.
func to_dict() -> Dictionary:
	var list := []
	for a: Agent in agents.values():
		if a.kept:
			continue
		var p := where(a)
		list.append({"id": a.id, "key": a.key, "male": a.male, "young": a.young, "at": [p.x, p.y, p.z], "yaw": a.yaw,
				"home": [a.home.x, a.home.y, a.home.z], "hunger": a.hunger, "tired": a.tired,
				"carrying": maxf(a.pregnant_until - now, 0.001) if a.pregnant_until > 0.0 else 0.0, "sire": a.sire,
				"bred": now - a.bred_at, "mother": a.mother, "brood": a.brood.duplicate(), "age": now - a.born_at,
				"grows": maxf(a.grow_at - now, 0.0), "slot": a.slot, "spent": maxf(a.dies_at - now, 0.001) if a.dies_at > 0.0 else 0.0, "site": [a.site.x, a.site.y, a.site.z] if a.site != Vector3.INF else []})
	var cells := []
	for k: Vector2i in seeded:
		cells.append([k.x, k.y])
	return {"now": now, "next": _next, "agents": list, "seeded": cells}


## As to_dict() gave it: its records as they were (none with a body yet:
## those near the focus given theirs as ever).
func from_dict(d: Dictionary) -> void:
	for a: Agent in agents.values().duplicate():
		if not a.kept:
			if a.body and is_instance_valid(a.body):
				var c := a.body
				_detach(a)
				c.queue_free()
			remove(a)
	now = float(d.get("now", 0.0))
	_slot = int(floorf(now / SLOT))
	_clock.clear()
	seeded.clear()
	for c: Array in d.get("seeded", []):
		seeded[Vector2i(int(c[0]), int(c[1]))] = true
	_seed_from = Vector2i.MAX
	_next = maxi(int(d.get("next", 1)), _next) + 1000000 # (those made here numbered clear of the ones kept, till each has its own again)
	for e: Dictionary in d.get("agents", []):
		var at: Array = e["at"]
		var a := add(String(e["key"]), Vector3(at[0], at[1], at[2]), bool(e.get("male", false)), bool(e.get("young", false)))
		if a == null:
			continue
		agents.erase(a.id)
		a.id = int(e["id"])
		agents[a.id] = a
		a.p0 = Vector3(at[0], at[1], at[2]) # (as it was: not set on the ground again)
		a.p1 = a.p0
		var h: Array = e.get("home", at)
		a.home = Vector3(h[0], h[1], h[2])
		a.yaw = float(e.get("yaw", 0.0))
		a.hunger = float(e.get("hunger", 0.3))
		a.tired = float(e.get("tired", 0.2))
		var carrying := float(e.get("carrying", 0.0))
		a.pregnant_until = now + carrying if carrying > 0.0 else 0.0
		a.sire = int(e.get("sire", 0))
		a.bred_at = now - float(e.get("bred", 1e9))
		a.mother = int(e.get("mother", 0))
		a.brood.assign((e.get("brood", []) as Array).map(func(v: Variant) -> int: return int(v)))
		a.born_at = now - float(e.get("age", 0.0))
		a.grow_at = now + float(e.get("grows", 0.0))
		a.slot = int(e.get("slot", 0))
		var spent := float(e.get("spent", 0.0))
		a.dies_at = now + spent if spent > 0.0 else 0.0
		var st: Array = e.get("site", [])
		a.site = Vector3(st[0], st[1], st[2]) if st.size() == 3 else Vector3.INF
		if a.young:
			a.stage = stage_of(a)
			wake(a, minf(a.grow_at, now + 10.0))
	_next = int(d.get("next", 1))
	for id: int in agents:
		_next = maxi(_next, id + 1)
