@tool
extends Control

enum State {
	INSTALL,
	INSTALLING,
	DONE
}

@export var state: State = State.INSTALL:
	set(new):
		state = new

var tween: Tween


func _ready() -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween().set_loops()
	tween.tween_property(%TextureProgressBar, "radial_initial_angle", 360.0, 1).from(0.0)


func change_state(to: State = State.INSTALL) -> void:
	match to:
		State.INSTALL:
			pass
		State.INSTALLING:
			pass
		State.DONE:
			pass
