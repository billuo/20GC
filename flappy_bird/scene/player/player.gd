class_name Player
extends CharacterBody2D

signal hit_by_obstacle(node: Node2D)

const JUMP_VELOCITY = -500.0

var _dead := false

@onready var _jump_sounds: Array[AudioStreamPlayer2D] = [
	$JumpSound1,
	$JumpSound2,
	$JumpSound3,
]


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if not _dead and Input.is_action_just_pressed("jump"):
		_jump_sounds.pick_random().play()
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	if _dead:
		return
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var node = col.get_collider() as Node2D
		if not node:
			continue
		print("Player collided with %s" % node)
		if node.is_in_group("obstacle"):
			hit_by_obstacle.emit(node)


func die():
	$AnimatedSprite2D.play("dead")
	_dead = true
