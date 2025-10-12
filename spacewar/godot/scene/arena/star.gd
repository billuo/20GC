class_name Star
extends GravitySource


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(1e9)


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		area.explode()
