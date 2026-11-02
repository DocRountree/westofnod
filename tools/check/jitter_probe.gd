extends SceneTree
## Run by tools/check/check.py. Stands the player still at the spawn and turns
## the view through eight directions; at each, waits for the streaming to
## settle, then grabs a few frames in a row with nothing moving on purpose.
## Writes the frames (v<view>_<grab>.png) and PROBE lines with the camera and
## the player's positions.

const VIEWS := 8     # (check.py: VIEWS)
const SETTLE := 30   # frames once the world is loaded, before the first view
const WAIT := 12     # frames at each view before the grabs
const GRABS := 4     # consecutive frames grabbed at each view

var main: Node
var out_dir := ""
var state := 0
var count := 0
var view := 0
var grab := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://check"
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	print("PROBE started ", Time.get_datetime_string_from_system())


func _process(_delta: float) -> bool:
	if main.player == null or main.player.frozen or not main._loaded:
		return false
	var p: Player = main.player
	p.velocity = Vector3.ZERO
	match state:
		0:
			count += 1
			if count >= SETTLE:
				print("PROBE world ready, player at ", p.global_position)
				state = 1
		1:
			p.rotation.y = TAU * view / VIEWS
			p.head.rotation.x = -0.2
			count = 0
			state = 2
		2:
			count += 1
			if count >= WAIT:
				grab = 0
				state = 3
		3:
			var img := root.get_texture().get_image()
			img.save_png(out_dir.path_join("v%d_%d.png" % [view, grab]))
			print("PROBE view %d grab %d camera %s player %s" % [view, grab, p.camera.global_position, p.global_position])
			grab += 1
			if grab >= GRABS:
				view += 1
				count = 0
				state = 1 if view < VIEWS else 4
		4:
			print("PROBE finished ", Time.get_datetime_string_from_system())
			return true
	return false
