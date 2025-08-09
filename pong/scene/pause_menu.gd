extends Control


func _ready() -> void:
	$TestBackground.hide()


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	get_tree().paused = false


func _on_button_resume_pressed() -> void:
	hide()
	queue_free()


func _on_button_restart_pressed() -> void:
	Game.new_game()


func _on_button_exit_pressed() -> void:
	Game.main_menu()
