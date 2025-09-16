class_name Player
extends CharacterBody3D

signal finished
signal died

const MAX_FALLING_SPEED := 10.0
const INITIAL_FALLING_SPEED := 5.0

enum State {
	Idle,
	Moving,
	Finished,
	Hit,
	Falling,
	Drowning,
}

@export var level_grid: GridMap

var _state := State.Idle
var _command_queue_mutex: Mutex = Mutex.new()
var _command_queue: Array[Vector2] = []


func _input(event: InputEvent) -> void:
	if _state == State.Idle or _state == State.Moving:
		if event.is_action_type() and event.is_pressed():
			_command_queue_mutex.lock()
			if event.is_action("move_forward"):
				_command_queue.push_back(Vector2.UP)
			elif event.is_action("move_backward"):
				_command_queue.push_back(Vector2.DOWN)
			if event.is_action("move_left"):
				_command_queue.push_back(Vector2.LEFT)
			elif event.is_action("move_right"):
				_command_queue.push_back(Vector2.RIGHT)
			_command_queue_mutex.unlock()


func move_one_tile(direction: Vector2) -> void:
	if _state != State.Idle:
		return
	const JUMP_HEIGHT := 1.0
	const JUMP_DURATION := 0.1
	_state = State.Moving
	var size = level_grid.cell_size
	var delta = Vector2(size.x * direction.x, size.z * direction.y)
	var midpoint = Vector3(position.x + delta.x / 2.0, position.y + JUMP_HEIGHT, position.z + delta.y / 2.0)
	var target_pos = Vector3(position.x + delta.x, position.y, position.z + delta.y)
	var tween = create_tween()
	tween.tween_property(self, "position", midpoint, JUMP_DURATION / 2.0)
	tween.tween_property(self, "position", target_pos, JUMP_DURATION / 2.0).from(midpoint)
	tween.finished.connect(finish_move)


func get_cell_pos() -> Vector3i:
	var v = level_grid.to_local(global_position)
	var size = level_grid.cell_size
	var x = int(floor(v.x / size.x))
	var y = 0
	var z = int(floor(v.z / size.z))
	return Vector3i(x, y, z)


func finish_move():
	assert(level_grid)
	var idx = level_grid.get_cell_item(get_cell_pos())
	if idx == GridMap.INVALID_CELL_ITEM:
		_state = State.Falling
		velocity = get_gravity() * INITIAL_FALLING_SPEED
	else:
		var item_name = level_grid.mesh_library.get_item_name(idx)
		match item_name:
			"WaterLilypad":
				_state = State.Finished
				finished.emit()
			_:
				_state = State.Idle


func die_to_car():
	_state = State.Hit
	died.emit()


func _physics_process(delta: float) -> void:
	_command_queue_mutex.lock()
	if _state == State.Idle and not _command_queue.is_empty():
		var dir = _command_queue.pop_front()
		move_one_tile(dir)
	_command_queue_mutex.unlock()
	if _state == State.Falling:
		velocity += get_gravity() * delta
		if velocity.length() > MAX_FALLING_SPEED:
			velocity = velocity.normalized() * MAX_FALLING_SPEED
	move_and_slide()
