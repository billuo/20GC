extends Node2D

var rd: RenderingDevice
var shader: RID
var buffer: RID
var uniform_set: RID
var pipeline: RID


func _ready() -> void:
	rd = RenderingServer.create_local_rendering_device()
	var shader_file: RDShaderFile = load("res://test/compute_shader/compute_shader_test.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)


func update_input(input: PackedFloat32Array):
	if input.is_empty():
		push_error("input is empty")
		return
	var t0 = Time.get_ticks_usec()
	var input_bytes := input.to_byte_array()
	_free_if_valid(buffer)
	buffer = rd.storage_buffer_create(input_bytes.size(), input_bytes)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	# this needs to match the "binding" in our shader file
	uniform.binding = 0
	uniform.add_id(buffer)
	# the last parameter (the 0) needs to match the "set" in our shader file
	_free_if_valid(uniform_set)
	uniform_set = rd.uniform_set_create([uniform], shader, 0)

	_free_if_valid(pipeline)
	pipeline = rd.compute_pipeline_create(shader)
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, input.size(), 1, 1)
	rd.compute_list_end()
	var t1 = Time.get_ticks_usec()
	print_debug("Ticks: %d us" % (t1 - t0))
	print_debug("Input: ", input)


func execute():
	var t0 = Time.get_ticks_usec()
	rd.submit()
	rd.sync()
	var t1 = Time.get_ticks_usec()
	if buffer.is_valid():
		var output_bytes := rd.buffer_get_data(buffer)
		var output := output_bytes.to_float32_array()
		print_debug("Ticks: %d us" % (t1 - t0))
		print_debug("Output: ", output)


func _free_if_valid(rid: RID):
	if rid.is_valid():
		RenderingServer.free_rid(rid)


func _on_update_input() -> void:
	var array = PackedFloat32Array()
	for i in range(%SpinBox.value):
		array.push_back(i)
	update_input(array)


func _on_execute_pressed() -> void:
	execute()
