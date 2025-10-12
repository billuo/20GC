class_name Player
extends RigidBody2D

const PROJECTILE_SCENE := preload("res://scene/projectile/projectile.tscn")
const EXPLOSION_SCENE := preload("res://scene/player/explosion.tscn")

enum Controller {
	None,
	Player1,
	Player2,
	Computer,
}

enum State {
	Normal,
	Dead,
}

const MAX_LINEAR_SPEED := 1200.0
const MAX_ANGULAR_SPEED := 12 * PI

@export var controller: Controller = Controller.None
@export var gravity_sources: Array[GravitySource] = []
@export var color: Color = Color.WHITE:
	set = set_color
@export var forward_power := 1000.0
@export var rotate_power := 1000.0
@export var hit_point := 100.0
@export var invincible := false

var _state := State.Normal

var _accelerating := false:
	set = set_accelerating
var _rotating_left := false
var _rotating_right := false
var _firing := false

var _thruster_on := false:
	set = set_thruster_on
var _fire_cooldown := 0.0


func _ready() -> void:
	set_color(color)
	_thruster_on = false


func _unhandled_input(event: InputEvent) -> void:
	match controller:
		Controller.Player1:
			if event.is_action("p1_accelerate"):
				_accelerating = event.is_pressed()
			if event.is_action("p1_rotate_left"):
				_rotating_left = event.is_pressed()
			if event.is_action("p1_rotate_right"):
				_rotating_right = event.is_pressed()
			if event.is_action("p1_fire"):
				_firing = event.is_pressed()
		Controller.Player2:
			if event.is_action("p2_accelerate"):
				_accelerating = event.is_pressed()
			if event.is_action("p2_rotate_left"):
				_rotating_left = event.is_pressed()
			if event.is_action("p2_rotate_right"):
				_rotating_right = event.is_pressed()
			if event.is_action("p2_fire"):
				_firing = event.is_pressed()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var can_handle = _state == State.Normal
	var forward_dir = Vector2.UP.rotated(rotation)
	# compute then apply total force
	var total_force = Vector2.ZERO
	if can_handle and _accelerating:
		total_force += forward_dir * forward_power
	for g in gravity_sources:
		total_force += g.get_gravity_force(self)
	state.apply_central_force(total_force)
	# compute then apply torque
	var torque = 0.0
	if can_handle and _rotating_right:
		torque += rotate_power
	if can_handle and _rotating_left:
		torque -= rotate_power
	state.apply_torque(torque)
	# limit both linear and angular speed for more friendly handling
	state.linear_velocity = state.linear_velocity.limit_length(MAX_LINEAR_SPEED)
	state.angular_velocity = clampf(state.angular_velocity, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)
	# wrap position in viewport
	var viewport = Rect2(Vector2.ZERO, Global.VIEWPORT_SIZE)
	if not viewport.has_point(global_position):
		global_position.x = fmod(global_position.x, Global.VIEWPORT_SIZE.x)
		global_position.y = fmod(global_position.y, Global.VIEWPORT_SIZE.y)
		if global_position.x < 0:
			global_position.x += Global.VIEWPORT_SIZE.x
		if global_position.y < 0:
			global_position.y += Global.VIEWPORT_SIZE.y


func _process(delta: float) -> void:
	_fire_cooldown = max(_fire_cooldown - delta, 0.0)
	if _state == State.Normal and _fire_cooldown == 0.0 and _firing:
		fire()
		_fire_cooldown = 0.20


func set_color(value: Color):
	color = value
	$Sprite2D.self_modulate = color


func set_accelerating(value: bool):
	_accelerating = value
	if _state == State.Normal:
		_thruster_on = _accelerating


func set_thruster_on(value: bool):
	var was_on = _thruster_on
	_thruster_on = value
	$Trail.visible = _thruster_on
	$TrailParticles.emitting = _thruster_on
	if was_on != _thruster_on:
		if _thruster_on:
			$Audio/Engine.play()
		else:
			$Audio/Engine.stop()


func fire():
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	proj.position = to_global(Vector2.UP * 20.0)
	proj.velocity = Vector2(0.0, -800.0).rotated(rotation)
	proj.fire_source = self
	proj.gravity_sources = gravity_sources
	get_viewport().add_child(proj)
	$Audio/Shoot.play()


func take_damage(dmg: float):
	if invincible:
		return
	hit_point -= dmg
	if hit_point <= 0.0:
		die()


func die():
	_state = State.Dead
	$Sprite2D.hide()
	collision_mask = 0
	collision_layer = 0
	set_deferred("freeze", true)
	_thruster_on = false

	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.position = global_position
	get_viewport().add_child(explosion)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		take_damage(100.0)
		body.take_damage(100.0)
