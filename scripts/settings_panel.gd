class_name SettingsPanel
extends Control
## The settings screen (Settings), the same from the start menu and from Esc
## in the game: over whatever's behind it, its own dim backdrop. Each change
## is kept at once (saved, applied); `changed` tells the game. Back (or Esc)
## closes it: `closed`.

signal changed
signal closed

var _fov_val: Label
var _sens_val: Label
var _scale_val: Label


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
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 10)
	centre.add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var scroll := ScrollContainer.new() # (scrolling, if the window's too short for it all)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, clampf(get_viewport().get_visible_rect().size.y - 260.0, 200.0, 560.0))
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	_heading(grid, "Controls")
	_sens_val = _slider(grid, "Mouse sensitivity", 0.1, 4.0, 0.05, Settings.mouse_sens,
			func(v: float) -> void: Settings.mouse_sens = v, "%.2f×")
	_check(grid, "Invert mouse (look up and down)", Settings.invert_y, func(b: bool) -> void: Settings.invert_y = b)

	_heading(grid, "View")
	_fov_val = _slider(grid, "Field of view", 50.0, 110.0, 1.0, Settings.fov,
			func(v: float) -> void: Settings.fov = v, "%.0f°")
	_check(grid, "Show frame rate", Settings.show_fps, func(b: bool) -> void: Settings.show_fps = b)

	_heading(grid, "Display")
	_options(grid, "Window", Settings.WINDOW_MODES, Settings.window_mode, func(i: int) -> void: Settings.window_mode = i)
	_check(grid, "V-sync", Settings.vsync, func(b: bool) -> void: Settings.vsync = b)
	var caps: Array = []
	for c: int in Settings.FPS_CAPS:
		caps.append("None" if c == 0 else "%d fps" % c)
	_options(grid, "Frame rate cap", caps, maxi(Settings.FPS_CAPS.find(Settings.fps_cap), 0),
			func(i: int) -> void: Settings.fps_cap = Settings.FPS_CAPS[i])
	_scale_val = _slider(grid, "Render scale", 0.5, 1.0, 0.05, Settings.render_scale,
			func(v: float) -> void: Settings.render_scale = v, "%.0f%%", 100.0)

	_heading(grid, "Graphics")
	_options(grid, "Shadows", Settings.SHADOWS, Settings.shadows, func(i: int) -> void: Settings.shadows = i)
	_slider(grid, "Tree render distance*", 300.0, 1500.0, 50.0, Settings.tree_distance,
			func(v: float) -> void: Settings.tree_distance = v, "%.0f m")
	_slider(grid, "Grass render distance*", 0.5, 2.0, 0.05, Settings.grass_distance,
			func(v: float) -> void: Settings.grass_distance = v, "%.0f%%", 100.0)

	_heading(grid, "Audio")
	_slider(grid, "Volume", 0.0, 100.0, 1.0, Settings.volume,
			func(v: float) -> void: Settings.volume = v, "%.0f%%")

	var note := Label.new()
	note.text = "* when a world is next loaded (the far trees' cards and the grass are laid out then)"
	note.modulate = Color(0.7, 0.75, 0.8)
	note.add_theme_font_size_override("font_size", 13)
	box.add_child(note)
	var keys := Button.new()
	keys.text = "Keybindings..."
	keys.pressed.connect(func() -> void: add_child(KeybindingsPanel.new()))
	box.add_child(keys)
	box.add_child(HSeparator.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var reset := Button.new()
	reset.text = "Defaults"
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(_defaults)
	row.add_child(reset)
	var back := Button.new()
	back.text = "Back"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	row.add_child(back)
	back.grab_focus.call_deferred()


func _heading(grid: GridContainer, text: String) -> void:
	for k in 3:
		var l := Label.new()
		if k == 0:
			l.text = text
			l.add_theme_font_size_override("font_size", 18)
			l.modulate = Color(0.7, 0.85, 1.0)
		grid.add_child(l)


func _label(grid: GridContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(l)


func _slider(grid: GridContainer, text: String, lo: float, hi: float, step: float, now: float, set_: Callable, fmt: String, shown := 1.0) -> Label:
	_label(grid, text)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = now
	s.custom_minimum_size = Vector2(220, 0)
	grid.add_child(s)
	var v := Label.new()
	v.text = fmt % (now * shown)
	v.custom_minimum_size = Vector2(60, 0)
	grid.add_child(v)
	s.value_changed.connect(func(x: float) -> void:
		set_.call(x)
		v.text = fmt % (x * shown)
		_kept())
	return v


func _check(grid: GridContainer, text: String, now: bool, set_: Callable) -> void:
	_label(grid, text)
	var c := CheckBox.new()
	c.button_pressed = now
	c.toggled.connect(func(b: bool) -> void:
		set_.call(b)
		_kept())
	grid.add_child(c)
	grid.add_child(Control.new())


func _options(grid: GridContainer, text: String, items: Array, now: int, set_: Callable) -> void:
	_label(grid, text)
	var o := OptionButton.new()
	for it in items:
		o.add_item(str(it))
	o.select(now)
	o.item_selected.connect(func(i: int) -> void:
		set_.call(i)
		_kept())
	grid.add_child(o)
	grid.add_child(Control.new())


func _kept() -> void:
	Settings.save_settings()
	Settings.apply(get_viewport())
	changed.emit()


func _defaults() -> void:
	Settings.mouse_sens = 1.0
	Settings.invert_y = false
	Settings.fov = 75.0
	Settings.window_mode = 0
	Settings.vsync = true
	Settings.fps_cap = 0
	Settings.render_scale = 1.0
	Settings.shadows = 2
	Settings.show_fps = false
	Settings.tree_distance = Settings.TREES_VIEW
	Settings.grass_distance = 1.0
	Settings.volume = 80.0
	_kept()
	# (the controls rebuilt, showing them)
	for c in get_children():
		c.queue_free()
	_ready()


func _unhandled_input(event: InputEvent) -> void:
	for c in get_children(): # (the keybindings over it: theirs)
		if c is KeybindingsPanel:
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
