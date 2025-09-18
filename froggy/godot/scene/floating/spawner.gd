extends PeriodicSpawner

@export var direction: Vector3 = Vector3.RIGHT
@export var speed: float = 5.0
@export var floating_objects: Array[PackedScene] = []

var _idx := 0


func spawn_once(_preprocess := 0.0):
	var obj: FloatingObject = floating_objects[_idx].instantiate()
	_idx = (_idx + 1) % floating_objects.size()
	add_child(obj)
	obj.direction = direction
	obj.speed = speed
	obj.look_at(obj.global_position + direction, Vector3.UP, true)
	obj.collision_mask = Global.COLLISION_MASK_PLAYER
	obj.body_entered.connect(obj._on_body_entered)
	obj.body_exited.connect(obj._on_body_exited)
	obj.position += _preprocess * (direction * speed)
