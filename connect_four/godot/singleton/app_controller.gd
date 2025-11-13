# see also:
# https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
# https://felgo.com/doc/felgo-different-screen-sizes/
extends Node

const CONTENT_SCALE_DELTA = 0.25

@onready var base_resolution := get_base_resolution()
@onready var initial_window_size := get_initial_window_size()


func _ready() -> void:
	OS.set_environment("RUST_BACKTRACE", "1")
	# DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_fullscreen"):
		get_viewport().set_input_as_handled()
		toggle_fullscreen()
	elif event.is_action_pressed(&"take_screenshot"):
		get_viewport().set_input_as_handled()
		var t = Time.get_unix_time_from_system()
		var milli = int(fmod(t * 1000.0, 1000.0))
		var d = Time.get_datetime_dict_from_unix_time(t)
		var path = "user://screenshot-%d%d%d-%d%d%d-%d.png" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"], milli]
		get_viewport().get_texture().get_image().save_png(path)
		print_debug("screenshot saved to %s" % ProjectSettings.globalize_path(path))
	elif event.is_action_pressed(&"print_orphan_nodes"):
		print_orphan_nodes()


func request_exit() -> void:
	if OS.get_name() == "Web":
		return
	# Log.info_stack(["Exiting..."])
	get_tree().quit()


func is_fullscreen(wid: int = 0) -> bool:
	match DisplayServer.window_get_mode(wid):
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN:
			return true
		_:
			return false


func toggle_fullscreen(wid: int = 0) -> void:
	# read: https://github.com/godotengine/godot/issues/63500
	# WINDOW_MODE_FULLSCREEN will leave a one pixel border, preventing exact 2x scaling
	match DisplayServer.window_get_mode(wid):
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, wid)
			DisplayServer.window_set_size(initial_window_size, wid)
		# Log.info(["Switched to window mode. resolution={}", DisplayServer.window_get_size(wid)])
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, wid)
			# Log.info(["Switched to exclusive fullscreen mode. resolution={}", DisplayServer.window_get_size(wid)])


func get_base_resolution() -> Vector2i:
	var w: int = ProjectSettings.get(&"display/window/size/viewport_width")
	var h: int = ProjectSettings.get(&"display/window/size/viewport_height")
	assert(w > 0)
	assert(h > 0)
	return Vector2i(w, h)


func get_initial_window_size() -> Vector2i:
	var w: int = ProjectSettings.get(&"display/window/size/window_width_override")
	var h: int = ProjectSettings.get(&"display/window/size/window_height_override")
	assert(w >= 0)
	assert(h >= 0)
	return Vector2i(w, h)
