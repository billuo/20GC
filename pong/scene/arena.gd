class_name Arena
extends Node2D

# TODO:
# 1. define max score of a game (BO9, etc)
# 2. highlight winner

const PAUSE_MENU_SCENE := preload("res://scene/pause_menu.tscn")
const SCORE_LABEL_MODULATE_DEFAULT = Color(1.0, 1.0, 1.0, 0.2)

@onready var paddle_left := $PaddleLeft
@onready var paddle_right := $PaddleRight
@onready var score_label_left := %ScoreLabelLeft
@onready var score_label_right := %ScoreLabelRight
@onready var ball := $Ball
@onready var round_label: Label = %RoundLabel
@onready var whistle := $Whistle
@onready var winner_label: Label = %WinnerLabel
@onready var prompt_label: Label = %PromptLabel

@onready var paddle_p1: Paddle
@onready var paddle_p2: Paddle
@onready var score_label_p1: Label
@onready var score_label_p2: Label

var p1_score := 0:
	set = set_p1_score
var p2_score := 0:
	set = set_p2_score
var round_number := 1:
	set = set_round_number
var round_server: Paddle
var game_is_over := false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		get_tree().paused = true
		var menu = PAUSE_MENU_SCENE.instantiate()
		$UILayer.add_child(menu)

	var k = event as InputEventKey
	if game_is_over and k and k.is_pressed():
		if k.keycode == KEY_ENTER:
			Game.main_menu()
	if OS.is_debug_build() and k and k.is_pressed():
		match k.keycode:
			KEY_BRACKETLEFT:
				p1_score += 1
			KEY_BRACKETRIGHT:
				p2_score += 1


func _ready() -> void:
	seed(round(Time.get_unix_time_from_system() * 1000))
	new_game()
	score_label_p1.modulate = SCORE_LABEL_MODULATE_DEFAULT
	score_label_p2.modulate = SCORE_LABEL_MODULATE_DEFAULT


func _process(_delta: float) -> void:
	if ball:
		Game.world_interface.ball_position = ball.global_position
		Game.world_interface.ball_velocity = ball.linear_velocity


func set_round_number(value: int):
	round_number = value
	round_label.text = "Round %d" % value
	var tween = round_label.create_tween()
	tween.tween_property(round_label, "modulate", Color.WHITE, 1.0).from(Color.WHITE)
	tween.tween_property(round_label, "modulate", Color.TRANSPARENT, 1.0).from(Color.WHITE)


func set_p1_score(value: int):
	var score_changed = p1_score != value
	p1_score = value
	_update_score_label(value, score_label_p1)
	if score_changed:
		next_round_or_end()


func set_p2_score(value: int):
	var score_changed = p1_score != value
	p2_score = value
	_update_score_label(value, score_label_p2)
	if score_changed:
		next_round_or_end()


func new_game():
	game_is_over = false
	if not Game.arena_config:
		paddle_left.controller = Paddle.Controller.Player1
		paddle_right.controller = Paddle.Controller.Player2
	else:
		paddle_left.controller = Game.arena_config.left_control
		paddle_right.controller = Game.arena_config.right_control
	paddle_p1 = paddle_left
	paddle_p2 = paddle_right
	score_label_p1 = score_label_left
	score_label_p2 = score_label_right
	winner_label.hide()
	prompt_label.hide()

	p1_score = 0
	p2_score = 0
	round_number = 1
	if randi() % 2 == 0:
		round_server = paddle_p1
	else:
		round_server = paddle_p2
	paddle_p1.path_follow.progress_ratio = 0.5
	paddle_p2.path_follow.progress_ratio = 0.5
	paddle_p1.on_round_start(paddle_p1 == round_server)
	paddle_p2.on_round_start(paddle_p2 == round_server)
	Game.world_interface.round_start = Time.get_unix_time_from_system()


func next_round_or_end():
	var score = Game.arena_config.target_score
	if score > 0:
		if p1_score >= score:
			# p1 wins
			game_over(paddle_p1)
			return
		elif p2_score >= score:
			# p2 wins
			game_over(paddle_p2)
			return

	if round_number != 0:
		whistle.play()
	round_number += 1
	ball.reset()
	paddle_p1.on_round_start(paddle_p1 == round_server)
	paddle_p2.on_round_start(paddle_p2 == round_server)
	Game.world_interface.round_start = Time.get_unix_time_from_system()


func restart_round():
	round_number = round_number
	ball.reset()
	paddle_p1.on_round_start(paddle_p1 == round_server)
	paddle_p2.on_round_start(paddle_p2 == round_server)
	Game.world_interface.round_start = Time.get_unix_time_from_system()


func game_over(winner: Paddle):
	game_is_over = true
	ball.set_deferred("freeze", true)
	whistle.play()
	get_tree().create_timer(0.25).timeout.connect(func(): whistle.play())
	get_tree().create_timer(0.50).timeout.connect(func(): whistle.play())
	# TODO:
	if winner == paddle_p1:
		_show_winner("P1")
	else:
		_show_winner("P2")


func _on_area_2d_player_1_home_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		round_server = paddle_p1
		p2_score += 1


func _on_area_2d_player_2_home_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		round_server = paddle_p2
		p1_score += 1


func _on_paddle_player_1_ball_served() -> void:
	if round_server == paddle_p1:
		var dir: Vector2 = paddle_p2.global_position - ball.global_position
		ball.serve(dir.normalized())


func _on_paddle_player_2_ball_served() -> void:
	if round_server == paddle_p2:
		var dir: Vector2 = paddle_p1.global_position - ball.global_position
		ball.serve(dir.normalized())


func _on_ball_stucked() -> void:
	restart_round()


func _on_ball_out_of_bound() -> void:
	if ball.global_position.x < 0:
		round_server = paddle_p1
		p2_score += 1
	elif ball.global_position.x > 1600:
		round_server = paddle_p2
		p1_score += 1


func _update_score_label(score: int, label: Label):
	label.text = str(score)
	label.modulate = Color.WHITE
	assert(is_inside_tree())
	var tween = create_tween()
	tween.tween_property(label, "modulate", SCORE_LABEL_MODULATE_DEFAULT, 0.5)


func _show_winner(winner: String):
	winner_label.text = "A winner is %s" % winner
	winner_label.show()
	prompt_label.show()


class Config:
	var left_control: Paddle.Controller
	var right_control: Paddle.Controller
	var target_score: float
