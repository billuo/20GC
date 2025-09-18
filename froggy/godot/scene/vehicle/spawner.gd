extends PeriodicSpawner

@export var direction: Vector3 = Vector3.RIGHT
@export var speed: float = 5.0
@export var vehicles: Array[PackedScene] = []

var _idx := 0


func spawn_once(_preprocess := 0.0):
	var vehicle: Vehicle = vehicles[_idx].instantiate()
	_idx = (_idx + 1) % vehicles.size()
	add_child(vehicle)
	vehicle.direction = direction
	vehicle.speed = speed
	vehicle.look_at(vehicle.global_position + direction, Vector3.UP, true)
	vehicle.collision_mask = Global.COLLISION_MASK_PLAYER
	vehicle.body_entered.connect(vehicle._on_body_entered)
	vehicle.position += _preprocess * (direction * speed)
