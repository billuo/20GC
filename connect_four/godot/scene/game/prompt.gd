class_name Prompt
extends Node2D

@export var screen: Screen

var color: Color:
	set = set_color

@onready var top_sprite: Sprite2D = $TopSprite2D
@onready var preview_sprite: Sprite2D = $PreviewSprite2D


func set_color(value: Color):
	color = value
	top_sprite.self_modulate = color
	preview_sprite.self_modulate = color
	preview_sprite.self_modulate.a = 0.5


func force_update(mouse_pos := get_global_mouse_position()):
	var hole_pos = screen.get_nearest_hole(mouse_pos)
	_update_position(hole_pos.x)


func _update_position(col: int):
	var hole_pos = Vector2i(col, 0)
	var hole_center = screen.get_hole_center_local(hole_pos)
	global_position = screen.global_position + hole_center - Vector2(0.0, 100.0)
	var n_filled = screen.get_n_filled(col)
	if n_filled != Screen.SIZE.y:
		preview_sprite.show()
		preview_sprite.position.y = Screen.HOLE_SIZE.y * (Screen.SIZE.y - n_filled)
	else:
		preview_sprite.hide()
