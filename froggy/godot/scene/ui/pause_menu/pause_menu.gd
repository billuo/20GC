extends Control

var on_restart: Callable
var on_exit: Callable


func _ready() -> void:
	$TestBackground.hide()


func _enter_tree() -> void:
	get_tree().paused = true


func _exit_tree() -> void:
	get_tree().paused = false


func _on_button_resume_pressed() -> void:
	hide()
	queue_free()


func _on_button_restart_pressed() -> void:
	if on_restart:
		on_restart.call()


func _on_button_exit_pressed() -> void:
	if on_exit:
		on_exit.call()
