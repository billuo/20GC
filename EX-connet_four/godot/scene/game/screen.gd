class_name Screen
extends Node2D

signal player_won(id: int, fours: Array)
signal tied
signal clear_finished

const SIZE = Vector2i(7, 6)
const HOLE_SIZE = Vector2(101, 101)
const SCAN_LINES := [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
	[Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)],
	[Vector2i(0, 3), Vector2i(1, 2), Vector2i(2, 1), Vector2i(3, 0)],
]

var pieces: Array[int]
var piece_sprites: Array[Sprite2D]
var piece_order: Array[Vector2i]

@onready var piece_sprites_parent: Node2D = $Pieces
@onready var piece_highlight: Sprite2D = $PieceHighlightSprite2D


func _ready() -> void:
	pieces.resize(SIZE.x * SIZE.y)
	piece_sprites.resize(SIZE.x * SIZE.y)
	var tween = piece_highlight.create_tween()
	tween.tween_property(piece_highlight, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	tween.tween_property(piece_highlight, "self_modulate", Color(1.0, 1.0, 1.0, 0.5), 0.5)
	tween.set_loops()


func get_nearest_hole(global_pos: Vector2) -> Vector2i:
	# assuming local(0, 0) is the center of all holes
	var pos = to_local(global_pos)
	pos += (HOLE_SIZE * Vector2(SIZE)) * 0.5
	var res = Vector2i(pos.x / HOLE_SIZE.x, pos.y / HOLE_SIZE.y).clamp(Vector2i.ZERO, SIZE - Vector2i.ONE)
	return res


func get_hole_center_local(hole_pos: Vector2i) -> Vector2:
	var origin = -(HOLE_SIZE * Vector2(SIZE)) * 0.5
	return origin + (Vector2(hole_pos) + Vector2(0.5, 0.5)) * HOLE_SIZE


func get_n_filled(col: int) -> int:
	for y in range(SIZE.y - 1, -1, -1):
		if _get_piece(Vector2i(col, y)) == 0:
			return SIZE.y - y - 1
	return SIZE.y


func get_n_pieces() -> int:
	return piece_order.size()


func get_moves_string() -> String:
	var s = ""
	for pos in piece_order:
		s += str(pos.x + 1)
	return s


func get_moves() -> PackedByteArray:
	var a = PackedByteArray()
	for pos in piece_order:
		a.push_back(pos.x)
	return a


# try insert a piece at top of given column.
# return if successful
func try_insert_piece(col: int, piece: int) -> bool:
	for y in range(SIZE.y - 1, -1, -1):
		if _get_piece(Vector2i(col, y)) == 0:
			_set_piece(Vector2i(col, y), piece)
			return true
	return false


func withdraw() -> bool:
	if piece_order.is_empty():
		return false
	var pos = piece_order.pop_back()
	if piece_order.is_empty():
		piece_highlight.hide()
	else:
		piece_highlight.position = get_hole_center_local(piece_order.back())
	var sprite = piece_sprites[pos.x + pos.y * SIZE.x]
	pieces[pos.x + pos.y * SIZE.x] = 0
	piece_sprites[pos.x + pos.y * SIZE.x] = null
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "position", sprite.position - Vector2(0.0, Global.VIEWPORT_SIZE.y), 0.5)
	tween.finished.connect(sprite.queue_free)
	return true


func clear() -> void:
	pieces.clear()
	pieces.resize(SIZE.x * SIZE.y)
	piece_order.clear()
	piece_highlight.hide()
	var old_parent := piece_sprites_parent
	piece_sprites_parent = Node2D.new()
	add_child(piece_sprites_parent)
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(old_parent.queue_free)
	timer.timeout.connect(clear_finished.emit)
	var interval = 0.0
	for x in range(SIZE.x):
		for y in range(SIZE.y - 1, -1, -1):
			var sprite = piece_sprites[x + y * SIZE.x]
			if not sprite:
				continue
			var tween = sprite.create_tween()
			tween.tween_interval(interval)
			interval += 0.01
			tween.tween_property(sprite, "position", sprite.position + Vector2(0, Global.VIEWPORT_SIZE.y), 0.5)


func _get_piece(hole_pos: Vector2i) -> int:
	return pieces[hole_pos.x + hole_pos.y * SIZE.x]


func _get_piece_or(hole_pos: Vector2i, default := 0) -> int:
	if hole_pos.x >= 0 and hole_pos.y >= 0 and hole_pos.x < SIZE.x and hole_pos.y < SIZE.y:
		return pieces[hole_pos.x + hole_pos.y * SIZE.x]
	return default


func _set_piece(hole_pos: Vector2i, piece: int) -> void:
	var old_piece = pieces[hole_pos.x + hole_pos.y * SIZE.x]
	pieces[hole_pos.x + hole_pos.y * SIZE.x] = piece
	if old_piece == 0 and piece != 0:
		piece_order.push_back(hole_pos)
		piece_highlight.show()
		piece_highlight.position = get_hole_center_local(hole_pos)
		# add sprite
		var center = get_hole_center_local(hole_pos)
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://asset/piece.png")
		sprite.self_modulate = PlayerManager.get_player_color(piece)
		sprite.z_index = -1
		piece_sprites_parent.add_child(sprite)
		piece_sprites[hole_pos.x + hole_pos.y * SIZE.x] = sprite
		sprite.position = get_hole_center_local(Vector2i(hole_pos.x, 0)) - Vector2(0, 20)
		var tween = sprite.create_tween()
		tween.tween_property(sprite, "position", center, 0.4).set_trans(Tween.TRANS_BOUNCE)
	else:
		assert(false, "unimplemented")

	# check winning conditions
	var wins = []
	for scan in SCAN_LINES:
		for k in range(4):
			# let hole_pos be k-th in the scan
			var apos = []
			var connect_four = true
			for i in range(4):
				var pos = hole_pos + (scan[i] - scan[k])
				if _get_piece_or(pos) != piece:
					connect_four = false
					break
				apos.push_back(pos)
			if connect_four:
				wins.push_back(apos)
	if !wins.is_empty():
		player_won.emit(piece, wins)
		piece_highlight.hide()
	elif piece_order.size() == SIZE.x * SIZE.y:
		tied.emit()
		piece_highlight.hide()
