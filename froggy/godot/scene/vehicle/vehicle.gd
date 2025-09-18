class_name Vehicle
extends Area3D

var direction: Vector3 = Vector3.RIGHT
var speed: float = 5.0


func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta


func _on_body_entered(body: Node3D):
	assert(body is Player)
	(body as Player).hit_by_car()
