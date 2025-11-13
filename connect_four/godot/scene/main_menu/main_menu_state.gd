class_name MainMenuState
extends Resource

const DEFAULT_PATH := "user://main_menu_state.tres"

@export var n_players_selected_index: int
@export var initiative_selected_index: int
@export var ai_difficulty_1_selected_index: int
@export var ai_difficulty_2_selected_index: int


static func load_from_fs(path: String = DEFAULT_PATH) -> MainMenuState:
	if not FileAccess.file_exists(path):
		return null

	var state = ResourceLoader.load(path, "MainMenuState")
	if not state:
		push_error("Failed to load save from %s" % path)
	return state


static func save_to_fs(state: MainMenuState, path: String = DEFAULT_PATH):
	var err = ResourceSaver.save(state, path)
	if err != OK:
		push_error("Failed to save state to %s: %s" % [path, error_string(err)])
