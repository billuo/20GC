class_name Projectile
extends Area2D

const ANIMATION_SCENE := preload("res://scene/projectile/animation.tscn")

@export var velocity := Vector2.ZERO
@export var ttl := 2.0
@export var gravity_sources: Array[GravitySource] = []
@export var gravity_factor := 10.0

@export var fire_source: Player:
	set = set_fire_source
@export var can_hurt_self := false
@export var damage := 100.0

var _moving := true
var _color: Color


func _ready() -> void:
	get_tree().create_timer(ttl).timeout.connect(explode)
	_update_rotation()


func _physics_process(delta: float) -> void:
	if _moving:
		for g in gravity_sources:
			velocity += gravity_factor * g.get_gravity_acc(self) * delta
		global_position += velocity * delta
	_update_rotation()

	# wrap position in viewport
	var viewport = Rect2(Vector2.ZERO, Global.VIEWPORT_SIZE)
	if not viewport.has_point(global_position):
		global_position.x = fmod(global_position.x, Global.VIEWPORT_SIZE.x)
		global_position.y = fmod(global_position.y, Global.VIEWPORT_SIZE.y)
		if global_position.x < 0:
			global_position.x += Global.VIEWPORT_SIZE.x
		if global_position.y < 0:
			global_position.y += Global.VIEWPORT_SIZE.y


func explode():
	var ani: AnimatedSprite2D = ANIMATION_SCENE.instantiate()
	ani.position = global_position
	ani.modulate = _color
	ani.animation_finished.connect(ani.queue_free)
	ani.play(&"vanish")
	get_viewport().add_child(ani)

	queue_free()


func set_fire_source(value: Player):
	fire_source = value
	_color = fire_source.color
	$Sprite2D.self_modulate = _color


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if can_hurt_self || body != fire_source:
			explode()
			body.take_damage(damage)


func _update_rotation():
	rotation = Vector2.UP.angle_to(velocity)
