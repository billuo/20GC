extends Node2D

const GAME_SCENE := preload("res://scene/game/game.tscn")


func _ready() -> void:
	%Start.grab_focus.call_deferred()
	rand_from_seed(int(Time.get_unix_time_from_system() * 1000.0))


func _on_start_pressed() -> void:
	GameOptions.mode = {
		0: GameOptions.Mode.SinglePlayer,
		1: GameOptions.Mode.TwoPlayers,
		2: GameOptions.Mode.NoPlayer,
	}[%NPlayers.selected]
	GameOptions.ai_difficulty = {
		0: GameOptions.AIDifficulty.Drunk,
		1: GameOptions.AIDifficulty.Normal,
		2: GameOptions.AIDifficulty.Veteran,
		3: GameOptions.AIDifficulty.Godlike,
	}[%AIDifficulty.selected]
	print_debug("mode: %s" % GameOptions.mode)
	print_debug("difficulty: %s" % GameOptions.ai_difficulty)
	get_tree().change_scene_to_packed(GAME_SCENE)
