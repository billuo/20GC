extends Control

const GAME_SCENE := preload("res://scene/stage/stage.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(GAME_SCENE)
