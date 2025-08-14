class_name Paddle
extends CharacterBody2D

const SPEED = 400.0

@export var path_follow: PathFollow2D
var _moving_left := false
var _moving_right := false


func _input(event: InputEvent) -> void:
	if event.is_action("move_left"):
		_moving_left = event.is_pressed()
	if event.is_action("move_right"):
		_moving_right = event.is_pressed()


func _physics_process(delta: float) -> void:
	if not path_follow:
		return

	var speed = 0.0
	if _moving_left:
		speed -= SPEED
	if _moving_right:
		speed += SPEED
	path_follow.progress += speed * delta

	# HACK: prevent sudden rotation jump at both ends
	const EPSILON = 0.003
	path_follow.progress_ratio = clampf(path_follow.progress_ratio, EPSILON, 1.0 - EPSILON)

	position = path_follow.position
	rotation = path_follow.rotation
