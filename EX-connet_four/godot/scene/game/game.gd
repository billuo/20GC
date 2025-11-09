extends Node2D

enum GameState {
	InProgress,
	FinishedWon,
	FinishedTie,
}

var game_state: GameState = GameState.InProgress:
	set = set_game_state
var four_highlights_parent: Node2D
var single_player_id: int
var current_player_id: int:
	set = set_current_player_id
var _tween_export_button_text_change: Tween

@onready var screen: Screen = $Screen
@onready var prompt: Prompt = $Prompt
@onready var solver: Solver = $Solver
@onready var restart_button: Button = %RestartButton
@onready var export_button: Button = %ExportButton


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	four_highlights_parent = Node2D.new()
	add_child(four_highlights_parent)
	match GameOptions.mode:
		GameOptions.Mode.SinglePlayer:
			single_player_id = randi_range(1, PlayerManager.N_PLAYERS)
			for id in range(1, PlayerManager.N_PLAYERS + 1):
				if id != single_player_id:
					PlayerManager.set_player_is_ai(id, true)
		GameOptions.Mode.TwoPlayers:
			pass
		GameOptions.Mode.NoPlayer:
			for id in range(1, PlayerManager.N_PLAYERS + 1):
				PlayerManager.set_player_is_ai(id, true)
	current_player_id = 1


func _unhandled_input(event: InputEvent) -> void:
	if game_state == GameState.InProgress:
		if event is InputEventKey:
			if event.is_pressed() and event.keycode == KEY_F1:
				print_debug(screen.get_moves_string())
		if not PlayerManager.get_player_is_ai(current_player_id):
			# only process mouse input if it's human player's turn
			if event is InputEventMouseMotion:
				prompt.force_update(event.global_position)
			elif event is InputEventMouseButton:
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					var mouse_pos = event.global_position
					var hole_pos = screen.get_nearest_hole(mouse_pos)
					if screen.try_insert_piece(hole_pos.x, current_player_id):
						_play_piece_drop_sound(hole_pos.x)
						current_player_id = PlayerManager.next_player(current_player_id)
						prompt.force_update(mouse_pos)


func set_game_state(value: GameState) -> void:
	game_state = value
	prompt.visible = game_state == GameState.InProgress


func set_current_player_id(value: int) -> void:
	current_player_id = value
	prompt.color = PlayerManager.get_player_color(value)
	if PlayerManager.get_player_is_ai(current_player_id):
		_solve()


func _solve():
	if game_state != GameState.InProgress:
		return
	solver.start_solve.call_deferred(screen)
	await solver.solved
	var inserted = screen.try_insert_piece(solver.solution, current_player_id)
	assert(inserted)
	_play_piece_drop_sound(solver.solution)
	current_player_id = PlayerManager.next_player(current_player_id)
	prompt.force_update()


func _play_piece_drop_sound(col: int) -> void:
	var fall_height = screen.SIZE.y - (screen.get_n_filled(col) - 1)
	match fall_height:
		1, 2:
			$Audio/PieceDropLow.play()
		3, 4:
			$Audio/PieceDropMid.play()
		5, 6:
			$Audio/PieceDropHigh.play()


func _on_player_won(id: int, fours: Array) -> void:
	game_state = GameState.FinishedWon
	var highlighted = {}
	print_debug("Player %d won" % id)
	for four in fours:
		print_debug(four)
		for pos in four:
			if not highlighted.has(pos):
				highlighted.set(pos, true)
	for pos in highlighted:
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://asset/piece_highlight.png")
		four_highlights_parent.add_child(sprite)
		sprite.global_position = screen.global_position + screen.get_hole_center_local(pos)


func _on_game_tied() -> void:
	game_state = GameState.FinishedTie
	print_debug("Tie")


func _on_restart_button_pressed() -> void:
	game_state = GameState.InProgress
	for child in four_highlights_parent.get_children():
		child.queue_free()
	var n = screen.get_n_pieces()
	if n > 6:
		restart_button.disabled = true
		$Audio/GridClear.play()
		$Audio/GridClear.finished.connect(func(): restart_button.disabled = false)
	else:
		var play_random_sound = func(): [$Audio/PieceDropLow, $Audio/PieceDropMid, $Audio/PieceDropHigh].pick_random().play()
		for i in range(n):
			get_tree().create_timer(randf_range(0.1, 0.5)).timeout.connect(play_random_sound)
	screen.clear()
	current_player_id = 1
	prompt.force_update()


func _on_withdraw_button_pressed() -> void:
	if game_state != GameState.InProgress:
		return
	if GameOptions.mode == GameOptions.Mode.NoPlayer:
		return
	var id = current_player_id
	while true:
		screen.withdraw()
		id = PlayerManager.prev_player(id)
		if not PlayerManager.get_player_is_ai(id):
			current_player_id = id
			break
	prompt.force_update()


func _on_export_button_pressed() -> void:
	DisplayServer.clipboard_set(screen.get_moves_string())
	export_button.text = "Copied!"
	if not _tween_export_button_text_change or _tween_export_button_text_change:
		_tween_export_button_text_change = export_button.create_tween()
		_tween_export_button_text_change.tween_interval(0.5)
		_tween_export_button_text_change.finished.connect(
			func():
				export_button.text = "Export"
				_tween_export_button_text_change = null
		)
	else:
		_tween_export_button_text_change.stop()
		_tween_export_button_text_change.play()
