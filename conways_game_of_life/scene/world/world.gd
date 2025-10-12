extends Node2D

var size: Vector2i
var bytes_1: PackedInt32Array
var bytes_2: PackedInt32Array

var rd: RenderingDevice
var shader: RID
var sbo1: RID
var sbo2: RID


func _mypprint(a: PackedInt32Array):
	var s = ""
	for j in range(size.y):
		for i in range(size.x):
			s += str(a[i + j * size.x])
		s += "\n"
	print(s)


func _enter_tree() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		push_error("Failed to create rendering device")
		queue_free()
		return

	var shader_file: RDShaderFile = load("res://scene/world/gol.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)

	# FIXME: test only
	reset(Vector2i(32, 33))
	for y in range(1, size.y, 2):
		for x in range(size.x):
			bytes_1[x + y * size.x] = 1
	$Grid.data = bytes_1


func _exit_tree() -> void:
	rd.free_rid(shader)
	rd.free()


func reset(new_size: Vector2i):
	size = new_size
	bytes_1.clear()
	bytes_1.resize(size.x * size.y)
	bytes_2.clear()
	bytes_2.resize(size.x * size.y)
	$Grid.width = size.x
	$Grid.height = size.y


func step():
	var t0 = Time.get_ticks_usec()

	# upload data
	var u_uniforms := RDUniform.new()
	u_uniforms.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_uniforms.binding = 0
	var ubo = rd.uniform_buffer_create(16, PackedInt32Array([size.x, size.y, 0, 0]).to_byte_array())
	u_uniforms.add_id(ubo)

	var u_cur := RDUniform.new()
	u_cur.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_cur.binding = 1
	_free_if_valid(sbo1)
	sbo1 = rd.storage_buffer_create(bytes_1.size() * 4, bytes_1.to_byte_array())
	u_cur.add_id(sbo1)

	var u_next := RDUniform.new()
	u_next.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_next.binding = 2
	_free_if_valid(sbo2)
	sbo2 = rd.storage_buffer_create(bytes_2.size() * 4, bytes_2.to_byte_array())
	u_next.add_id(sbo2)

	var uniform_set = rd.uniform_set_create([u_uniforms, u_cur, u_next], shader, 0)

	# setup pipeline
	var pipeline = rd.compute_pipeline_create(shader)
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, int(ceilf(size.x / 32.0)), int(ceilf(size.y / 32.0)), 1)
	rd.compute_list_end()

	# compute and free memory
	rd.submit()
	rd.sync()
	_free_if_valid(ubo)
	_free_if_valid(uniform_set)
	_free_if_valid(pipeline)

	# retrieve output
	bytes_2 = rd.buffer_get_data(sbo2).to_int32_array()
	# _mypprint(bytes_1)
	# _mypprint(bytes_2)
	var t = bytes_2
	bytes_2 = bytes_1
	bytes_1 = t
	$Grid.data = bytes_1

	var t1 = Time.get_ticks_usec()
	print_debug("Time elapsed: %d us" % (t1 - t0))


func _free_if_valid(rid: RID):
	if rid.is_valid():
		RenderingServer.free_rid(rid)


func _on_step_button_pressed() -> void:
	step()


class StepData:
	var current: PackedInt32Array
	var next: PackedInt32Array
