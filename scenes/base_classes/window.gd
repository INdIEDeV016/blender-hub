extends Window
class_name WindowManager


func _ready() -> void:
	title = name


func _on_close_requested() -> void:
	hide()
