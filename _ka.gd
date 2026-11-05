extends SceneTree
var demo: Node
var t := 0.0
var step := 0
var stations: Array = []
const ACTS := ["eat", "hunt", "mate", "lay", "nurse", "play", "sleep", "sit", "groom", "mark", "display", "alarm", "forage", "wander"]

func _initialize() -> void:
	for s in OS.get_cmdline_user_args()[0].split(","):
		stations.append(int(s))
	demo = (load("res://tools/creatures/life_cycle_demo.tscn") as PackedScene).instantiate()
	get_root().add_child(demo)

func _process(dt: float) -> bool:
	t += dt
	if t > 1.0 + step * 2.5:
		var i := step
		if i >= ACTS.size() * stations.size():
			print("DONE")
			return true
		var st: int = stations[i / ACTS.size()]
		if i % ACTS.size() == 0:
			demo.call("_go", st)
		print("ACT ", st, " ", ACTS[i % ACTS.size()])
		demo.call("_act_here", ACTS[i % ACTS.size()])
		step += 1
	return false
