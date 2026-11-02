class_name Knapsack
extends CanvasLayer
## The knapsack (E opens and closes it; Esc closes it too): its Inventory.SLOTS
## slots and the two hands. Click a stack to pick it up, click again to put it
## down (swapping with what is there, or adding to a stack of the same);
## right-click picks up half, or puts down one; shift-click moves a stack
## between the knapsack and the hands. The hands are shown at the bottom
## corners of the screen while it's closed too.

const SIZE := 64.0 ## px, a slot

var main: Node
var inv: Inventory
var open := false
var _panel: Control
var _slots: Array[_Slot] = []
var _corner: Array[_Slot] = [] # the hands, while closed
var _cursor: _Slot # the stack picked up, at the mouse
var _held := {}


class _Slot:
	extends Control
	var stack := {}
	var label := ""
	var index := -1
	var on_click: Callable

	func _init(i: int, l: String, size_px: float) -> void:
		index = i
		label = l
		custom_minimum_size = Vector2(size_px, size_px)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP if i >= 0 else Control.MOUSE_FILTER_IGNORE

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and on_click.is_valid():
			on_click.call(index, event)
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var font := ThemeDB.fallback_font
		if index >= 0:
			draw_rect(r, Color(0.12, 0.1, 0.08, 0.85))
			draw_rect(r, Color(0.55, 0.47, 0.36, 0.9), false, 2.0)
		if label != "" and stack.is_empty():
			draw_string(font, Vector2(0, size.y * 0.5 + 6), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(1, 1, 1, 0.35))
		if stack.is_empty():
			return
		var id := str(stack.id)
		draw_circle(size * Vector2(0.5, 0.4), size.x * 0.2, Items.color_of(id))
		draw_string(font, Vector2(2, size.y - 6), Items.name_of(id), HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, 11, Color.WHITE)
		if int(stack.count) > 1:
			draw_string(font, Vector2(0, 16), str(stack.count), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5, 14, Color.WHITE)


func _ready() -> void:
	layer = 5
	# a backdrop over the whole screen: clicks off the panel go nowhere (not
	# to the game, which would take the mouse back)
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	add_child(_panel)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(shade)
	var box := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.16, 0.11, 0.92)
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(14)
	box.add_theme_stylebox_override("panel", bg)
	box.set_anchors_preset(Control.PRESET_CENTER)
	_panel.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	var title := Label.new()
	title.text = "Knapsack"
	title.add_theme_font_size_override("font_size", 20)
	v.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for i in Inventory.SLOTS:
		var s := _Slot.new(i, "", SIZE)
		s.on_click = _click
		grid.add_child(s)
		_slots.append(s)
	var hands_title := Label.new()
	hands_title.text = "Hands"
	hands_title.add_theme_font_size_override("font_size", 16)
	v.add_child(hands_title)
	var hands := HBoxContainer.new()
	hands.add_theme_constant_override("separation", 6)
	v.add_child(hands)
	for i in [Inventory.LEFT, Inventory.RIGHT]:
		var s := _Slot.new(i, "left" if i == Inventory.LEFT else "right", SIZE)
		s.on_click = _click
		hands.add_child(s)
		_slots.append(s)
	var help := Label.new()
	help.text = "Click: pick up / put down · Right-click: half / one · Shift-click: to or from the hands · E or Esc: close"
	help.add_theme_font_size_override("font_size", 12)
	help.modulate.a = 0.7
	v.add_child(help)
	box.reset_size()
	box.position = -box.size * 0.5
	# the hands, at the bottom corners while it's closed
	for i in 2:
		var s := _Slot.new(Inventory.LEFT + i, "L" if i == 0 else "R", 54.0)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if i == 0 else Control.PRESET_BOTTOM_RIGHT)
		s.position = Vector2(16, -70) if i == 0 else Vector2(-70, -70)
		add_child(s)
		_corner.append(s)
	_cursor = _Slot.new(-1, "", SIZE)
	_cursor.visible = false
	add_child(_cursor)
	if inv:
		inv.changed.connect(_refresh)
	_refresh()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		if open and event is InputEventMouseMotion:
			_cursor.position = event.position - Vector2(SIZE, SIZE) * 0.5
		return
	if not event.pressed or event.echo:
		if open:
			get_viewport().set_input_as_handled()
		return
	if event.is_action("knapsack") or (open and event.keycode == KEY_ESCAPE):
		if open:
			close()
		elif not main.player.typing and not main.player.frozen:
			show_knapsack()
		else:
			return
		get_viewport().set_input_as_handled()
	elif open:
		get_viewport().set_input_as_handled() # (the game's keys wait)


func show_knapsack() -> void:
	open = true
	_panel.visible = true
	main.player.typing = true
	main.clock.typing = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close() -> void:
	if not _held.is_empty():
		# back in the knapsack, or a hand (there is always room: it came from one)
		var left := inv.add(str(_held.id), int(_held.count))
		if left > 0:
			for h in [Inventory.RIGHT, Inventory.LEFT]:
				if inv.get_at(h).is_empty():
					inv.set_at(h, {"id": _held.id, "count": left})
					break
		_held = {}
	open = false
	_panel.visible = false
	main.player.typing = false
	main.clock.typing = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh()


func _click(i: int, event: InputEventMouseButton) -> void:
	var here := inv.get_at(i).duplicate()
	if event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed and _held.is_empty():
		_quick_move(i, here)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if _held.is_empty():
			_held = here
			inv.set_at(i, {})
		elif here.is_empty():
			inv.set_at(i, _held)
			_held = {}
		elif here.id == _held.id:
			var n := mini(Items.stack_of(str(here.id)) - int(here.count), int(_held.count))
			here.count += n
			_held.count -= n
			inv.set_at(i, here)
			if _held.count <= 0:
				_held = {}
		else:
			inv.set_at(i, _held)
			_held = here
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _held.is_empty() and not here.is_empty():
			var half := ceili(int(here.count) / 2.0)
			_held = {"id": here.id, "count": half}
			here.count -= half
			inv.set_at(i, here)
		elif not _held.is_empty() and (here.is_empty() or (here.id == _held.id and int(here.count) < Items.stack_of(str(here.id)))):
			inv.set_at(i, {"id": _held.id, "count": int(here.get("count", 0)) + 1})
			_held.count -= 1
			if _held.count <= 0:
				_held = {}
	_refresh()


## Shift-click: a hand's stack into the knapsack; a knapsack's into a free
## hand (the right first).
func _quick_move(i: int, here: Dictionary) -> void:
	if here.is_empty():
		return
	if i >= Inventory.SLOTS:
		var left := inv.add(str(here.id), int(here.count))
		inv.set_at(i, {} if left <= 0 else {"id": here.id, "count": left})
		return
	for h in [Inventory.RIGHT, Inventory.LEFT]:
		if inv.get_at(h).is_empty():
			inv.set_at(h, here)
			inv.set_at(i, {})
			return


func _refresh() -> void:
	if inv == null:
		return
	for s in _slots + _corner:
		s.stack = inv.get_at(s.index)
		s.queue_redraw()
	for s in _corner:
		s.visible = not open
	_cursor.stack = _held
	_cursor.visible = open and not _held.is_empty()
	_cursor.queue_redraw()
