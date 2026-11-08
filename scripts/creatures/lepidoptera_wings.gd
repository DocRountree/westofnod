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
		"uv_origin": Vector2(0.009052, 0.081224),
		"uv_per_mm": Vector2(0.0047326, 0.0047326),
		"under": Vector2(0.2500, 0.0000),
	},
	"monarch_hind": {
		"outline": [Vector2(-0.371, -1.335), Vector2(8.764, -1.941), Vector2(19.036, -0.499), Vector2(27.307, 3.106), Vector2(33.457, 8.298), Vector2(36.499, 13.968), Vector2(35.985, 19.620), Vector2(32.921, 24.769), Vector2(27.792, 28.906), Vector2(21.099, 30.990), Vector2(14.388, 30.487), Vector2(8.189, 27.391), Vector2(3.551, 22.220), Vector2(0.700, 14.995), Vector2(-0.455, 6.793)],
		"middle": Vector2(17.9133, 15.1667),
		"uv_origin": Vector2(0.511418, 0.033504),
		"uv_per_mm": Vector2(0.0063101, 0.0063101),
		"under": Vector2(0.2500, 0.0000),
	},
	"hemaris_fore": {
		"outline": [Vector2(-0.484, -0.726), Vector2(4.572, -1.859), Vector2(10.930, -2.895), Vector2(17.362, -2.945), Vector2(21.451, -2.216), Vector2(23.681, -0.936), Vector2(23.293, 0.518), Vector2(21.500, 2.818), Vector2(18.964, 5.387), Vector2(15.813, 7.590), Vector2(12.566, 9.096), Vector2(9.335, 9.172), Vector2(5.623, 7.728), Vector2(2.523, 5.351), Vector2(0.500, 2.816), Vector2(-0.495, 0.730)],
		"middle": Vector2(11.6875, 2.4562),
		"uv_origin": Vector2(0.016042, 0.346352),
		"uv_per_mm": Vector2(0.0093929, 0.0093929),
		"under": Vector2(0.0000, 0.0000),
	},
	"hemaris_hind": {
		"outline": [Vector2(-0.372, -0.835), Vector2(4.377, -1.085), Vector2(8.754, -0.131), Vector2(11.958, 2.099), Vector2(13.300, 5.016), Vector2(12.449, 8.021), Vector2(9.793, 10.205), Vector2(6.556, 10.997), Vector2(3.288, 10.253), Vector2(0.867, 7.650), Vector2(-0.295, 3.932), Vector2(-0.436, 1.256)],
		"middle": Vector2(5.8583, 4.7750),
		"uv_origin": Vector2(0.275316, 0.297901),
		"uv_per_mm": Vector2(0.0155756, 0.0155756),
		"under": Vector2(0.0000, 0.0000),
	},
	"swallowtail_fore": {
		"outline": [Vector2(-0.481, -1.638), Vector2(7.567, -3.849), Vector2(17.774, -5.646), Vector2(28.198, -6.259), Vector2(36.387, -5.516), Vector2(41.449, -3.720), Vector2(43.072, -1.766), Vector2(41.892, 1.913), Vector2(39.497, 6.851), Vector2(36.444, 12.030), Vector2(33.331, 16.575), Vector2(30.627, 19.646), Vector2(26.605, 20.689), Vector2(18.837, 18.073), Vector2(11.589, 13.285), Vector2(5.506, 8.080), Vector2(1.501, 3.972), Vector2(-0.492, 0.911)],
		"middle": Vector2(23.2722, 5.1889),
		"uv_origin": Vector2(0.510048, 0.336143),
		"uv_per_mm": Vector2(0.0053968, 0.0053968),
		"under": Vector2(0.2500, 0.0000),
	},
	"swallowtail_hind": {
		"outline": [Vector2(-0.376, -1.329), Vector2(9.800, -2.258), Vector2(20.114, -0.887), Vector2(27.347, 2.640), Vector2(31.460, 7.405), Vector2(32.693, 10.916), Vector2(31.692, 16.287), Vector2(25.772, 38.269), Vector2(23.726, 40.484), Vector2(8.780, 29.849), Vector2(6.510, 28.007), Vector2(0.550, 5.781), Vector2(-0.410, 1.714)],
		"middle": Vector2(16.7231, 13.6462),
		"uv_origin": Vector2(0.036560, 0.520081),
		"uv_per_mm": Vector2(0.0054932, 0.0054932),
		"under": Vector2(0.2500, 0.0000),
	},
	"luna_fore": {
		"outline": [Vector2(-0.479, -1.943), Vector2(8.565, -5.046), Vector2(19.704, -7.203), Vector2(32.058, -8.097), Vector2(43.336, -7.170), Vector2(50.427, -5.060), Vector2(54.969, -1.974), Vector2(55.988, 1.390), Vector2(53.000, 7.507), Vector2(48.964, 14.686), Vector2(44.859, 21.348), Vector2(40.737, 26.640), Vector2(36.130, 28.883), Vector2(26.912, 25.992), Vector2(17.647, 19.854), Vector2(9.516, 12.626), Vector2(3.501, 5.977), Vector2(-0.491, 1.407)],
		"middle": Vector2(30.2778, 7.2056),
		"uv_origin": Vector2(0.508263, 0.581250),
		"uv_per_mm": Vector2(0.0042067, 0.0042067),
		"under": Vector2(0.2500, 0.0000),
	},
	"luna_hind": {
		"outline": [Vector2(-0.316, -1.587), Vector2(10.843, -2.875), Vector2(22.061, -1.496), Vector2(31.264, 2.776), Vector2(37.407, 9.210), Vector2(39.681, 16.362), Vector2(35.557, 71.975), Vector2(32.936, 71.081), Vector2(29.315, 65.487), Vector2(6.528, 26.665), Vector2(2.713, 18.386), Vector2(0.591, 9.213), Vector2(-0.353, 2.645)],
		"middle": Vector2(19.1385, 22.2462),
		"uv_origin": Vector2(0.062276, 0.764434),
		"uv_per_mm": Vector2(0.0032002, 0.0032002),
		"under": Vector2(0.2500, 0.0000),
	},
}
