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
		"uv_origin": Vector2(0.009052, 0.046414),
		"uv_per_mm": Vector2(0.0047326, 0.0027043),
		"under": Vector2(0.2500, 0.0000),
	},
	"monarch_hind": {
		"outline": [Vector2(-0.371, -1.335), Vector2(8.764, -1.941), Vector2(19.036, -0.499), Vector2(27.307, 3.106), Vector2(33.457, 8.298), Vector2(36.499, 13.968), Vector2(35.985, 19.620), Vector2(32.921, 24.769), Vector2(27.792, 28.906), Vector2(21.099, 30.990), Vector2(14.388, 30.487), Vector2(8.189, 27.391), Vector2(3.551, 22.220), Vector2(0.700, 14.995), Vector2(-0.455, 6.793)],
		"middle": Vector2(17.9133, 15.1667),
		"uv_origin": Vector2(0.511418, 0.019145),
		"uv_per_mm": Vector2(0.0063101, 0.0036058),
		"under": Vector2(0.2500, 0.0000),
	},
	"hemaris_fore": {
		"outline": [Vector2(-0.484, -0.726), Vector2(4.572, -1.859), Vector2(10.930, -2.895), Vector2(17.362, -2.945), Vector2(21.451, -2.216), Vector2(23.681, -0.936), Vector2(23.293, 0.518), Vector2(21.500, 2.818), Vector2(18.964, 5.387), Vector2(15.813, 7.590), Vector2(12.566, 9.096), Vector2(9.335, 9.172), Vector2(5.623, 7.728), Vector2(2.523, 5.351), Vector2(0.500, 2.816), Vector2(-0.495, 0.730)],
		"middle": Vector2(11.6875, 2.4562),
		"uv_origin": Vector2(0.016042, 0.197915),
		"uv_per_mm": Vector2(0.0093929, 0.0053674),
		"under": Vector2(0.0000, 0.0000),
	},
	"hemaris_hind": {
		"outline": [Vector2(-0.372, -0.835), Vector2(4.377, -1.085), Vector2(8.754, -0.131), Vector2(11.958, 2.099), Vector2(13.300, 5.016), Vector2(12.449, 8.021), Vector2(9.793, 10.205), Vector2(6.556, 10.997), Vector2(3.288, 10.253), Vector2(0.867, 7.650), Vector2(-0.295, 3.932), Vector2(-0.436, 1.256)],
		"middle": Vector2(5.8583, 4.7750),
		"uv_origin": Vector2(0.275316, 0.170229),
		"uv_per_mm": Vector2(0.0155756, 0.0089003),
		"under": Vector2(0.0000, 0.0000),
	},
	"swallowtail_fore": {
		"outline": [Vector2(-0.481, -1.638), Vector2(7.567, -3.849), Vector2(17.774, -5.646), Vector2(28.198, -6.259), Vector2(36.387, -5.516), Vector2(41.449, -3.720), Vector2(43.072, -1.766), Vector2(41.892, 1.913), Vector2(39.497, 6.851), Vector2(36.444, 12.030), Vector2(33.331, 16.575), Vector2(30.627, 19.646), Vector2(26.605, 20.689), Vector2(18.837, 18.073), Vector2(11.589, 13.285), Vector2(5.506, 8.080), Vector2(1.501, 3.972), Vector2(-0.492, 0.911)],
		"middle": Vector2(23.2722, 5.1889),
		"uv_origin": Vector2(0.510048, 0.192082),
		"uv_per_mm": Vector2(0.0053968, 0.0030839),
		"under": Vector2(0.2500, 0.0000),
	},
	"swallowtail_hind": {
		"outline": [Vector2(-0.376, -1.329), Vector2(9.800, -2.258), Vector2(20.114, -0.887), Vector2(27.347, 2.640), Vector2(31.460, 7.405), Vector2(32.693, 10.916), Vector2(31.692, 16.287), Vector2(25.772, 38.269), Vector2(23.726, 40.484), Vector2(8.780, 29.849), Vector2(6.510, 28.007), Vector2(0.550, 5.781), Vector2(-0.410, 1.714)],
		"middle": Vector2(16.7231, 13.6462),
		"uv_origin": Vector2(0.036560, 0.297189),
		"uv_per_mm": Vector2(0.0054932, 0.0031390),
		"under": Vector2(0.2500, 0.0000),
	},
	"luna_fore": {
		"outline": [Vector2(-0.479, -1.943), Vector2(8.565, -5.046), Vector2(19.704, -7.203), Vector2(32.058, -8.097), Vector2(43.336, -7.170), Vector2(50.427, -5.060), Vector2(54.969, -1.974), Vector2(55.988, 1.390), Vector2(53.000, 7.507), Vector2(48.964, 14.686), Vector2(44.859, 21.348), Vector2(40.737, 26.640), Vector2(36.130, 28.883), Vector2(26.912, 25.992), Vector2(17.647, 19.854), Vector2(9.516, 12.626), Vector2(3.501, 5.977), Vector2(-0.491, 1.407)],
		"middle": Vector2(30.2778, 7.2056),
		"uv_origin": Vector2(0.508263, 0.332143),
		"uv_per_mm": Vector2(0.0042067, 0.0024038),
		"under": Vector2(0.2500, 0.0000),
	},
	"luna_hind": {
		"outline": [Vector2(-0.316, -1.587), Vector2(10.843, -2.875), Vector2(22.061, -1.496), Vector2(31.264, 2.776), Vector2(37.407, 9.210), Vector2(39.681, 16.362), Vector2(35.557, 71.975), Vector2(32.936, 71.081), Vector2(29.315, 65.487), Vector2(6.528, 26.665), Vector2(2.713, 18.386), Vector2(0.591, 9.213), Vector2(-0.353, 2.645)],
		"middle": Vector2(19.1385, 22.2462),
		"uv_origin": Vector2(0.062276, 0.436819),
		"uv_per_mm": Vector2(0.0032002, 0.0018287),
		"under": Vector2(0.2500, 0.0000),
	},
	"cloak_fore": {
		"outline": [Vector2(-0.470, -1.671), Vector2(7.600, -3.900), Vector2(16.832, -5.471), Vector2(26.201, -5.858), Vector2(33.374, -4.932), Vector2(37.035, -3.047), Vector2(38.869, -0.575), Vector2(38.297, 4.350), Vector2(35.480, 10.340), Vector2(32.379, 15.926), Vector2(30.086, 19.210), Vector2(27.184, 21.865), Vector2(23.888, 22.492), Vector2(16.845, 18.675), Vector2(9.570, 12.855), Vector2(4.000, 6.615), Vector2(0.708, 2.513), Vector2(-0.485, 0.677)],
		"middle": Vector2(20.9500, 6.1056),
		"uv_origin": Vector2(0.510870, 0.471807),
		"uv_per_mm": Vector2(0.0059443, 0.0033967),
		"under": Vector2(0.2500, 0.0000),
	},
	"cloak_hind": {
		"outline": [Vector2(-0.362, -1.345), Vector2(8.797, -2.057), Vector2(18.065, -0.796), Vector2(25.310, 2.607), Vector2(30.045, 7.173), Vector2(31.493, 11.717), Vector2(32.884, 18.727), Vector2(27.986, 24.118), Vector2(23.852, 27.632), Vector2(18.476, 29.894), Vector2(13.106, 29.891), Vector2(7.927, 26.819), Vector2(3.563, 21.242), Vector2(0.701, 13.473), Vector2(-0.444, 5.771)],
		"middle": Vector2(16.0800, 14.3067),
		"uv_origin": Vector2(0.012381, 0.587640),
		"uv_per_mm": Vector2(0.0069518, 0.0039725),
		"under": Vector2(0.2500, 0.0000),
	},
	"cecropia_fore": {
		"outline": [Vector2(-0.482, -2.134), Vector2(9.560, -6.037), Vector2(21.680, -8.584), Vector2(36.021, -9.700), Vector2(48.306, -8.995), Vector2(57.417, -6.876), Vector2(63.465, -3.384), Vector2(65.486, 0.482), Vector2(63.698, 4.950), Vector2(58.995, 11.069), Vector2(53.433, 18.250), Vector2(48.308, 24.394), Vector2(43.171, 29.470), Vector2(39.077, 31.894), Vector2(29.876, 28.984), Vector2(19.634, 22.340), Vector2(10.516, 14.124), Vector2(3.500, 6.479), Vector2(-0.492, 1.514)],
		"middle": Vector2(35.3000, 7.7895),
		"uv_origin": Vector2(0.507382, 0.619902),
		"uv_per_mm": Vector2(0.0036190, 0.0020680),
		"under": Vector2(0.2500, 0.0000),
	},
	"cecropia_hind": {
		"outline": [Vector2(-0.361, -1.546), Vector2(11.802, -3.059), Vector2(24.060, -1.496), Vector2(34.314, 3.611), Vector2(41.459, 10.801), Vector2(44.500, 18.990), Vector2(43.472, 27.166), Vector2(39.384, 34.320), Vector2(32.232, 39.943), Vector2(24.056, 41.997), Vector2(15.869, 40.282), Vector2(8.673, 34.379), Vector2(3.531, 26.175), Vector2(0.511, 14.894), Vector2(-0.424, 5.735)],
		"middle": Vector2(21.5333, 19.4667),
		"uv_origin": Vector2(0.010052, 0.727643),
		"uv_per_mm": Vector2(0.0052249, 0.0029857),
		"under": Vector2(0.2500, 0.0000),
	},
	"polyphemus_fore": {
		"outline": [Vector2(-0.482, -2.031), Vector2(8.559, -5.636), Vector2(19.686, -7.989), Vector2(33.049, -8.898), Vector2(44.329, -7.976), Vector2(52.429, -5.857), Vector2(57.471, -2.568), Vector2(58.890, 1.100), Vector2(56.500, 7.007), Vector2(51.973, 13.662), Vector2(46.874, 20.332), Vector2(42.243, 25.937), Vector2(37.633, 28.882), Vector2(27.908, 25.891), Vector2(18.137, 19.344), Vector2(9.515, 12.120), Vector2(3.300, 5.581), Vector2(-0.493, 1.317)],
		"middle": Vector2(31.5111, 6.6722),
		"uv_origin": Vector2(0.507965, 0.762811),
		"uv_per_mm": Vector2(0.0040080, 0.0022903),
		"under": Vector2(0.2500, 0.0000),
	},
	"polyphemus_hind": {
		"outline": [Vector2(-0.357, -1.550), Vector2(10.809, -2.862), Vector2(22.071, -1.295), Vector2(31.318, 3.214), Vector2(37.454, 9.390), Vector2(39.900, 16.981), Vector2(38.868, 25.177), Vector2(35.376, 31.829), Vector2(29.232, 36.643), Vector2(21.553, 38.697), Vector2(13.864, 37.081), Vector2(7.271, 31.576), Vector2(2.930, 23.771), Vector2(0.312, 13.490), Vector2(-0.417, 4.724)],
		"middle": Vector2(19.3400, 17.7800),
		"uv_origin": Vector2(0.013806, 0.870838),
		"uv_per_mm": Vector2(0.0056444, 0.0032253),
		"under": Vector2(0.2500, 0.0000),
	},
}
