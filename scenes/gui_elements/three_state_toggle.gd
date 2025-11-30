extends Panel
class_name ThreeStateToggle


signal state(current_state: int)

@export var current_state: = 1:
	set(new):
		current_state = new
		if is_node_ready():
			match current_state:
				0:
					tween = create_tween().set_trans(Tween.TRANS_QUAD)
					tween.tween_property(circle, "position:x", 10.0, 1/tween_speed)
				1:
					tween = create_tween().set_trans(Tween.TRANS_QUAD)
					tween.tween_property(circle, "position:x", size.x/2.0 - circle.size.x/2.0, 1/tween_speed)
				2:
					tween = create_tween().set_trans(Tween.TRANS_QUAD)
					tween.tween_property(circle, "position:x", size.x - circle.size.x - 10.0, 1/tween_speed)

@export var tween_speed: float = 5

var tween: Tween

@onready var circle: = %Circle


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if tween and tween.is_running():
				return

			if event.position.x < get_rect().size.x * 1.0/3.0:
				current_state = 0
			elif event.position.x < get_rect().size.x * 2.0/3.0 and event.position.x > get_rect().size.x * 1.0/3.0:
				current_state = 1
			elif event.position.x > get_rect().size.x * 2.0/3.0:
				current_state = 2

			state.emit(current_state)


func _on_visibility_changed() -> void:
	current_state = current_state


func _on_draw() -> void:
	if has_focus() and (get_tree().current_scene as Control).theme.has_stylebox("focus", "ThreeStateToggle"):
		draw_style_box((get_tree().current_scene as Control).theme.get_stylebox("focus", "ThreeStateToggle"), get_rect())
