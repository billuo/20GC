class_name Obstacle
extends Area2D

signal player_hit(Obstacle)

const VIEWPORT_HEIGHT = 900.0
const TILE_SIZE := Vector2(70.0, 70.0)

@export var velocity := Vector2(-300.0, 0.0)
@export var gap_width_min := 200
@export var gap_width_max := 300

var player_passed := false

var _width := TILE_SIZE.x
var _gap_width := 400.0
var _gap_center_y := 450.0

@onready var upper: CollisionShape2D = $Upper
@onready var lower: CollisionShape2D = $Lower
@onready var upper_layer: TileMapLayer = $UpperLayer
@onready var lower_layer: TileMapLayer = $LowerLayer


func _ready() -> void:
	const LEEWAY = 100.0
	_gap_width = randi_range(gap_width_min, gap_width_max)
	_gap_center_y = randf_range(LEEWAY + _gap_width / 2.0, VIEWPORT_HEIGHT - (LEEWAY + _gap_width / 2.0))
	_update_shape()
	_update_tiles()


func _process(delta: float) -> void:
	position += velocity * delta


func just_passed(player: Player):
	if player_passed:
		return false
	if player.global_position.x > global_position.x + _width + 20:
		player_passed = true
		return true


func _update_shape():
	upper.shape = CapsuleShape2D.new()
	upper.shape.radius = _width / 2.0 - 4
	upper.shape.height = _gap_center_y - _gap_width / 2.0
	upper.position = Vector2(_width / 2.0, upper.shape.height / 2.0 - 6)

	var lower_size = Vector2(_width, VIEWPORT_HEIGHT - _gap_center_y - _gap_width / 2.0)
	lower.shape = RectangleShape2D.new()
	lower.shape.size = lower_size
	lower.position = Vector2(_width / 2, VIEWPORT_HEIGHT - lower_size.y / 2)


func _update_tiles():
	var upper_height = _gap_center_y - _gap_width / 2.0
	var upper_tiles = upper_height / TILE_SIZE.y
	var upper_tiles_actual = ceilf(upper_tiles)
	upper_layer.position.y = (upper_tiles - upper_tiles_actual) * TILE_SIZE.y
	for i in range(upper_tiles_actual):
		if i == upper_tiles_actual - 1:
			if randf() < 0.1:
				upper_layer.set_cell(Vector2i(0, i), 1, Vector2i(16, 3))
			else:
				upper_layer.set_cell(Vector2i(0, i), 1, Vector2i(16, 2))
		else:
			upper_layer.set_cell(Vector2i(0, i), 1, Vector2i(17, 5))

	var lower_height = VIEWPORT_HEIGHT - _gap_center_y - _gap_width / 2.0
	var lower_tiles = lower_height / TILE_SIZE.y
	var lower_tiles_actual = ceilf(lower_tiles)
	lower_layer.position.y = VIEWPORT_HEIGHT + (lower_tiles_actual - lower_tiles) * TILE_SIZE.y
	for i in range(lower_tiles_actual):
		if i == 0:
			lower_layer.set_cell(Vector2i(0, -i - 1), 1, Vector2i(10, 8))
		elif i == lower_tiles_actual - 1:
			lower_layer.set_cell(Vector2i(0, -i - 1), 1, Vector2i(10, 6))
		else:
			lower_layer.set_cell(Vector2i(0, -i - 1), 1, Vector2i(10, 7))


func _on_screen_exited() -> void:
	hide()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_hit.emit(self)
