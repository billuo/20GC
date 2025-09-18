extends Node3D

const COLLISION_MASK_PLAYER := 0x02

@export var direction: Vector3 = Vector3.RIGHT
@export var speed: float = 5.0
@export var interval: float = 2.0
@export var phase: float = 0.0
## Time in seconds to spawn entities in advance, similar to "preprocess" for particles.
@export var prespawn: float = 0.0
@export var vehicles: Array[PackedScene] = []

var _idx := 0


func start_spawn():
	if vehicles.is_empty():
		push_error("No vehicle to spawn")
		return

	var init_delay = fmod(phase, interval)
	if init_delay < 0:
		init_delay += interval

	var t = prespawn - init_delay
	while t > 0:
		_spawn_once(t)
		t -= interval
	get_tree().create_timer(-t, false).timeout.connect(_spawn_loop)


func _spawn_loop():
	_spawn_once()
	get_tree().create_timer(interval, false).timeout.connect(_spawn_loop)


func _spawn_once(preprocess := 0.0):
	var vehicle: Vehicle = vehicles[_idx].instantiate()
	_idx = (_idx + 1) % vehicles.size()
	add_child(vehicle)
	vehicle.direction = direction
	vehicle.speed = speed
	vehicle.look_at(vehicle.global_position + direction, Vector3.UP, true)
	vehicle.collision_mask = COLLISION_MASK_PLAYER
	vehicle.body_entered.connect(vehicle._on_body_entered)
	vehicle.position += preprocess * (direction * speed)
