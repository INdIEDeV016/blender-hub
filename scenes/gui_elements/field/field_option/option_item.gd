@tool # @tool is required here to avoid an unknown editor bug in the console.
#Probably because this script is also being using in another tool script.
extends Resource
class_name OptionItem


@export var text: = ""
@export var icon: Texture2D
@export var tooltip: = ""
@export var disabled: = false
@export var seperator: = false
@export var id: = -1
@export var metadata: Dictionary[StringName, Variant] = {}

var index: int

func _to_string() -> String:
	return text
