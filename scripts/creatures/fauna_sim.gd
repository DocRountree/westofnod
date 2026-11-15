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
## signal died(agent, by): one's dead (hunted down: by its hunter's record).

signal died(agent: Agent, by: Agent)

const SLOT := 0.2 ## s: the clock's grain
const CELL := 16.0 ## m: the records' own cells
const RING_PER_M := 45.0 ## a body's ring: so many metres for each of its length
const RING_MIN := 18.0
const RING_MAX := 260.0
const RING_OUT := 1.35 ## freed again past its ring by this much

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
	var on_finished: Callable
	var on_gone: Callable

var space: Node3D ## the bodies' parent
var height: Callable ## (x, z) -> the ground's y
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
	a.p0 = _on_ground(at)
	a.p1 = a.p0
	a.home = a.p0
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
	if a.body:
		_detach(a)
	a.alive = false
	a.stamp += 1
	agents.erase(a.id)
	_unfile(a)


## The record of a body (null: it has none).
func agent_of(c: Creature) -> Agent:
	return _by_body.get(c.fauna_id) if c else null


## Where it is now (the space's).
func where(a: Agent) -> Vector3:
	if a.body:
		return a.body.where()
	if now >= a.t1 or a.t1 <= a.t0:
		return a.p1
	return a.p0.lerp(a.p1, (now - a.t0) / (a.t1 - a.t0))


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
	if a.body == null and a.doing != "" and now >= a.until - 1e-3: # (with no body: its order's time is up)
		var d := a.doing
		a.doing = ""
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
		if not a.alive:
			continue
		var p := where(a)
		var d := Vector2(p.x - focus.x, p.z - focus.z).length()
		var r := ring(a)
		if a.body == null:
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
	var c := Species.make(a.key, space, p, a.yaw, a.male, a.young, height)
	if c == null:
		return false
	a.p0 = p
	a.p1 = p
	_attach(a, c)
	a.doing = ""
	wake(a, now + 0.1)
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


func _attach(a: Agent, c: Creature) -> void:
	a.body = c
	_by_body[c.fauna_id] = a
	a.on_finished = _finished.bind(a)
	a.on_gone = _body_gone.bind(a, c)
	c.action_finished.connect(a.on_finished)
	c.tree_exiting.connect(a.on_gone)


func _detach(a: Agent) -> void:
	var c := a.body
	if c == null:
		return
	a.body = null
	_by_body.erase(c.fauna_id)
	if is_instance_valid(c):
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
	elif what == &"killed" and data.get("prey") is Creature:
		var a: Agent = _by_body.get((data["prey"] as Creature).fauna_id)
		if a != null:
			_dead(a, _by_body.get((who as Creature).fauna_id) if who is Creature else null)


## a's dead (its body, if it has one, left as it lies: its hunter's to eat).
func _dead(a: Agent, by: Agent) -> void:
	if not a.alive:
		return
	_detach(a)
	a.alive = false
	a.stamp += 1
	agents.erase(a.id)
	_unfile(a)
	_hunters.clear()
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
func go_to(a: Agent, point: Vector3, running := false) -> void:
	point = _on_ground(point)
	a.doing = "go_to"
	a.doing_name = "go_to"
	if a.body:
		a.issuing = true
		a.body.go_to(point, a.body._p_speed() * (float(a.sp.run) / maxf(float(a.sp.walk), 0.01)) if running else -1.0)
		a.issuing = false
		wake(a, now + 4.0) # (to look about as it goes)
		return
	var from := where(a)
	var sp := float(a.sp.run if running else a.sp.walk)
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
