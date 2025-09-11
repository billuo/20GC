class_name Ball
extends CharacterBody2D

signal escaped
signal hit_top

const MAX_PHYSICS_ITERATIONS := 4

enum State {
	Start,
	Locked,  ## locked to paddle waiting to be served
	Free,  ## freely bouncing around
	Escaped,  ## gone out of bound
}

@export var initial_speed := 400
@export var max_speed := 800
@export var delta_speed := 50

var _state: State = State.Start
var _next_state = null
var _locked_by: Paddle = null
var _speed := 0
var _look_at: Vector2:
	set = set_look_at


func _physics_process(delta: float) -> void:
	# update according to current state
	match _state:
		State.Start:
			pass
		State.Locked:
			assert(_locked_by)
			global_position = _locked_by.global_position + Vector2(0, -50)
			_look_at = Vector2.UP
		State.Free:
			if not Global.VIEWPORT_RECT.has_point(global_position):
				_next_state = State.Escaped
				print_debug("ESCAPED")
				escaped.emit()
			velocity = velocity.normalized() * _speed
			_look_at = velocity
		State.Escaped:
			pass

	# process state switching if any
	match _next_state:
		State.Start:
			pass
		State.Locked:
			pass
		State.Free:
			var dir = Vector2(randf_range(-0.25, 0.25), -1).normalized()
			velocity = dir * initial_speed
			_speed = initial_speed
		State.Escaped:
			pass
	if _next_state != null:
		_state = _next_state
		_next_state = null

	# update physics
	var motion = velocity * delta
	for i in range(MAX_PHYSICS_ITERATIONS):
		var c = move_and_collide(motion)
		if not c:
			break
		var node = c.get_collider() as Node2D
		assert(node)
		velocity = (-velocity).reflect(c.get_normal())

		if node.is_in_group("paddle"):
			var paddle = node as Paddle
			assert(paddle)
			paddle.on_hit()
			if c.get_normal().dot(Vector2.UP) > 0:
				# tweak velocity direction based on impact position on paddle
				var offset_x = c.get_position().x - node.global_position.x
				var offset_ratio = offset_x / paddle.length * 2  ## [-1.0, 1.0]
				var rot = deg_to_rad(offset_ratio * 20)
				velocity = velocity.rotated(rot)
				# ... while also clamping its angel to avoid lengthy horizontal bounces
				const MAX_ANGLE = deg_to_rad(75)
				var angle_to_y = velocity.angle_to(Vector2.UP)
				if angle_to_y > MAX_ANGLE:
					velocity = velocity.rotated(angle_to_y - MAX_ANGLE)
				elif angle_to_y < -MAX_ANGLE:
					velocity = velocity.rotated(-MAX_ANGLE - angle_to_y)

		elif node.is_in_group("brick"):
			var brick = node as Brick
			assert(brick)
			brick.on_hit(self)
			# increase ball speed on hitting bricks
			_speed = min(max_speed, _speed + delta_speed)

		elif node.is_in_group("boundry"):
			var boundry = node as Boundry
			assert(boundry)
			boundry.on_hit(self)
			if c.get_normal() == Vector2.DOWN:
				hit_top.emit()

		# calculate remaining motion during this frame
		var remainder = c.get_remainder()
		if remainder == Vector2.ZERO:
			break
		delta *= remainder.length() / motion.length()
		motion = velocity * delta


func set_look_at(value: Vector2):
	_look_at = value
	($Sprite2D.material as ShaderMaterial).set_shader_parameter("look_at", _look_at.normalized())
	queue_redraw()


func lock_to_paddle(paddle: Paddle):
	match _state:
		State.Start, State.Locked, State.Free, State.Escaped:
			_next_state = State.Locked
			_locked_by = paddle
			# to avoid colliding with bricks in new level
			global_position = _locked_by.global_position + Vector2(0, -50)
		_:
			_err_trans_state(_state, State.Locked)


func can_serve() -> bool:
	match _state:
		State.Start, State.Locked:
			return true
		_:
			return false


func serve():
	match _state:
		State.Start, State.Locked:
			_next_state = State.Free
		_:
			_err_trans_state(_state, State.Free)


func has_escaped():
	return _state == State.Escaped or _next_state == State.Escaped


func _err_trans_state(from: State, to: State):
	push_error("Invalid state transition: %s -> %s" % [from, to])
