@tool

extends Camera3D

@onready var frog: Node3D = %Frog


func _process(_delta: float) -> void:
	look_at(frog.global_position + Vector3(0.0, 0.0, -3.0))
