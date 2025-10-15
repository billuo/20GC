class_name GridGPUCompute
extends GridCompute

var size: Vector2i
var data_1: PackedInt32Array
var data_2: PackedInt32Array
var image_bytes: PackedByteArray

var rd: RenderingDevice
var shader: RID
var ubo: RID
var sbo1: RID
var sbo2: RID
var output_texture: RID
var uniform_set: RID
var pipeline: RID


func _enter_tree() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		push_error("Failed to create rendering device")
		queue_free()
		return

	var shader_file: RDShaderFile = load("res://scene/world/gol.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)


func _exit_tree() -> void:
	rd.free_rid(shader)
	rd.free()


func reset(new_size: Vector2i, new_data := PackedInt32Array()):
	if not new_data:
		new_data = PackedInt32Array()
	if new_data.is_empty():
		new_data.resize(new_size.x * new_size.y)
	else:
		assert(new_data.size() == new_size.x * new_size.y)
	size = new_size
	data_1 = new_data
	data_2.resize(size.x * size.y)
	image_bytes.clear()
	image_bytes.resize(size.x * size.y)


func get_data() -> PackedInt32Array:
	return data_1


func get_image_bytes() -> PackedByteArray:
	return image_bytes


func step(callback: Callable):
	# upload data
	_free_if_valid(ubo)
	ubo = rd.uniform_buffer_create(16, PackedInt32Array([size.x, size.y, 0, 0]).to_byte_array())
	var u_uniforms := RDUniform.new()
	u_uniforms.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_uniforms.binding = 0
	u_uniforms.add_id(ubo)

	_free_if_valid(sbo1)
	sbo1 = rd.storage_buffer_create(data_1.size() * 4, data_1.to_byte_array())
	var u_cur := RDUniform.new()
	u_cur.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_cur.binding = 1
	u_cur.add_id(sbo1)

	_free_if_valid(sbo2)
	sbo2 = rd.storage_buffer_create(data_2.size() * 4, data_2.to_byte_array())
	var u_next := RDUniform.new()
	u_next.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_next.binding = 2
	u_next.add_id(sbo2)

	_free_if_valid(output_texture)
	var format = RDTextureFormat.new()
	format.width = size.x
	format.height = size.y
	format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	output_texture = rd.texture_create(format, RDTextureView.new())
	var u_image := RDUniform.new()
	u_image.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_image.binding = 3
	u_image.add_id(output_texture)

	_free_if_valid(uniform_set)
	uniform_set = rd.uniform_set_create([u_uniforms, u_cur, u_next, u_image], shader, 0)

	# setup pipeline
	_free_if_valid(pipeline)
	pipeline = rd.compute_pipeline_create(shader)
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, int(ceilf(size.x / 32.0)), int(ceilf(size.y / 32.0)), 1)
	rd.compute_list_end()

	# compute and free memory
	var my_callback = func(bytes: PackedByteArray):
		data_2 = bytes.to_int32_array()
		# _mypprint(data_1)
		# _mypprint(data_2)
		var t = data_2
		data_2 = data_1
		data_1 = t
		callback.call(data_1)
	rd.buffer_get_data_async(sbo2, my_callback)
	rd.submit()
	rd.sync()
	image_bytes = rd.texture_get_data(output_texture, 0)


func _free_if_valid(rid: RID):
	if rid.is_valid():
		rd.free_rid(rid)


func _mypprint(a: PackedInt32Array):
	var s = ""
	for j in range(size.y):
		for i in range(size.x):
			s += str(a[i + j * size.x])
		s += "\n"
	print(s)
