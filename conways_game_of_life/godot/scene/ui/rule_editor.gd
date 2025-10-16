class_name RuleEditor
extends VBoxContainer

signal rules_changed

const DEFAULT_RULE_STRING := "B3/S23"

var b_mask := 0
var s_mask := 0

@onready var line_edit: LineEdit = %RuleStringLineEdit
@onready var b_buttons := $BGridContainer.get_children()
@onready var s_buttons := $SGridContainer.get_children()


func _ready() -> void:
	assert(b_buttons.size() == 9)
	assert(s_buttons.size() == 9)
	# B signals
	for button in b_buttons:
		# just ignore the argument; it's easier to simply rebuild everything
		(button as Button).toggled.connect(func(_v): _rebuild_based_on_buttons())
	$BButtons/NoneButton.pressed.connect(
		func():
			for button in b_buttons:
				(button as Button).button_pressed = false
			_rebuild_based_on_buttons()
	)
	$BButtons/AllButton.pressed.connect(
		func():
			for button in b_buttons:
				(button as Button).button_pressed = true
			_rebuild_based_on_buttons()
	)
	$BButtons/InvertButton.pressed.connect(
		func():
			for button in b_buttons:
				(button as Button).button_pressed = not (button as Button).button_pressed
			_rebuild_based_on_buttons()
	)
	# S signals
	for button in s_buttons:
		(button as Button).toggled.connect(func(_v): _rebuild_based_on_buttons())
	$SButtons/NoneButton.pressed.connect(
		func():
			for button in s_buttons:
				(button as Button).button_pressed = false
			_rebuild_based_on_buttons()
	)
	$SButtons/AllButton.pressed.connect(
		func():
			for button in s_buttons:
				(button as Button).button_pressed = true
			_rebuild_based_on_buttons()
	)
	$SButtons/InvertButton.pressed.connect(
		func():
			for button in s_buttons:
				(button as Button).button_pressed = not (button as Button).button_pressed
			_rebuild_based_on_buttons()
	)

	line_edit.text = DEFAULT_RULE_STRING
	_on_line_edit_text_changed(DEFAULT_RULE_STRING)


func _on_line_edit_text_changed(new_text: String) -> void:
	var rules: PackedByteArray = GridCPUCompute.parse_rule_string(new_text)
	if rules.is_empty():
		# invalid string, do nothing
		return
	var b_read := false
	b_mask = 0x00
	s_mask = 0x00
	for byte in rules:
		if byte == 255:
			b_read = true
			continue
		if b_read:
			s_mask |= 0x01 << byte
		else:
			b_mask |= 0x01 << byte
	for i in range(9):
		var button: Button = b_buttons[i]
		var pressed = b_mask & (0x01 << i) != 0
		button.set_pressed_no_signal(pressed)
	for i in range(9):
		var button: Button = s_buttons[i]
		var pressed = s_mask & (0x01 << i) != 0
		button.set_pressed_no_signal(pressed)
	rules_changed.emit()


func _rebuild_based_on_buttons():
	b_mask = 0x00
	s_mask = 0x00
	var s = "B"
	for i in range(9):
		if (b_buttons[i] as Button).button_pressed:
			s += str(i)
			b_mask |= 0x01 << i
	s += "/S"
	for i in range(9):
		if (s_buttons[i] as Button).button_pressed:
			s += str(i)
			s_mask |= 0x01 << i
	line_edit.text = s
	rules_changed.emit()


func _on_rule_string_line_edit_focus_exited() -> void:
	if GridCPUCompute.parse_rule_string(line_edit.text).is_empty():
		_rebuild_based_on_buttons()
