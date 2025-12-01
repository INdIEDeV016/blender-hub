@tool
extends Field


enum Type {
	TEXT,
	URL,
	NUMBERS,
	FILE,
	FOLDER,
}

@export var type: Type = Type.TEXT:
	set(new):
		type = new
		if not is_node_ready():
			await ready
		%SelectButton.hide()
		match type:
			Type.FILE, Type.FOLDER:
				%SelectButton.show()
@export var text: String:
	set(new):
		text = new
		if not is_node_ready():
			await ready
		%LineEdit.text = new
@export var placeholder_text: String:
	set(new):
		placeholder_text = new
		if not is_node_ready():
			await ready
		%LineEdit.placeholder_text = new


func _ready() -> void:
	super()
	%Error.hide()
	%Error.text = ""


func get_value():
	return %LineEdit.text


func set_value(new):
	if new is String:
		%LineEdit.text = new


func _on_field_value_changed(new_value: String) -> void:
	if not is_node_ready():
		%Error.text = ""
	if not new_value.is_empty():
		match type:
			Type.NUMBERS:
				if not new_value.is_valid_float():
					%Error.text = "Not a valid number!"
			Type.URL:
				if not Helper.is_valid_url(new_value):
					%Error.text = "Not a valid URL!"

	if not %Error.text.is_empty():
		%Error.show()
		return

	super(new_value)


func _on_select_button_pressed() -> void:
	if type == Type.FILE:
		%Select.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	elif type == Type.FOLDER:
		%Select.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	%Select.popup_centered()


func _on_select_file_selected(path: String) -> void:
	%LineEdit.text = path
	%LineEdit.text_changed.emit(path)
