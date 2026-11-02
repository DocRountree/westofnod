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
## (OakTree.fresh_stump: flat, its top pale wood, no moss; none for a
## sapling), and lies where it fell.
##
## The fallen trees and their stumps are saved with the game (to_list,
## from_list: main.gd), as nodes under Origin.root (their positions the
## map's), each drawn with its kind's levels of detail as the population
## draws them (the shaders pick the level by distance). They can't be stood
## on or climbed.

const REACH := 1.3 ## m from the trunk's surface
const SWING := 0.6 ## s, a swing
const STRIKE := 0.62 ## where in the swing the blade meets the trunk (0..1)
const BLOW_DEPTH := 0.045 ## m of trunk radius one blow cuts: a 0.5 m trunk takes 11
const FALL_TIME := 2.6 ## s, a full-sized tree from upright to the ground
const CUT := 0.75 ## of the stump's own height: where the trunk comes away (at the stump's top)

var main: Node
var _swing := -1.0 # 0..1 through a swing; < 0 none
var _struck := false
var _blows := {} # tree uid -> blows so far
var _falling: Array = [] # {node, axis, angle, t, time, pivot, basis}
var _lying: Array = [] # what to_list saves, one entry a tree


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or main.player.typing or main.player.frozen:
		return
	if _axe_hand() < 0 or _swing >= 0.0 or main.player.climbing:
		return
	_swing = 0.0
	_struck = false
	get_viewport().set_input_as_handled()


## Which hand holds an axe: 1 right, 0 left, -1 neither (the right first).
func _axe_hand() -> int:
	var inv: Inventory = main.inventory
	if str(inv.right.get("id", "")) == "axe":
		return 1
	if str(inv.left.get("id", "")) == "axe":
		return 0
	return -1


func _process(delta: float) -> void:
	_animate_swing(delta)
	for f in _falling.duplicate():
		f.t = minf(f.t + delta, f.time)
		var u: float = f.t / f.time
		var a: float = f.angle * u * u # (gathering speed as it goes over)
		var turn := Basis(f.axis, a)
		# the trunk's foot starts where it stood (below the cut, in the
		# stump) and slides off the stump's top as it goes over
		f.node.transform = Transform3D(turn * f.basis, f.pivot - turn * Vector3.UP * f.cut * (1.0 - u))
		if f.t >= f.time:
			_falling.erase(f)


func _animate_swing(delta: float) -> void:
	var hand := _axe_hand()
	var angle := 0.0
	if _swing >= 0.0:
		_swing += delta / SWING
		var t := _swing
		# up and back, then down and through, then back to rest
		if t < 0.45:
			angle = lerpf(0.0, 0.9, smoothstep(0.0, 1.0, t / 0.45))
		elif t < STRIKE:
			angle = lerpf(0.9, -0.8, (t - 0.45) / (STRIKE - 0.45))
		else:
			angle = lerpf(-0.8, 0.0, smoothstep(0.0, 1.0, (t - STRIKE) / (1.0 - STRIKE)))
		if not _struck and t >= STRIKE:
			_struck = true
			_strike()
		if _swing >= 1.0:
			_swing = -1.0
			angle = 0.0
	if hand >= 0:
		for m in _held_models(hand):
			m.rotation.x = angle


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
	if n < need:
		_blows[tree.uid] = n
		_notch(tree, p.position, float(n) / need)
		return
	_blows.erase(tree.uid)
	main.population.remove_prop(tree.uid)
	var xf: Transform3D = tree.transform
	var away := Vector3(xf.origin.x - p.position.x, 0.0, xf.origin.z - p.position.z)
	if away.length() < 0.01:
		away = -p.global_basis.z
	away = away.normalized()
	var entry := _fell(tree.kind, tree.variant, xf, tree.radius, away)
	var f: Dictionary = entry.falling
	_falling.append(f)
	entry.erase("falling")
	_lying.append(entry)


## Puts a felled tree in the world: its stump (if it has one) and the tree,
## upright, to fall over toward `away`. Returns the entry to save, with
## "falling" the fall to animate.
func _fell(kind: PropKind, variant: int, xf: Transform3D, radius: float, away: Vector3) -> Dictionary:
	var world: WorldData = main.world
	var cut := 0.08
	var stump_scale := _stump_scale(radius)
	if stump_scale > 0.0:
		cut = _cut(radius)
	var pivot := xf.origin + Vector3.UP * cut
	var axis := Vector3.UP.cross(away).normalized()
	# over until its crown, about half its height out, comes down on the ground
	var height := kind.mesh.get_aabb().end.y * xf.basis.get_scale().y
	var reach := height * 0.5
	var ground := world.height_at(pivot.x + away.x * reach, pivot.z + away.z * reach)
	var angle := clampf(PI * 0.5 + atan2(pivot.y - ground, reach), deg_to_rad(65.0), deg_to_rad(105.0))
	var entry := {
		"kind": String(kind.id), "basis": _floats(xf.basis), "at": [xf.origin.x, xf.origin.y, xf.origin.z],
		"away": [away.x, away.z], "angle": angle, "cut": cut, "stump_scale": stump_scale,
	}
	var node := _model([kind.mesh] + kind.lods)
	node.transform = xf
	if stump_scale > 0.0:
		var sn := _model([OakTree.fresh_stump()[0]] + OakTree.fresh_stump()[1])
		sn.transform = Transform3D(Basis(Vector3.UP, xf.basis.get_euler().y).scaled(Vector3.ONE * stump_scale), xf.origin)
	entry.falling = {"node": node, "axis": axis, "angle": angle, "t": 0.0, "cut": cut,
			"time": FALL_TIME * sqrt(maxf(height, 1.0) / 15.0), "pivot": pivot, "basis": xf.basis}
	return entry


## The stump's scale for a trunk of this radius (0: none, a sapling's).
static func _stump_scale(radius: float) -> float:
	return radius / 0.5 if radius > 0.12 else 0.0 # (the stump is 0.5 m round at the foot)


## The height (m, on the map) the trunk comes away at: the stump's top, where
## the notch is cut.
static func _cut(radius: float) -> float:
	var s := _stump_scale(radius)
	return OakTree.fresh_stump()[0].get_aabb().end.y * CUT * s if s > 0.0 else 0.08


## A blow's mark: the notch, done part of the way (0..1), on the side toward
## `from` (on the map).
func _notch(tree: Dictionary, from: Vector3, done: float) -> void:
	var xf: Transform3D = tree.transform
	var s := xf.basis.get_scale().x
	var to := xf.basis.inverse() * (from - xf.origin) # (the tree's own space)
	var r: float = float(tree.radius) / s * 1.05 # (a little over: the bark's ridges)
	var depth := r * 1.1 * done # (over half way through, by the last blow)
	main.population.set_notch(tree.uid, Color(atan2(to.z, to.x), depth, _cut(float(tree.radius)) / s, r))


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
		var node := _model([kind.mesh] + kind.lods)
		node.transform = Transform3D(Basis(Vector3.UP.cross(dir).normalized(), float(e.get("angle", PI * 0.5))) * basis, pivot)
		var s := float(e.get("stump_scale", 0.0))
		if s > 0.0:
			var sn := _model([OakTree.fresh_stump()[0]] + OakTree.fresh_stump()[1])
			sn.transform = Transform3D(Basis(Vector3.UP, basis.get_euler().y).scaled(Vector3.ONE * s), origin)
		_lying.append(e)
