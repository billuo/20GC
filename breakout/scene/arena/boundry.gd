class_name Boundry
extends StaticBody2D


func on_hit(_ball: Ball):
	$AudioStreamPlayer2D.play()
