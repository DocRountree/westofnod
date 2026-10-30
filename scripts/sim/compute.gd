class_name Compute
extends RefCounted
## Small helpers for compute shaders on a local RenderingDevice.


## Compiles a `#[compute]` GLSL file from source. (Not via the RDShaderFile
## importer, which refuses to run headless. Exports need `*.glsl` in the
## non-resource export filter.)
static func load_shader(rd: RenderingDevice, path: String) -> RID:
	var src := RDShaderSource.new()
	src.source_compute = FileAccess.get_file_as_string(path).replace("#[compute]", "")
	var spirv := rd.shader_compile_spirv_from_source(src)
	if spirv.compile_error_compute != "":
		push_error(path + ": " + spirv.compile_error_compute)
		return RID()
	return rd.shader_create_from_spirv(spirv)


static func buffer(rd: RenderingDevice, data: PackedFloat32Array) -> RID:
	if data.is_empty():
		data = PackedFloat32Array([0, 0, 0, 0])
	var bytes := data.to_byte_array()
	return rd.storage_buffer_create(bytes.size(), bytes)


static func uniform_set(rd: RenderingDevice, shader: RID, bufs: Array[RID]) -> RID:
	var uniforms: Array[RDUniform] = []
	for i in bufs.size():
		var u := RDUniform.new()
		u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u.binding = i
		u.add_id(bufs[i])
		uniforms.append(u)
	return rd.uniform_set_create(uniforms, shader, 0)
