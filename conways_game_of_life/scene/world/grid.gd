class_name Grid
extends Node2D

var width := 0
var height := 0
var cell_size := 1.0:
	set = set_cell_size

var _data: PackedByteArray:
	set = set_data
var _generation := 0

@onready var compute: GridCompute = $GridGPUCompute
@onready var texrect: TextureRect = %GridRect


func _ready() -> void:
	position = Global.VIEWPORT_SIZE / 2.0


func _draw() -> void:
	# FIXME: needs to compute beforehand???
	var image = Image.create_from_data(width, height, false, Image.FORMAT_R8, compute.get_image_bytes())
	if texrect.texture and texrect.texture.get_size() == Vector2(width, height):
		texrect.texture.update(image)
	else:
		texrect.texture = ImageTexture.create_from_image(image)


func set_cell_size(value: float):
	cell_size = value
	texrect.scale = Vector2.ONE * cell_size
	if texrect.texture:
		var size = texrect.texture.get_size() * cell_size
		texrect.position = -size / 2.0


func set_data(value: PackedByteArray):
	assert(value.size() == width * height)
	_data = value
	queue_redraw()


func global_to_cell_pos(global_pos: Vector2) -> Vector2i:
	var local_pos = to_local(global_pos)
	local_pos += cell_size * Vector2(width, height) / 2.0
	return local_pos / cell_size


func cell_to_global_pos(cell_pos: Vector2i) -> Vector2:
	var local_pos = cell_pos * cell_size
	local_pos -= cell_size * Vector2(width, height) / 2.0
	return to_global(local_pos)


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
	_generation = 0


func generate_pattern():
	const N = 1000
	reset(Vector2i(N, N + 1))
	for y in range(1, height, 2):
		for x in range(width):
			_data[x + y * width] = 1
	# FIXME: image not updated
	queue_redraw()


func step():
	_data = compute.step()
	_generation += 1


func get_generation() -> int:
	return _generation


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
	cell_size = int(value)
