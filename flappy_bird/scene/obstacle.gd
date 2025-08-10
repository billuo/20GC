class_name Obstacle
extends Area2D

signal hit_player(Obstacle)

const SCREEN_HEIGHT = 900.0

@export var velocity := Vector2(-300.0, 0.0)
@export var gap_width_min := 300
@export var gap_width_max := 500

var player_passed := false

var _width := 100.0
var _gap_width := 400.0
var _gap_center_y := 450.0

@onready var upper: CollisionShape2D = $Upper
@onready var lower: CollisionShape2D = $Lower


func _ready() -> void:
	const LEEWAY = 100.0
	_gap_width = randi_range(gap_width_min, gap_width_max)
	_gap_center_y = randf_range(LEEWAY + _gap_width / 2.0, SCREEN_HEIGHT - (LEEWAY + _gap_width / 2.0))
	_update_shape()


func _process(delta: float) -> void:
	position += velocity * delta


func _update_shape():
	var upper_size = Vector2(_width, _gap_center_y - _gap_width / 2.0)
	upper.shape = RectangleShape2D.new()
	upper.shape.size = upper_size
	upper.position = upper_size / 2.0
	var lower_size = Vector2(_width, SCREEN_HEIGHT - _gap_center_y - _gap_width / 2.0)
	lower.shape = RectangleShape2D.new()
	lower.shape.size = lower_size
	lower.position = Vector2(_width / 2, SCREEN_HEIGHT - lower_size.y / 2)


func _on_screen_exited() -> void:
	hide()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hit_player.emit(self)
