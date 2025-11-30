extends PanelContainer
class_name Table


signal table_changed(table: Table)

@export var strech_ratio_per_column: Array[float]:
	set(new):
		strech_ratio_per_column = new
		if not (is_inside_tree() and %MainContainer.is_node_ready()):
			await ready

		for index in strech_ratio_per_column.size():
			for row in %MainContainer.get_children():
				if row.name != "Empty":
					var ratio: = strech_ratio_per_column[index]
					(row.get_child(0).get_child(index) as Control).size_flags_stretch_ratio = ratio
@export var row_width: = 80
@export var header_width: = 40
@export var row_scene: = preload("uid://bfwvgukbo43ng")

var data: Array[Array] = []


func _ready() -> void:
	clear()
	pass


func set_header(header_names: PackedStringArray) -> void:
	if not %MainContainer.has_child("Header"):
		var panel: = PanelContainer.new()
		panel.name = "Header"
		panel.theme_type_variation = &"TableHeader"
		%MainContainer.add_child(panel)

		var hbox: = HBoxContainer.new()
		hbox.custom_minimum_size.y = header_width
		panel.add_child(hbox)

	var column_names: PackedStringArray
	for child in %MainContainer.get_children():
		column_names.append(child.text)

	for header_name in header_names:
		if header_name not in column_names:
			var label = Label.new()
			label.text = header_name
			label.name = header_name.to_pascal_case()
			label.uppercase = true
			label.theme_type_variation = &"TableHeaderLabel"
			label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			%MainContainer/Header/HboxContainer.add_child(label)
	table_changed.emit(self)


func add_row(blender_data: BlenderData) -> TableRow:
	var row: = row_scene.instantiate()
	%MainContainer.add_child(row)
	row.blender_data = blender_data
	strech_ratio_per_column = strech_ratio_per_column
	table_changed.emit(self)
	return row


func set_row(index: int, blender_data: BlenderData) -> TableRow:
	var row: TableRow = %MainContainer.get_child(index + 1)
	row.blender_data = blender_data
	strech_ratio_per_column = strech_ratio_per_column
	table_changed.emit(self)
	return row


func get_row(index: int) -> TableRow:
	var row: TableRow = %MainContainer.get_child(index + 1)
	return row


func remove_row(index: int) -> Error:
	index += 1
	if %MainContainer.get_child_count() <= 1:
		printerr("There are no rows in the table!")
		return ERR_DOES_NOT_EXIST

	%MainContainer.get_child(index).queue_free()
	table_changed.emit(self)
	return OK


func clear() -> void:
	table_changed.emit(self)
	for child in %MainContainer.get_children():
		if child is TableRow:
			child.queue_free()
		else:
			child.show()


func get_nodes_in_column(column) -> Array[Node]:
	if column is String:
		return %Header/HBoxContainer.get_node(column).get_children()
	elif column is int:
		return %MainContainer.get_child(column).get_children()
	return []


func set_empty_message(text: String) -> void:
	%Empty/Message.text = text


func _on_table_changed(_table: Table = self) -> void:
	%Empty.visible = %MainContainer.get_child_count() == 2
