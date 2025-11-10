class_name HintCircle
extends Sprite2D

const FONT := preload("res://asset/ZhiyiMaru-Regular.ttf")

var score = null:
	set(value):
		score = value
		queue_redraw()


func _draw() -> void:
	if score is int:
		var _modulate = Color.WHITE
		if score < 0:
			_modulate = Color.RED
		if score > 0:
			_modulate = Color.GREEN
		var s = str(score)
		var size = FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)
		var pos = Vector2(-size.x / 2, size.y / 2)
		draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, _modulate)
