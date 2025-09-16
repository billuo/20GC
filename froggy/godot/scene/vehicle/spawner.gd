extends Node3D

const TRUCK := preload("res://scene/vehicle/truck.tscn")

@export var direction: Vector3 = Vector3.RIGHT
@export var speed: float = 5.0
@export var interval: float = 2.0
@export var phase: float = 0.0
@export var vehicles: Array[PackedScene] = []

var _idx := 0


func start_spawn():
	if vehicles.is_empty():
		push_error("No vehicle to spawn")
		return
	get_tree().create_timer(phase, false).timeout.connect(_spawn)


func _spawn():
	var vehicle: Area3D = vehicles[_idx].instantiate()
	_idx = (_idx + 1) % vehicles.size()
	add_child(vehicle)
	vehicle.direction = direction
	vehicle.look_at(vehicle.global_position + direction, Vector3.UP, true)
	vehicle.collision_mask = 0x02
	vehicle.body_entered.connect(_on_body_entered)
	get_tree().create_timer(interval, false).timeout.connect(_spawn)


func _on_body_entered(body: Node3D):
	assert(body is Player)
	(body as Player).die_to_car()
