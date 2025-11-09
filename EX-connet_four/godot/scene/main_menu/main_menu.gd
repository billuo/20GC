extends Node2D

const GAME_SCENE := preload("res://scene/game/game.tscn")


func _on_two_players_pressed() -> void:
	GameOptions.mode = GameOptions.Mode.TwoPlayers
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_single_player_pressed() -> void:
	GameOptions.mode = GameOptions.Mode.SinglePlayer
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_no_player_pressed() -> void:
	GameOptions.mode = GameOptions.Mode.NoPlayer
	get_tree().change_scene_to_packed(GAME_SCENE)
