class_name GravitySource
extends Node2D

@export var mass := 100.0


func get_gravity_acc(other: Node2D):
	var rel = global_position - other.global_position
	var l = rel.length()
	var dir = rel / l
	l /= 100.0
	return mass / (l * l) * dir


func get_gravity_force(other: RigidBody2D):
	var rel = global_position - other.global_position
	var l = rel.length()
	var dir = rel / l
	l /= 100.0
	return other.mass * mass / (l * l) * dir
