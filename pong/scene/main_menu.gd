extends Node2D

@onready var title := %Title
@onready var prompt := %Prompt
@onready var settings := %Settings
@onready var settings_window := %SettingsWindow
@onready var mode_selects := %ModeSelects
@onready var game_over_settings := %GameOverSettings
@onready var bo_slider := %BOSlider
@onready var bo_label := %BOLabel

enum State {
	Prompt,
	ModeSelect,  # PvP or PvE or EvE
}
var _state: State:
	set = set_state


func _ready() -> void:
	_state = State.Prompt
	_on_bo_slider_value_changed(bo_slider.value)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	assert(event is InputEventKey)
	event = event as InputEventKey
	if event.keycode == KEY_ESCAPE:
		match _state:
			State.Prompt:
				get_tree().quit()
			State.ModeSelect:
				_state = State.Prompt
	else:
		match _state:
			State.Prompt:
				_state = State.ModeSelect
			_:
				pass


func set_state(value: State):
	_state = value
	match _state:
		State.Prompt:
			title.show()
			prompt.show()
			settings.hide()
			game_over_settings.hide()
			mode_selects.hide()
		State.ModeSelect:
			title.show()
			prompt.hide()
			settings.show()
			game_over_settings.show()
			mode_selects.show()


func _on_settings_pressed() -> void:
	settings_window.popup_centered()


func _on_mode_pve_pressed() -> void:
	Game.arena_config.left_control = Paddle.Controller.Player1
	Game.arena_config.right_control = Paddle.Controller.Ai
	Game.new_game()


func _on_mode_pvp_pressed() -> void:
	Game.arena_config.left_control = Paddle.Controller.Player1
	Game.arena_config.right_control = Paddle.Controller.Player2
	Game.new_game()


func _on_mode_eve_pressed() -> void:
	Game.arena_config.left_control = Paddle.Controller.Ai
	Game.arena_config.right_control = Paddle.Controller.Ai
	Game.new_game()


func _on_bo_slider_value_changed(value: float) -> void:
	if value == bo_slider.max_value:
		bo_label.text = "Target Score: Infinite"
		Game.arena_config.target_score = -1
	else:
		bo_label.text = "Target Score: %d" % value
		Game.arena_config.target_score = value
