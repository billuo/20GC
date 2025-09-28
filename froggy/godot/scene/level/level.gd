class_name Level
extends Node3D

const PLAYER_SCENE := preload("res://scene/player/player.tscn")
const FROG_ICON_SCENE := preload("res://scene/ui/frog_icon/frog_icon.tscn")

@export var player_spawn_position := Vector3i.ZERO

var player: Player
var total_lives := 8
var live_idx := 0
var needs_finished: int
var finished_players: Array[Player] = []
var timer_running := false
var time_elapsed := 0.0

@onready var pcam: PhantomCamera3D = $PhantomCamera3D
@onready var grid_map: GridMap = $GridMap
@onready var lives_counter := %LivesCounter
@onready var goal_counter: Label = %LivesCounter/CountLabel
@onready var time_label: Label = %Time
@onready var fps_label: Label = %FPSLabel
@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton

@onready var multi_grass_1: MultiMeshInstance3D = %MultiGrass1
@onready var multi_grass_2: MultiMeshInstance3D = %MultiGrass2
@onready var multi_grass_3: MultiMeshInstance3D = %MultiGrass3


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var pause_menu := preload("res://scene/ui/pause_menu/pause_menu.tscn").instantiate()
		pause_menu.on_restart = Game.switch_to_level
		pause_menu.on_exit = Game.switch_to_main_menu
		%UI.add_child(pause_menu)
	if event.is_action_pressed("toggle_vsync"):
		var mode = DisplayServer.window_get_vsync_mode()
		if mode == DisplayServer.VSYNC_ENABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			fps_label.show()
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			fps_label.hide()


func _ready() -> void:
	var idx = grid_map.mesh_library.find_item_by_name("WaterLilypad")
	assert(idx != -1)
	needs_finished = grid_map.get_used_cells_by_item(idx).size()
	assert(needs_finished != 0)
	goal_counter.text = "0/%d" % needs_finished
	total_lives = needs_finished + 3
	for i in range(total_lives):
		lives_counter.add_child(FROG_ICON_SCENE.instantiate())
	lives_counter.move_child(goal_counter, -1)

	spawn_player()
	for node in $VehicleSpawners.get_children():
		node.start_spawn()
	for node in $FloatingSpawners.get_children():
		node.start_spawn()

	timer_running = true
	restart_button.pressed.connect(Game.switch_to_level)
	exit_button.pressed.connect(Game.switch_to_main_menu)


func _physics_process(delta: float) -> void:
	if timer_running:
		time_elapsed += delta
		time_label.text = "%.2f" % time_elapsed
	if fps_label.visible:
		fps_label.text = "FPS:%.1f" % Engine.get_frames_per_second()


func next_player(last_has_finished: bool):
	var icon: FrogIcon = lives_counter.get_child(live_idx)
	if last_has_finished:
		icon.state = FrogIcon.State.Checked
		finished_players.push_back(player)
		goal_counter.text = "%d/%d" % [finished_players.size(), needs_finished]
	else:
		icon.state = FrogIcon.State.Crossed
	live_idx += 1
	if finished_players.size() >= needs_finished:
		end_level(true)
		pcam.follow_mode = PhantomCamera3D.FollowMode.GROUP
		# NOTE: https://github.com/godotengine/godot-proposals/discussions/7364
		# explains why the following line won't work.
		# pcam.follow_targets = finished_players.map(func(x): return x as Node3D) as Array[Node3D]
		pcam.follow_targets.clear()
		for p in finished_players:
			pcam.follow_targets.push_back(p as Node3D)
	elif total_lives - live_idx < needs_finished - finished_players.size():
		end_level(false)
	else:
		spawn_player()


func end_level(succeeded: bool):
	timer_running = false
	%LevelEnd.show()
	if succeeded:
		%LevelEnd/LevelResultLabel.text = "LEVEL CLEARED"
	else:
		%LevelEnd/LevelResultLabel.text = "LEVEL FAILED"


func spawn_player():
	assert(live_idx < total_lives)
	player = PLAYER_SCENE.instantiate()
	player.position = grid_map.cell_size * (Vector3(player_spawn_position) + Vector3(0.5, 0.0, 0.5))
	player.level = self
	player.level_grid = grid_map
	player.finished.connect(next_player.bind(true))
	player.died.connect(next_player.bind(false))
	add_child(player)
	pcam.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
	pcam.follow_target = player
	for multi in [multi_grass_1, multi_grass_2, multi_grass_3]:
		multi.avoid_objects.clear()
		multi.avoid_objects.append(player)


func can_move_to(cell_pos: Vector3i) -> bool:
	if cell_pos.z > 0:
		return false
	for p in finished_players:
		if p.get_cell_pos() == cell_pos:
			return false
	return true


func _on_floor_limit_body_entered(body: Node3D) -> void:
	if body is Player:
		next_player(false)


func _on_side_limit_area_entered(area: Area3D) -> void:
	if area is Vehicle:
		area.queue_free()
	elif area is FloatingObject:
		area.queue_free()
