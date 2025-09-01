extends Node2D

const BALL_SCENE := preload("res://scene/ball.tscn")
const MAX_BALLS := 1024

@onready var balls: Node2D = $Balls
@onready var paddle: Paddle = $Paddle
@onready var bricks: Node2D = $Bricks

var _score: int = 0:
	set = set_score
var _highscore: int = 0:
	set = set_highscore
var _lives: int = 3:
	set = set_lives


func _ready() -> void:
	_load_game()
	init_level()
	for ball in balls.get_children():
		ball.lock_to_paddle(paddle)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("serve_ball"):
		for ball in balls.get_children():
			if ball.can_serve():
				ball.serve()
	if OS.is_debug_build() and event is InputEventKey and event.is_pressed():
		event = event as InputEventKey
		match event.keycode:
			KEY_F1:
				# break all bricks
				for brick in bricks.get_children():
					brick = brick as Brick
					assert(brick)
					brick._destroy()
			KEY_BRACKETLEFT:
				paddle.set_length_animated(paddle.length * 0.9)
			KEY_BRACKETRIGHT:
				if event.get_modifiers_mask() & KEY_MASK_SHIFT:
					paddle.set_length_animated(1600, 10000.0)
				else:
					paddle.set_length_animated(paddle.length / 0.9)
			KEY_EQUAL:
				if event.get_modifiers_mask() & KEY_MASK_SHIFT:
					for ball in balls.get_children():
						ball.max_speed = 10000
						ball._speed = 10000
				else:
					for ball in balls.get_children():
						ball.max_speed += 100
						ball._speed += 100
			KEY_MINUS:
				if event.get_modifiers_mask() & KEY_MASK_SHIFT:
					for ball in balls.get_children():
						ball.max_speed = 1000
						ball._speed = 100
				else:
					for ball in balls.get_children():
						ball.max_speed = max(100, ball.max_speed - 100)
						ball._speed = max(100, ball._speed - 100)
			KEY_M:
				# M for multiply
				var new_balls = []
				for ball in balls.get_children():
					ball = ball as Ball
					assert(ball)
					if ball.has_escaped():
						continue
					var new_ball = BALL_SCENE.instantiate()
					var angle = randf_range(PI / 9.0, PI / 3.0)
					var v1 = ball.velocity.rotated(angle)
					var v2 = ball.velocity.rotated(-angle)
					ball.velocity = v1
					new_ball.velocity = v2
					new_ball.position = ball.position
					new_balls.append(new_ball)
				for new_ball in new_balls:
					balls.add_child(new_ball)
					new_ball.serve()

				var all_balls = balls.get_children()
				while all_balls.size() > MAX_BALLS:
					var i = randi_range(0, all_balls.size() - 1)
					all_balls[i].queue_free()
					all_balls.remove_at(i)


func init_level():
	const BRICK_SCENE := preload("res://scene/brick.tscn")
	const BRICK_SIZE := Vector2(80, 20)
	var gap = Vector2(8, 8)
	var count = Vector2(8, 6)
	var start_x = (Global.VIEWPORT_WIDTH - count.x * BRICK_SIZE.x - (count.x - 1) * gap.x) / 2 + BRICK_SIZE.x / 2
	var start_y = (Global.VIEWPORT_HEIGHT - count.y * BRICK_SIZE.y - (count.y - 1) * gap.y) / 2 + BRICK_SIZE.y / 2 - 200
	for i in range(count.x):
		for j in range(count.y):
			# if i != 0 and j != 0 and i != count.x - 1 and j != count.y - 1:
			# 	continue
			var x = start_x + i * (BRICK_SIZE.x + gap.x)
			var y = start_y + j * (BRICK_SIZE.y + gap.y)
			var brick = BRICK_SCENE.instantiate()
			brick.position = Vector2(x, y)
			brick.destroyed.connect(_on_brick_destroyed)
			if j < 1:
				brick.color = Color.RED
				brick.max_hits = 3
				brick.score = 300
			elif j < 3:
				brick.color = Color.YELLOW
				brick.max_hits = 2
				brick.score = 200
			else:
				brick.color = Color.GREEN
				brick.max_hits = 1
				brick.score = 100
			bricks.add_child(brick)

	%BricksLabel.text = "Bricks: %d" % bricks.get_child_count()


func finish_level():
	print_debug("CLEAR")
	var all_balls = balls.get_children()
	all_balls[0].lock_to_paddle(paddle)
	for ball in all_balls.slice(1):
		ball.queue_free()
	# TODO: create more levels
	init_level.call_deferred()
	_save_game()


func fail_level():
	# TODO: main menu?
	print_debug("GAME OVER")
	_save_game()


func set_score(value: int):
	_score = value
	if _score > _highscore:
		_highscore = _score
		# TODO: show congrats for new highscore
	%ScoreLabel.text = "Score: %06d" % _score


func set_highscore(value: int):
	_highscore = value
	%HighscoreLabel.text = "Highscore: %06d" % _highscore


func set_lives(value: int):
	_lives = value
	%LivesLabel.text = "Lives: %d" % _lives


func _load_game():
	var save = Save.load_from_fs()
	_highscore = save.high_score


func _save_game():
	var save = Save.new()
	save.high_score = _highscore
	Save.save_to_fs(save)


func _on_ball_escaped() -> void:
	for ball in balls.get_children():
		if not ball.has_escaped():
			return
	# if all balls have escaped, lose a live and start a new round
	if _lives <= 0:
		fail_level()
		return
	_lives -= 1
	var ball = BALL_SCENE.instantiate()
	balls.add_child(ball)
	ball.lock_to_paddle(paddle)


func _on_ball_hit_top() -> void:
	paddle.set_length_animated(paddle.length - 2.0)


func _on_brick_destroyed(brick: Brick) -> void:
	# TODO: random power-ups
	# TODO: paddle length
	paddle.set_length_animated(paddle.length + 10.0)
	_score += brick.score
	var remaining = bricks.get_child_count()
	%BricksLabel.text = "Bricks: %d" % remaining
	if remaining == 0:
		finish_level()
