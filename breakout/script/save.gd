class_name Save
extends Resource

@export var high_score := 0

const DEFAULT_SAVE_PATH := "user://save.tres"


static func load_from_fs(path: String = DEFAULT_SAVE_PATH) -> Save:
	if not FileAccess.file_exists(path):
		print_debug("Save does not exist, creating a new one")
		return Save.new()

	var save = ResourceLoader.load(path, "Save")
	if not save:
		push_error("Failed to load save from %s" % path)
	else:
		print_debug("Loaded")
	return save


static func save_to_fs(save: Save, path: String = DEFAULT_SAVE_PATH):
	var err = ResourceSaver.save(save, path)
	if err != OK:
		push_error("Failed to save save to %s: %s" % [path, error_string(err)])
	else:
		print_debug("Saved")
