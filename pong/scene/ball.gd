class_name Ball
extends RigidBody2D

signal stucked
signal out_of_bound

enum State {
	Ready,
	Served,
}

@export var initial_speed := 800.0
@export var speed_delta := 100.0
@export var speed := initial_speed
@export var max_speed := 2000.0

var _state: State = State.Ready
var _next_state = null
var _serve_direction: Vector2
var _last_collided_paddle: Paddle = null
var _n_collisions_wo_paddle := 0
@onready var bounces: Array[AudioStreamPlayer2D] = [
	$Bounce1,
	$Bounce2,
	$Bounce3,
]


func _integrate_forces(_s: PhysicsDirectBodyState2D) -> void:
	if global_position.x < -100 or global_position.x > 1700:
		out_of_bound.emit()
	match _state:
		State.Ready:
			match _next_state:
				State.Served:
					var dir = _serve_direction
					dir = dir.rotated(deg_to_rad(randf_range(-30.0, 30.0)))
					linear_velocity = dir * speed
				_:
					pass
		State.Served:
			if linear_velocity.length() < speed:
				linear_velocity = linear_velocity.normalized() * speed
			match _next_state:
				State.Ready:
					linear_velocity = Vector2.ZERO
					position = Vector2(800, 450)
					speed = initial_speed
				_:
					pass
	if _next_state != null:
		_state = _next_state
		_next_state = null


func _draw() -> void:
	var shape = $CollisionShape2D.shape
	var r := (shape as CircleShape2D).radius
	draw_circle(Vector2.ZERO, r, Color.WHITE)


func reset() -> void:
	set_deferred("freeze", false)
	_next_state = State.Ready
	_last_collided_paddle = null
	_n_collisions_wo_paddle = 0


func serve(direction: Vector2) -> void:
	_next_state = State.Served
	_serve_direction = direction


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("paddle"):
		_n_collisions_wo_paddle = 0
		if body != _last_collided_paddle:
			_last_collided_paddle = body
			speed = min(speed + speed_delta, max_speed)
	else:
		_n_collisions_wo_paddle += 1
		if _n_collisions_wo_paddle >= 20:
			stucked.emit()
	bounces.pick_random().play()
