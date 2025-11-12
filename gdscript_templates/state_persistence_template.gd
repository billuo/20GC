class_name State
extends Resource

const DEFAULT_PATH := "user://state.tres"

@export var value: int


static func load_from_fs(path: String = DEFAULT_PATH) -> State:
	if not FileAccess.file_exists(path):
		print_debug("State does not exist")
		return null

	var state = ResourceLoader.load(path, "State")
	if not state:
		push_error("Failed to load save from %s" % path)
	else:
		print_debug("Loaded")
	return state


static func save_to_fs(state: State, path: String = DEFAULT_PATH):
	var err = ResourceSaver.save(state, path)
	if err != OK:
		push_error("Failed to save state to %s: %s" % [path, error_string(err)])
	else:
		print_debug("Saved")
