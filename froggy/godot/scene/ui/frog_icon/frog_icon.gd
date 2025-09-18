class_name FrogIcon
extends Control

enum State {
	Normal,
	Checked,
	Crossed,
}

@export var state := State.Normal:
	set = set_state


func set_state(value: State):
	state = value
	match state:
		State.Normal:
			$Frog.modulate = Color.WHITE
			$Check.hide()
			$Cross.hide()
		State.Checked:
			$Frog.modulate = Color(0.5, 0.5, 0.5)
			$Check.show()
			$Cross.hide()
		State.Crossed:
			$Frog.modulate = Color(0.5, 0.5, 0.5)
			$Check.hide()
			$Cross.show()
