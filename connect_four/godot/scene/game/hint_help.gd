extends PanelContainer


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		queue_free()
