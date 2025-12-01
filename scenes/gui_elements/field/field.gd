@tool
extends HFlowContainer
class_name Field


signal value_changed(section: StringName, key: StringName, value: Variant, immediate_save: bool)

@export var label: = "":
	set(new):
		label = new
		if not is_node_ready():
			await ready
		%Label.text = label
@export var immediate_save: = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		value_changed.connect(get_parent().owner._on_setting_value_changed)


func get_value():
	return null


@warning_ignore("unused_parameter")
func set_value(new):
	pass


func _on_field_value_changed(new_value) -> void:
	#print_debug(new_value)
	value_changed.emit(StringName((get_node("../..") as FoldableContainer).title), name, new_value, immediate_save)
