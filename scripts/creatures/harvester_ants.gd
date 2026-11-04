class_name HarvesterAnts
extends "res://scripts/creatures/ant_colony.gd" # (by path: found whether or not the editor has seen the class yet)
## Red harvester ants (Pogonomyrmex barbatus), workers, drawn at twice life
## size (about 15 mm long): rust red all over, the gaster a shade darker
## and smooth, shining; the head big and squarish, its cuticle and the
## mesosoma's finely ridged lengthwise (rugose), heavy toothed mandibles
## for cracking seeds, under the head a basket of long hairs (the
## psammophore, for carrying sand out of the nest); a squared-off
## mesosoma with a short spine each side at its back (the propodeum's); a
## two-noded waist (petiole and postpetiole); shorter antennae than a
## carpenter ant's. Made and moved as AntColony's carpenter ants are
## (the same shader, the same doings), a little quicker. Not yet in the
## game (tools/creatures/ant_demo.tscn, wasp_demo.tscn).

const HARVESTER := {
	"head_at": Vector3(0.0, 0.2, -1.5),
	"head": [[0.12, 0.0, 0.2, 0.2], [0.0, 0.05, 0.9, 0.72], [-0.25, 0.05, 1.12, 0.86], [-0.9, 0.0, 1.16, 0.88],
			[-1.5, -0.1, 1.08, 0.78], [-1.85, -0.22, 0.9, 0.56], [-2.05, -0.3, 0.52, 0.32], [-2.15, -0.32, 0.1, 0.1]],
	"head_sq": 2.9, # (squarish)
	"head_lobes": false,
	"eye": [Vector3(1.0, 0.28, -1.05), Vector3(0.4, 0.5, 0.5)],
	"mandible": Vector3(0.55, 0.36, 1.15),
	"teeth": 4,
	"beard": true,
	"antenna_at": Vector3(0.42, 0.35, -1.95), "scape": 1.5, "funiculus": [6, 0.32, 0.075],
	"meso": [[-1.6, 0.0, 0.14, 0.14], [-1.38, 0.1, 0.42, 0.4], [-1.0, 0.2, 0.68, 0.6], [-0.5, 0.25, 0.66, 0.62],
			[0.0, 0.16, 0.48, 0.52], [0.5, 0.12, 0.45, 0.55], [0.95, 0.08, 0.45, 0.5], [1.2, 0.0, 0.3, 0.32], [1.35, -0.05, 0.1, 0.1]],
	"meso_sq": 2.5, # (angular)
	"spines": [[Vector3(0.28, 0.5, 0.95), Vector3(0.36, 0.9, 1.3)]],
	"waist": [[Vector3(0.0, -0.05, 1.5), Vector3(0.3, 0.3, 0.55)], [Vector3(0.0, 0.18, 1.72), Vector3(0.55, 0.8, 0.55)],
			[Vector3(0.0, 0.08, 2.18), Vector3(0.78, 0.72, 0.62)]], # (a stalk, the petiole's node, the postpetiole)
	"gaster_at": Vector3(0.0, 0.05, 2.45),
	"gaster": [[2.42, 0.05, 0.15, 0.15], [2.6, 0.08, 0.65, 0.6], [3.1, 0.05, 1.0, 0.88], [3.8, -0.02, 1.08, 0.95],
			[4.5, -0.15, 0.9, 0.8], [5.0, -0.25, 0.5, 0.45], [5.25, -0.3, 0.08, 0.08]],
	"gaster_bands": [], # (smooth, unbanded)
	"legs": [
		{"hip": Vector3(0.32, -0.62, -0.85), "f": 1.95, "t": 1.7, "s": 1.6, "home": Vector2(3.1, -3.8)},
		{"hip": Vector3(0.4, -0.62, 0.15), "f": 2.15, "t": 2.0, "s": 1.9, "home": Vector2(4.4, 0.4)},
		{"hip": Vector3(0.42, -0.58, 0.85), "f": 2.6, "t": 2.5, "s": 2.4, "home": Vector2(4.1, 4.8)},
	],
	"leg_r": 0.15,
}


func _init() -> void:
	ant = HARVESTER
	body_h = 1.3
	top_speed = 0.07
	reach = 3.8
	apart = 8.0
	egg_kind = "harvester"
	egg_back = 4.6
	colors = {
		"black": Color(0.44, 0.12, 0.04), # (rust red: the head, the mesosoma)
		"leg_color": Color(0.5, 0.16, 0.05),
		"gaster_tint": Color(0.72, 0.66, 0.66), # (a shade darker)
		"gaster_gloss": 0.8,
		"rugose": 1.0,
		"stride_hz": 8.0,
	}


## A little pile of seeds, for them to feed at (harvest): a dozen grass
## and forb seeds, 2-3 mm (twice life size), tan to brown, its origin at
## its middle on the ground.
static func seeds() -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 8
	s.rings = 5
	for k in 14:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.008
		mi.scale = Vector3(0.0028, 0.0022, 0.005) * rng.randf_range(0.8, 1.2)
		mi.position = Vector3(cos(a) * r, 0.0011 + (0.0018 if k > 10 else 0.0), sin(a) * r)
		mi.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, 0.0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.62, 0.48, 0.3).lerp(Color(0.38, 0.26, 0.14), rng.randf())
		m.roughness = 0.55
		mi.material_override = m
		root.add_child(mi)
	return root
