extends Node

const ARENA_SCENE := preload("res://scene/arena/arena.tscn")
const MAIN_MENU_SCENE := preload("res://scene/main_menu/main_menu.tscn")

var arena_config := Arena.Config.new()
var world_interface := WorldInterface.new()


func new_game():
	get_tree().change_scene_to_packed(ARENA_SCENE)


func main_menu():
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)


class WorldInterface:
	var ball_position: Vector2
	var ball_velocity: Vector2
	var round_start: float
