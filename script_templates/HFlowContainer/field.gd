@tool
extends Field


func set_value(new: Variant) -> void:
	super(new)
	if not is_node_ready():
		await ready

	#if %node.value != new:
	#	%node.value = new


func get_value():
	#var new_value = %node.value
	#value = %node.value
	#return new_value
	super()


func _on_field_value_changed(new_value: String) -> void:
	# Don't forget to connect the signal of the node to this function.
	super(new_value)