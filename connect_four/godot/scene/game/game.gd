extends Node2D

enum GameState {
	InProgress,
	FinishedWon,
	FinishedTie,
}

const HINT_HELP_SCENE := preload("res://scene/game/hint_help.tscn")

var _game_state: GameState = GameState.InProgress:
	set = set_game_state
var _four_highlights_parent: Node2D
var _single_player_id: int
var _current_piece_stack: PieceStack
var _winner_player_id: int
var _tween_export_button_text_change: Tween
var _position_analysis: Ai.Analysis

@onready var screen: Screen = $Screen
@onready var prompt: Prompt = $Prompt
@onready var solver: Solver = $Solver
@onready var restart_button: Button = %RestartButton
@onready var copy_moves_button: Button = %CopyMovesButton
@onready var game_result_label: Label = %GameResultLabel
@onready var piece_stack_1: PieceStack = $PieceStack1
@onready var piece_stack_2: PieceStack = $PieceStack2


func _ready() -> void:
	_four_highlights_parent = Node2D.new()
	add_child(_four_highlights_parent)
	match GameOptions.mode:
		GameOptions.Mode.SinglePlayer:
			_single_player_id = randi_range(1, 2)
			for id in range(1, 3):
				PlayerManager.set_player_is_ai(id, id != _single_player_id)
		GameOptions.Mode.TwoPlayers:
			for id in range(1, 3):
				PlayerManager.set_player_is_ai(id, false)
		GameOptions.Mode.NoPlayer:
			for id in range(1, 3):
				PlayerManager.set_player_is_ai(id, true)
	screen.clear()
	_current_piece_stack.pop()
	prompt.force_update()
	%CurrentMovesLabel.text = "Moves: "


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_exit()
	elif event.is_action_pressed(&"restart"):
		get_viewport().set_input_as_handled()
		restart()
	else:
		# only process mouse input if it's human player's turn
		if not PlayerManager.get_player_is_ai(current_player_id()) and _game_state == GameState.InProgress:
			if event is InputEventMouseMotion:
				prompt.force_update(event.global_position)
			elif event is InputEventMouseButton:
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					var mouse_pos = event.global_position
					var hole_pos = screen.get_nearest_hole(mouse_pos)
					if screen.can_insert_piece(hole_pos.x):
						play_a_move(hole_pos.x)


func current_player_id() -> int:
	return screen.get_n_moves() % 2 + 1


func set_game_state(value: GameState) -> void:
	_game_state = value
	# update prompt
	prompt.visible = _game_state == GameState.InProgress
	# update game result
	game_result_label.visible = _game_state != GameState.InProgress
	if _game_state == GameState.FinishedTie:
		game_result_label.text = "Tie"
		game_result_label.self_modulate = Color.WHITE
	elif _game_state == GameState.FinishedWon:
		game_result_label.text = "Player %d Won!" % _winner_player_id
		game_result_label.self_modulate = PlayerManager.get_player_color(_winner_player_id)
	# update buttons
	%HintButton.disabled = _game_state != GameState.InProgress
	%WithdrawButton.disabled = _game_state != GameState.InProgress


func play_a_move(column: int):
	var pid = current_player_id()
	var inserted = screen.try_insert_piece(column, pid)
	assert(inserted)
	_play_piece_drop_sound(column)
	_current_piece_stack.pop()
	prompt.force_update()


func restart() -> void:
	_game_state = GameState.InProgress
	for child in _four_highlights_parent.get_children():
		child.queue_free()
	var n = screen.get_n_moves()
	var play_random_sound = func(): [$Audio/PieceDropLow, $Audio/PieceDropMid, $Audio/PieceDropHigh].pick_random().play()
	if n > 6:
		$Audio/GridClear.play()
		for i in range(n / 2):
			get_tree().create_timer(randf_range(0.1, 0.5)).timeout.connect(play_random_sound)
	else:
		for i in range(n):
			get_tree().create_timer(randf_range(0.1, 0.5)).timeout.connect(play_random_sound)
	screen.clear()
	piece_stack_1.reset()
	piece_stack_2.reset()
	piece_stack_1.pop()
	prompt.force_update()
	# TODO: player should switch side


func _play_piece_drop_sound(col: int) -> void:
	var fall_height = screen.get_top_empty_hole(col) + 1
	match fall_height:
		1, 2:
			$Audio/PieceDropLow.play()
		3, 4:
			$Audio/PieceDropMid.play()
		5, 6:
			$Audio/PieceDropHigh.play()


func _exit():
	print_debug("back to main menu")
	get_tree().change_scene_to_packed(load("res://scene/main_menu/main_menu.tscn"))


func _on_player_won(id: int, fours: Array) -> void:
	_winner_player_id = id
	_game_state = GameState.FinishedWon
	var highlighted = {}
	for four in fours:
		print_debug(four)
		for pos in four:
			if not highlighted.has(pos):
				highlighted.set(pos, true)
	for pos in highlighted:
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://asset/piece_highlight.png")
		_four_highlights_parent.add_child(sprite)
		sprite.global_position = screen.global_position + screen.get_hole_center_local(pos)


func _on_game_tied() -> void:
	_game_state = GameState.FinishedTie


func _on_hint_button_pressed() -> void:
	if _game_state != GameState.InProgress:
		return
	if PlayerManager.get_player_is_ai(current_player_id()):
		return
	if not _position_analysis:
		solver.solve_position(screen.get_game_position())
		var res = await solver.solved
		var moves: Array[AnalyzedMove] = res[1]
		_position_analysis = Ai.Analysis.new(moves)
	screen.display_hints(_position_analysis)


func _on_withdraw_button_pressed() -> void:
	if _game_state != GameState.InProgress:
		return
	match GameOptions.mode:
		GameOptions.Mode.NoPlayer:
			return
		GameOptions.Mode.SinglePlayer:
			if screen.get_n_moves() > 1 and not PlayerManager.get_player_is_ai(current_player_id()):
				screen.withdraw()
				screen.withdraw()
				piece_stack_1.push()
				piece_stack_2.push()
				prompt.force_update()
		GameOptions.Mode.TwoPlayers:
			if screen.get_n_moves() > 0:
				_current_piece_stack.push()
				screen.withdraw()
				prompt.force_update()


func _on_restart_button_pressed() -> void:
	restart()


func _on_copy_moves_button_pressed() -> void:
	DisplayServer.clipboard_set(screen.get_moves_string())
	var orig_text = copy_moves_button.text
	copy_moves_button.text = "Copied!"
	if not _tween_export_button_text_change or _tween_export_button_text_change:
		_tween_export_button_text_change = copy_moves_button.create_tween()
		_tween_export_button_text_change.tween_interval(0.5)
		_tween_export_button_text_change.finished.connect(
			func():
				copy_moves_button.text = orig_text
				_tween_export_button_text_change = null
		)
	else:
		_tween_export_button_text_change.stop()
		_tween_export_button_text_change.play()


func _on_screen_position_changed() -> void:
	var pid = current_player_id()
	%CurrentMovesLabel.text = "Moves: %s" % screen.get_moves_string()
	_position_analysis = null
	screen.clear_hints()
	print_debug("position changed. pid=%d (%sAI)" % [pid, "" if PlayerManager.get_player_is_ai(pid) else "not "])
	if PlayerManager.get_player_is_ai(pid):
		print_debug("solving...")
		solver.solve_position(screen.get_game_position())
	prompt.color = PlayerManager.get_player_color(pid)
	%WithdrawButton.disabled = PlayerManager.get_player_is_ai(pid)
	%HintButton.disabled = PlayerManager.get_player_is_ai(pid)
	if pid == 1:
		_current_piece_stack = piece_stack_1
	else:
		_current_piece_stack = piece_stack_2


func _on_hint_help_button_pressed() -> void:
	$UI.add_child(HINT_HELP_SCENE.instantiate())


func _on_exit_button_pressed() -> void:
	_exit()


func _on_solver_solved(pos: PackedByteArray, moves: Array[AnalyzedMove]) -> void:
	print_debug("solved")
	if not is_inside_tree():
		return
	print_debug("in tree")
	if _game_state != GameState.InProgress:
		return
	print_debug("in progress")
	if pos != screen.get_game_position():
		return
	print_debug("same position")
	var pid = pos.size() % 2 + 1
	if not PlayerManager.get_player_is_ai(pid):
		return
	print_debug("is AI; playing move")
	var move = Ai.pick_a_move(moves, PlayerManager.get_player_ai_difficulty(pid))
	play_a_move(move)
