class_name KeybindingsPanel
extends Control
## The keys (Settings.KEYS), from the settings screen: each game action and
## its key; click one, then press the key wanted (Esc: leave it as it was).
## A key another action had goes over to it: the two swap. Kept at once.
## Back (or Esc) closes it.

signal closed

var _buttons := {} # action -> Button
var _waiting := "" # the action whose key is being chosen


func _ready() -> void:
	Settings.ensure_loaded()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(620, 0)
	box.add_theme_constant_override("separation", 8)
	centre.add_child(box)
	var title := Label.new()
	title.text = "Keybindings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var hint := Label.new()
	hint.text = "Click an action, then press its new key (Esc: keep it as it was)."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.75, 0.8, 0.85)
	box.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for k: Array in Settings.KEYS:
		var l := Label.new()
		l.text = k[1]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(130, 0)
		var a: String = k[0]
		b.pressed.connect(func() -> void: _choose(a))
		grid.add_child(b)
		_buttons[a] = b
	_show()
	box.add_child(HSeparator.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var reset := Button.new()
	reset.text = "Defaults"
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(func() -> void:
		Settings.keys = {}
		_kept())
	row.add_child(reset)
	var back := Button.new()
	back.text = "Back"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	row.add_child(back)


func _show() -> void:
	for a: String in _buttons:
		(_buttons[a] as Button).text = "Press a key..." if a == _waiting else Settings.key_name(Settings.key_of(a))


func _choose(action: String) -> void:
	_waiting = action
	_show()


func _input(event: InputEvent) -> void:
	if _waiting == "" or not (event is InputEventKey and event.pressed and not event.echo):
		return
	get_viewport().set_input_as_handled()
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if code != KEY_ESCAPE:
		var old := Settings.key_of(_waiting)
		for k: Array in Settings.KEYS: # (whoever had it: given this one's old key)
			if k[0] != _waiting and Settings.key_of(k[0]) == code:
				Settings.keys[k[0]] = old
		Settings.keys[_waiting] = code
	_waiting = ""
	_kept()


func _kept() -> void:
	# (only those changed from the defaults kept)
	for k: Array in Settings.KEYS:
		if Settings.keys.has(k[0]) and int(Settings.keys[k[0]]) == int(k[2]):
			Settings.keys.erase(k[0])
	Settings.save_settings()
	Settings.apply_keys()
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if _waiting == "" and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
