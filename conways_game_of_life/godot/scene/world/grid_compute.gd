class_name GridCompute
extends Node


func reset(_new_size: Vector2i, _new_data := PackedByteArray()):
	pass


func get_data() -> PackedByteArray:
	return PackedByteArray()


func get_image_bytes() -> PackedByteArray:
	return PackedByteArray()


func step(_b_mask: int, _s_mask: int) -> PackedByteArray:
	return PackedByteArray()
