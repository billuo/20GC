extends Node2D

const VIEWPORT_WIDTH := 1600
const OBSTACLE_SCENE := preload("res://scene/obstacle/obstacle.tscn")
const STAGE_SCENE := preload("res://scene/stage/stage.tscn")

var speed := 0.0:
	set = set_speed  ## how fast the _player seems to advance
var min_obstacle_gap := 300
var max_obstacle_gap := 500
var next_obstacle_gap := 400

var _game_is_over := false
var _score := 0
var _high_score := 0:
	set = set_high_score
@onready var _player: Player = $Player
@onready var _obstacles: Node2D = $Obstacles
@onready var _score_label: Label = %ScoreLabel
@onready var _high_score_label: Label = %HighScoreLabel


func _ready() -> void:
	# load high score
	var save = Save.load_from_fs()
	_high_score = save.high_score

	game_start()


func _unhandled_input(event: InputEvent) -> void:
	# TODO:
	if _game_is_over and event.is_action_pressed("restart"):
		get_tree().change_scene_to_packed(STAGE_SCENE)


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 10 == 0:
		try_spawn_obstacle()
	if not _player.is_on_floor():
		var player_v = _player.velocity + Vector2.RIGHT * speed
		_player.rotation = player_v.angle()
	else:
		_player.rotation = 0
	for o in _obstacles.get_children():
		if o.just_passed(_player):
			_increase_score(1)


func game_start():
	speed = 300.0
	%GameOverLabel.hide()
	%RestartLabel.hide()


func game_over():
	if _game_is_over:
		return
	_game_is_over = true

	# save high score
	var save = Save.new()
	save.high_score = _high_score
	Save.save_to_fs(save)

	speed = 0.0
	_player.die()
	$GameOverSound.play()
	%GameOverLabel.show()
	%RestartLabel.show()


func set_speed(value: float):
	$Parallax/Background.autoscroll.x = -value / 3.0
	$Parallax/Floor.autoscroll.x = -value
	$Parallax/ForegroundWater.autoscroll.x = -value - 100.0
	for o in _obstacles.get_children():
		o.velocity = Vector2(-value, 0.0)
	speed = value


func set_high_score(value: int):
	_high_score = value
	_high_score_label.text = "HiScore %05d" % _high_score


func try_spawn_obstacle():
	var max_obstacle_x := 0
	for o in _obstacles.get_children():
		max_obstacle_x = max(max_obstacle_x, o.position.x)
	if max_obstacle_x + next_obstacle_gap < VIEWPORT_WIDTH:
		spawn_obstacle()
		next_obstacle_gap = randi_range(min_obstacle_gap, max_obstacle_gap)


func spawn_obstacle():
	var o = OBSTACLE_SCENE.instantiate()
	o.velocity = Vector2.LEFT * speed
	o.player_hit.connect(_on_player_hit)
	o.position.x = VIEWPORT_WIDTH
	$Obstacles.add_child(o)


func _increase_score(delta: int):
	_score += delta
	$ScoreSound.pitch_scale = randf_range(0.9, 1.1)
	$ScoreSound.play()
	_score_label.text = "Score %05d" % _score
	if _score > _high_score:
		_high_score = _score


func _on_player_hit(_node: Node2D):
	game_over()
