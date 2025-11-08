class_name Solver
extends Node

signal solved

enum Method {
	Random,
	Score,
}

@export var method: Method

# which column to put down a piece
var solution: int


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
			var position = PackedByteArray()
			for pos in screen.piece_order:
				position.push_back(pos.x + 1)
			print_debug("position: %s" % position)
			# TODO: remove
			var non_full_cols = []
			for col in range(screen.SIZE.x):
				if screen.get_n_filled(col) != screen.SIZE.y:
					non_full_cols.push_back(col)
			solution = non_full_cols.pick_random()
			assert(solution != null)
			get_tree().create_timer(0.5).timeout.connect(solved.emit)
