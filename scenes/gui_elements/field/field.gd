@tool
extends HFlowContainer
class_name Field


signal value_changed(section: StringName, key: StringName, value: Variant, save_now: bool)

@export var label: = "":
	set(new):
		label = new
		if not is_node_ready():
			await ready
		%Label.text = label
@export var value: Variant
@export var save_now: = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		value_changed.connect(get_parent().owner._on_setting_value_changed)


func set_value(new: Variant) -> void:
	value = new

func get_value():
	return value


func _on_field_value_changed(new_value) -> void:
	value = new_value
	value_changed.emit(StringName((get_node("../..") as FoldableContainer).title), name, new_value, save_now)
