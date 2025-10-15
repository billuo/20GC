class_name GridCompute
extends Node


func reset(_new_size: Vector2i, _new_data := PackedInt32Array()):
	pass


func get_data() -> PackedInt32Array:
	return PackedInt32Array()


func get_image_bytes() -> PackedByteArray:
	return PackedByteArray()


func step(_callback: Callable):
	pass
