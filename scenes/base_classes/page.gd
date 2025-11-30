@tool
extends Control
class_name Page


@export var tab_icon: Texture2D

var table_sections: Dictionary[StringName, TableSection] = {}


func _ready() -> void:
	%Title.tooltip_text = %Title.text
	%SubText.tooltip_text = %SubText.text

	if not Engine.is_editor_hint():
		get_tree().current_scene.pages.append(self)
