extends WindowManager


func _ready() -> void:
	super()
	if not FileAccess.file_exists(Settings.path):
		print("Creating Settings at: ", Settings.path)
		read_and_store()
		Settings.save()
	%HTabs.current_tab = 0


func read_and_store() -> void:
	for foldable_container in %FoldedContainers.get_children():
		if foldable_container is FoldableContainer:
			for field in (foldable_container.get_child(0) as VBoxContainer).get_children():
				if field is Field:
					#if field.get_value() is Object:
						#Settings.set_setting(foldable_container.title, field.name, var_to_str(field.get_value()))
					#else:
						Settings.set_setting(foldable_container.title, field.name, field.get_value())


func set_fields() -> void:
	for section_name in Settings.get_sections():
		var section_container: VBoxContainer = %FoldedContainers.get_node_or_null(section_name.replace(" ", "")).get_child(0)
		if section_container:
			var section: = Settings.get_section(section_name)
			for key in section:
				if section_container.has_node(key):
					var field: Field = section_container.get_node(key)
					#if field.get_value() is Object:
						#print_debug(section[key] is Resource)
						#field.set_value(section[key])
					#else:
					field.set_value(section[key])



func _on_setting_value_changed(section: StringName, key: StringName, value, save_now: = false) -> void:
	#if value is Object:
		#Settings.set_setting(section, key, var_to_str(value), save_now)
	#else:
		Settings.set_setting(section, key, value, save_now)


func _on_folded_settings_child_entered_tree(node: Node) -> void:
	if node is FoldableContainer:
		%HTabs.add_tab(node.title)


func _on_about_to_popup() -> void:
	set_fields()


func _on_close_requested() -> void:
	read_and_store()
	Settings.save()
	super()
