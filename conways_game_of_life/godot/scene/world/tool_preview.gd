extends Node2D

var grid: Grid
var tool := World.Tool.None:
	set = set_tool
var cell_pos: Vector2i:
	set = set_cell_pos


func _draw() -> void:
	match tool:
		World.Tool.Pencil:
			if grid.cell_size <= 2.0:
				return
			if not grid.has_cell(cell_pos):
				return
			var rect = Rect2(Vector2(cell_pos) - Vector2(grid.size) / 2.0, Vector2.ONE)
			rect.position *= grid.cell_size
			rect.position += grid.position
			rect.size *= grid.cell_size
			draw_rect(rect, Color.YELLOW, false, -2.0)


func set_tool(value: World.Tool):
	tool = value
	queue_redraw()


func set_cell_pos(value: Vector2i):
	cell_pos = value
	queue_redraw()
