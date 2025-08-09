extends Window


func _ready() -> void:
	hide()
	close_requested.connect(Callable(self, "hide"))


func _on_volume_slider_value_changed(value: float) -> void:
	print("old volume(linear):", AudioServer.get_bus_volume_linear(0))
	AudioServer.set_bus_volume_linear(0, value / 50.0)
