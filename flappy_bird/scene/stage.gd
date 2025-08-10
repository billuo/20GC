extends Node2D

const OBSTACLE_SCENE := preload("res://scene/obstacle.tscn")

var speed := 300  ## how fast the player seems to advance
var min_obstacle_gap := 300
var max_obstacle_gap := 500
var next_obstacle_gap := 400

@onready var player: Player = $Player
@onready var obstacles: Node2D = $Obstacles


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 10 == 0:
		try_spawn_obstacle()
	if not player.is_on_floor():
		var player_v = player.velocity + Vector2.RIGHT * speed
		player.rotation = player_v.angle()
	else:
		player.rotation = 0


func try_spawn_obstacle():
	var max_obstacle_x := 0
	for o in obstacles.get_children():
		max_obstacle_x = max(max_obstacle_x, o.position.x)
	if max_obstacle_x + next_obstacle_gap < 1600:
		spawn_obstacle()
		next_obstacle_gap = randi_range(min_obstacle_gap, max_obstacle_gap)


func spawn_obstacle():
	var o = OBSTACLE_SCENE.instantiate()
	o.velocity = Vector2.LEFT * speed
	o.hit_player.connect(_on_hit_player)
	o.position.x = 1600
	$Obstacles.add_child(o)


func _on_hit_player(o: Obstacle):
	print("Player hit %s" % o)
