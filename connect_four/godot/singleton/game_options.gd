extends Node

enum Mode {
	SinglePlayer,
	TwoPlayers,
	NoPlayer,
}

enum AIDifficulty {
	Drunk,    # basically choose randomly
	Normal,   # usually reasonable, but can make mistake
	Veteran,  # always choose a non-losing move if possible
	Godlike,  # always choose the optimal move
}

var mode: Mode
var ai_difficulty: AIDifficulty
