extends Node2D

var animation_finished := false
var audio_finished := false


func _free_if_all_finished():
	if animation_finished and audio_finished:
		queue_free()


func _on_audio_stream_player_2d_finished() -> void:
	animation_finished = true
	_free_if_all_finished()


func _on_animated_sprite_2d_animation_finished() -> void:
	audio_finished = true
	_free_if_all_finished()
