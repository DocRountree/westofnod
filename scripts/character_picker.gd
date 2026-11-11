class_name CharacterPicker
extends Control
## The character picker: a figure to look at (turned by dragging; its whole
## self or its face) and, beside it, everything its look is made of
## (CharacterLook.FIELDS, section by section: a list for each choice, a
## palette of swatches for each colour, and where a colour has more than
## one palette, which of them), a figure by chance, a plain one again.
## Shown when a game is made (menu.gd) and, in debug mode, over the game
## (P: main.gd). It lays itself out from FIELDS: a field added there is
## here with no more to do.
##
##   var p := CharacterPicker.new()
##   p.setup(look, "Start")      # (a copy is worked on)
##   p.done.connect(func(look): ...)

signal done(look: CharacterLook)
signal cancelled

const SWATCH := 26 ## px, a colour's square

var look := CharacterLook.new()
var _done_text := "Done"
var _can_cancel := true
var _avatar: Avatar
var _view: SubViewport
var _cam: Camera3D
var _turn := 0.5 # (the figure's, radians)
var _face := false
var _zoom := 0.0 # 0 the whole figure .. 1 its face (eased toward _face)
var _drag := false
var _rows := {} # field key -> its control(s): an OptionButton, or {grid, palette}
var _fields: VBoxContainer


## l: the look to start from (its own copy made); done_text: the button
## that ends it; cancel: whether it can be left without choosing.
func setup(l: CharacterLook, done_text := "Done", cancel := true) -> void:
	look = l.copy() if l else CharacterLook.new()
	_done_text = done_text
	_can_cancel = cancel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 0)
	add_child(split)

	# the figure
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	split.add_child(left)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.gui_input.connect(_view_input)
	left.add_child(box)
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.msaa_3d = Viewport.MSAA_4X
	box.add_child(_view)
	_stage()
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(bar)
	var whole := _button(bar, "Whole figure", func() -> void: _face = false)
	whole.tooltip_text = "Drag the figure to turn it"
	_button(bar, "Face", func() -> void: _face = true)
	_button(bar, "Turn round", func() -> void: _turn += PI)

	# what it's made of
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 430
	split.add_child(right)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	right.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)
	var title := Label.new()
	title.text = "Your character"
	title.add_theme_font_size_override("font_size", 24)
	col.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_fields = VBoxContainer.new()
	_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields.add_theme_constant_override("separation", 6)
	scroll.add_child(_fields)
	_build_fields()
	var ends := HBoxContainer.new()
	ends.add_theme_constant_override("separation", 8)
	col.add_child(ends)
	_button(ends, "Random", _random)
	_button(ends, "Plain", func() -> void: _set_look(CharacterLook.new()))
	if _can_cancel:
		_button(ends, "Cancel", func() -> void: cancelled.emit())
	var ok := _button(ends, _done_text, func() -> void: done.emit(look))
	ok.size_flags_stretch_ratio = 1.6
	_show()


func _button(parent: Control, text: String, on: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on)
	parent.add_child(b)
	return b


## The figure's own little world: a floor, a sky, a sun, a camera.
func _stage() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.2, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.76)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	_view.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(32.0), 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 8.0
	_view.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(-140.0), 0.0)
	fill.light_energy = 0.35
	_view.add_child(fill)
	var floor_mi := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.1
	disc.bottom_radius = 1.1
	disc.height = 0.04
	disc.radial_segments = 48
	floor_mi.mesh = disc
	floor_mi.position.y = -0.02
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.3, 0.33, 0.3)
	fm.roughness = 0.95
	floor_mi.material_override = fm
	_view.add_child(floor_mi)
	_avatar = Avatar.new()
	_avatar.look = look
	_view.add_child(_avatar)
	_avatar.wear_pack(false)
	_cam = Camera3D.new()
	_cam.fov = 32.0
	_view.add_child(_cam)


## A row for every field, under its section's heading.
func _build_fields() -> void:
	var section := ""
	for f: Dictionary in CharacterLook.FIELDS:
		if f.section != section:
			section = f.section
			var h := Label.new()
			h.text = section
			h.add_theme_font_size_override("font_size", 18)
			h.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
			if _fields.get_child_count() > 0:
				_fields.add_child(HSeparator.new())
			_fields.add_child(h)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_fields.add_child(row)
		var name := Label.new()
		name.text = f.label
		name.custom_minimum_size.x = 150
		name.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(name)
		var key: String = f.key
		if f.type == "choice":
			var ob := OptionButton.new()
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ob.focus_mode = Control.FOCUS_NONE
			for o: String in f.options:
				ob.add_item(CharacterLook.name_of(o))
			ob.item_selected.connect(func(i: int) -> void: _put(key, f.options[i]))
			row.add_child(ob)
			_rows[key] = ob
		else:
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(v)
			var pal: OptionButton = null
			if (f.palettes as Array).size() > 1: # (which palette: its own, or another)
				pal = OptionButton.new()
				pal.focus_mode = Control.FOCUS_NONE
				for p: String in f.palettes:
					pal.add_item(_palette_name(p, f))
				pal.item_selected.connect(func(_i: int) -> void: _fill_swatches(key))
				v.add_child(pal)
			var grid := HFlowContainer.new()
			grid.add_theme_constant_override("h_separation", 3)
			grid.add_theme_constant_override("v_separation", 3)
			v.add_child(grid)
			_rows[key] = {"grid": grid, "palette": pal}


func _palette_name(p: String, _f: Dictionary) -> String:
	return {"colors": "Any colour", "dyes": "Dyes", "skin": "Skin tones", "hair": "Natural hair", "eyes": "Eye colours"}.get(p, p.capitalize())


## A colour field's swatches, of the palette it's showing; the one chosen
## ringed.
func _fill_swatches(key: String) -> void:
	var f := CharacterLook.field(key)
	var r: Dictionary = _rows[key]
	var grid: HFlowContainer = r.grid
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	var pal: OptionButton = r.palette
	var name: String = f.palettes[pal.selected if pal else 0]
	for hex: String in CharacterLook.PALETTES[name]:
		var c := Color.html(hex)
		var b := Button.new()
		b.custom_minimum_size = Vector2(SWATCH, SWATCH)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = hex
		var chosen := look.color(key).is_equal_approx(c)
		for state in ["normal", "hover", "pressed"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = c if state != "hover" else c.lightened(0.12)
			sb.set_corner_radius_all(4)
			sb.set_border_width_all(3 if chosen else 1)
			sb.border_color = Color.WHITE if chosen else Color(0, 0, 0, 0.5)
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func() -> void: _put(key, c))
		grid.add_child(b)


## Which of a colour field's palettes has colour c (the first, if none).
func _palette_with(f: Dictionary, c: Color) -> int:
	for i in (f.palettes as Array).size():
		for hex: String in CharacterLook.PALETTES[f.palettes[i]]:
			if Color.html(hex).is_equal_approx(c):
				return i
	return 0


func _put(key: String, value: Variant) -> void:
	look.put(key, value)
	_avatar.set_look(look)
	if value is Color:
		_fill_swatches(key)


func _set_look(l: CharacterLook) -> void:
	look = l
	_avatar.set_look(look)
	_show()


func _random() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_set_look(CharacterLook.random(rng))


## Every row showing the look as it is.
func _show() -> void:
	for f: Dictionary in CharacterLook.FIELDS:
		var r: Variant = _rows[f.key]
		if r is OptionButton:
			(r as OptionButton).select(maxi((f.options as Array).find(look.option(f.key)), 0))
		else:
			if r.palette:
				(r.palette as OptionButton).select(_palette_with(f, look.color(f.key)))
			_fill_swatches(f.key)


func _view_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_drag = e.pressed
	elif e is InputEventMouseMotion and _drag:
		_turn += (e as InputEventMouseMotion).relative.x * 0.012
	elif e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_face = (e as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_UP


func _process(delta: float) -> void:
	if _avatar == null:
		return
	_avatar.rotation.y = PI + _turn # (its front toward the camera, turned as dragged)
	_avatar.walk(delta, 0.0, true)
	_zoom = lerpf(_zoom, 1.0 if _face else 0.0, minf(1.0, delta * 6.0))
	var at := Vector3(0.0, 0.98, 0.0).lerp(Vector3(0.0, 1.66, 0.0), _zoom)
	_cam.look_at_from_position(at + Vector3(0.0, lerpf(0.12, 0.02, _zoom), lerpf(4.3, 0.95, _zoom)), at)
