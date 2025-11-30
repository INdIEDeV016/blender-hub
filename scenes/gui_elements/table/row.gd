extends PanelContainer
class_name TableRow


var blender_data: BlenderData:
	set(new):
		blender_data = new
		if is_inside_tree():
			set_row()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_row()

	for button in %Buttons.get_children():
		add_user_signal(button.name.to_lower())
		button.hide()


func set_row():
	if blender_data:
		%Version.text = "Blender " + blender_data.version
		%Date.text = blender_data.get_friendly_timestamp()
		%Date.tooltip_text = blender_data.timestamp
		%Type.current_type = blender_data.stability


func set_install_mode(source: = ""):
	if blender_data.source.is_empty():
		blender_data.source = source
	%Buttons/Install.show()


func set_open_mode(installation_path: = ""):
	if blender_data.installation_path.is_empty():
		blender_data.installation_path = installation_path
	%Buttons/Open.show()
	%Buttons/Uninstall.show()


func set_update_available(source: = ""):
	if blender_data.source.is_empty():
		blender_data.source = source
	%Buttons/Update.show()


func _on_action_button_pressed(button: Button) -> void:
	emit_signal(button.name.to_lower())
