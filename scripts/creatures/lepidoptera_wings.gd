extends RefCounted
## The butterflies' and moths' wings (Lepidoptera): each one's outline (mm,
## its hinge at the origin, x out along it, z back; the right wing; walking
## clockwise seen from above, a fan from `middle`), and where a point (mm)
## is on data/creatures/lepidoptera_wings.png: uv_origin + p * uv_per_mm
## (its underside's: + under). Written by
## tools/creatures/bake_lepidoptera_wings.py: don't edit it by hand.

const WINGS := {
	"monarch_fore": {
		"outline": [Vector2(-0.476, -1.653), Vector2(5.555, -3.727), Vector2(13.640, -5.547), Vector2(23.898, -6.889), Vector2(34.229, -7.245), Vector2(41.364, -6.543), Vector2(45.923, -4.866), Vector2(48.457, -2.402), Vector2(49.479, 0.356), Vector2(49.093, 3.417), Vector2(47.100, 7.817), Vector2(44.077, 12.550), Vector2(40.400, 17.300), Vector2(36.684, 21.411), Vector2(33.174, 24.269), Vector2(30.087, 25.592), Vector2(27.005, 25.800), Vector2(20.823, 23.068), Vector2(14.119, 17.923), Vector2(8.522, 12.746), Vector2(4.000, 7.304), Vector2(1.006, 3.123), Vector2(-0.487, 0.888)],
		"middle": Vector2(26.8348, 7.1435),
		"uv_origin": Vector2(0.009052, 0.162447),
		"uv_per_mm": Vector2(0.0047326, 0.0094651),
		"under": Vector2(0.2500, 0.0000),
	},
	"monarch_hind": {
		"outline": [Vector2(-0.371, -1.335), Vector2(8.764, -1.941), Vector2(19.036, -0.499), Vector2(27.307, 3.106), Vector2(33.457, 8.298), Vector2(36.499, 13.968), Vector2(35.985, 19.620), Vector2(32.921, 24.769), Vector2(27.792, 28.906), Vector2(21.099, 30.990), Vector2(14.388, 30.487), Vector2(8.189, 27.391), Vector2(3.551, 22.220), Vector2(0.700, 14.995), Vector2(-0.455, 6.793)],
		"middle": Vector2(17.9133, 15.1667),
		"uv_origin": Vector2(0.511418, 0.067007),
		"uv_per_mm": Vector2(0.0063101, 0.0126202),
		"under": Vector2(0.2500, 0.0000),
	},
	"hemaris_fore": {
		"outline": [Vector2(-0.484, -0.726), Vector2(4.572, -1.859), Vector2(10.930, -2.895), Vector2(17.362, -2.945), Vector2(21.451, -2.216), Vector2(23.681, -0.936), Vector2(23.293, 0.518), Vector2(21.500, 2.818), Vector2(18.964, 5.387), Vector2(15.813, 7.590), Vector2(12.566, 9.096), Vector2(9.335, 9.172), Vector2(5.623, 7.728), Vector2(2.523, 5.351), Vector2(0.500, 2.816), Vector2(-0.495, 0.730)],
		"middle": Vector2(11.6875, 2.4562),
		"uv_origin": Vector2(0.016042, 0.692703),
		"uv_per_mm": Vector2(0.0093929, 0.0187858),
		"under": Vector2(0.0000, 0.0000),
	},
	"hemaris_hind": {
		"outline": [Vector2(-0.372, -0.835), Vector2(4.377, -1.085), Vector2(8.754, -0.131), Vector2(11.958, 2.099), Vector2(13.300, 5.016), Vector2(12.449, 8.021), Vector2(9.793, 10.205), Vector2(6.556, 10.997), Vector2(3.288, 10.253), Vector2(0.867, 7.650), Vector2(-0.295, 3.932), Vector2(-0.436, 1.256)],
		"middle": Vector2(5.8583, 4.7750),
		"uv_origin": Vector2(0.275316, 0.595802),
		"uv_per_mm": Vector2(0.0155756, 0.0311511),
		"under": Vector2(0.0000, 0.0000),
	},
}
