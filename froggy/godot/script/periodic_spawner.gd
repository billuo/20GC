class_name PeriodicSpawner
extends Node3D

@export var interval: float = 2.0
@export var phase: float = 0.0
## Time in seconds to spawn entities in advance, similar to "preprocess" for particles.
@export var preprocess: float = 0.0


func start_spawn():
	var init_delay = fmod(phase, interval)
	if init_delay < 0:
		init_delay += interval

	var t = preprocess - init_delay
	while t > 0:
		spawn_once(t)
		t -= interval
	get_tree().create_timer(-t, false).timeout.connect(_spawn_loop)


## Virtual
func spawn_once(_preprocess := 0.0):
	pass


func _spawn_loop():
	spawn_once()
	get_tree().create_timer(interval, false).timeout.connect(_spawn_loop)
