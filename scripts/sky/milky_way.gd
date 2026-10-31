class_name MilkyWay
extends MeshInstance3D
## The Milky Way, star by star (see milky_way.gdshader): V 10.5 to 17.5 in
## one-magnitude bins, each with its own grid of cells on the sky. A child of
## the Starfield, which places it in the local sky and passes on visibility,
## pixel size and the telescope's light grasp.
##
## Star counts (whole sky, brighter than V) from the classic star-count
## tables (Allen's Astrophysical Quantities, roughly; Tycho-2 has 2.5 million
## to V 11.5); across the sky, a disc concentrated toward the galactic plane
## (more so for fainter, farther stars) and brighter toward the centre, plus
## the bulge. No dust: the plane is as the stars alone would make it.

const RADIUS := 99000.0
## log10 of the number of stars brighter than V, at each bin edge.
const BIN_EDGES := [10.5, 11.5, 12.5, 13.5, 14.5, 15.5, 16.5, 17.5]
const LOG_COUNT := [5.45, 5.9, 6.3, 6.7, 7.05, 7.4, 7.75, 8.05]


func _ready() -> void:
	var dome := SphereMesh.new()
	dome.radius = RADIUS
	dome.height = RADIUS * 2.0
	dome.radial_segments = 64
	dome.rings = 32
	mesh = dome
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3.ONE * -RADIUS, Vector3.ONE * RADIUS * 2.0)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/sky/milky_way.gdshader")
	material_override = mat
	var cells := PackedFloat32Array()
	var mags := PackedFloat32Array()
	var counts := PackedFloat32Array()
	var shapes: Array[Vector4] = []
	var n := BIN_EDGES.size() - 1
	for k in n:
		var t := float(k) / (n - 1)
		var disc := lerpf(3.0, 12.0, t)
		var height := deg_to_rad(lerpf(15.0, 7.0, t))
		var bulge := lerpf(0.5, 8.0, t)
		# normalise the shape to a mean of 1 over the sky, and find its peak
		var sum := 0.0
		var weight := 0.0
		var peak := 0.0
		for bi in 90:
			var b := deg_to_rad(-89.0 + 2.0 * bi)
			for li in 180:
				var l := deg_to_rad(-179.0 + 2.0 * li)
				var f := 1.0 + disc * (0.55 + 0.45 * cos(l)) * exp(-absf(b) / height) \
						+ bulge * exp(-(l * l + b * b) / (2.0 * 0.17 * 0.17))
				sum += f * cos(b)
				weight += cos(b)
				peak = maxf(peak, f)
		var norm := sum / weight
		var total := pow(10.0, LOG_COUNT[k + 1]) - pow(10.0, LOG_COUNT[k])
		var per_sr := total / (4.0 * PI)
		# cells small enough to hold about one star at the densest
		var omega := 1.2 / (per_sr * peak / norm)
		cells.append(ceilf(2.0 / sqrt(omega)))
		mags.append(BIN_EDGES[k])
		counts.append(per_sr)
		shapes.append(Vector4(disc, height, bulge, norm))
	mat.set_shader_parameter("levels", n)
	mat.set_shader_parameter("lv_cells", cells)
	mat.set_shader_parameter("lv_mag", mags)
	mat.set_shader_parameter("lv_count", counts)
	mat.set_shader_parameter("lv_shape", shapes)


func update_sky(visibility: float, pixel_angle: float, gain: float) -> void:
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter("visibility", visibility)
	mat.set_shader_parameter("pixel_angle", pixel_angle)
	mat.set_shader_parameter("gain", gain)
