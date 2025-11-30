@tool
extends Field


@export var options: Array[Dictionary]:
	set(new):
		options = new
		if not is_node_ready():
			await ready

		%OptionButton.clear()
		for index in new.size():
			var item: = new[index]
			for key in item:
				match key:
					"disabled", "icon", "id", "metadata", "tooltip":
						%OptionButton.call("set_item_" + key, index, item[key])
					"name", _:
						%OptionButton.add_item(item[key])

func set_value(new: Variant) -> void:
	if not is_node_ready():
		await ready

	value = new

	#print(new)
	if new != null and %OptionButton.has_selectable_items():
		%OptionButton.selected = %OptionButton.get_item_index(new[0])


func get_value():
	if Engine.is_editor_hint():
		var new: = [%OptionButton.get_item_id(%OptionButton.selected), %OptionButton.get_item_text(%OptionButton.selected)]
		return new
	else:
		return value


func _on_field_value_changed(new_value: int) -> void:
	# Don't forget to connect the signal of the node to this function.
	super([%OptionButton.get_item_id(new_value), %OptionButton.get_item_text(new_value)])
