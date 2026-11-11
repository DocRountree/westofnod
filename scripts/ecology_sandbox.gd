class_name EcologySandbox
extends Node
## Debug mode's ecology tools: the creature toolkit (tools/creatures/
## ecology_demo: the list, placing, selecting, what they all do) in the game
## itself, L (Settings: "ecology_tools", rebindable; main.gd) or /sandbox,
## and away again the same way. The game goes on
## under them: what's put down is put down on the land where the view meets
## it, and lives there (a creature over the ground as it lies, by day and
## night, among the game's own trees), whether the tools are open or not.
## Nothing of it is saved.
##
## Open, the mouse is free: the list (right), then a left click on the
## ground puts one there, and again; right click or the panel's Done:
## stop. A left click on a creature (not placing) selects it (Shift: more).
## The right button held: looking round, as ever; the keys are the game's,
## as ever: the tools have none of their own. What the selected do (none:
## everything put down), taking them away: the panel's buttons.
##
## The toolkit's own space is the drawn one (Origin's: its creatures go by
## where things are drawn), so the floating origin is held where it is
## while anything put down is there (Origin.hold); 3 km from it everything
## put down is taken away, and the origin follows again.
##
## Not here yet: ponds, the sea and what lives in them (the toolkit digs
## them in its own plain: EcologyDemo.WET); those are still in its own
## scene, tools/creatures/ecology_demo.tscn.

const DEMO := preload("res://tools/creatures/ecology_demo.gd")
const HOLD := 3072.0 ## m: how far past its step the origin's held for what's put down

var main: Node ## (main.gd: its world, its player, its chat)
var is_open := false
var _demo: Node3D
var _looking := false # (the right button held: the view turned)
var _looked := 0.0 # (px, since it went down)
var _left_down := Vector2.INF


func _ready() -> void:
	_demo = DEMO.new()
	_demo.set("world", main.world)
	_demo.set("cam", main.player.camera)
	main.add_child(_demo) # (main: at the origin, unmoved, so its space is the drawn one)
	_demo.call("show_ui", false)


func _exit_tree() -> void:
	Origin.hold = 0.0


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_demo.call("show_ui", true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not is_open:
		return
	is_open = false
	_looking = false
	_demo.call("show_ui", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_dt: float) -> void:
	# the origin held while anything put down is here; too far from it,
	# everything taken away
	var things: bool = _demo.call("has_things")
	Origin.hold = HOLD if things else 0.0
	var p: Vector3 = Origin.render(main.player.position)
	if things and maxf(absf(p.x), absf(p.z)) > Origin.STEP + HOLD - 64.0:
		_demo.call("clear_all")
		Origin.hold = 0.0
		main.chat.say("The ecology tools: too far from what was put down; all of it taken away.", Color(0.75, 0.85, 1.0))
	# (the chat, the menu and the knapsack take the mouse and give it back
	# caught: open, it's free again)
	if is_open and not _looking and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not get_tree().paused and not main.player.typing:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Open: the mouse's buttons are the tools' (none gets to the game: the axe,
## the hands), but over the panel, which takes its own. The keys are all
## the game's.
func _input(event: InputEvent) -> void:
	if not is_open or get_tree().paused or main.player.typing:
		return
	if event is InputEventMouseMotion and _looking:
		_looked += (event as InputEventMouseMotion).relative.length()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not _looking and mb.pressed and get_viewport().gui_get_hovered_control() != null:
			return # (the panel's own)
		match mb.button_index:
			MOUSE_BUTTON_RIGHT:
				_looking = mb.pressed
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mb.pressed else Input.MOUSE_MODE_VISIBLE
				if mb.pressed:
					_looked = 0.0
				elif _looked < 4.0:
					_demo.call("_stop_placing")
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_left_down = mb.position
				elif _left_down != Vector2.INF and not _looking:
					if mb.position.distance_to(_left_down) < 6.0:
						_demo.call("click", mb.position, mb.shift_pressed)
					_left_down = Vector2.INF
			_:
				return
		get_viewport().set_input_as_handled()
