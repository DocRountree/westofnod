extends Control
## The start menu (menu.tscn, the project's main scene): the saved games,
## the one played last first, to resume; a new game; renaming and deleting;
## debug mode (flying, the time keys, every command, nothing saved: see
## Session); quit.

var _list: ItemList
var _games: Array[Dictionary] = []
var _name: LineEdit
var _name_row: HBoxContainer
var _name_ok: Button
var _renaming := "" # the game being renamed ("": the name box makes a new game)
var _play: Button
var _rename: Button
var _delete: Button
var _confirm: ConfirmationDialog
var _loading: Label
var _box: VBoxContainer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	_box = VBoxContainer.new()
	_box.custom_minimum_size = Vector2(520, 0)
	_box.add_theme_constant_override("separation", 12)
	centre.add_child(_box)

	var title := Label.new()
	title.text = "West of Nod"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	_box.add_child(title)
	var sub := Label.new()
	sub.text = ProjectSettings.get_setting("application/config/description", "")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.7, 0.75, 0.8)
	_box.add_child(sub)
	_box.add_child(HSeparator.new())

	var heading := Label.new()
	heading.text = "Games"
	heading.add_theme_font_size_override("font_size", 20)
	_box.add_child(heading)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 220)
	_list.item_selected.connect(func(_i): _update_buttons())
	_list.item_activated.connect(func(_i): _resume())
	_box.add_child(_list)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_box.add_child(row)
	_play = _button(row, "Resume", _resume)
	_button(row, "New game", _new_game)
	_rename = _button(row, "Rename", _start_rename)
	_delete = _button(row, "Delete", _ask_delete)

	_name_row = HBoxContainer.new()
	_name_row.visible = false
	_box.add_child(_name_row)
	_name = LineEdit.new()
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.max_length = 40
	_name.text_submitted.connect(func(_t): _name_done())
	_name.text_changed.connect(func(_t): _name.modulate = Color.WHITE)
	_name_row.add_child(_name)
	_name_ok = _button(_name_row, "Start", _name_done)
	_button(_name_row, "Cancel", func(): _name_row.visible = false)

	_box.add_child(HSeparator.new())
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	_box.add_child(row2)
	var dbg := _button(row2, "Debug mode", _debug)
	dbg.tooltip_text = "Fly, the time keys, every command; nothing is saved"
	_button(row2, "Quit", func(): get_tree().quit())

	_loading = Label.new()
	_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading.add_theme_font_size_override("font_size", 24)
	_loading.visible = false
	_box.add_child(_loading)

	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(_delete_selected)
	add_child(_confirm)
	_refresh()


func _button(parent: Control, text: String, on: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(on)
	parent.add_child(b)
	return b


func _refresh() -> void:
	_games = Session.list()
	_list.clear()
	for g in _games:
		var when := Time.get_datetime_string_from_unix_time(int(g.saved) + _tz_offset(), true)
		var mins := int(g.play_seconds / 60.0)
		_list.add_item("%s      last played %s      %d:%02d played" % [g.name, when, mins / 60, mins % 60])
	if not _games.is_empty():
		_list.select(0)
	else:
		_list.add_item("(no games yet: start a new one)")
		_list.set_item_disabled(0, true)
		_list.set_item_selectable(0, false)
	_update_buttons()


func _tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _selected() -> Dictionary:
	var s := _list.get_selected_items()
	if s.is_empty() or s[0] >= _games.size():
		return {}
	return _games[s[0]]


func _update_buttons() -> void:
	var none := _selected().is_empty()
	_play.disabled = none
	_rename.disabled = none
	_delete.disabled = none


func _resume() -> void:
	var g := _selected()
	if not g.is_empty():
		Session.play(g.name)
		_start("Loading %s..." % g.name)


func _new_game() -> void:
	_renaming = ""
	_name_ok.text = "Start"
	_name.text = Session.free_name()
	_name_row.visible = true
	_name.grab_focus()
	_name.select_all()


func _start_rename() -> void:
	var g := _selected()
	if g.is_empty():
		return
	_renaming = g.name
	_name_ok.text = "Rename"
	_name.text = g.name
	_name_row.visible = true
	_name.grab_focus()
	_name.select_all()


func _name_done() -> void:
	var n := _name.text.strip_edges()
	if n == "" or n.validate_filename() == "":
		return
	if _renaming != "":
		if n != _renaming and Session.rename(_renaming, n):
			_name_row.visible = false
			_refresh()
		elif n == _renaming:
			_name_row.visible = false
		else:
			_name.modulate = Color(1, 0.5, 0.5) # (taken)
		return
	if Session.exists(n):
		_name.modulate = Color(1, 0.5, 0.5)
		return
	Session.play(n)
	_start("Starting %s..." % n)


func _ask_delete() -> void:
	var g := _selected()
	if g.is_empty():
		return
	_confirm.dialog_text = "Delete %s? This can't be undone." % g.name
	_confirm.popup_centered()


func _delete_selected() -> void:
	var g := _selected()
	if not g.is_empty():
		Session.delete(g.name)
		_refresh()


func _debug() -> void:
	Session.play_debug()
	_start("Loading debug mode...")


## Shows the message for a frame (loading the world takes a few seconds),
## then goes into the game.
func _start(message: String) -> void:
	for c in _box.get_children():
		c.visible = false
	_loading.text = message
	_loading.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://main.tscn")
