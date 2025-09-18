extends Node

const MAIN_MENU_SCENE := preload("res://scene/ui/main_menu/main_menu.tscn")
const LEVEL_SCENE := preload("res://scene/level/level.tscn")


func switch_to_main_menu():
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)


func switch_to_level():
	get_tree().change_scene_to_packed(LEVEL_SCENE)
