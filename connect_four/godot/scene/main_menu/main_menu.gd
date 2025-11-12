extends Node2D

const GAME_SCENE := preload("res://scene/game/game.tscn")


func _ready() -> void:
	%Start.grab_focus.call_deferred()
	rand_from_seed(int(Time.get_unix_time_from_system() * 1000.0))
	var state = MainMenuState.load_from_fs()
	if state:
		%NPlayers.select(state.n_players_selected_index)
		%AIDifficulty1.select(state.ai_difficulty_1_selected_index)
		%AIDifficulty2.select(state.ai_difficulty_2_selected_index)


func _exit_tree() -> void:
	var state = MainMenuState.new()
	state.n_players_selected_index = %NPlayers.selected
	state.ai_difficulty_1_selected_index = %AIDifficulty1.selected
	state.ai_difficulty_2_selected_index = %AIDifficulty2.selected
	MainMenuState.save_to_fs(state)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		AppController.request_exit()
		return


func _on_start_pressed() -> void:
	GameOptions.mode = {
		0: GameOptions.Mode.SinglePlayer,
		1: GameOptions.Mode.TwoPlayers,
		2: GameOptions.Mode.NoPlayer,
	}[%NPlayers.selected]
	GameOptions.ai_difficulty_1 = {
		0: GameOptions.AIDifficulty.Drunk,
		1: GameOptions.AIDifficulty.Normal,
		2: GameOptions.AIDifficulty.Veteran,
		3: GameOptions.AIDifficulty.Godlike,
	}[%AIDifficulty1.selected]
	GameOptions.ai_difficulty_2 = {
		0: GameOptions.AIDifficulty.Drunk,
		1: GameOptions.AIDifficulty.Normal,
		2: GameOptions.AIDifficulty.Veteran,
		3: GameOptions.AIDifficulty.Godlike,
	}[%AIDifficulty2.selected]
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_n_players_item_selected(index: int) -> void:
	match index:
		0:
			%AIDifficulty1.show()
			%AIDifficulty2.hide()
		1:
			%AIDifficulty1.hide()
			%AIDifficulty2.hide()
		2:
			%AIDifficulty1.show()
			%AIDifficulty2.show()
