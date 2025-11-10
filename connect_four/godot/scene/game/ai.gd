class_name Ai

enum Personality {
	Drunk,  # usually choose randomly
	Veteran,  # always choose a reasonable move
	Godlike,  # always choose the optimal move
}

var personality := Personality.Godlike
# 0~10
var difficulty: int


func pick_a_move(moves: Array[AnalyzedMove]) -> int:
	match personality:
		Personality.Drunk:
			var possible_moves = []
			for m in moves:
				if not m:
					continue
				if m.forced:
					return m.col
				if m.winning:
					return m.col
				possible_moves.push_back(m.col)
			return possible_moves.pick_random()
		Personality.Veteran:
			var winning_moves := []
			var losing_moves := []
			var forced_moves := []
			var good_moves := []
			var neutral_moves := []
			var bad_moves := []
			for i in range(7):
				var m = moves[i]
				if m != null:
					if m.winning:
						winning_moves.push_back(m.col)
					if m.forced:
						forced_moves.push_back(m.col)
					if m.score > 0:
						good_moves.push_back(m.col)
					elif m.score == 0:
						neutral_moves.push_back(m.col)
					else:
						if m.losing:
							losing_moves.push_back(m.col)
						else:
							bad_moves.push_back(m.col)
			print_debug("winning moves: %s" % str(winning_moves))
			print_debug("forced moves: %s" % str(forced_moves))
			print_debug("good moves: %s" % str(good_moves))
			print_debug("neutral moves: %s" % str(neutral_moves))
			print_debug("bad moves: %s" % str(bad_moves))
			if not winning_moves.is_empty():
				return winning_moves.pick_random()
			elif not forced_moves.is_empty():
				return forced_moves.pick_random()
			elif not good_moves.is_empty():
				return good_moves.pick_random()
			elif not neutral_moves.is_empty():
				return neutral_moves.pick_random()
			elif not bad_moves.is_empty():
				return bad_moves.pick_random()
			else:
				assert(not losing_moves.is_empty(), "bad moves and losing moves should not be both empty")
				return losing_moves.pick_random()
		Personality.Godlike:
			var max_score = -100
			var max_score_col = []
			for m in moves:
				if not m:
					continue
				if m.score > max_score:
					max_score = m.score
					max_score_col = [m.col]
				elif m.score == max_score:
					max_score_col.push_back(m.col)
			return max_score_col.pick_random()
		_:
			assert(false, "unknown personality")
	return -1
