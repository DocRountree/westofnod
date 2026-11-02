class_name Origin
## The floating origin. The map is hundreds of km across; a 32-bit float only
## resolves a few mm at tens of km out, so drawn there everything shimmered
## as the view turned (each vertex's position rounded afresh). So what is
## drawn is drawn near the origin: everything in the world (terrain, sea,
## trees, grass, the player) is a child of one node, `root`, moved by
## -offset, and offset follows the player in whole steps.
##
## The game itself still works in map coordinates: a world node's `position`
## (its parent is root, or under it) is where it is on the map. Only global
## positions (global_position, a camera's, a bone's) are drawn ones: map() and
## render() turn one into the other. Shaders read the offset as the global
## shader parameter world_origin (shaders/render/origin.gdshaderinc): map =
## drawn + world_origin.
##
## The offset is a whole number of STEPs (exact in a float), only in x and z,
## and only changes when the player is more than a STEP from it, so nothing
## moves on screen when it does: the drawn positions all shift together, and
## the shaders' world_origin with them.

const STEP := 1024.0 ## m

static var offset := Vector3.ZERO ## map = drawn + offset (y 0)
static var root: Node3D ## the node all of the world hangs from (main.gd)


## A drawn (global) position to the map's.
static func map(p: Vector3) -> Vector3:
	return p + offset


## A map position to the drawn (global) one.
static func render(p: Vector3) -> Vector3:
	return p - offset


## Keeps the offset within a STEP of the player (map position p). True when
## it moved.
static func follow(p: Vector3) -> bool:
	if absf(p.x - offset.x) <= STEP and absf(p.z - offset.z) <= STEP and root and root.position == -offset:
		return false
	offset = Vector3(snappedf(p.x, STEP), 0.0, snappedf(p.z, STEP))
	if root:
		root.position = -offset
	RenderingServer.global_shader_parameter_set("world_origin", offset)
	return true
