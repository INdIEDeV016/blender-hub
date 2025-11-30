extends VBoxContainer
class_name HTabs


signal tab_clicked(tab: int)

@export var tween_speed: float = 2
@export var tween_trans_type: Tween.TransitionType

var tween: Tween
var button_group: = ButtonGroup.new()
var tab_container: TabContainer
var current_tab: = 0:
	set(new):
		current_tab = new
		if is_node_ready() and %Tabs.get_child_count() > 0:
			%Tabs.get_child(current_tab).button_pressed = true
			button_group.pressed.emit(%Tabs.get_child(current_tab))

@onready var under: = %Under as HSeparator
@onready var over: = %Over as HSeparator


func _ready() -> void:
	button_group.pressed.connect(_on_button_group_pressed)


func _on_button_group_pressed(button: BaseButton) -> void:
	tab_clicked.emit(button.get_index())
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween().set_trans(tween_trans_type).set_parallel()
	tween.tween_property(over, "global_position:x", maxf(button.global_position.x - %Tabs.get_theme_constant("separation") / 2.0, 0.0) , 1/tween_speed)
	tween.tween_property(over, "size:x", button.size.x + %Tabs.get_theme_constant("separation"), 1/tween_speed)


func add_tab(tab_name: String) -> int:
	if not %Tabs.has_node(tab_name):
		var button: = Button.new()
		button.name = tab_name.to_pascal_case()
		button.toggle_mode = true
		button.text = tab_name
		button.button_group = button_group
		button.theme_type_variation = &"HTabButton"
		%Tabs.add_child(button)
		return button.get_index()
	else:
		printerr("Can't add tab! Tab already exists with the same name.")
		return -1


func remove_tab(tab) -> Error:
	if %Tabs.get_child_count() > 0:
		if tab is int:
			%Tabs.get_child(tab)
		elif tab is String:
			if %Tabs.has_child(tab):
				%Tabs.get_node(tab).queue_free()
			else:
				printerr("No tab named \"%s\" exists!" % tab)
				return ERR_DOES_NOT_EXIST
		else:
			printerr("Parameter provided should be either index or the name of the tab.")
			return ERR_INVALID_PARAMETER
		return OK
	else:
		printerr("There are no tabs to remove!")
		return ERR_DOES_NOT_EXIST


func _on_tab_clicked(tab: int) -> void:
	if tab_container:
		tab_container.current_tab = tab
