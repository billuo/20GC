extends Node2D

@onready var ball: Ball = $Ball
@onready var paddle: Paddle = $Paddle


func _ready() -> void:
	ball.lock_to_paddle(paddle)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("serve_ball"):
		ball.serve()
