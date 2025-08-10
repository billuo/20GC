class_name Player
extends CharacterBody2D

signal dead

const JUMP_VELOCITY = -500.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var obj = col.get_collider()
		var node = obj as Node2D
		if not node:
			continue
		print("Player collided with %s" % obj)
		if obj.is_in_group("obstacle"):
			dead.emit()
