class_name Fauna
extends RefCounted
## The world's book of its animals: every Creature in the tree (bodies),
## each with its number; what's near what (near(): each space's things
## filed by where they are, so a search looks only round itself); what
## they do that changes the numbers (report(), listen()); how fast their
## lives run (life_rate); and how often each one's frame comes (pace()).
##
## A space: a node and its children (the sandbox; in the game, the land's
## creatures' holder): what Diet.find searches, a creature among its
## siblings. Everything with a script or a food's meta in it is filed by its
## place (Diet._at: its _pos, its home, its position), in CELL-metre
## cells; Creatures filed again as they move (each tick), the rest looked
## over a few a frame (things are carried, dragged, put down).

const CELL := 8.0 ## m
const RECHECK := 48 ## of a space's still things looked over again each time it's searched

static var bodies: Array[Creature] = []
static var _next_id := 1
static var _by_id := {} # id -> WeakRef
static var _spaces := {} # the space's instance id -> _Space
static var _listeners: Array[Callable] = []

## Their lives' pace: growing, incubating, gestating run this many times
## as fast as their own figures (the sandbox's: quick to watch).
static var life_rate := 1.0

## Pacing (pace()): bodies within near of the focus every frame, to far
## every mid-th, beyond every far_every-th.
static var pace_near := 40.0
static var pace_far := 120.0
static var pace_mid_every := 2
static var pace_far_every := 6
static var pace_sight := 400.0 ## m: past this none is posed


class _Space:
	var grid := {} # Vector2i -> Array[Node3D]
	var cell_of := {} # instance id -> Vector2i
	var still: Array = [] # (not Creatures: looked over again in turn)
	var pending: Array = [] # (come in, not yet filed: their places are set after they're added)
	var at := 0

	func file(n: Node3D, c: Vector2i) -> void:
		var id := n.get_instance_id()
		var old: Variant = cell_of.get(id)
		if old != null:
			if old == c:
				return
			var a: Array = grid.get(old, [])
			a.erase(n)
			if a.is_empty():
				grid.erase(old)
		cell_of[id] = c
		if grid.has(c):
			(grid[c] as Array).append(n)
		else:
			grid[c] = [n]

	func drop(n: Node) -> void:
		var id := n.get_instance_id()
		var old: Variant = cell_of.get(id)
		if old != null:
			var a: Array = grid.get(old, [])
			a.erase(n)
			if a.is_empty():
				grid.erase(old)
			cell_of.erase(id)
		still.erase(n)
		pending.erase(n)


static func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.z / CELL))


## (A creature's come into the tree.)
static func join(c: Creature) -> void:
	if c.fauna_id == 0:
		c.fauna_id = _next_id
		_next_id += 1
	_by_id[c.fauna_id] = weakref(c)
	if not bodies.has(c):
		bodies.append(c)


static func leave(c: Creature) -> void:
	bodies.erase(c)


## The body numbered id (null: it has none now).
static func body(id: int) -> Creature:
	var w: WeakRef = _by_id.get(id)
	if w == null:
		return null
	var c: Variant = w.get_ref()
	if c == null:
		_by_id.erase(id)
		return null
	return c as Creature


# --- what's near ----------------------------------------------------------------

static func _space(parent: Node) -> _Space:
	var key := parent.get_instance_id()
	var sp: _Space = _spaces.get(key)
	if sp != null:
		return sp
	sp = _Space.new()
	_spaces[key] = sp
	for o in parent.get_children():
		if o is Node3D:
			sp.pending.append(o)
	parent.child_entered_tree.connect(func(n: Node) -> void:
		if n is Node3D:
			sp.pending.append(n))
	parent.child_exiting_tree.connect(func(n: Node) -> void: sp.drop(n))
	parent.tree_exiting.connect(func() -> void: _spaces.erase(key))
	return sp


static func _place_of(n: Node3D) -> Vector3:
	var q: Variant = n.get("_pos")
	if q is Vector3:
		return q
	var h: Variant = n.get_meta("home", null) if n.has_meta("home") else null
	return h if h is Vector3 else n.position


## (A creature's had its frame: filed where it is now, if its space is kept.)
static func moved(c: Creature) -> void:
	var par := c.get_parent()
	if par == null:
		return
	var sp: _Space = _spaces.get(par.get_instance_id())
	if sp != null and sp.cell_of.has(c.get_instance_id()):
		sp.file(c, _cell(_place_of(c)))


## Everything in parent (its children: Node3Ds) within r of p (level: x, z;
## its space), by where each is (Diet._at).
static func near(parent: Node, p: Vector3, r: float) -> Array:
	var sp := _space(parent)
	for n in sp.pending:
		if is_instance_valid(n) and n.get_parent() == parent:
			sp.file(n, _cell(_place_of(n)))
			sp.still.append(n)
	sp.pending.clear()
	# (the creatures are filed again as they move, moved(); the rest, and
	# any creature held still, a few looked over again each search)
	for i in mini(sp.still.size(), RECHECK):
		sp.at = (sp.at + 1) % sp.still.size()
		var n: Node3D = sp.still[sp.at]
		if is_instance_valid(n):
			sp.file(n, _cell(_place_of(n)))
	var lo := _cell(p - Vector3(r, 0.0, r))
	var hi := _cell(p + Vector3(r, 0.0, r))
	var out := []
	if (hi.x - lo.x + 1) * (hi.y - lo.y + 1) >= sp.grid.size(): # (few cells in use: those)
		for c: Vector2i in sp.grid:
			if c.x >= lo.x and c.x <= hi.x and c.y >= lo.y and c.y <= hi.y:
				out.append_array(sp.grid[c])
	else:
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				var a: Variant = sp.grid.get(Vector2i(x, y))
				if a != null:
					out.append_array(a)
	return out


# --- what happens ----------------------------------------------------------------

## f(what: StringName, who: Node, data: Dictionary) told of everything
## reported from now on.
static func listen(f: Callable) -> void:
	if not _listeners.has(f):
		_listeners.append(f)


static func unlisten(f: Callable) -> void:
	_listeners.erase(f)


## Something that changes the world's numbers: "died" {by}, "killed"
## {prey}, "ate" {food, kind}, "born" {young: [...]}, "laid" {eggs, n},
## "hatched" {young}, "mated" {partner}.
static func report(what: StringName, who: Node, data := {}) -> void:
	for f in _listeners:
		if f.is_valid():
			f.call(what, who, data)


# --- pacing ---------------------------------------------------------------------

static var _swarms := {} # instance id -> [node, every, time kept, the frame it last asked]


## A swarm's frame (a colony, a school, a pool: everything of its kind in
## one node, not a Creature): the time to step by now, or 0 to leave this
## frame out (paced: far off, every few frames, with all the time since).
## Asked first thing in its _process; asked again the same frame (its
## parent class's), dt as it is.
static func swarm_dt(node: Node, dt: float) -> float:
	var id := node.get_instance_id()
	var e: Variant = _swarms.get(id)
	var f := Engine.get_process_frames()
	if e == null:
		e = [node, 1, 0.0, -1, 0.0]
		_swarms[id] = e
		node.tree_exited.connect(func() -> void: _swarms.erase(id), CONNECT_ONE_SHOT)
	if e[3] == f:
		return e[4]
	e[3] = f
	e[4] = dt
	if int(e[1]) > 1:
		e[2] = float(e[2]) + dt
		if (f + id) % int(e[1]) != 0:
			e[4] = 0.0
		else:
			e[4] = minf(float(e[2]), 0.25)
			e[2] = 0.0
	return e[4]


## Each body's pace by how far it is from focus (the world's space: the
## camera): tick_every set; and whether it's seen (within pace_near, or
## in cam's view within pace_sight). Called now and then (a few times a
## second). focus INF: every one every frame, seen.
static func pace(focus: Vector3, cam: Camera3D = null) -> void:
	for c in bodies:
		if focus == Vector3.INF:
			c.tick_every = 1
			c.seen = true
			continue
		var at := c.global_position
		var d := at.distance_to(focus)
		c.tick_every = 1 if d < pace_near else (pace_mid_every if d < pace_far else pace_far_every)
		c.seen = d < pace_near or (d < pace_sight and (cam == null or cam.is_position_in_frustum(at)))
	for id: int in _swarms:
		var e: Array = _swarms[id]
		var n := e[0] as Node3D
		if n == null or not is_instance_valid(n) or not n.is_inside_tree():
			continue
		if focus == Vector3.INF:
			e[1] = 1
			continue
		var d := n.global_position.distance_to(focus) - float(n.get_meta("swarm_reach", 0.0)) # (its members' reach from its own place, if it says)
		e[1] = 1 if d < pace_near else (pace_mid_every if d < pace_far else pace_far_every)
