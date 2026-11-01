class_name Chat
extends CanvasLayer
## Chat and commands, as in Minecraft: T opens the chat, / opens it with a
## command started. Enter sends, Esc closes, Up/Down step through what you
## sent before, Tab completes a command's name. Messages show bottom-left and
## fade after a while; with the chat open, all of them show.
##
## Commands (/help lists them): tp / teleport, time, spawn, fly, zoom, aurora,
## pos, pop, clear.

const SHOW_SECONDS := 10.0
const FADE_SECONDS := 1.5
const MAX_LINES := 100 ## kept
const SHOWN := 12      ## shown at most
## Islands /tp knows by name: (longitude, latitude) on the planet.
const PLACES := {
	"isabela": Vector2(-110.0, 5.0), "fernandina": Vector2(-150.0, 2.0), "santiago": Vector2(-30.0, 8.0),
	"santa cruz": Vector2(5.0, -16.0), "san cristobal": Vector2(145.0, -31.0), "floreana": Vector2(2.0, -63.0),
	"espanola": Vector2(110.0, -70.0), "santa fe": Vector2(57.0, -31.0), "pinzon": Vector2(-28.0, -16.0),
	"rabida": Vector2(-36.0, -2.0), "pinta": Vector2(-48.0, 70.0), "marchena": Vector2(-3.0, 52.0),
	"genovesa": Vector2(60.0, 52.0), "spawn": Vector2.INF,
}

var main: Node
var open := false
var _input: LineEdit
var _log: VBoxContainer
var _lines: Array[Dictionary] = [] # {label, time}
var _history: PackedStringArray = []
var _history_at := 0
var _commands := {}


func _ready() -> void:
	layer = 5
	_commands = {
		"help": [_help, "/help: this list"],
		"tp": [_tp, "/tp x y z  |  /tp x z  |  /tp <lat> <lon> (with N/S, E/W)  |  /tp <island>: teleport"],
		"teleport": [_tp, "/teleport: as /tp"],
		"time": [_time, "/time set <day|noon|sunset|night|midnight|hh:mm>  |  /time add <hours>  |  /time"],
		"spawn": [_spawn, "/spawn: back to the spawn point"],
		"fly": [_fly, "/fly: toggle flying"],
		"zoom": [_zoom, "/zoom <1-8>: magnify"],
		"aurora": [_aurora, "/aurora: toggle an aurora every night"],
		"pos": [_pos, "/pos: where you are"],
		"pop": [_pop, "/pop: what is living near by (trees, rocks, animals: Population)"],
		"clear": [_clear, "/clear: clear the chat"],
	}
	var box := VBoxContainer.new()
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 12
	box.offset_right = 760
	box.offset_top = -420
	box.offset_bottom = -12
	box.alignment = BoxContainer.ALIGNMENT_END
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_log = VBoxContainer.new()
	_log.alignment = BoxContainer.ALIGNMENT_END
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_log)
	_input = LineEdit.new()
	_input.visible = false
	_input.context_menu_enabled = false
	_input.add_theme_color_override("font_color", Color.WHITE)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.content_margin_left = 6
	bg.content_margin_right = 6
	_input.add_theme_stylebox_override("normal", bg)
	_input.add_theme_stylebox_override("focus", bg)
	_input.text_submitted.connect(_submit)
	_input.gui_input.connect(_on_input_key)
	box.add_child(_input)


func _unhandled_input(event: InputEvent) -> void:
	if open or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_SLASH or event.unicode == 47:
		_open("/")
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_open("")
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for i in _lines.size():
		var l: Dictionary = _lines[i]
		var age := now - float(l.time)
		var a := 1.0 if open else clampf((SHOW_SECONDS + FADE_SECONDS - age) / FADE_SECONDS, 0.0, 1.0)
		if i < _lines.size() - SHOWN:
			a = 0.0
		(l.label as Label).modulate.a = a
		(l.label as Label).get_parent().visible = a > 0.0


## Shows a line in the chat (from commands, or anything else in the game).
func say(text: String, colour := Color.WHITE) -> void:
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.4)
	bg.content_margin_left = 6
	bg.content_margin_right = 6
	panel.add_theme_stylebox_override("panel", bg)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", colour)
	panel.add_child(label)
	_log.add_child(panel)
	_lines.append({"label": label, "time": Time.get_ticks_msec() / 1000.0})
	while _lines.size() > MAX_LINES:
		(_lines.pop_front().label as Label).get_parent().queue_free()


func _open(start: String) -> void:
	open = true
	_set_typing(true)
	_input.visible = true
	_input.text = start
	_input.grab_focus()
	_input.caret_column = start.length()
	_history_at = _history.size()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	open = false
	_set_typing(false)
	_input.visible = false
	_input.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_typing(on: bool) -> void:
	main.player.typing = on
	main.clock.typing = on


func _on_input_key(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ESCAPE:
			_close()
		KEY_UP:
			if _history_at > 0:
				_history_at -= 1
				_input.text = _history[_history_at]
				_input.caret_column = _input.text.length()
		KEY_DOWN:
			if _history_at < _history.size():
				_history_at += 1
				_input.text = _history[_history_at] if _history_at < _history.size() else ""
				_input.caret_column = _input.text.length()
		KEY_TAB:
			_complete()
		_:
			return
	_input.accept_event()


func _complete() -> void:
	var t := _input.text
	if not t.begins_with("/") or " " in t:
		return
	var hits := []
	for c in _commands:
		if c.begins_with(t.substr(1)):
			hits.append(c)
	if hits.size() == 1:
		_input.text = "/" + hits[0] + " "
	elif hits.size() > 1:
		say("  ".join(hits.map(func(c): return "/" + c)), Color(0.7, 0.7, 0.7))
	_input.caret_column = _input.text.length()


func _submit(text: String) -> void:
	text = text.strip_edges()
	_close()
	if text == "":
		return
	_history.append(text)
	if text.begins_with("/"):
		var parts := text.substr(1).split(" ", false)
		if parts.is_empty():
			return
		var name := parts[0].to_lower()
		if not _commands.has(name):
			say("Unknown command /%s. Try /help." % name, Color(1.0, 0.45, 0.4))
			return
		(_commands[name][0] as Callable).call(parts.slice(1))
	else:
		say("<you> " + text)


# --- commands --------------------------------------------------------------

func _help(_args: PackedStringArray) -> void:
	for c in _commands:
		say(_commands[c][1], Color(0.75, 0.85, 1.0))


func _tp(args: PackedStringArray) -> void:
	var p: Player = main.player
	var w: WorldData = main.world
	var target := Vector3.INF
	var joined := " ".join(args).to_lower()
	if joined == "spawn":
		target = w.spawn
	elif PLACES.has(joined):
		var ll: Vector2 = PLACES[joined]
		target = _from_lat_lon(ll.y, ll.x)
	elif args.size() == 2 and (_is_lat(args[0]) or _is_lat(args[1])):
		var a := _deg(args[0])
		var b := _deg(args[1])
		target = _from_lat_lon(a, b)
	elif args.size() == 3 and args[0].is_valid_float() and args[1].is_valid_float() and args[2].is_valid_float():
		target = Vector3(args[0].to_float(), args[1].to_float(), args[2].to_float())
	elif args.size() == 2 and args[0].is_valid_float() and args[1].is_valid_float():
		var x := args[0].to_float()
		var z := args[1].to_float()
		target = Vector3(x, w.height_at(x, z) + 1.0, z)
	if target == Vector3.INF:
		say(_commands.tp[1], Color(1.0, 0.45, 0.4))
		return
	p.velocity = Vector3.ZERO
	p.global_position = target
	say("Teleported to x %.0f  y %.0f  z %.0f  (%s)" % [target.x, target.y, target.z, _where()], Color(0.6, 1.0, 0.6))


## Planet degrees (+ north, + east) to a point on the ground (a little above it).
func _from_lat_lon(lat: float, lon: float) -> Vector3:
	var w: WorldData = main.world
	var x := w.origin.x + (wrapf(lon, -180.0, 180.0) + 180.0) / 360.0 * w.domain
	var z := w.origin.y + (90.0 - clampf(lat, -89.9, 89.9)) / 180.0 * w.domain
	return Vector3(x, maxf(w.height_at(x, z), 0.0) + 1.0, z)


func _is_lat(s: String) -> bool:
	var u := s.to_upper()
	return u.ends_with("N") or u.ends_with("S") or u.ends_with("E") or u.ends_with("W")


## "22.4S" -> -22.4, "18E" -> 18 (a plain number is taken as it is).
func _deg(s: String) -> float:
	var u := s.to_upper().replace("°", "")
	var sign := -1.0 if u.ends_with("S") or u.ends_with("W") else 1.0
	return u.trim_suffix("N").trim_suffix("S").trim_suffix("E").trim_suffix("W").to_float() * sign


func _time(args: PackedStringArray) -> void:
	var c: GameClock = main.clock
	if args.is_empty():
		say(c.time_text())
		return
	if args[0] == "add" and args.size() > 1 and args[1].is_valid_float():
		c.advance(args[1].to_float())
	elif args[0] == "set" and args.size() > 1:
		var named := {"day": 9.0, "morning": 8.0, "noon": 12.0, "sunset": c.sunset(), "dusk": c.sunset() + 0.5,
				"night": 22.0, "midnight": 0.0, "sunrise": c.sunrise()}
		var v := args[1].to_lower()
		var t := -1.0
		if named.has(v):
			t = named[v]
		elif ":" in v:
			var hm := v.split(":")
			t = hm[0].to_float() + hm[1].to_float() / 60.0
		elif v.is_valid_float():
			t = v.to_float()
		if t < 0.0 or t >= 24.0:
			say(_commands.time[1], Color(1.0, 0.45, 0.4))
			return
		c.advance(fposmod(t - c.time_of_day, 24.0))
	else:
		say(_commands.time[1], Color(1.0, 0.45, 0.4))
		return
	say("Time: " + c.time_text(), Color(0.6, 1.0, 0.6))


func _spawn(_args: PackedStringArray) -> void:
	main.player.velocity = Vector3.ZERO
	main.player.global_position = main.world.spawn
	say("Back at the spawn point.", Color(0.6, 1.0, 0.6))


func _fly(_args: PackedStringArray) -> void:
	main.player.set_flying(not main.player.flying)
	say("Flying " + ("on." if main.player.flying else "off."), Color(0.6, 1.0, 0.6))


func _zoom(args: PackedStringArray) -> void:
	if args.is_empty() or not args[0].is_valid_float():
		say(_commands.zoom[1], Color(1.0, 0.45, 0.4))
		return
	var z := clampf(args[0].to_float(), 1.0, Player.MAX_ZOOM)
	main.player.zoom_power = maxf(z, 2.0)
	main.player.set_zoom(z)
	say("Magnification %.1fx." % z, Color(0.6, 1.0, 0.6))


func _aurora(_args: PackedStringArray) -> void:
	main.aurora.set_forced(not main.aurora.forced)
	say("Aurora every night: " + ("on (north of %d°N)." % int(main.aurora.min_latitude) if main.aurora.forced else "off."), Color(0.6, 1.0, 0.6))


func _pos(_args: PackedStringArray) -> void:
	var p: Vector3 = main.player.global_position
	var b: String = main.world.biome_at(p.x, p.z)
	say("x %.0f  y %.1f  z %.0f  (%s)%s" % [p.x, p.y, p.z, _where(), ("  " + b) if b != "" else ""])


func _pop(_args: PackedStringArray) -> void:
	var s: Dictionary = main.population.stats()
	say("%d props, %d actors in %d chunks (%d generating); %d prop kinds, %d actor kinds" % [
			s.props, s.actors, s.chunks, s.generating, s.prop_kinds, s.actor_kinds])


func _where() -> String:
	var p: Vector3 = main.player.global_position
	var lat: float = main.latitude_at(p.z)
	var lon: float = main.longitude_at(p.x)
	return "%.1f°%s %.1f°%s" % [absf(lat), "N" if lat >= 0.0 else "S", absf(lon), "E" if lon >= 0.0 else "W"]


func _clear(_args: PackedStringArray) -> void:
	for l in _lines:
		(l.label as Label).get_parent().queue_free()
	_lines.clear()
