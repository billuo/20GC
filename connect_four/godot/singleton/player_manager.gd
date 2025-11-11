extends Node

const N_PLAYERS = 2

var _player_is_ai: Array[bool] = [false, false]


func get_player_color(id: int) -> Color:
	assert(id > 0)
	assert(id <= N_PLAYERS)
	match id:
		1:
			return Color.RED
		2:
			return Color.YELLOW
		_:
			return Color.GRAY


func get_player_ai_difficulty(id: int) -> GameOptions.AIDifficulty:
	match GameOptions.mode:
		GameOptions.Mode.SinglePlayer:
			return GameOptions.ai_difficulty_1
		GameOptions.Mode.TwoPlayers:
			assert(false, "2P mode should not involve AI")
		GameOptions.Mode.NoPlayer:
			return GameOptions.ai_difficulty_1 if id == 1 else GameOptions.ai_difficulty_2
	assert(false, "unknown game mode")
	return GameOptions.AIDifficulty.Normal


func get_player_is_ai(id: int) -> bool:
	assert(id > 0)
	assert(id <= N_PLAYERS)
	return _player_is_ai[id - 1]


func set_player_is_ai(id: int, b: bool) -> void:
	assert(id > 0)
	assert(id <= N_PLAYERS)
	_player_is_ai[id - 1] = b


func prev_player(id: int) -> int:
	assert(id > 0)
	assert(id <= N_PLAYERS)
	id -= 1
	if id <= 0:
		return N_PLAYERS
	return id


func next_player(id: int) -> int:
	assert(id > 0)
	assert(id <= N_PLAYERS)
	id += 1
	if id > N_PLAYERS:
		return 1
	return id
