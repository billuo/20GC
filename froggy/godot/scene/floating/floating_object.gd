class_name FloatingObject
extends Area3D

var direction: Vector3 = Vector3.RIGHT
var speed: float = 5.0


func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta


func _on_body_entered(body: Node3D):
	assert(body is Player)
	(body as Player).platform_enter(self)


func _on_body_exited(body: Node3D):
	assert(body is Player)
	(body as Player).platform_exit(self)
