class_name Ball
extends RigidBody2D

enum State {
	Start,
	Locked,  ## locked to paddle waiting to be served
	Free,  ## freely bouncing around
	Escaped,  ## gone out of bound
}

@export var speed := 500

var _state: State = State.Start
var _next_state = null
var _locked_by: Paddle = null


func _integrate_forces(_s: PhysicsDirectBodyState2D) -> void:
	if OS.is_debug_build():
		queue_redraw()

	# update according to current state
	match _state:
		State.Locked:
			assert(_locked_by)
			global_position = _locked_by.global_position + Vector2(0, -50)
		State.Free:
			if not Global.VIEWPORT_RECT.has_point(global_position):
				_next_state = State.Escaped
				print_debug("ESCAPED")
			linear_velocity = linear_velocity.normalized() * speed


	# process state switching if any
	match _next_state:
		State.Locked:
			pass
		State.Free:
			var dir = Vector2(1, -1).normalized()
			linear_velocity = dir * speed
		State.Escaped:
			pass
	if _next_state != null:
		_state = _next_state
		_next_state = null


func _draw() -> void:
	var shape = $CollisionShape2D.shape as CircleShape2D
	assert(shape)
	draw_circle(Vector2.ZERO, shape.radius, Color.ORANGE_RED)
	if OS.is_debug_build():
		draw_line(Vector2.ZERO, linear_velocity / 4, Color.BLUE, 4)


func lock_to_paddle(paddle: Paddle):
	match _state:
		State.Start, State.Free:
			_next_state = State.Locked
			_locked_by = paddle
		_:
			_err_trans_state(_state, State.Locked)


func serve():
	match _state:
		State.Locked:
			_next_state = State.Free
		_:
			_err_trans_state(_state, State.Free)


func _err_trans_state(from: State, to: State):
	push_error("Invalid state transition: %s -> %s" % [from, to])
