extends TableSection


func refresh() -> void:
	await super()
	for data in await Blender.get_installed_blenders():
		var row: = table.add_row(data)
		row.set_open_mode()
		if row.has_user_signal("open"):
			row.connect("open", _on_open_button_pressed.bind(row.blender_data.installation_path.path_join("blender.exe")))

	table.set_empty_message(empty_table_message)


func _on_open_button_pressed(path: String, args: = PackedStringArray()) -> void:
	OS.create_process(path, args)


func _on_add_pressed(button: Button) -> void:
	var popup_panel: PopupPanel = button.get_node("PopupPanel")
	popup_panel.popup(
		Rect2i(
			get_tree().root.position + Vector2i(
				int(button.global_position.x),
				int(button.global_position.y + button.size.y)
			),
			Vector2i(
				int(button.size.x),
				0
			)
		)
	)


func _on_download_pressed() -> void:
	pass
	#TODO
	#var side_bar: Control = get_tree().current_scene.side_bar
	#side_bar.download_and_install(url)


func _on_popup_panel_popup_hide() -> void:
	%ActionButtonContainer/Add.button_pressed = false
