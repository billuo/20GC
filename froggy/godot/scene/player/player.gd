class_name Player
extends CharacterBody3D

signal finished
signal died

enum State {
	Idle,
	Moving,
	Finished,
	Hit,
	Eaten,
	Drowning,
}

@export var level: Level
@export var level_grid: GridMap

var _state := State.Idle:
	set = set_state
var _command_queue_mutex: Mutex = Mutex.new()
var _command_queue: Array[Vector2] = []
var _pressed: Array[bool] = [false, false, false, false]  # forward, backward, left, right
var _platform: FloatingObject
var _in_water := false

@onready var _jump_sound := $JumpSound


func _input(event: InputEvent) -> void:
	if _state == State.Idle or _state == State.Moving:
		if event.is_action_type():
			_command_queue_mutex.lock()
			if event.is_action("move_forward"):
				if event.is_pressed() and not _pressed[0]:
					_command_queue.push_back(Vector2.UP)
				_pressed[0] = event.is_pressed()
			elif event.is_action("move_backward"):
				if event.is_pressed() and not _pressed[1]:
					_command_queue.push_back(Vector2.DOWN)
				_pressed[1] = event.is_pressed()
			if event.is_action("move_left"):
				if event.is_pressed() and not _pressed[2]:
					_command_queue.push_back(Vector2.LEFT)
				_pressed[2] = event.is_pressed()
			elif event.is_action("move_right"):
				if event.is_pressed() and not _pressed[3]:
					_command_queue.push_back(Vector2.RIGHT)
				_pressed[3] = event.is_pressed()
			_command_queue_mutex.unlock()


func _physics_process(_delta: float) -> void:
	match _state:
		State.Idle:
			if _in_water and not _platform:
				_state = State.Drowning
				var tween = create_tween()
				tween.tween_property(self, "position", position + Vector3.DOWN, 0.5)
				tween.finished.connect(die)
				return

			if out_of_bound():
				get_eaten()
				return

			if _platform:
				velocity = _platform.direction * _platform.speed
			else:
				velocity = Vector3.ZERO
			_command_queue_mutex.lock()
			if not _command_queue.is_empty():
				var dir = _command_queue.pop_front()
				move_one_tile(dir)
			_command_queue_mutex.unlock()

		State.Moving:
			velocity = Vector3.ZERO
		State.Finished:
			velocity = Vector3.ZERO
		State.Hit:
			velocity = Vector3.ZERO
		State.Eaten:
			pass
		State.Drowning:
			velocity = Vector3.ZERO

	move_and_slide()


func set_state(value: State):
	_state = value
	# print_debug("Player State: %s" % _state)


func move_one_tile(direction: Vector2) -> void:
	if _state != State.Idle:
		return
	_jump_sound.play()
	const JUMP_HEIGHT := 1.0
	const JUMP_DURATION := 0.1
	_state = State.Moving
	var size = level_grid.cell_size
	var delta = Vector2(size.x * direction.x, size.z * direction.y)
	var midpoint = Vector3(position.x + delta.x / 2.0, position.y + JUMP_HEIGHT, position.z + delta.y / 2.0)
	var target_pos = Vector3(position.x + delta.x, position.y, position.z + delta.y)
	var cur_cell_pos = get_cell_pos()
	var target_cell_pos = Vector3i(cur_cell_pos.x + direction.x, cur_cell_pos.y, cur_cell_pos.z + direction.y)
	look_at(target_pos)
	var tween = create_tween()
	if level.can_move_to(target_cell_pos):
		tween.tween_property(self, "position", midpoint, JUMP_DURATION / 2.0)
		tween.tween_property(self, "position", target_pos, JUMP_DURATION / 2.0).from(midpoint)
	else:
		tween.tween_property(self, "position", midpoint, JUMP_DURATION / 2.0)
		tween.tween_property(self, "position", position, JUMP_DURATION / 2.0).from(midpoint)
	tween.finished.connect(finish_move)


func get_cell_pos() -> Vector3i:
	var v = level_grid.to_local(global_position)
	var size = level_grid.cell_size
	var x = int(floor(v.x / size.x))
	var y = 0
	var z = int(floor(v.z / size.z))
	return Vector3i(x, y, z)


func finish_move():
	var idx = level_grid.get_cell_item(get_cell_pos())
	if idx == GridMap.INVALID_CELL_ITEM:
		get_eaten()
		return
	var item_name = level_grid.mesh_library.get_item_name(idx)
	_in_water = item_name == "Water"
	match item_name:
		"WaterLilypad":
			level.timer_running = false
			_state = State.Finished
			var tween = create_tween()
			tween.parallel().tween_property(self, "rotation:y", rotation.y + PI, 0.5).set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_CUBIC)
			var goal_center = (Vector3(get_cell_pos()) + Vector3.ONE * 0.5) * level_grid.cell_size
			tween.parallel().tween_property(self, "position", goal_center, 0.2)
			tween.tween_interval(0.5)
			var on_finish = func():
				level.timer_running = true
				finished.emit()
			tween.finished.connect(on_finish)
		_:
			_state = State.Idle


func out_of_bound() -> bool:
	var idx = level_grid.get_cell_item(get_cell_pos())
	# if idx != GridMap.INVALID_CELL_ITEM:
	# print_debug("%s: %s" % [get_cell_pos(), level_grid.mesh_library.get_item_name(idx)])
	return idx == GridMap.INVALID_CELL_ITEM


func die():
	died.emit()
	hide()
	queue_free()


func hit_by_car():
	_state = State.Hit
	die()


func get_eaten():
	# TODO: animate a bird
	_state = State.Eaten
	_platform = null
	velocity = -get_gravity().normalized() * 20
	get_tree().create_timer(1.0).timeout.connect(die)


func platform_enter(obj: FloatingObject):
	match _state:
		State.Idle, State.Moving:
			_platform = obj


func platform_exit(obj: FloatingObject):
	match _state:
		State.Idle, State.Moving:
			if _platform == obj:
				_platform = null


func get_grass_avoidance_radius() -> float:
	return 1.5
