class_name Felling
extends Node
## Felling trees with the axe. With an axe in either hand, the left mouse
## button swings it; a swing that reaches a standing tree's trunk (live oak,
## dead oak or sapling: Population.choppable_near) is a blow, and enough blows
## (more the thicker the trunk) fell it. Each blow cuts the notch deeper and
## wider (a V in the trunk on the side the blows come from, at the height the
## stump will be: Population.set_notch, drawn by bark.gdshader). Felled, the
## tree leaves the population for good (Population.remove_prop) and falls
## away from the player, off a fresh-sawn stump left where it stood
## (OakTree.fresh_stump: its top chopped flat in strokes, pale wood, no moss;
## none for a sapling), its foot landing a little beyond the stump, and lies
## where it fell, its trunk along the ground, pressed only a few cm into it
## (pitched up from its foot where it would sink further: _rest); its crown
## and limbs go into the ground as they will.
##
## The swing is sideways, from the axe's side across: the blade's edge
## leading, sweeping round the body in a level arc tilted to pass through
## the point it aims at, the notch's middle on the trunk in reach (or ahead
## at waist height with none), and meeting it at the strike.
##
## The fallen trees and their stumps are saved with the game (to_list,
## from_list: main.gd), as nodes under Origin.root (their positions the
## map's), each drawn with its kind's levels of detail as the population
## draws them (the shaders pick the level by distance). A felled tree can
## be stood on and climbed as a log and a standing tree are: its trunk and
## limbs as they lie (Population.add_fallen: its climbable lines, and the
## segments between their nodes to stand on).

const REACH := 1.3 ## m from the trunk's surface
const SWING := 0.6 ## s, a swing
const STRIKE := 0.62 ## where in the swing the blade meets the trunk (0..1)
const BLOW_DEPTH := 0.045 ## m of trunk radius one blow cuts: a 0.5 m trunk takes 11
const FALL_TIME := 2.6 ## s, a full-sized tree from upright to the ground
const CUT := 1.0 ## of the stump model's own height (its flat-sawn top): where the trunk comes away
const KICK := 0.5 ## m beyond the stump (and as much again as the trunk's radius) the felled trunk's foot lands
## How far a felled trunk's underside may press into the ground (m), and as
## much again as this share of its radius there: past that it's pitched up
## off it (_rest). Only the trunk counts: the crown and the limbs go into
## the ground as they will.
const SINK := 0.06
const SINK_SHARE := 0.12
const RING := 8 ## points round the trunk at each of its nodes (_rest_points)
const REST_VERSION := 3 ## (saved with a felled tree: laid afresh as it loads if laid by an earlier rule)
const WIND_UP := 1.5 ## rad round from the aim the swing starts (to the axe's side)
const FOLLOW := 0.6 ## rad past the aim it follows through
const HANDLE := 0.43 ## m from the grip to the head (Items._axe)
const EDGE := 0.135 ## m from the handle to the blade's edge

var main: Node
var _swing := -1.0 # 0..1 through a swing; < 0 none
var _struck := false
var _repeat := false # the button held since a swing began: swing again (_keep_swinging)
var _blows := {} # tree uid -> blows so far
var _heights := {} # tree uid -> the height (m over its foot) its notch is cut at: where the first blow was aimed
var _aim := Vector3.INF # the swing's mark (on the map): the notch's middle; INF none
var _falling: Array = [] # {node, axis, angle, t, time, pivot, basis}
var _lying: Array = [] # what to_list saves, one entry a tree


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or main.player.typing or main.player.frozen:
		return
	if _axe_hand() < 0 or main.player.climbing:
		return
	_repeat = true # (held down: swings again and again until the tree is down)
	if _swing < 0.0:
		_start_swing()
	get_viewport().set_input_as_handled()


func _start_swing() -> void:
	_swing = 0.0
	_struck = false
	_aim = _mark()


## Held down: another swing as one ends, as long as
## the tree being chopped still stands (once it's down, let go and click again).
func _keep_swinging() -> void:
	if not _repeat:
		return
	var p: Player = main.player
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			or p.typing or p.frozen or p.climbing or _axe_hand() < 0:
		_repeat = false
		return
	if _swing < 0.0:
		_start_swing()


## Where a swing now would strike (on the map): the middle of the notch on
## the trunk in reach, facing the view; INF if none.
func _mark() -> Vector3:
	var p: Player = main.player
	var tree: Dictionary = main.population.choppable_near(Origin.map(p.camera.global_position), -p.camera.global_basis.z, REACH)
	if tree.is_empty():
		return Vector3.INF
	var at: Vector3 = (tree.transform as Transform3D).origin
	return at + Vector3.UP * _tree_cut(tree) + _notch_side() * float(tree.radius)


const CUT_LOW := 0.12 ## m: the lowest a tree can be cut (over its foot)
const CUT_HIGH := 1.9 ## m: the highest (a swing at shoulder height)


## The height (m over its foot) a tree is cut at: where its notch was begun,
## or (none yet) where the view meets its trunk: aim low, a low stump; aim
## high, a tall one. Never above about two fifths of the tree.
func _tree_cut(tree: Dictionary) -> float:
	if _heights.has(tree.uid):
		return _heights[tree.uid]
	var p: Player = main.player
	var eye := Origin.map(p.camera.global_position)
	var fwd := -p.camera.global_basis.z
	var xf: Transform3D = tree.transform
	var to := Vector2(xf.origin.x - eye.x, xf.origin.z - eye.z)
	var flat := maxf(Vector2(fwd.x, fwd.z).length(), 0.05)
	var t := maxf(to.length() - float(tree.radius), 0.0) / flat # (along the view, to the bark)
	var h := eye.y + fwd.y * t - xf.origin.y
	var kind: PropKind = tree.kind
	var top := kind.mesh.get_aabb().end.y * xf.basis.get_scale().y * 0.4
	return clampf(h, CUT_LOW, maxf(minf(CUT_HIGH, top), CUT_LOW))


## The side of the trunk the notch is cut in (on the map, across the ground,
## unit): the side the axe swings in from, square to the view (the right
## for an axe in the right hand).
func _notch_side() -> Vector3:
	var right := (main.player as Player).camera.global_basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else (main.player as Player).global_basis.x
	return right * (1.0 if _axe_hand() != 0 else -1.0)


## The way the player looks, across the ground (on the map, unit).
func _view_dir() -> Vector3:
	var f := -(main.player as Player).camera.global_basis.z
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else -(main.player as Player).global_basis.z


## Which hand holds an axe: 1 right, 0 left, -1 neither (the right first).
func _axe_hand() -> int:
	var inv: Inventory = main.inventory
	if str(inv.right.get("id", "")) == "axe":
		return 1
	if str(inv.left.get("id", "")) == "axe":
		return 0
	return -1


func _process(delta: float) -> void:
	_keep_swinging()
	_animate_swing(delta)
	for f in _falling.duplicate():
		f.t = minf(f.t + delta, f.time)
		var u: float = f.t / f.time
		var a: float = f.angle * u * u # (gathering speed as it goes over)
		var turn := Basis(f.axis, a)
		# the trunk's foot starts where it stood (below the cut, in the
		# stump) and slides off the stump's top as it goes over, landing a
		# little beyond it
		f.node.transform = Transform3D(turn * f.basis, f.pivot - turn * Vector3.UP * f.cut * (1.0 - u) + (f.end - f.pivot) * u * u)
		if f.t >= f.time:
			_falling.erase(f)


func _animate_swing(delta: float) -> void:
	var hand := _axe_hand()
	var avatar: Avatar = main.player.avatar
	if hand < 0 or _swing < 0.0:
		avatar.arm_targets.clear()
		if hand >= 0:
			for m in _held_models(hand):
				m.transform = Transform3D() # (at rest in the hand)
		return
	_swing += delta / SWING
	var t := _swing
	if not _struck and t >= STRIKE:
		_struck = true
		_strike()
	if _swing >= 1.0:
		_swing = -1.0
		avatar.arm_targets.clear()
		for m in _held_models(hand):
			m.transform = Transform3D()
		return
	# out to the side (wind up), round to the mark faster and faster, on
	# through it, and back to the hand
	var side := 1.0 if hand == 1 else -1.0
	var phi := 0.0
	var w := 1.0
	if t < 0.3:
		phi = WIND_UP
		w = smoothstep(0.0, 1.0, t / 0.3)
	elif t < STRIKE:
		var k := (t - 0.3) / (STRIKE - 0.3)
		phi = WIND_UP * (1.0 - k * k)
	else:
		# into the notch it stops there (lodged a moment, then pulled back);
		# swung at nothing it follows on through
		var follow := 0.0 if _aim != Vector3.INF else FOLLOW
		phi = -follow * smoothstep(0.0, 1.0, minf((t - STRIKE) / (0.8 - STRIKE), 1.0))
		if t >= 0.8:
			w = 1.0 - smoothstep(0.0, 1.0, (t - 0.8) / 0.2)
	var pose := _swing_pose(phi * side, side)
	var p: Player = main.player
	var view: Node3D = p._view_grips[hand]
	var grip: Node3D = avatar.grip("l" if hand == 0 else "r")
	# first person: the axe alone, swung
	for m in view.get_children():
		if not m.is_queued_for_deletion():
			m.global_transform = view.global_transform.interpolate_with(pose, w)
	# the figure: it turns to face the swing, both hands take the handle
	# (the axe's hand at the grip, the other a hand's breadth below) and
	# the arms follow it round; the axe sits in the hand as far as the arm
	# reaches
	if avatar.visible and grip:
		avatar.global_basis = Basis(Vector3.UP, p.rotation.y)
		var held := Transform3D(grip.global_transform.basis.orthonormalized(), grip.global_position)
		var at := held.interpolate_with(pose, w)
		var down := -at.basis.y.normalized()
		var right := avatar.global_basis.x
		var me := "l" if hand == 0 else "r"
		var other := "r" if hand == 0 else "l"
		avatar.arm_targets[me] = [at.origin, Vector3.DOWN + right * side * 0.6]
		avatar.arm_targets[other] = [at.origin + down * 0.14, Vector3.DOWN - right * side * 0.6]
		for m in grip.get_children():
			if not m.is_queued_for_deletion():
				m.global_transform = Transform3D(at.basis, grip.global_position)


## The axe (its grip) in the world, swung round to phi (rad from the mark;
## the side it comes from: +1 the right): round the chest in a level arc,
## tilted to pass through the mark, the handle out along the arc's radius,
## the blade's edge leading.
func _swing_pose(phi: float, side: float) -> Transform3D:
	var p: Player = main.player
	var head: Transform3D = p.head.global_transform
	var centre := Vector3(0.0, -0.5, 0.0) # (the chest, in the head's space)
	var mark := Vector3(0.0, -0.45, -1.1) # (ahead, at the waist: no tree in reach)
	if _aim != Vector3.INF:
		mark = head.affine_inverse() * Origin.render(_aim)
	var to := mark - centre
	var dist := maxf(to.length(), HANDLE + 0.1)
	var elev := asin(clampf(to.y / dist, -1.0, 1.0))
	var yaw := atan2(to.x, -to.z) + phi
	var out := Vector3(sin(yaw) * cos(elev), sin(elev), -cos(yaw) * cos(elev))
	var moving := -side * Vector3(cos(yaw), 0.0, sin(yaw)) # (phi falling toward the mark)
	moving = (moving - out * moving.dot(out)).normalized()
	var z := -moving
	var x := out.cross(z).normalized()
	var grip := centre + out * dist - out * HANDLE - moving * EDGE
	return head * Transform3D(Basis(x, out, z), grip)


## The axe's models (first-person and in the figure's hand).
func _held_models(hand: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var p: Player = main.player
	var holders: Array[Node3D] = [p._view_grips[hand]]
	var g: Node3D = p.avatar.grip("l" if hand == 0 else "r")
	if g:
		holders.append(g)
	for h in holders:
		for c in h.get_children():
			if not c.is_queued_for_deletion():
				out.append(c)
	return out


func _strike() -> void:
	var p: Player = main.player
	var eye := Origin.map(p.camera.global_position)
	var fwd := -p.camera.global_basis.z
	var tree: Dictionary = main.population.choppable_near(eye, fwd, REACH)
	if tree.is_empty():
		return
	var need := clampi(ceili(float(tree.radius) / BLOW_DEPTH), 2, 14)
	var n: int = _blows.get(tree.uid, 0) + 1
	var cut := _tree_cut(tree)
	_heights[tree.uid] = cut # (the first blow sets the notch's height: the rest go into it)
	if n < need:
		_blows[tree.uid] = n
		_notch(tree, _notch_side(), float(n) / need, cut)
		return
	_blows.erase(tree.uid)
	_heights.erase(tree.uid)
	_repeat = false # (down: no more swings till the button's pressed again)
	main.population.remove_prop(tree.uid)
	var xf: Transform3D = tree.transform
	var away := _notch_side() # (falling toward the notch, as a tree does: square to the view)
	var stripes := _view_dir() # (the axe's strokes across the cut run square to the notch's)
	var entry := _fell(tree.kind, tree.variant, xf, tree.radius, away, stripes, cut)
	var f: Dictionary = entry.falling
	_falling.append(f)
	entry.erase("falling")
	_lying.append(entry)


## Puts a felled tree in the world: its stump (if it has one) and the tree,
## upright, to fall over toward `away`. Returns the entry to save, with
## "falling" the fall to animate.
func _fell(kind: PropKind, variant: int, xf: Transform3D, radius: float, away: Vector3, stripes: Vector3, cut: float) -> Dictionary:
	var world: WorldData = main.world
	var stump_scale := _stump_scale(radius)
	var stump_h := _stump_height(cut)
	var pivot := xf.origin + Vector3.UP * cut
	var axis := Vector3.UP.cross(away).normalized()
	var lie := _lie(kind, variant, xf, radius, away, cut)
	var angle: float = lie[0]
	var end: Vector3 = lie[1]
	var height := kind.mesh.get_aabb().end.y * xf.basis.get_scale().y
	var entry := {
		"kind": String(kind.id), "basis": _floats(xf.basis), "at": [xf.origin.x, xf.origin.y, xf.origin.z],
		"away": [away.x, away.z], "angle": angle, "cut": cut, "stump_scale": stump_scale, "stump_h": stump_h,
		"end": [end.x, end.y, end.z], "stripes": [stripes.x, stripes.z], "rested": REST_VERSION,
	}
	var node := _model(_felled_meshes(kind, variant))
	node.transform = xf
	_cut_base(node, kind, variant, xf, cut, stripes)
	if stump_scale > 0.0:
		var sn := _model([OakTree.fresh_stump()[0]] + OakTree.fresh_stump()[1])
		sn.transform = Transform3D(_stump_basis(stripes, stump_scale, stump_h), xf.origin)
		_solid_stump(xf.origin, cut, stump_scale)
	_solid(kind, Transform3D(Basis(axis, angle) * xf.basis, end), cut)
	entry.falling = {"node": node, "axis": axis, "angle": angle, "t": 0.0, "cut": cut, "end": end,
			"time": FALL_TIME * sqrt(maxf(height, 1.0) / 15.0), "pivot": pivot, "basis": xf.basis}
	return entry


## Where a felled tree (its own basis xf.basis, standing at xf.origin, cut
## `cut` m up, its trunk `radius` thick) comes to rest, falling toward
## `away`: [angle it's pitched over round its axis, where its foot lands].
## Its foot lands beyond the stump, its underside just into the ground; it
## goes over till its trunk, about half its height out, comes down on the
## ground; then it's pitched up off it where its trunk would sink in further
## than a little (_rest).
func _lie(kind: PropKind, variant: int, xf: Transform3D, radius: float, away: Vector3, cut: float) -> Array:
	var world: WorldData = main.world
	var pivot := xf.origin + Vector3.UP * cut
	var end := pivot + away * (KICK + radius)
	end.y = maxf(world.height_at(end.x, end.z) + radius * 0.92, xf.origin.y)
	var height := kind.mesh.get_aabb().end.y * xf.basis.get_scale().y
	var reach := height * 0.5
	var ground := world.height_at(end.x + away.x * reach, end.z + away.z * reach)
	var angle := clampf(PI * 0.5 + atan2(end.y - ground, reach), deg_to_rad(65.0), deg_to_rad(105.0))
	return _rest(kind, variant, xf.basis, Vector3.UP.cross(away).normalized(), angle, end, cut)


## As it was to lie (pitched angle round axis, its foot at end; its own
## basis), unless its trunk would sink further into the ground than a little
## (SINK, SINK_SHARE of its radius), when it's pitched up about its foot till
## it doesn't; and if even pitched up as far as it goes that's not enough, raised as
## well. Only the trunk is tried against the ground, ring by ring at each of
## its nodes: the crown and the limbs sink as they will. [angle, end].
func _rest(kind: PropKind, variant: int, basis: Basis, axis: Vector3, angle: float, end: Vector3, cut: float) -> Array:
	var world: WorldData = main.world
	var rp := _rest_points(kind, variant)
	var pts: PackedVector3Array = rp[0]
	var radii: PackedFloat32Array = rp[1]
	var s := basis.get_scale().y
	var h := cut / s # (the tree's own units: what's below stays in the stump)
	# how much deeper into the ground than it may go its worst part goes, pitched a
	var over := func(a: float) -> float:
		var t := Transform3D(Basis(axis, a) * basis, end)
		var most := -INF
		for i in pts.size():
			var p := pts[i]
			if p.y <= h:
				continue
			var w := t * p
			most = maxf(most, world.height_at(w.x, w.z) - w.y - (SINK + SINK_SHARE * radii[i] * s))
		return most
	if over.call(angle) <= 0.0:
		return [angle, end]
	var lo := minf(deg_to_rad(55.0), angle) # (the most it's pitched up)
	var d: float = over.call(lo)
	if d > 0.0:
		return [lo, end + Vector3.UP * d]
	# pitched up only as far as it needs (lo rests, hi sinks)
	var hi := angle
	for i in 8:
		var mid := (lo + hi) * 0.5
		if over.call(mid) <= 0.0:
			lo = mid
		else:
			hi = mid
	return [lo, end]


static var _rest_cache := {} # [kind id, variant] -> [points, their trunk's radius]


## Points round a tree's trunk (its own space) for _rest, a ring at each of
## its nodes (kind.climb's first line: the trunk as drawn, its radius), and
## each one's trunk radius. A tree with no trunk to climb (a sapling): a
## straight one up its middle, tapering, to six tenths of its height.
static func _rest_points(kind: PropKind, variant: int) -> Array:
	var key := [String(kind.id), variant]
	if not _rest_cache.has(key):
		var nodes: Array[Vector4] = [] # x, y, z, radius
		var c := kind.climb
		if not c.is_empty():
			var n := int(c[0])
			for m in n:
				var k := 1 + m * 4
				nodes.append(Vector4(c[k], c[k + 1], c[k + 2], c[k + 3]))
		else:
			var r0: float = kind.mesh_script.trunk_radius(variant) if kind.mesh_script and kind.mesh_script.has_method("trunk_radius") else 0.05
			var top := kind.mesh.get_aabb().end.y * 0.6
			for m in 9:
				var f := m / 8.0
				nodes.append(Vector4(0.0, top * f, 0.0, r0 * (1.0 - 0.7 * f)))
		var out := PackedVector3Array()
		var radii := PackedFloat32Array()
		for m in nodes.size():
			var q := Vector3(nodes[m].x, nodes[m].y, nodes[m].z)
			var nxt := Vector3(nodes[m + 1].x, nodes[m + 1].y, nodes[m + 1].z) if m < nodes.size() - 1 else q
			var prv := Vector3(nodes[m - 1].x, nodes[m - 1].y, nodes[m - 1].z) if m > 0 else q
			var along := (nxt - prv).normalized() if nxt != prv else Vector3.UP
			var u := along.cross(Vector3.UP if absf(along.y) < 0.9 else Vector3.RIGHT).normalized()
			var v := along.cross(u)
			for j in RING:
				var a := TAU * j / RING
				out.append(q + (u * cos(a) + v * sin(a)) * nodes[m].w)
				radii.append(nodes[m].w)
		_rest_cache[key] = [out, radii]
	return _rest_cache[key]


## The stump turned so its own x runs the way the axe came, away from the
## player (bark.gdshader lays the chopped top's strokes along it: square to
## the notch's), s across, sy up (as tall as the cut: _stump_height).
static func _stump_basis(away: Vector3, s: float, sy := -1.0) -> Basis:
	return Basis(Vector3.UP, atan2(-away.z, away.x)).scaled(Vector3(s, s if sy < 0.0 else sy, s))


## The stump's scale across for a trunk of this radius (the stump is 0.5 m
## round at the foot).
static func _stump_scale(radius: float) -> float:
	return radius / 0.5


## The stump's scale up, for a cut this high (m): its top where the trunk
## came away (CUT of the stump model's own height).
static func _stump_height(cut: float) -> float:
	return cut / (OakTree.fresh_stump()[0].get_aabb().end.y * CUT)


## A blow's mark: the notch, done part of the way (0..1), facing `toward`
## (on the map, across the ground: back along the player's view, so the cut
## lies square to it).
func _notch(tree: Dictionary, toward: Vector3, done: float, cut: float) -> void:
	var xf: Transform3D = tree.transform
	var s := xf.basis.get_scale().x
	var to := xf.basis.inverse() * toward # (the tree's own space)
	var h := cut / s
	# the trunk's radius there as drawn (the roots' flare widens it), a little
	# over (the bark's ridges): the notch's mouth is at the bark
	var r: float = float(tree.radius) / s
	var kind: PropKind = tree.kind
	if kind.mesh_script and kind.mesh_script.has_method("trunk_radius_at"):
		r = kind.mesh_script.trunk_radius_at(int(tree.variant), h)
	r *= 1.08
	var depth := r * 1.05 * done # (about half way through, by the last blow)
	main.population.set_notch(tree.uid, Color(atan2(to.z, to.x), depth, h, r))


## A felled tree, lying at t (on the map), to stand on and climb: its kind's
## climbable lines (the trunk from the cut up, the limbs) as they lie, and
## between each line's nodes a segment to stand on, which keeps the grass
## and ferns off too (Population.walk_near), as the stump's post does.
func _solid(kind: PropKind, t: Transform3D, cut: float) -> void:
	var c := kind.climb
	if c.is_empty():
		return
	var s := t.basis.get_scale().y
	var h := cut / s # (the tree's own units)
	var walk := PackedFloat32Array()
	var trunks: Array[PackedFloat32Array] = []
	var k := 0
	var first := true
	while k < c.size():
		var n := int(c[k])
		k += 1
		var pts: Array[Vector4] = [] # (x, y, z, radius: the tree's own)
		for m in n:
			pts.append(Vector4(c[k], c[k + 1], c[k + 2], c[k + 3]))
			k += 4
		if first:
			# the trunk from the cut up (below it is the stump's)
			while pts.size() >= 2 and pts[1].y <= h:
				pts.pop_front()
			if pts.size() >= 2 and pts[0].y < h:
				var u := (h - pts[0].y) / maxf(pts[1].y - pts[0].y, 1e-4)
				pts[0] = pts[0].lerp(pts[1], u)
		var line := PackedFloat32Array()
		for q in pts:
			var p := t * Vector3(q.x, q.y, q.z)
			line.append_array([p.x, p.y, p.z, q.w * s])
		if line.size() >= 8:
			trunks.append(line)
			for i in range(4, line.size(), 4):
				var r0 := line[i - 1] # (limbs too: they lie on the ground, so keep the grass off as the trunk does)
				walk.append_array([line[i - 4], line[i - 3], line[i - 2], line[i], line[i + 1], line[i + 2], r0, line[i + 3]])
		first = false
	main.population.add_fallen(walk, trunks)


## The stump left, to stand on as the stumps are: a post to its top.
func _solid_stump(at: Vector3, top: float, s: float) -> void:
	main.population.add_fallen(PackedFloat32Array([at.x, at.y, at.z, at.x, at.y + top, at.z, 0.5 * s, 0.5 * s]), [] as Array[PackedFloat32Array])


## A felled tree's meshes (every level of detail): the cut variant, so its
## foot is a cut face (OakTree.cut_meshes).
static func _felled_meshes(kind: PropKind, variant: int) -> Array:
	if kind.mesh_script and kind.mesh_script.has_method("cut_meshes"):
		var cm: Array = kind.mesh_script.cut_meshes(variant)
		return [cm[0]] + cm[1]
	return [kind.mesh] + kind.lods


## A felled tree's foot: not drawn below the cut (that stays in the stump),
## closed there by the cut face (bark.gdshader, BARK_CUT: cut_below, cut_r;
## OakTree.felled_material).
func _cut_base(node: Node3D, kind: PropKind, variant: int, xf: Transform3D, cut: float, stripes: Vector3) -> void:
	var s := xf.basis.get_scale().y
	var h := cut / s
	var r := 0.5
	if kind.mesh_script.has_method("trunk_radius_at"):
		r = kind.mesh_script.trunk_radius_at(variant, h) # (the rings' scale)
	# the strokes across the cut, the stump's way (in the tree's own space)
	var sl := xf.basis.inverse() * stripes
	var sd := Vector2(sl.x, sl.z).normalized() if Vector2(sl.x, sl.z).length() > 1e-4 else Vector2(1.0, 0.0)
	# (its own copy of each level's cut bark, set to its cut)
	var cap: ShaderMaterial = null
	for c2 in node.get_children():
		var mi := c2 as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for si in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(si) as ShaderMaterial
			if mat and mat.shader == OakTree._cut_shader:
				var fm := OakTree.felled_material(mat, h, r, sd)
				mi.set_surface_override_material(si, fm)
				if cap == null:
					cap = fm
	# the cut itself, a face across the foot (just inside the wood, beyond
	# the cut seen from outside: the material draws there the cut it sees
	# through the trunk's open foot; on this side of it, it drew nothing), so the wood
	# is there in depth: where the foot sinks into the ground the ground
	# hides it, not the trunk's inside behind it (with the cut drawn on it)
	if cap and kind.mesh_script.has_method("trunk_outline_at"):
		var ring: PackedVector2Array = kind.mesh_script.trunk_outline_at(variant, h)
		if ring.size() > 4:
			var mid := ring[0]
			var y := h + 0.003
			var verts := PackedVector3Array()
			for i in range(1, ring.size()):
				var a := ring[i]
				var b := ring[1 + i % (ring.size() - 1)]
				verts.append_array([Vector3(mid.x, y, mid.y), Vector3(a.x, y, a.y), Vector3(b.x, y, b.y)])
			var norms := PackedVector3Array()
			norms.resize(verts.size())
			norms.fill(Vector3.DOWN)
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_NORMAL] = norms
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var cm := cap.duplicate() as ShaderMaterial
			cm.set_shader_parameter("lod_range", Vector3(0.0, 1e9, 0.0)) # (at every distance)
			mesh.surface_set_material(0, cm)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(mi)


## Meshes drawn as the population draws a kind: every level of detail, each
## showing over its own span of distance (lod_fade.gdshaderinc).
func _model(meshes: Array) -> Node3D:
	var root := Node3D.new()
	for mesh in meshes:
		if mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	Origin.root.add_child(root)
	return root


static func _floats(b: Basis) -> Array:
	return [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z]


## The fallen trees, to save.
## The notches part cut (how many blows, at what height): to go on with.
func marks_to_dict() -> Dictionary:
	var out := {}
	for uid in _blows:
		out[str(uid)] = [_blows[uid], _heights.get(uid, CUT_LOW)]
	return out


func marks_from_dict(d: Dictionary) -> void:
	_blows.clear()
	_heights.clear()
	for k in d:
		var a = d[k]
		if a is Array and a.size() == 2:
			_blows[int(k)] = int(a[0])
			_heights[int(k)] = float(a[1])


func to_list() -> Array:
	return _lying.duplicate(true)


## Puts back saved fallen trees, lying where they fell.
func from_list(list: Array) -> void:
	var pop: Population = main.population
	for e in list:
		if not (e is Dictionary):
			continue
		var kind := pop.kind_by_id(StringName(str(e.get("kind", ""))))
		var b: Array = e.get("basis", [])
		var at: Array = e.get("at", [])
		var away: Array = e.get("away", [])
		if kind == null or b.size() != 9 or at.size() != 3 or away.size() != 2:
			continue
		var basis := Basis(Vector3(b[0], b[1], b[2]), Vector3(b[3], b[4], b[5]), Vector3(b[6], b[7], b[8]))
		var origin := Vector3(at[0], at[1], at[2])
		var dir := Vector3(away[0], 0.0, away[1]).normalized()
		var pivot := origin + Vector3.UP * float(e.get("cut", 0.0))
		var end: Array = e.get("end", [])
		if end.size() == 3:
			pivot = Vector3(end[0], end[1], end[2])
		if int(e.get("rested", 0)) < REST_VERSION:
			# (felled when they came to rest by another rule: laid afresh,
			# once, as they'd fall now, and saved so)
			var v := int(kind.get_meta("variant", 0))
			var fr: float = kind.mesh_script.trunk_radius(v) * basis.get_scale().y if kind.mesh_script and kind.mesh_script.has_method("trunk_radius") else 0.3
			var lie := _lie(kind, v, Transform3D(basis, origin), fr, dir, float(e.get("cut", 0.0)))
			e["angle"] = lie[0]
			pivot = lie[1]
			e["end"] = [pivot.x, pivot.y, pivot.z]
			e["rested"] = REST_VERSION
		var node := _model(_felled_meshes(kind, int(kind.get_meta("variant", 0))))
		node.transform = Transform3D(Basis(Vector3.UP.cross(dir).normalized(), float(e.get("angle", PI * 0.5))) * basis, pivot)
		var sv: Array = e.get("stripes", e.get("chop", [dir.x, dir.z]))
		var stripes := Vector3(sv[0], 0.0, sv[1])
		_cut_base(node, kind, int(kind.get_meta("variant", 0)), Transform3D(basis, origin), float(e.get("cut", 0.0)), stripes)
		_solid(kind, node.transform, float(e.get("cut", 0.0)))
		var s := float(e.get("stump_scale", 0.0))
		if s > 0.0:
			var sn := _model([OakTree.fresh_stump()[0]] + OakTree.fresh_stump()[1])
			sn.transform = Transform3D(_stump_basis(stripes, s, float(e.get("stump_h", s))), origin) # (saved before stumps went by the cut: as tall as wide)
			_solid_stump(origin, float(e.get("cut", 0.0)), s)
		_lying.append(e)
