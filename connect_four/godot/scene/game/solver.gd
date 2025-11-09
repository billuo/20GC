class_name Solver
extends Node

signal solved

enum Method {
	Random,
	Score,
}

@export var method: Method

# which column to put down a piece
var solution
var _solver := C4Solver.new()


func start_solve(screen: Screen):
	match method:
		Method.Random:
			var non_full_cols = []
			for col in range(screen.SIZE.x):
				if screen.get_n_filled(col) != screen.SIZE.y:
					non_full_cols.push_back(col)
			solution = non_full_cols.pick_random()
			assert(solution != null)
			get_tree().create_timer(0.5).timeout.connect(solved.emit)
		Method.Score:
			solution = null
			print_debug("current game: %s" % screen.get_moves_string())
			var analyzed_moves = _solver.analyze(screen.get_moves())
			var winning_moves := []
			var losing_moves := []
			var forced_moves := []
			var good_moves := []
			var neutral_moves := []
			var bad_moves := []
			for i in range(7):
				var m = analyzed_moves[i]
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
				solution = winning_moves.pick_random()
			elif not forced_moves.is_empty():
				solution = forced_moves.pick_random()
			elif not good_moves.is_empty():
				solution = good_moves.pick_random()
			elif not neutral_moves.is_empty():
				solution = neutral_moves.pick_random()
			elif not bad_moves.is_empty():
				solution = bad_moves.pick_random()
			elif not losing_moves.is_empty():
				solution = losing_moves.pick_random()
			assert(solution != null, "bad moves and losing moves should not be both empty")
			get_tree().create_timer(0.5).timeout.connect(solved.emit)
