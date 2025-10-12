extends Node2D

var width := 0:
	set = set_width
var height := 0:
	set = set_height
var cell_size := Vector2(20.0, 20.0):
	set = set_cell_size
var data: PackedInt32Array:
	set = set_data


func _ready() -> void:
	position = Global.VIEWPORT_SIZE / 2.0
	%WidthSpinBox.value = width
	%HeightSpinBox.value = height
	%CellSizeSpinBox.value = cell_size.x


func _draw() -> void:
	var total_size = cell_size * Vector2(width, height)
	var o = -total_size / 2
	for i in range(width):
		for j in range(height):
			var cell_rect = Rect2(o + cell_size * Vector2(i, j), cell_size)
			var idx = i + j * width
			var alive = data.get(idx)
			var color: Color
			if alive:
				color = Color.GREEN
			else:
				color = Color.BLACK
			draw_rect(cell_rect, color)


func set_width(value: int):
	width = value
	%WidthSpinBox.value = width


func set_height(value: int):
	height = value
	%HeightSpinBox.value = height


func set_cell_size(value: Vector2):
	cell_size = value
	queue_redraw()


func set_data(value: PackedInt32Array):
	assert(value.size() == width * height)
	data = value
	queue_redraw()


func _on_height_spin_box_value_changed(value: float) -> void:
	height = round(value)


func _on_width_spin_box_value_changed(value: float) -> void:
	width = round(value)


func _on_cell_size_spin_box_value_changed(value: float) -> void:
	value = round(value)
	cell_size = Vector2(value, value)
