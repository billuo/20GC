extends Label

const MAX_N_DOTS := 3

var n_dots := 0:
	set(value):
		if n_dots != value:
			text = "Thinking" + ".".repeat(value)
		n_dots = value

@onready var _tween_n_dots: Tween


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed():
	if visible:
		_restart_tween()
	else:
		if _tween_n_dots and _tween_n_dots.is_running():
			_tween_n_dots.stop()


func _restart_tween():
	if _tween_n_dots and _tween_n_dots.is_running():
		_tween_n_dots.stop()
		_tween_n_dots.play()
	else:
		_tween_n_dots = create_tween()
		_tween_n_dots.set_loops()
		_tween_n_dots.tween_property(self, "n_dots", MAX_N_DOTS, 0.5).from(0)
