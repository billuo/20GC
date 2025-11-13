class_name HintCircle
extends Sprite2D

const FONT := preload("res://asset/fonts/ZhiyiMaru-Regular.ttf")
const FONT_SIZE := 24

@export var score := 0:
	set(value):
		score = value
		queue_redraw()
@export var winning := false:
	set(value):
		winning = value
		queue_redraw()
@export var forced := false:
	set(value):
		forced = value
		queue_redraw()


func _draw() -> void:
	# modulate circle
	if winning:
		self_modulate = Color.ORANGE
	elif forced:
		self_modulate = Color.PURPLE
	elif score < 0:
		self_modulate = Color.RED
	elif score > 0:
		self_modulate = Color.GREEN
	else:
		self_modulate = Color.BLUE
	# draw score
	if not winning and not forced:
		var _modulate = Color.WHITE
		if score < 0:
			_modulate = Color.RED
		if score > 0:
			_modulate = Color.GREEN
		var s = str(score)
		var size = FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
		var pos = 0.5 * Vector2(-size.x, FONT.get_ascent(FONT_SIZE) - FONT.get_descent(FONT_SIZE))
		draw_string(FONT, pos, s, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, _modulate)
		# draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
