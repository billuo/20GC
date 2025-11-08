class_name Grid
extends Sprite2D

signal size_changed(size: Vector2i)
signal cell_size_changed(size: float)
signal generation_changed(gen: int)
signal compute_method_changed(node)

enum ComputeMethod {
	Auto,
	GPU,
	CPU,
}

const TOTAL_TIME_MAX_SAMPLES := 100

@export var compute_method = ComputeMethod.Auto:
	set(value):
		compute_method = value
		if is_node_ready():
			_resolve_compute()

var size: Vector2i
var cell_size := 1.0:
	set = set_cell_size
var force_multithread := false:
	set(value):
		force_multithread = value
		if _compute is GridCompute:
			_compute.parallel = value
			print_debug(_compute.parallel)
var _generation := 0:
	set = _set_generation
var _b_mask := 0
var _s_mask := 0
var _compute
var _total_time_samples: Array[float] = []
var _image: Image


func _ready() -> void:
	$GridCompute.auto_parallel = true
	_resolve_compute()


func _process(_delta: float) -> void:
	if scale.x < 1.0:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_cell_size(value: float):
	cell_size = clampf(value, 0.1, 100.0)
	scale = Vector2.ONE * cell_size
	cell_size_changed.emit(cell_size)


func set_rules(b_mask: int, s_mask: int):
	_b_mask = b_mask
	_s_mask = s_mask


func global_to_cell_pos(global_pos: Vector2) -> Vector2i:
	var local_pos = to_local(global_pos)
	local_pos += Vector2(size) / 2.0
	return Vector2i(local_pos)


func cell_to_global_pos(cell_pos: Vector2i) -> Vector2:
	var local_pos = Vector2(cell_pos)
	local_pos -= Vector2(size) / 2.0
	return to_global(local_pos)


func has_cell(cell_pos: Vector2i) -> bool:
	var bound := Rect2i(Vector2i.ZERO, size)
	return bound.has_point(cell_pos)


func get_generation() -> int:
	return _generation


func get_population() -> int:
	return _compute.get_population()


func zoom_at(new_cell_size: float, center: Vector2):
	var center_cell_pos = global_to_cell_pos(center)
	cell_size = new_cell_size
	var center_new = cell_to_global_pos(center_cell_pos)
	global_position += center - center_new


func reset(new_size := Vector2i()):
	if new_size == Vector2i.ZERO:
		_compute.reset(size)
	else:
		size = new_size
		_compute.reset(size)
		size_changed.emit(size)
	_update_image()
	_generation = 0


func set_data(new_size: Vector2i, new_data: PackedByteArray):
	assert(new_size.x * new_size.y == new_data.size())
	size = new_size
	_compute.reset(new_size)
	size_changed.emit(size)
	_compute.set_data(new_data)
	_update_image()
	_generation = 0


func generate_pattern():
	for y in range(size.y):
		for x in range(size.x):
			_compute.set_cell(Vector2i(x, y), y % 2 == 0)
	_update_image()


func step():
	var t0 = Time.get_ticks_usec()
	_compute.step(_b_mask, _s_mask)
	_generation += 1
	# var t1 = Time.get_ticks_usec()
	_update_image()
	var t2 = Time.get_ticks_usec()
	# var step_time = t1 - t0
	# var image_time = t2 - t1
	var total_time = t2 - t0
	if _total_time_samples.size() >= TOTAL_TIME_MAX_SAMPLES:
		_total_time_samples.remove_at(0)
	_total_time_samples.push_back(total_time)
	var sum = 0.0
	for t in _total_time_samples:
		sum += t
	var avg = sum / _total_time_samples.size()
	if Engine.get_process_frames() % 30 == 0:
		# TODO:
		print_debug("%dus ~ %.1f/s" % [avg, 1e6 / avg])


func randomize(alive_ratio: float):
	_compute.randomize(alive_ratio)
	_update_image()


func toggle_cell(cell_pos: Vector2i):
	if has_cell(cell_pos):
		var current: int = _compute.get_cell(cell_pos)
		if current == 0:
			_compute.set_cell(cell_pos, 1)
		else:
			_compute.set_cell(cell_pos, 0)
		_update_image()


func set_cell(cell_pos: Vector2i, alive: bool):
	if has_cell(cell_pos):
		_compute.set_cell(cell_pos, alive)
		_update_image()


func save_image():
	if not texture:
		push_error("no image yet")
		return
	var save_dir := OS.get_user_data_dir()
	var d = Time.get_datetime_dict_from_system()
	var timestamp = "%04d%02d%02d-%02d%02d%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"]]
	var make_filename := func(i) -> String:
		if i == 0:
			return "grid-" + timestamp + ".png"
		else:
			return "grid-" + timestamp + "-" + str(i) + ".png"
	var id = 0
	var path = save_dir.path_join(make_filename.call(id))
	while FileAccess.file_exists(path):
		id += 1
		path = save_dir.path_join(make_filename.call(id))
	var image = (texture as ImageTexture).get_image()
	image.save_png(path)
	print("Image saved to ", path)


func _resolve_compute():
	# FIXME: not properly initialized and data transferred if switch at runtime
	var renderer = ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")
	match renderer:
		"forward_plus":
			match compute_method:
				ComputeMethod.Auto, ComputeMethod.GPU:
					_compute = $GridGPUCompute
				ComputeMethod.CPU:
					_compute = $GridCompute
		"mobile":
			match compute_method:
				ComputeMethod.GPU:
					_compute = $GridGPUCompute
				ComputeMethod.Auto, ComputeMethod.CPU:
					_compute = $GridCompute
		"gl_compatibility":
			if compute_method == ComputeMethod.GPU:
				push_error("GPU compute unsupported by compatibility renderer")
			_compute = $GridCompute
		_:
			push_error("unknown renderer: %s" % renderer)
			_compute = $GridCompute
	print("Using %s compute" % ("CPU" if _compute is GridCompute else "GPU"))
	compute_method_changed.emit(_compute)


func _set_generation(value: int):
	_generation = value
	generation_changed.emit(_generation)


func _update_image():
	var image_bytes = _compute.render_image()
	_image = Image.create_from_data(size.x, size.y, false, Image.FORMAT_R8, image_bytes)
	if texture and texture.get_size() == Vector2(size):
		texture.update(_image)
	else:
		texture = ImageTexture.create_from_image(_image)
