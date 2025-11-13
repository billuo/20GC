extends Node

enum Mode {
	SinglePlayer,
	TwoPlayers,
	NoPlayer,
}
enum Initiative {
	Random,
	Human,
	Computer,
}
enum AIDifficulty {
	Drunk,  # basically choose randomly
	Normal,  # usually reasonable, but can make mistake
	Veteran,  # always choose a non-losing move if possible
	Godlike,  # always choose the optimal move
}

var mode: Mode
var initiative: Initiative
var ai_difficulty_1: AIDifficulty
var ai_difficulty_2: AIDifficulty
