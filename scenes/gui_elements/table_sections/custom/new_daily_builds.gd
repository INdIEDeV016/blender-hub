extends TableSection


func refresh() -> void:
	await super()
	for data in await Blender.get_daily_builds():
		var row: = table.add_row(data)
		row.set_install_mode()
		if row.has_user_signal("install"):
			row.connect("install", _on_install_button_pressed.bind(row.blender_data))

	table.set_empty_message(empty_table_message)


func _on_install_button_pressed(data: BlenderData) -> void:
	var installation_path: String = Settings.get_setting("Blender Versions", "default_install_location", "C:/Program Files/Blender Foundation/")
	if data.stability == BlenderData.Stability.ALPHA:
		installation_path = installation_path.path_join("Blender %s.x" % data.version[0])
	else:
		installation_path = installation_path.path_join("Blender %s" % data.get_short_version())

	print("Downloading and Installing:\n", data, "Installing at: ", installation_path)
	get_tree().current_scene.side_bar.download_and_install(data.source, installation_path)
