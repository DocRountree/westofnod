@tool
class_name Moon
extends MeshInstance3D
## The moon: a sphere lit by the real sun direction, drawn as a camera-facing
## disc in the sky, so its phase is simply where the light falls. By day it
## adds to the sky (a pale disc); at night it covers the stars behind it.

const DISTANCE := 96000.0          ## Beyond the farthest land, inside the camera's far plane (120 km).

@export var size_scale := 3.5      ## Angular size relative to the real moon (0.52 deg), which is only a few pixels.
@export var zoomed_scale := 1.5    ## ... and once magnified (a little larger than life there too).


func _ready() -> void:
	if mesh == null:
		mesh = QuadMesh.new()
	custom_aabb = AABB(Vector3.ONE * -1.0, Vector3.ONE * 2.0)


## Place the moon. moon_dir and sun_dir are world unit vectors; night is 0 by day, 1 at night.
## pole: the celestial north pole (world unit vector), to turn the moon's face.
func update_sky(moon_dir: Vector3, sun_dir: Vector3, night: float, pole := Vector3.UP) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var z := -moon_dir                                   # disc faces the camera
	var x := (Vector3.UP if absf(z.y) < 0.99 else Vector3.FORWARD).cross(z).normalized()
	var y := z.cross(x)
	# drawn larger than life for the naked eye, true to size once magnified
	var zoom := tan(deg_to_rad(75.0) * 0.5) / tan(deg_to_rad(cam.fov) * 0.5)
	var size := deg_to_rad(0.52) * maxf(size_scale / maxf(zoom, 1.0), zoomed_scale) * DISTANCE
	global_transform = Transform3D(Basis(x * size, y * size, z), cam.global_position + moon_dir * DISTANCE)
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter("sun_local", Vector3(sun_dir.dot(x), sun_dir.dot(y), sun_dir.dot(z)))
	mat.set_shader_parameter("night", night)
	var pl := pole - z * pole.dot(z)
	mat.set_shader_parameter("north_local", Vector2(pl.dot(x), pl.dot(y)))
	if mat.get_shader_parameter("albedo_map") == null:
		mat.set_shader_parameter("albedo_map", load("res://data/sky/moon_albedo.jpg"))
	visible = moon_dir.y > -0.05


const PHASES: Array[String] = ["new moon", "waxing crescent", "first quarter", "waxing gibbous",
		"full moon", "waning gibbous", "last quarter", "waning crescent"]
