extends Control

# TODO: more levels and level select


func _ready() -> void:
	%StartButton.pressed.connect(Game.switch_to_level)
