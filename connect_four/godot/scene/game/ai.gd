class_name Ai


static func pick_a_move(moves: Array[AnalyzedMove], difficulty: GameOptions.AIDifficulty) -> int:
	var a = Analysis.new(moves)

	match difficulty:
		GameOptions.AIDifficulty.Drunk:
			if not a.winning_moves.is_empty() and randf() < 0.9:
				return a.winning_moves.pick_random()
			if not a.forced_moves.is_empty() and randf() < 0.9:
				return a.forced_moves.pick_random()
			return a.possible_moves.pick_random()
		GameOptions.AIDifficulty.Normal:
			if not a.winning_moves.is_empty():
				return a.winning_moves.pick_random()
			if not a.forced_moves.is_empty():
				return a.forced_moves.pick_random()
			if not a.good_moves.is_empty() and randf() < 0.5:
				return a.good_moves.pick_random()
			if not a.neutral_moves.is_empty() and randf() < 0.9:
				return a.neutral_moves.pick_random()
			if not a.non_losing_moves.is_empty() and randf() < 0.9:
				return a.non_losing_moves.pick_random()
			return a.possible_moves.pick_random()
		GameOptions.AIDifficulty.Veteran:
			if not a.winning_moves.is_empty():
				return a.winning_moves.pick_random()
			if not a.forced_moves.is_empty():
				return a.forced_moves.pick_random()
			if not a.okay_moves.is_empty():
				return a.okay_moves.pick_random()
			return a.possible_moves.pick_random()
		GameOptions.AIDifficulty.Godlike:
			if not a.winning_moves.is_empty():
				return a.winning_moves.pick_random()
			return a.best_moves.pick_random()
		_:
			assert(false, "unknown personality")
	return -1


class Analysis:
	var analyzed_moves: Array[AnalyzedMove]
	var possible_moves: Array[int] = []
	var winning_moves: Array[int] = []
	var non_losing_moves: Array[int] = []
	var forced_moves: Array[int] = []
	var good_moves: Array[int] = []
	var neutral_moves: Array[int] = []
	var okay_moves: Array[int] = []
	var bad_moves: Array[int] = []
	var best_moves: Array[int] = []
	var best_move_score := -100

	func _init(moves: Array[AnalyzedMove]) -> void:
		analyzed_moves = moves
		for move in moves:
			if move == null:
				continue
			var col = move.col
			assert(col >= 0 and col < 7, "invalid move")
			possible_moves.push_back(col)
			if move.winning:
				winning_moves.push_back(col)
			if move.forced:
				forced_moves.push_back(col)
			if move.score > 0:
				good_moves.push_back(col)
				okay_moves.push_back(col)
			elif move.score == 0:
				neutral_moves.push_back(col)
				okay_moves.push_back(col)
			else:
				bad_moves.push_back(col)
				if not move.losing:
					non_losing_moves.push_back(col)
			if move.score > best_move_score:
				best_move_score = move.score
				best_moves = [col]
			elif move.score == best_move_score:
				best_moves.push_back(col)
