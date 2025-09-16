class_name Level
extends Node3D

const PLAYER_SCENE := preload("res://scene/player/player.tscn")

@onready var pcam: PhantomCamera3D = $PhantomCamera3D
@onready var grid_map: GridMap = $GridMap

var player: Player
var needs_finished: int
var finished_players: Array[Player] = []
var lives := 3


func _ready() -> void:
	var idx = grid_map.mesh_library.find_item_by_name("WaterLilypad")
	assert(idx != -1)
	needs_finished = grid_map.get_used_cells_by_item(idx).size()
	assert(needs_finished != 0)
	print_debug("Needs %d players" % needs_finished)
	spawn_player()
	for node in $VehicleSpawners.get_children():
		node.start_spawn()


func next_player_or_win():
	print_debug("finished")
	finished_players.push_back(player)
	if finished_players.size() >= needs_finished:
		print_debug("LEVEL CLEAR")
		pcam.follow_mode = PhantomCamera3D.FollowMode.GROUP
		# BUG: upstream: the following line doesn't work???
		# pcam.follow_targets = finished_players.map(func(x): return x as Node3D) as Array[Node3D]
		var targets: Array[Node3D] = []
		for p in finished_players:
			targets.push_back(p as Node3D)
		pcam.follow_targets = targets
	else:
		spawn_player()


func next_player_or_lose():
	print_debug("died")
	player.queue_free()
	player = null
	if lives <= 0:
		print_debug("GAME OVER")
	else:
		lives -= 1
		spawn_player()


func spawn_player():
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(1, 0, 1)
	player.level_grid = grid_map
	player.finished.connect(next_player_or_win)
	player.died.connect(next_player_or_lose)
	add_child(player)
	pcam.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
	pcam.follow_target = player


func _on_floor_limit_body_entered(body: Node3D) -> void:
	if body is Player:
		next_player_or_lose()


func _on_side_limit_area_entered(area: Area3D) -> void:
	if area is Vehicle:
		area.queue_free()
