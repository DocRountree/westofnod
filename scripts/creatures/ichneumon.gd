class_name Ichneumon
extends "res://scripts/creatures/trigonalid.gd" # (by path: found whether or not the editor has seen the class yet)
## An ichneumon wasp (a female of the Ichneumoninae, about 13 mm): the
## paper wasp's model (Wasp) in its own colours and its own proportions,
## drawn at the paper wasp's size. Its head orange red, the eyes dark; its
## thorax black, the mesoscutum red on top, the scutellum and the tegulae
## cream; its gaster long and slender, orange red, on a narrow waist; its
## legs orange, the hind coxae black; its antennae long, curving, black, a
## broad cream band past their middle (the female's), the scape orange; its
## wings smoky, brownish violet, the veins dark.
##
## The adults drink nectar (as the trigonalid: visit_flowers). A female
## lays her eggs inside living caterpillars, one at a time: hovering beside
## one, drumming it with her antennae, her gaster swung under and forward
## and her ovipositor driven into it, pumping, the caterpillar thrashing;
## then off. Her larva eats it from within as it goes on feeding, and, when
## it's pupated, kills it: an ichneumon, not a butterfly or a moth, chews
## its way out of the pupa (Pupa: parasitized; one in three butterfly and
## moth pupae, and every one whose caterpillar was stung: Larva.parasitized).
##
## Its own (the trigonalid's visit_flowers, and the paper wasp's seek_food,
## feed_on_flower, land, take_off, mate):
## - lay_in_caterpillar(caterpillar): to it (a Larva, crawling or eating,
##   on a leaf or the ground), hovering beside it facing it, drumming it,
##   the gaster curled under and forward, its tip driven into it, pumping;
##   it thrashes, then goes on as it was, stung (parasitized); she off
##   again, seeking
## Steering (pilot.gd): act visit_flowers {heads, sway}, lay_in_caterpillar
## {caterpillar}, seek_food, feed_on_flower, land, take_off, mate.

const RED := Color(0.62, 0.17, 0.05)
const ORANGE := Color(0.78, 0.33, 0.07)
const CREAM := Color(0.93, 0.8, 0.45)
const BLACK := Color(0.03, 0.025, 0.025)

var stung: Array[Node3D] = [] ## the caterpillars it's laid in
const LARVA_MM := 0.002 ## (Larva.MM: its drawing's scale)


func _init() -> void:
	super()
	ant_seg = 2.4 # (long: the flagellum nearly the body's length)
	ant_curl = 0.07


func _palette() -> Dictionary:
	return {"body": BLACK, "dark": Color(0.02, 0.018, 0.016), "mark": CREAM, "leg": ORANGE, "leg2": Color(0.85, 0.42, 0.1),
		"tip": BLACK, "antenna": BLACK, "mandible": Color(0.5, 0.2, 0.06),
		"membrane": Color(0.3, 0.2, 0.2), "vein": Color(0.08, 0.05, 0.05),
		"bands": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]}


func _build() -> void:
	super()
	var red := _chitin(RED, 0.0, 0.7)
	var orange := _chitin(ORANGE, 0.0, 0.5)
	var cream := _chitin(CREAM, 0.0, 0.5)
	var black := _chitin(BLACK, 0.0, 0.6)
	# the head: all but the eyes and the antennae orange red
	var ant_parts := []
	for segs: Array in _antennae:
		ant_parts.append_array(segs)
	for c in _head.get_children():
		var mi := c as MeshInstance3D
		if mi == null or ant_parts.has(mi):
			continue
		var m := mi.material_override as ShaderMaterial
		if m and (m.get_shader_parameter("base_color") as Color).is_equal_approx(Color(0.05, 0.035, 0.03)):
			continue # (an eye)
		mi.material_override = red
	# the antennae: the scape orange; a cream band past the middle
	for segs: Array in _antennae:
		(segs[0] as MeshInstance3D).material_override = orange
		(segs[1] as MeshInstance3D).material_override = black
		(segs[2] as MeshInstance3D).material_override = cream
		(segs[3] as MeshInstance3D).material_override = black
		(segs[4] as MeshInstance3D).material_override = black
	# the thorax: the propodeum's marks and the collar's rim black; the
	# mesoscutum red on top
	for c in _body.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		if mi.position.z > 1.9 and mi.position.y > 0.3 and mi.position.y < 0.6: # (the propodeum's marks)
			mi.material_override = black
		elif absf(mi.position.z + 1.72) < 0.01: # (the collar's rim)
			mi.material_override = black
	_ball(_body, Vector3(0.0, 1.25, -0.6), Vector3(2.35, 1.0, 2.5), red) # (the mesoscutum)
	# the gaster: long and slender on a narrow waist, orange red
	(_gaster[0] as Node3D).scale = Vector3(0.78, 0.8, 1.45)
	for g in _gaster_mesh:
		g.material_override = red
	# the legs: orange (the hind coxae black)
	for i in _legs.size():
		var parts: Array = _legs[i]
		var pair := i / 2
		(parts[0] as MeshInstance3D).material_override = black if pair == 2 else orange
		(parts[1] as MeshInstance3D).material_override = orange
		(parts[2] as MeshInstance3D).material_override = orange
		(parts[3] as MeshInstance3D).material_override = orange


## Laying in a caterpillar (a Larva): to it, down beside it facing its
## middle, drumming it with its antennae; its gaster swung under and
## forward, the ovipositor driven in, pumping; the caterpillar thrashing,
## then going on as it was, stung. Then off, seeking food about there.
func lay_in_caterpillar(c: Node3D) -> void:
	var id := _begin()
	release()
	if male or not is_instance_valid(c) or c.get("_mode") in ["pupate", "struggle"]:
		return
	if not flying:
		if not await _take_off(id):
			return
	# over it
	var mid := _cat_mid(c)
	_look = _away(mid)
	_max_speed = 0.7
	var over := mid + Vector3.UP * 0.035
	_fly_target = over
	if not await _until(id, func() -> bool: return _pos.distance_to(_cat_mid(c) + Vector3.UP * 0.035) < 0.008, 8.0):
		return
	if not is_instance_valid(c):
		return
	# at it from beside, hovering, facing its middle (on a leaf or the
	# ground, whichever: from the air), drumming it with her antennae
	mid = _cat_mid(c)
	var cd: Vector3 = c.get("_dir")
	var side := Vector3(cd.z, 0.0, -cd.x).normalized()
	if side.dot(_pos - mid) < 0.0:
		side = -side
	var face := -side
	_look = face
	var near := mid + side * 0.014 + Vector3.UP * 0.008
	_max_speed = 0.25
	_fly_target = near
	_p.ant_tap = 0.7
	_p.ant_down = 0.5
	if not await _until(id, func() -> bool: return _pos.distance_to(near) < 0.004, 4.0):
		return
	if not await _wait(id, 0.7):
		return
	if not is_instance_valid(c):
		return
	# the sting: the gaster swung under and forward, its tip on it, in
	_p.curl = 1.25
	_p.sting_out = 1.0
	_p.ant_pitch = 0.5
	if not await _wait(id, 0.3):
		return
	_max_speed = 0.6
	_jitter = 0.0004
	_fly_target = _cat_mid(c) - face * 2.0 * MM + Vector3.UP * 7.0 * MM # (the curled tip on it: as the paper wasp's sting)
	if not await _wait(id, 0.2):
		return
	if is_instance_valid(c):
		c.call("flinch", 1.1)
	_p.pump = 0.9
	if not await _wait(id, 1.4):
		return
	if is_instance_valid(c):
		c.set("parasitized", true)
		stung.append(c)
	_jitter = 0.002
	_max_speed = 0.7
	_fly_target = near + Vector3.UP * 0.02
	_p.pump = 0.0
	_p.curl = 0.15
	_p.sting_out = 0.0
	_p.ant_pitch = 0.35
	_p.ant_tap = 0.0
	_p.ant_down = 0.0
	if not await _wait(id, 0.6):
		return
	seek_food(mid * Vector3(1.0, 0.0, 1.0), 0.5)


## (A caterpillar's middle, its body's: the head's front back half its
## length; in this one's parent's space.)
func _cat_mid(c: Node3D) -> Vector3:
	var K: Dictionary = c.get("K")
	var g := float(c.get("_g"))
	var p: Vector3 = c.get("_pos")
	var d: Vector3 = c.get("_dir")
	var m := p - d.normalized() * float(K.len) * LARVA_MM * g * 0.5
	var par := get_parent() as Node3D
	var cp := c.get_parent() as Node3D
	if par and cp and par != cp:
		return par.to_local(cp.to_global(m))
	return m


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["seek_food", "visit_flowers", "feed_on_flower", "lay_in_caterpillar", "land", "take_off", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"lay_in_caterpillar":
			if male or not is_instance_valid(args.get("caterpillar")):
				return false
		"lay_on_leaf":
			return false # (not its way)
	return super(name, args)


func _p_run(name: String, args: Dictionary) -> void:
	if name != "lay_in_caterpillar":
		await super(name, args)
		return
	_p_done = false
	var id := _act + 1
	await lay_in_caterpillar(args.caterpillar)
	if _act == id:
		_p_done = true


func _p_act_secs(name: String) -> float:
	if name == "lay_in_caterpillar":
		return 20.0
	return super(name)
