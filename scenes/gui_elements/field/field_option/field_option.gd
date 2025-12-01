@tool
extends Field


@export var options: Array[OptionItem]:
	set(new):
		options = new
		if not is_node_ready():
			await ready

		%OptionButton.clear()
		for index in new.size():
			var item: = new[index]
			item.index = index

			%OptionButton.add_item(item.text)
			%OptionButton.set_item_icon(index, item.icon)
			%OptionButton.set_item_tooltip(index, item.tooltip)
			%OptionButton.set_item_id(index, item.id if item.id > -1 else index)
			%OptionButton.set_item_disabled(index, item.disabled)

@export var selection: int = -1:
	set(new):
		if not is_node_ready():
			await ready

		if %OptionButton.item_count > 0:
			selection = clampi(new, 0, %OptionButton.item_count - 1)

			%OptionButton.select(clampi(new, 0, %OptionButton.item_count - 1))


func _ready() -> void:
	super()


func get_value():
	var dict: = {
		"id" = 0,
		"text" = ""
	}
	var selected: int = %OptionButton.selected
	dict.id = %OptionButton.get_item_id(selected)
	dict.text = %OptionButton.get_item_text(selected)
	return dict


func set_value(new):
	assert(new is Dictionary)
	selection = %OptionButton.get_item_index(new.id)
	%OptionButton.select(selection)


func _on_field_value_changed(new_value: int) -> void:
	# Don't forget to connect the signal of the node to this function.
	super({
		"id" = %OptionButton.get_item_id(new_value),
		"text" = %OptionButton.get_item_text(new_value)
	})


func _on_menu_about_to_popup(menu: PopupMenu) -> void:
	#menu.position.x += DisplayServer.screen_get_position(get_tree().root.current_screen).x
	pass
