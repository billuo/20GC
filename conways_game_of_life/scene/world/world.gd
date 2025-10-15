extends Node2D

const PLAY_ICON := preload("res://asset/play-button.svg")
const PAUSE_ICON := preload("res://asset/pause-button.svg")

enum Tool {
	None,
	Pencil,
	Bucket,
}

var _playing := false:
	set = set_playing
var _last_step_start := 0.0
var _step_interval := 1000.0

var _current_tool := Tool.None:
	set = set_current_tool
var _current_mouse_cell_pos = null
var _tool_last_clicked_pos = null
var _tool_last_clicked_button = 0
var _tool_drag_start = null
var _tool_drag_last = null

@onready var grid: Grid = $Grid
@onready var next_button: Button = %NextButton
@onready var play_pause_button: Button = %PlayPauseButton
@onready var tool_buttons: Array[Button] = [
	%PencilButton,
	%BucketButton,
]


func _ready() -> void:
	grid.reset(Vector2i(32, 32))
	for button in tool_buttons:
		assert(button.toggle_mode)


func _process(_delta: float) -> void:
	if _playing:
		var now = Time.get_ticks_usec()
		if now - _last_step_start > _step_interval:
			_last_step_start = now
			grid.step()
			%GenerationLabel.text = "Generation: %d" % grid.get_generation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_current_mouse_cell_pos = grid.global_to_cell_pos(event.global_position)
		if _current_tool != Tool.None:
			if _tool_drag_last != null and _tool_drag_last != _current_mouse_cell_pos and event.button_mask & _tool_last_clicked_button:
				_tool_drag_last = _current_mouse_cell_pos
				if _tool_last_clicked_button == MOUSE_BUTTON_LEFT:
					_tool_apply_left_drag(_tool_drag_last)
				elif _tool_last_clicked_button == MOUSE_BUTTON_RIGHT:
					_tool_apply_right_drag(_tool_drag_last)

		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			grid.position += event.screen_relative

	elif event is InputEventMouseButton:
		if _current_tool != Tool.None:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_tool_last_clicked_pos = grid.global_to_cell_pos(event.global_position)
				_tool_last_clicked_button = MOUSE_BUTTON_LEFT
				_tool_drag_last = _tool_last_clicked_pos
				_tool_apply_left_click(_tool_last_clicked_pos)
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
				_tool_last_clicked_pos = grid.global_to_cell_pos(event.global_position)
				_tool_last_clicked_button = MOUSE_BUTTON_RIGHT
				_tool_drag_last = _tool_last_clicked_pos
				_tool_apply_right_click(_tool_last_clicked_pos)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			var zoom_center = Global.VIEWPORT_SIZE / 2.0
			var zoom_center_cell_pos = grid.global_to_cell_pos(zoom_center)
			grid.cell_size = minf(100.0, grid.cell_size * 1.25)
			var zoom_center_new = grid.cell_to_global_pos(zoom_center_cell_pos)
			grid.global_position += zoom_center - zoom_center_new
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			var zoom_center = Global.VIEWPORT_SIZE / 2.0
			var zoom_center_cell_pos = grid.global_to_cell_pos(zoom_center)
			grid.cell_size = maxf(1.0, grid.cell_size / 1.25)
			var zoom_center_new = grid.cell_to_global_pos(zoom_center_cell_pos)
			grid.global_position += zoom_center - zoom_center_new


func set_playing(value: bool):
	_playing = value
	if _playing:
		play_pause_button.icon = PAUSE_ICON
		play_pause_button.tooltip_text = "Pause"
		next_button.disabled = true
	else:
		play_pause_button.icon = PLAY_ICON
		play_pause_button.tooltip_text = "Play"
		next_button.disabled = false


func set_current_tool(value: Tool):
	_current_tool = value
	if _current_tool == Tool.None:
		_tool_last_clicked_pos = null
		_tool_drag_start = null
		_tool_drag_last = null


func _ensure_tool_buttons_exclusive(just_toggled: Button):
	assert(just_toggled in tool_buttons)
	if not just_toggled.button_pressed:
		return
	for button in tool_buttons:
		if button == just_toggled:
			continue
		button.button_pressed = false


func _tool_apply_left_click(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			grid.set_cell(cell_pos, true)
			if _playing:
				_playing = false


func _tool_apply_right_click(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			grid.set_cell(cell_pos, false)
			if _playing:
				_playing = false


func _tool_apply_left_drag(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			if cell_pos != _tool_drag_start:
				grid.set_cell(cell_pos, true)


func _tool_apply_right_drag(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			if cell_pos != _tool_drag_start:
				grid.set_cell(cell_pos, false)


func _on_generate_pattern_button_pressed() -> void:
	grid.generate_pattern()


func _on_next_button_pressed() -> void:
	if _playing:
		return
	grid.step()
	%GenerationLabel.text = "Generation: %d" % grid.get_generation()


func _on_play_pause_button_pressed() -> void:
	_playing = not _playing


func _on_pencil_button_toggled(toggled_on: bool) -> void:
	_ensure_tool_buttons_exclusive(%PencilButton)
	_current_tool = Tool.Pencil if toggled_on else Tool.None


func _on_bucket_button_toggled(toggled_on: bool) -> void:
	_ensure_tool_buttons_exclusive(%BucketButton)
	_current_tool = Tool.Bucket if toggled_on else Tool.None


func _on_trash_button_pressed() -> void:
	grid.reset()
	_playing = false
