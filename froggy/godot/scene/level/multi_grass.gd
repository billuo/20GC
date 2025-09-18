extends MultiMeshInstance3D

@export var avoid_objects: Array[Node3D] = []

@onready var _mat: ShaderMaterial = self.material_override as ShaderMaterial


func _process(_delta: float) -> void:
	if avoid_objects.is_empty():
		_mat.set_shader_parameter("avoidance_enabled", false)
	else:
		_mat.set_shader_parameter("avoidance_enabled", true)

	var remove_idx := []
	for i in range(avoid_objects.size()):
		var obj = avoid_objects[i]
		if not obj or obj.is_queued_for_deletion():
			remove_idx.append(i)
			continue
		# TODO: support multiple objects
		_mat.set_shader_parameter("object_origin", obj.global_position)
		if obj.has_method("get_grass_avoidance_radius"):
			_mat.set_shader_parameter("object_radius", obj.get_grass_avoidance_radius())
	remove_idx.reverse()
	for i in remove_idx:
		avoid_objects.remove_at(i)
