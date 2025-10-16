class_name World
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
var _step_interval := 0.0

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
@onready var zoom_spin_box: SpinBox = %ZoomSpinBox
@onready var play_back_limit_spin_box: SpinBox = %PlaybackLimitSpinBox


func _ready() -> void:
	for button in tool_buttons:
		assert(button.toggle_mode)
	var new_popup: PopupMenu = %NewButton.get_popup()
	new_popup.id_pressed.connect(_on_new_popup_id_pressed)
	grid.size_changed.connect(func(sz): %GridSizeLabel.text = "Grid Size: %d x %d" % [sz.x, sz.y])
	grid.generation_changed.connect(func(gen): %GenerationLabel.text = "Generation: " + str(gen))
	# grid.data_changed.connect(
	# 	# OPTIMIZE:
	# 	func(data: PackedByteArray):
	# 		var n_alive = 0
	# 		for byte in data:
	# 			n_alive += int(byte != 0)
	# 		%CounterLabel.text = "Alive: " + str(n_alive)
	# )
	grid.cell_size_changed.connect(func(sz): zoom_spin_box.value = sz)
	zoom_spin_box.value_changed.connect(func(v): grid.cell_size = v)
	play_back_limit_spin_box.value_changed.connect(func(v): _step_interval = 1e6 / v)
	_step_interval = 1e6 / play_back_limit_spin_box.value
	grid.position = Global.VIEWPORT_SIZE / 2.0
	grid.reset(Vector2i(32, 32))
	grid.cell_size = 20.0
	%ToolPreview.grid = grid


func _process(_delta: float) -> void:
	if _playing:
		var now = Time.get_ticks_usec()
		if now - _last_step_start > _step_interval:
			_last_step_start = now
			grid.step()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_current_mouse_cell_pos = grid.global_to_cell_pos(get_global_mouse_position())
		if _current_tool != Tool.None:
			%ToolPreview.cell_pos = _current_mouse_cell_pos
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
			grid.zoom_at(grid.cell_size * 1.25, event.global_position)
			%ToolPreview.cell_pos = grid.global_to_cell_pos(event.global_position)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			grid.zoom_at(grid.cell_size / 1.25, event.global_position)
			%ToolPreview.cell_pos = grid.global_to_cell_pos(event.global_position)
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.is_pressed() and event.double_click:
			grid.position = Global.VIEWPORT_SIZE / 2.0

	elif event.is_action_type():
		if event.is_action(&"zoom_reset"):
			grid.position = Global.VIEWPORT_SIZE / 2.0
			grid.zoom_at(10.0, Global.VIEWPORT_SIZE / 2.0)


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
	%ToolPreview.tool = _current_tool
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


func _on_play_pause_button_pressed() -> void:
	_playing = not _playing


func _on_pencil_button_toggled(toggled_on: bool) -> void:
	_ensure_tool_buttons_exclusive(%PencilButton)
	_current_tool = Tool.Pencil if toggled_on else Tool.None


func _on_bucket_button_toggled(toggled_on: bool) -> void:
	_ensure_tool_buttons_exclusive(%BucketButton)
	_current_tool = Tool.Bucket if toggled_on else Tool.None


func _on_trash_button_pressed() -> void:
	grid.position = Global.VIEWPORT_SIZE / 2.0
	grid.reset()
	_playing = false


func _on_new_popup_id_pressed(id: int) -> void:
	grid.position = Global.VIEWPORT_SIZE / 2.0
	match id:
		0:
			grid.reset(Vector2i(32, 32))
			grid.cell_size = 20.0
		1:
			grid.reset(Vector2i(128, 128))
			grid.cell_size = 5.0
		2:
			grid.reset(Vector2i(1024, 1024))
			grid.cell_size = 1.0
		3:
			grid.reset(Vector2i(4096, 4096))
			grid.cell_size = 1.0


func _on_playback_limit_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%PlaybackLimitCheckBox.self_modulate = Color.WHITE
		play_back_limit_spin_box.editable = true
		_step_interval = 1e6 / play_back_limit_spin_box.value
	else:
		%PlaybackLimitCheckBox.self_modulate = Color.DARK_GRAY
		play_back_limit_spin_box.editable = false
		_step_interval = 0.0


func _on_randomize_button_pressed() -> void:
	grid.position = Global.VIEWPORT_SIZE / 2.0
	grid.randomize(0.5)
