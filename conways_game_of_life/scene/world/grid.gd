class_name Grid
extends Node2D

var width := 0
var height := 0
var cell_size := Vector2(10.0, 10.0):
	set = set_cell_size

var _data: PackedInt32Array:
	set = set_data
var _computing_step := false

@onready var compute: GridCompute = $GridGPUCompute
@onready var texrect: TextureRect = %GridRect


func _ready() -> void:
	position = Global.VIEWPORT_SIZE / 2.0
	%CellSizeSpinBox.value = cell_size.x


func _draw() -> void:
	var image = Image.create_from_data(width, height, false, Image.FORMAT_R8, compute.get_image_bytes())
	if texrect.texture and texrect.texture.get_size() == Vector2(width, height):
		texrect.texture.update(image)
	else:
		texrect.texture = ImageTexture.create_from_image(image)

	# var bytes = PackedByteArray()
	# for y in range(height):
	# 	for x in range(width):
	# 		var alive = _data[x + y * width]
	# 		bytes.push_back(0)
	# 		bytes.push_back(255 if alive else 0)
	# 		bytes.push_back(0)
	# var image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, bytes)

	# var total_size = cell_size * Vector2(width, height)
	# var o = -total_size / 2.0
	# for i in range(width):
	# 	for j in range(height):
	# 		var cell_rect = Rect2(o + cell_size * Vector2(i, j), cell_size)
	# 		var idx = i + j * width
	# 		var alive = _data.get(idx)
	# 		var color: Color
	# 		if alive:
	# 			color = Color.GREEN
	# 		else:
	# 			color = Color.BLACK
	# 		draw_rect(cell_rect, color)


func set_cell_size(value: Vector2):
	cell_size = value
	queue_redraw()


func set_data(value: PackedInt32Array):
	assert(value.size() == width * height)
	_data = value
	queue_redraw()


func global_to_cell_pos(global_pos: Vector2) -> Vector2i:
	var local_pos = to_local(global_pos)
	local_pos += cell_size * Vector2(width, height) / 2.0
	var cell_pos = Vector2i(local_pos.x / cell_size.x, local_pos.y / cell_size.y)
	return cell_pos


func has_cell(cell_pos: Vector2i) -> bool:
	var bound := Rect2i(Vector2i.ZERO, Vector2i(width, height))
	return bound.has_point(cell_pos)


func reset(new_size := Vector2i()):
	if new_size == Vector2i.ZERO:
		compute.reset(Vector2i(width, height))
		_data = compute.get_data()
	else:
		width = new_size.x
		height = new_size.y
		compute.reset(new_size)
		_data = compute.get_data()
		%GridSizeLabel.text = "Grid Size: %d x %d" % [width, height]


func generate_pattern():
	reset(Vector2i(1024, 1025))
	for y in range(1, height, 2):
		for x in range(width):
			_data[x + y * width] = 1
	queue_redraw()


func step():
	if _computing_step:
		return
	_computing_step = true
	compute.step(_step_callback)


func step_in_progress():
	return _computing_step


func _step_callback(new_data: PackedInt32Array):
	_data = new_data
	queue_redraw()
	_computing_step = false


func toggle_cell(cell_pos: Vector2i):
	if has_cell(cell_pos):
		_data[cell_pos.x + cell_pos.y * width] = 1 - _data[cell_pos.x + cell_pos.y * width]
		queue_redraw()


func set_cell(cell_pos: Vector2i, alive: bool):
	if has_cell(cell_pos):
		_data[cell_pos.x + cell_pos.y * width] = 1 if alive else 0
		queue_redraw()


func _on_cell_size_spin_box_value_changed(value: float) -> void:
	value = round(value)
	cell_size = Vector2(value, value)
