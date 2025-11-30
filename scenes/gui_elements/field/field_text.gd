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
@export var placeholder_text: String:
	set(new):
		placeholder_text = new
		if not is_node_ready():
			await ready
		%LineEdit.placeholder_text = new


func set_value(new: Variant) -> void:
	super(new)
	if not is_node_ready():
		await ready

	if %LineEdit.text != str(new):
		%LineEdit.text = str(new)

func get_value():
	var new_value = %LineEdit.text
	value = %LineEdit.text
	return new_value


func _on_field_value_changed(new_value: String) -> void:
	if not new_value.is_empty():
		match type:
			Type.NUMBERS:
				if not new_value.is_valid_float():
					return
			Type.URL:
				if not Helper.is_valid_url(new_value):
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
