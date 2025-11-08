extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_requested.connect(_close)


func _close():
	hide()
	queue_free()
