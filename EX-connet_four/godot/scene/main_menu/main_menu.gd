extends Node2D

const GAME_SCENE := preload("res://scene/game/game.tscn")


func _on_two_players_pressed() -> void:
	GameOptions.single_player = false
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_single_player_pressed() -> void:
	GameOptions.single_player = true
	get_tree().change_scene_to_packed(GAME_SCENE)
