class_name Tapping
extends Node
## Sap from the maples. A notch an axe has cut in a living maple
## (Population.notches: Felling) and left there drips sap: a drop gathers at
## its lower lip, falls, and another gathers (drawn on the maples near you).
## A clay pot (an item) put under it catches it: a click of the hand holding
## the pot, looking at the notch within reach, sets the pot on the ground
## under the drip. It fills as the day goes, the sap rising in it; a whole
## day (of the game's clock, while the notch is there to drip) and it's
## full. A click with a hand empty (or holding pots), looking at a pot,
## takes it up: full, a pot of sap; not yet, the pot, empty again. Saved
## with the game (to_list).

const REACH := 2.4 ## m from the eye: a notch or a pot in reach
const SHOW := 40.0 ## m: the drips drawn on the maples this near
const FILL_HOURS := 24.0 ## of the game's clock: a pot full
const DROP_EVERY := 1.6 ## s between drops
const POT_H := 0.15 ## m: a pot's height (Items: clay_pot)

var main: Node
var _pots: Array = [] # each {"tree": uid, "at": Vector3 (the map's), "fill": 0..1, "node": Node3D}
var _drips := {} # tree uid -> {"at": Vector3 (the lip, the map's), "ground": float (y), "node": MeshInstance3D, "t": s}
var _last_hours := -1.0
var _scan := 0.0
var _drop_mesh: SphereMesh


func _ready() -> void:
	_drop_mesh = SphereMesh.new()
	_drop_mesh.radius = 0.5
	_drop_mesh.height = 1.0
	_drop_mesh.radial_segments = 8
	_drop_mesh.rings = 5
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.72, 0.42, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.08
	m.metallic_specular = 0.8
	_drop_mesh.material = m


## The lip a living maple's notch drips from (the map's), or INF: not a
## maple standing, or no notch, or its chunk not in.
func _lip(uid: int) -> Vector3:
	var notch: Color = main.population.notches().get(uid, Color(0, 0, 0, 0))
	if notch.g <= 0.0:
		return Vector3.INF
	var tree: Dictionary = main.population.tree_by_uid(uid)
	if tree.is_empty():
		return Vector3.INF
	var kind: PropKind = tree.kind
	if kind.mesh_script != MapleTree or MapleTree.species().kind_of(tree.variant) != "tree":
		return Vector3.INF
	var xf: Transform3D = tree.transform
	# the notch's mouth at the bark, its lower face: below its middle by half its gape
	var d := Vector2(cos(notch.r), sin(notch.r))
	var r := notch.a * 1.02
	return xf * Vector3(d.x * r, notch.b - notch.g * 0.45, d.y * r)


func _process(delta: float) -> void:
	if main == null or main.player == null or main.population == null:
		return
	var clock: GameClock = main.clock
	var hours := clock.day * 24.0 + clock.time_of_day
	var dh := 0.0 if _last_hours < 0.0 else maxf(hours - _last_hours, 0.0)
	_last_hours = hours
	# the pots filling, while their notches drip
	for p in _pots:
		if p.fill < 1.0 and dh > 0.0 and _lip(p.tree) != Vector3.INF:
			p.fill = minf(p.fill + dh / FILL_HOURS, 1.0)
		_show_fill(p)
	# which notches drip near you (every half second)
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.5
		_find_drips()
	# the drops: gathering at the lip, then falling to the ground (or into a pot)
	for uid in _drips:
		var dr: Dictionary = _drips[uid]
		dr.t += delta
		var mi: MeshInstance3D = dr.node
		var at: Vector3 = dr.at
		var grow := 1.1
		if dr.t < grow:
			var s: float = 0.002 + 0.004 * dr.t / grow
			mi.position = at - Vector3.UP * s * 0.5
			mi.scale = Vector3(s, s * 1.25, s)
		else:
			var ft: float = dr.t - grow
			var y := at.y - 0.003 - 4.9 * ft * ft
			mi.position = Vector3(at.x, y, at.z)
			mi.scale = Vector3(0.004, 0.007, 0.004)
			if y <= dr.ground:
				dr.t = grow - DROP_EVERY # (a pause before the next gathers)
				mi.scale = Vector3.ZERO
		if dr.t < 0.0:
			mi.scale = Vector3.ZERO


func _find_drips() -> void:
	var at := Origin.map(main.player.global_position)
	var want := {}
	for uid in main.population.notches():
		var lip := _lip(uid)
		if lip == Vector3.INF or lip.distance_to(at) > SHOW:
			continue
		want[uid] = lip
	for uid in _drips.keys():
		if not want.has(uid):
			(_drips[uid].node as Node).queue_free()
			_drips.erase(uid)
	for uid in want:
		var lip: Vector3 = want[uid]
		var ground: float = main.world.height_at(lip.x, lip.z)
		var pot = _pot_of(uid)
		if pot:
			ground = pot.at.y + POT_H * (0.15 + 0.7 * pot.fill)
		if _drips.has(uid):
			_drips[uid].at = lip
			_drips[uid].ground = ground
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = _drop_mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ZERO
		Origin.root.add_child(mi)
		_drips[uid] = {"at": lip, "ground": ground, "node": mi, "t": randf() * DROP_EVERY}


func _pot_of(uid: int):
	for p in _pots:
		if p.tree == uid:
			return p
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]):
		return
	var p: Player = main.player
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or p.typing or p.frozen:
		return
	var inv: Inventory = main.inventory
	var hand := Inventory.LEFT if event.button_index == MOUSE_BUTTON_LEFT else Inventory.RIGHT
	var held: Dictionary = inv.get_at(hand)
	var eye := Origin.map(p.camera.global_position)
	var fwd := -p.camera.global_basis.z
	# taking up a pot looked at: with the hand empty, or holding empty pots
	var pot = _pot_looked_at(eye, fwd)
	if pot:
		var want := "pot_of_sap" if pot.fill >= 1.0 else "clay_pot"
		var into := hand
		if not _room(held, want):
			var other := Inventory.RIGHT if hand == Inventory.LEFT else Inventory.LEFT
			if not _room(inv.get_at(other), want):
				return
			into = other
		get_viewport().set_input_as_handled()
		var h: Dictionary = inv.get_at(into)
		inv.set_at(into, {"id": want, "count": int(h.get("count", 0)) + 1})
		(pot.node as Node).queue_free()
		_pots.erase(pot)
		_scan = 0.0
		main.chat.say("Took up a pot of sap." if want == "pot_of_sap" else "Took up the pot (%d%% full: it spills)." % int(pot.fill * 100.0), Color(0.85, 0.85, 0.8))
		return
	# setting a pot under a dripping notch
	if held.get("id", "") != "clay_pot":
		return
	var best := -1
	var best_d := INF
	for uid in _drips:
		var lip: Vector3 = _drips[uid].at
		var to := lip - eye
		if to.length() > REACH or to.normalized().dot(fwd) < 0.85 or _pot_of(uid) != null:
			continue
		if to.length() < best_d:
			best_d = to.length()
			best = uid
	if best < 0:
		return
	get_viewport().set_input_as_handled()
	var lip: Vector3 = _drips[best].at
	var at := Vector3(lip.x, main.world.height_at(lip.x, lip.z), lip.z)
	_add_pot(best, at, 0.0)
	var n := int(held.get("count", 1)) - 1
	inv.set_at(hand, {} if n <= 0 else {"id": "clay_pot", "count": n})
	_scan = 0.0
	main.chat.say("Set the pot under the drip. It'll fill in a day.", Color(0.85, 0.85, 0.8))


static func _room(held: Dictionary, id: String) -> bool:
	return held.is_empty() or (held.get("id", "") == id and int(held.get("count", 0)) < Items.stack_of(id))


func _pot_looked_at(eye: Vector3, fwd: Vector3):
	var best = null
	var best_d := INF
	for p in _pots:
		var c: Vector3 = p.at + Vector3.UP * POT_H * 0.5
		var to := c - eye
		var along := to.dot(fwd)
		if along < 0.0 or along > REACH:
			continue
		var off := (eye + fwd * along).distance_to(c)
		if off < 0.14 and along < best_d:
			best_d = along
			best = p
	return best


func _add_pot(tree: int, at: Vector3, fill: float) -> void:
	var node := Node3D.new()
	var pot := Items.model("clay_pot")
	pot.position.y = POT_H * 0.5 # (the model's centred on its grip: its middle)
	node.add_child(pot)
	# the sap in it: a disc rising as it fills
	var sap := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.058
	disc.bottom_radius = 0.05
	disc.height = 0.004
	sap.mesh = disc
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.6, 0.3)
	m.roughness = 0.08
	sap.material_override = m
	sap.name = "sap"
	node.add_child(sap)
	node.position = at
	Origin.root.add_child(node)
	var p := {"tree": tree, "at": at, "fill": fill, "node": node}
	_pots.append(p)
	_show_fill(p)


func _show_fill(p: Dictionary) -> void:
	var sap: MeshInstance3D = (p.node as Node3D).get_node("sap")
	sap.visible = p.fill > 0.01
	sap.position.y = POT_H * (0.12 + 0.72 * p.fill)
	var w: float = lerpf(0.75, 1.0, p.fill) # (the pot widening up to its shoulder)
	sap.scale = Vector3(w, 1.0, w)


func to_list() -> Array:
	var out := []
	for p in _pots:
		out.append({"tree": str(p.tree), "at": [p.at.x, p.at.y, p.at.z], "fill": p.fill})
	return out


func from_list(list: Array) -> void:
	for p in _pots:
		(p.node as Node).queue_free()
	_pots.clear()
	for e in list:
		var a: Array = e.get("at", [])
		if a.size() == 3:
			_add_pot(int(e.get("tree", "0")), Vector3(a[0], a[1], a[2]), float(e.get("fill", 0.0)))
