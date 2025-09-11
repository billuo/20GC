class_name Brick
extends Node2D

signal destroyed(brick: Brick)

const DEFAULT_SIZE := Vector2(80, 20)

@export var color := Color.WHITE:
	set = set_color
@export var size := DEFAULT_SIZE:
	set = set_size
@export var max_hits := 1
@export var score := 100

var _hits := 0


func set_size(value: Vector2):
	size = value
	$ColorRect.position = -size / 2
	$ColorRect.size = size
	$CollisionShape2D.shape.size = size
	($ColorRect.material as ShaderMaterial).set_shader_parameter("brick_size", size)


func set_color(value: Color):
	color = value
	$ColorRect.color = color


func on_hit(_ball: Ball):
	_hits += 1
	modulate.a = 1.0 - _hits / float(max_hits)
	if _hits >= max_hits:
		var sfx = $BreakSound
		sfx.reparent(get_viewport())
		sfx.finished.connect(func(): sfx.queue_free())
		sfx.play()
		_destroy()
	else:
		$HitSound.play()


func _destroy():
	get_parent().remove_child(self)
	queue_free()
	destroyed.emit(self)
