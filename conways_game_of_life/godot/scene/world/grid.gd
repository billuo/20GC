class_name Grid
extends Sprite2D

signal size_changed(size: Vector2i)
signal cell_size_changed(size: float)
signal data_changed(data: PackedByteArray)
signal generation_changed(gen: int)

var size: Vector2i
var cell_size := 1.0:
	set = set_cell_size
var _data: PackedByteArray:
	set = _set_data
var _generation := 0:
	set = _set_generation

@onready var compute: GridCompute = $GridGPUCompute


func _draw() -> void:
	_update_image()


func set_cell_size(value: float):
	cell_size = clampf(value, 0.1, 100.0)
	scale = Vector2.ONE * cell_size
	cell_size_changed.emit(cell_size)


func _set_data(value: PackedByteArray):
	assert(value.size() == size.x * size.y)
	_data = value
	data_changed.emit(_data)
	queue_redraw()


func _set_generation(value: int):
	_generation = value
	generation_changed.emit(_generation)


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


func get_n_alive() -> int:
	var ret = 0
	for y in range(size.y):
		for x in range(size.x):
			ret += int(_data[x + y * size.x] != 0)
	return ret


func zoom_at(new_cell_size: float, center: Vector2):
	var center_cell_pos = global_to_cell_pos(center)
	cell_size = new_cell_size
	var center_new = cell_to_global_pos(center_cell_pos)
	global_position += center - center_new


func reset(new_size := Vector2i()):
	if new_size == Vector2i.ZERO:
		compute.reset(size)
		_data = compute.get_data()
	else:
		size = new_size
		compute.reset(size)
		_data = compute.get_data()
		size_changed.emit(size)
	_update_image()
	_generation = 0


func generate_pattern():
	for y in range(1, size.y, 2):
		for x in range(size.x):
			_data[x + y * size.x] = 1
	queue_redraw()


func step():
	_data = compute.step()
	_generation += 1

func randomize(alive_ratio: float):
	for i in range(_data.size()):
		_data[i] = int(randf_range(0.0, 1.0) < alive_ratio)

func toggle_cell(cell_pos: Vector2i):
	if has_cell(cell_pos):
		_data[cell_pos.x + cell_pos.y * size.x] = 1 - _data[cell_pos.x + cell_pos.y * size.x]
		queue_redraw()


func set_cell(cell_pos: Vector2i, alive: bool):
	if has_cell(cell_pos):
		_data[cell_pos.x + cell_pos.y * size.x] = 1 if alive else 0
		queue_redraw()


func _update_image():
	var image = Image.create_from_data(size.x, size.y, false, Image.FORMAT_R8, compute.get_image_bytes())
	if texture and texture.get_size() == Vector2(size):
		texture.update(image)
	else:
		texture = ImageTexture.create_from_image(image)
