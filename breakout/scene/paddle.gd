class_name Paddle
extends CharacterBody2D

# TODO: mark center for easier movement

const MIN_LENGTH := 50.0
const MAX_LENGTH := 1600.0

@export var path_follow: PathFollow2D
@export var speed := 600.0
@export var length := 200.0:
	set = set_length
var _moving_left := false
var _moving_right := false
var _target_length := 200.0
var _length_change_speed := 200.0


func _input(event: InputEvent) -> void:
	if event.is_action("move_left"):
		_moving_left = event.is_pressed()
	if event.is_action("move_right"):
		_moving_right = event.is_pressed()


func _physics_process(delta: float) -> void:
	if path_follow:
		var _speed = 0.0
		if _moving_left:
			_speed -= speed
		if _moving_right:
			_speed += speed
		path_follow.progress += _speed * delta
		# HACK: prevent sudden rotation jump at both ends
		const EPSILON = 0.003
		path_follow.progress_ratio = clampf(path_follow.progress_ratio, EPSILON, 1.0 - EPSILON)
		position = path_follow.position
		rotation = path_follow.rotation

	if length != _target_length:
		var diff = _target_length - length
		var d = signf(diff) * _length_change_speed * delta
		if abs(d) < abs(diff):
			length += d
		else:
			length = _target_length


func set_length_animated(new_len: float, change_speed: float = 1000.0):
	_target_length = clampf(new_len, MIN_LENGTH, MAX_LENGTH)
	_length_change_speed = change_speed


func set_length(value: float):
	length = clampf(value, MIN_LENGTH, MAX_LENGTH)
	$ColorRect.position.x = -length / 2.0
	$ColorRect.size.x = length
	$CollisionShape2D.shape.size.x = length


func on_hit():
	$HitSound.pitch_scale = randf_range(.9, 1.1)
	$HitSound.play()
