class_name GridCompute
extends Node


func reset(_new_size: Vector2i, _new_data := PackedByteArray()):
	pass


func get_data() -> PackedByteArray:
	return PackedByteArray()


func get_image_bytes() -> PackedByteArray:
	return PackedByteArray()


func set_cell(_cell_pos: Vector2i, _alive: bool):
	pass


func toggle_cell(_cell_pos: Vector2i):
	pass


func step(_b_mask: int, _s_mask: int):
	pass


func randomize(_alive_ratio: float):
	pass
