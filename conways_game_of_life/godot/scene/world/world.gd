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
var _fast_forward := 0

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
@onready var fast_forward_spin_box: SpinBox = %FastForwardSpinBox
@onready var rule_editor: RuleEditor = %RuleEditor


func _ready() -> void:
	for button in tool_buttons:
		assert(button.toggle_mode)
	var new_popup: PopupMenu = %NewButton.get_popup()
	new_popup.id_pressed.connect(_on_new_popup_id_pressed)
	grid.size_changed.connect(func(sz): %GridSizeLabel.text = "Grid Size: %d x %d" % [sz.x, sz.y])
	grid.generation_changed.connect(func(gen): %GenerationLabel.text = "Generation: " + str(gen))
	grid.cell_size_changed.connect(func(sz): zoom_spin_box.value = sz)
	zoom_spin_box.value_changed.connect(func(v): grid.cell_size = v)
	play_back_limit_spin_box.value_changed.connect(func(v): _step_interval = 1e6 / v)
	fast_forward_spin_box.value_changed.connect(func(v): _fast_forward = v)

	_step_interval = 1e6 / play_back_limit_spin_box.value
	grid.position = Global.VIEWPORT_SIZE / 2.0
	grid.reset(Vector2i(50, 50))
	grid.cell_size = 20.0
	%ToolPreview.grid = grid
	%MTCheckButton.toggled.connect(func(v): grid.force_multithread = v)
	%GridSizeLabel.gui_input.connect(
		func(e: InputEvent):
			if e is InputEventMouseButton and e.is_pressed() and e.double_click:
				grid.grow(10)
	)

	grid.set_rules(rule_editor.b_mask, rule_editor.s_mask)
	rule_editor.rules_changed.connect(func(): grid.set_rules(rule_editor.b_mask, rule_editor.s_mask))

	var dst = PackedByteArray([0])
	dst = GridUtil.blit_rect(PackedByteArray([1]), Vector2i.ONE, Rect2i(Vector2i.ZERO, Vector2i.ONE), dst, Vector2i.ONE, Vector2i.ZERO)
	print(dst)


func _process(_delta: float) -> void:
	if _playing:
		if _fast_forward > 1:
			for i in range(_fast_forward):
				grid.step()
			_update_population()
		else:
			var now = Time.get_ticks_usec()
			if now - _last_step_start > _step_interval:
				_last_step_start = now
				grid.step()
				_update_population()


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
			var sz = grid.cell_size
			if sz < 1.0:
				sz += 0.1
			elif sz < 10:
				sz += 1
			else:
				sz += 2
			grid.zoom_at(sz, event.global_position)
			%ToolPreview.cell_pos = grid.global_to_cell_pos(event.global_position)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			var sz = grid.cell_size
			if sz <= 1.0:
				sz -= 0.1
			elif sz <= 10:
				sz -= 1
			else:
				sz -= 2
			grid.zoom_at(sz, event.global_position)
			%ToolPreview.cell_pos = grid.global_to_cell_pos(event.global_position)
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.is_pressed() and event.double_click:
			grid.position = Global.VIEWPORT_SIZE / 2.0

	elif event.is_action_type():
		if event.is_action_pressed(&"zoom_reset"):
			grid.position = Global.VIEWPORT_SIZE / 2.0
			grid.zoom_at(10.0, Global.VIEWPORT_SIZE / 2.0)
		elif event.is_action_pressed(&"save_grid_image"):
			grid.save_image()


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


func _update_population():
	%CounterLabel.text = "Population: " + str(grid.get_population())


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
	_update_population()


func _tool_apply_right_click(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			grid.set_cell(cell_pos, false)
			if _playing:
				_playing = false
	_update_population()


func _tool_apply_left_drag(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			if cell_pos != _tool_drag_start:
				grid.set_cell(cell_pos, true)
	_update_population()


func _tool_apply_right_drag(cell_pos: Vector2i):
	if not grid.has_cell(cell_pos):
		return
	match _current_tool:
		Tool.Pencil:
			if cell_pos != _tool_drag_start:
				grid.set_cell(cell_pos, false)
	_update_population()


func _on_generate_pattern_button_pressed() -> void:
	grid.generate_pattern()
	_update_population()


func _on_next_button_pressed() -> void:
	if _playing:
		return
	grid.step()
	_update_population()


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
	_update_population()
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
	_update_population()


func _on_playback_limit_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%FastForwardCheckBox.button_pressed = false
		%PlaybackLimitCheckBox.self_modulate = Color.WHITE
		play_back_limit_spin_box.editable = true
		_step_interval = 1e6 / play_back_limit_spin_box.value
	else:
		%PlaybackLimitCheckBox.self_modulate = Color(0.5, 0.5, 0.5)
		play_back_limit_spin_box.editable = false
		_step_interval = 0.0


func _on_fast_forward_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%PlaybackLimitCheckBox.button_pressed = false
		%FastForwardCheckBox.self_modulate = Color.WHITE
		fast_forward_spin_box.editable = true
		_fast_forward = int(fast_forward_spin_box.value)
	else:
		%FastForwardCheckBox.self_modulate = Color(0.5, 0.5, 0.5)
		fast_forward_spin_box.editable = false
		_fast_forward = 1


func _on_randomize_button_pressed() -> void:
	grid.position = Global.VIEWPORT_SIZE / 2.0
	grid.randomize(%RandomizeSpinBox.value)
	_update_population()


func _on_grid_compute_method_changed(node: Variant) -> void:
	(%MTCheckButton.get_parent() as Control).visible = node is GridCompute


func _on_load_button_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.rle", "*.cell"])
	dialog.file_selected.connect(func(path): _on_load_parsed_pattern(GridUtil.parse_file(path)))
	add_child(dialog)
	dialog.popup_centered()


func _on_load_parsed_pattern(pattern: ParsedPattern):
	if not pattern:
		return
	rule_editor.apply_rule_string(pattern.rule)
	grid.set_data(pattern.size, pattern.bytes)
	var s = ""
	for y in range(pattern.size.y):
		if not s.is_empty():
			s += "\n"
		for x in range(pattern.size.x):
			var idx = x + y * pattern.size.x
			s += "O" if pattern.bytes[idx] == 1 else "."
	print("size:%s" % pattern.size)
	print("rule:%s" % pattern.rule)
	print(s)
