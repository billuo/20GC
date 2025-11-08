class_name GridGPUCompute
extends Node

var size: Vector2i
var data_1: PackedByteArray
var data_2: PackedByteArray
var image_bytes: PackedByteArray
var population := 0
var rd: RenderingDevice
var step_shader: RID
var ubo: RID
var sbo1: RID
var sbo2: RID
var sbo3: RID
var pipeline: RID


func _enter_tree() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		push_error("Failed to create rendering device")
		queue_free()
		return

	step_shader = rd.shader_create_from_spirv(preload("res://scene/world/gol.glsl").get_spirv())


func _exit_tree() -> void:
	_free_if_valid(step_shader)
	rd.free()


func set_data(new_data: PackedByteArray):
	data_1 = new_data


func reset(new_size: Vector2i):
	size = new_size
	data_1.clear()
	data_1.resize(new_size.x * new_size.y)
	data_2.resize(size.x * size.y)
	image_bytes.clear()
	image_bytes.resize(size.x * size.y)
	population = 0


func render_image() -> PackedByteArray:
	return GridUtil.render_image(data_1)


func get_population() -> int:
	return population


func get_cell(cell_pos: Vector2i) -> int:
	return data_1[cell_pos.x + cell_pos.y * size.x]


func set_cell(cell_pos: Vector2i, byte: int):
	var cur := get_cell(cell_pos)
	data_1[cell_pos.x + cell_pos.y * size.x] = byte
	var was_alive := cur != 0
	var now_alive := byte != 0
	if was_alive != now_alive:
		if now_alive:
			population += 1
		else:
			population -= 1


func step(b_mask: int, s_mask: int):
	# upload data
	_free_if_valid(ubo)
	ubo = rd.uniform_buffer_create(16, PackedInt32Array([size.x, size.y, b_mask, s_mask]).to_byte_array())
	var u_uniforms := RDUniform.new()
	u_uniforms.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_uniforms.binding = 0
	u_uniforms.add_id(ubo)

	# FIXME: what if PackedByteArray size is not multiples of 4?
	_free_if_valid(sbo1)
	sbo1 = rd.storage_buffer_create(data_1.size(), data_1)
	var u_cur := RDUniform.new()
	u_cur.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_cur.binding = 1
	u_cur.add_id(sbo1)

	_free_if_valid(sbo2)
	sbo2 = rd.storage_buffer_create(data_2.size(), data_2)
	var u_next := RDUniform.new()
	u_next.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_next.binding = 2
	u_next.add_id(sbo2)

	_free_if_valid(sbo3)
	var stats := PackedInt32Array()
	stats.push_back(0)
	var stats_bytes = stats.to_byte_array()
	sbo3 = rd.storage_buffer_create(stats_bytes.size(), stats_bytes)
	var u_stats := RDUniform.new()
	u_stats.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_stats.binding = 3
	u_stats.add_id(sbo3)

	var uniform_set = rd.uniform_set_create([u_uniforms, u_cur, u_next, u_stats], step_shader, 0)

	# setup pipeline
	_free_if_valid(pipeline)
	pipeline = rd.compute_pipeline_create(step_shader)
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, int(ceilf(size.x / 32.0)), int(ceilf(size.y / 32.0)), 1)
	rd.compute_list_end()

	# compute and free memory
	rd.submit()
	rd.sync()
	data_2 = data_1
	data_1 = rd.buffer_get_data(sbo2)
	population = rd.buffer_get_data(sbo3).to_int32_array()[0]
	RenderingServer.free_rid(uniform_set)


func randomize(alive_ratio: float):
	var d = GridUtil.randomize(data_1, alive_ratio)
	data_1 = d["data"]
	population = d["population"]


func _free_if_valid(rid: RID):
	if rid.is_valid():
		rd.free_rid(rid)


func _mypprint(a: PackedByteArray):
	var s = ""
	for y in range(size.y):
		for x in range(size.x):
			s += str(a[x + y * size.x])
		s += "\n"
	print(s)
