extends Node3D

const COLLISION_MASK_PLAYER := 0x02

@export var direction: Vector3 = Vector3.RIGHT
@export var speed: float = 5.0
@export var interval: float = 2.0
@export var phase: float = 0.0
@export var floating_objects: Array[PackedScene] = []

var _idx := 0


func start_spawn():
	if floating_objects.is_empty():
		push_error("No floating object to spawn")
		return
	get_tree().create_timer(phase, false).timeout.connect(_spawn)


func _spawn():
	var obj: FloatingObject = floating_objects[_idx].instantiate()
	_idx = (_idx + 1) % floating_objects.size()
	add_child(obj)
	obj.direction = direction
	obj.speed = speed
	obj.look_at(obj.global_position + direction, Vector3.UP, true)
	obj.collision_mask = COLLISION_MASK_PLAYER
	obj.body_entered.connect(obj._on_body_entered)
	obj.body_exited.connect(obj._on_body_exited)
	get_tree().create_timer(interval, false).timeout.connect(_spawn)
