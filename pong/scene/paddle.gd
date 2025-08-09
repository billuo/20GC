class_name Paddle
extends CharacterBody2D

signal ball_served

enum Controller {
	None,
	Ai,
	Player1,
	Player2,
}

const SPEED = 300.0

@export var path_follow: PathFollow2D
var controller := Controller.None:
	set = set_controller

var _ai_personality := Personality.new()
var _moving_left := false
var _moving_right := false
var _accelerated := false
@onready var _animation: AnimationPlayer = $AnimationPlayer


func _input(event: InputEvent) -> void:
	match controller:
		Controller.Player1:
			if event.is_action("p1_move_left"):
				_moving_left = event.is_pressed()
			if event.is_action("p1_move_right"):
				_moving_right = event.is_pressed()
			if event.is_action_pressed("p1_serve"):
				_serve_ball()
			if event.is_action("p1_accelerate"):
				_accelerated = event.is_pressed()
		Controller.Player2:
			if event.is_action("p2_move_left"):
				_moving_left = event.is_pressed()
			if event.is_action("p2_move_right"):
				_moving_right = event.is_pressed()
			if event.is_action_pressed("p2_serve"):
				_serve_ball()
			if event.is_action("p2_accelerate"):
				_accelerated = event.is_pressed()
		_:
			pass


func _physics_process(delta: float) -> void:
	if not path_follow:
		return

	if controller == Controller.Ai:
		if Engine.get_physics_frames() % _ai_personality.react_interval == 0:
			_update_ai_decision()

	var speed = 0.0
	if _moving_left:
		speed -= SPEED
	if _moving_right:
		speed += SPEED
	if _accelerated:
		speed *= 3
	path_follow.progress += speed * delta

	# HACK: prevent sudden rotation jump at both ends
	const EPSILON = 0.003
	path_follow.progress_ratio = clampf(path_follow.progress_ratio, EPSILON, 1.0 - EPSILON)

	position = path_follow.position
	rotation = path_follow.rotation


func _draw() -> void:
	var shape = $CollisionShape2D.shape
	var rect: Rect2 = (shape as RectangleShape2D).get_rect()
	draw_rect(rect.grow(2.0), Color.WHITE, true, -1.0, true)
	draw_rect(rect, Color(0.1, 0.1, 0.1), true, -1.0, true)


func set_controller(value: Controller):
	controller = value
	if value == Controller.Ai:
		_ai_personality.randomize()


func on_round_start(is_server: bool):
	if controller == Controller.Ai:
		_ai_personality.randomize()
	if is_server:
		_animation.play("prompt_serve")


func prompt_serve():
	_animation.play("prompt_serve")


func _serve_ball():
	self.ball_served.emit()
	_animation.play("RESET")


func _update_ai_decision():
	var ball_v = Game.world_interface.ball_velocity
	if ball_v == Vector2.ZERO:
		# waiting for ball to be served
		var time_elapsed = Time.get_unix_time_from_system() - Game.world_interface.round_start
		if time_elapsed >= _ai_personality.serve_grace_period:
			_serve_ball()
		return
	var ball_pos = Game.world_interface.ball_position
	var ball_rel = path_follow.global_position - ball_pos
	var ball_eta = ball_rel.x / ball_v.x
	if ball_eta <= 0:
		# ball is moving away, don't care. be random.
		# TODO:
		return
	else:
		var d_still = path_follow.global_position.distance_squared_to(ball_pos)
		var d_left = _peek_path_follow(-0.01).distance_squared_to(ball_pos)
		var d_right = _peek_path_follow(0.01).distance_squared_to(ball_pos)
		var d_min = min(d_still, d_left, d_right)
		_moving_left = d_min == d_left
		_moving_right = d_min == d_right
		_accelerated = ball_eta <= _ai_personality.acc_threshold


func _peek_path_follow(ratio_delta: float) -> Vector2:
	var old_ratio = path_follow.progress_ratio
	path_follow.progress_ratio = old_ratio + ratio_delta
	var ret = path_follow.position
	path_follow.progress_ratio = old_ratio
	return ret


class Personality:
	var react_interval := 5
	var serve_grace_period := 1.0
	var acc_threshold := 0.2

	func randomize():
		var r

		r = randf()
		if r < 0.1:
			react_interval = 1
		else:
			react_interval = randi_range(3, 10)

		serve_grace_period = randf_range(0.2, 1.0)

		r = randf()
		if r < 0.1:
			acc_threshold = INF
		elif r < 0.2:
			acc_threshold = 0.0
		else:
			acc_threshold = randf_range(0.1, 0.5)
