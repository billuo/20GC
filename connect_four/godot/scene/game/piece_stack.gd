class_name PieceStack
extends Node2D

const PIECE_SIZE := Vector2(90, 18)
const PIECE_SIDEWAY_SCENE := preload("res://scene/game/piece_sideway.tscn")

@export var player_id: int


func _ready() -> void:
	reset()
	modulate = PlayerManager.get_player_color(player_id)
	$StaticBody2D.collision_layer = 1 << player_id
	$StaticBody2D.collision_mask = 1 << player_id


func reset():
	for child in get_children():
		if child is RigidBody2D:
			child.queue_free()
	for i in range(21):
		_add_piece(i)


func pop() -> bool:
	if get_child_count() == 1:
		return false
	var max_y = -1e9
	var bottom_piece: RigidBody2D
	for child in get_children():
		if not child is RigidBody2D:
			continue
		if child.position.y > max_y:
			max_y = child.position.y
			bottom_piece = child
	assert(bottom_piece)
	remove_child(bottom_piece) # NOTE: will be freed once out of screen
	bottom_piece.collision_layer = 0
	bottom_piece.collision_mask = 0
	return true


func push():
	_add_piece(30)


func _add_piece(height: int):
	var piece: RigidBody2D = PIECE_SIDEWAY_SCENE.instantiate()
	piece.collision_layer = 1 << player_id
	piece.collision_mask = 1 << player_id
	add_child(piece)
	var jitter = randi_range(-4, 4)
	piece.position = Vector2(jitter, -height * PIECE_SIZE.y - PIECE_SIZE.y * 0.5)
