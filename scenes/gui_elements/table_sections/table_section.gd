extends VBoxContainer
class_name TableSection


@export_multiline var empty_table_message: = "":
	set(new):
		empty_table_message = new
		if is_inside_tree():
			table.set_empty_message(empty_table_message)

@onready var table: Table = %Table

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	table.set_empty_message(empty_table_message)
	await refresh()

	owner.table_sections[name] = self


func add_action(function: Callable, text: = "", icon: = Texture2D.new()) -> Button:
	var button: = Button.new()
	button.text = text
	button.icon = icon
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(function)
	%ActionButtonContainer.add_child(button)
	return button


func refresh() -> void:
	table.clear()
	table.set_empty_message("Refreshing...")
	await get_tree().process_frame
	await get_tree().process_frame
