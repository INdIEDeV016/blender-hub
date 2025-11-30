extends Node


signal notifcation_created(text: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func notify(text: String) -> void:
	notifcation_created.emit(text)
