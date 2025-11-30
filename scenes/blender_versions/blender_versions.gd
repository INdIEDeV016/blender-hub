@tool
extends Page


func _ready() -> void:
	super()


func update_check() -> void:
	get_download_button()


func get_download_button() -> BlenderData:
	var thanks_page: = func get_link_from_thanks_page(link: String) -> String:
		var data: = await Helper.fetch_request(%Body, link)
		#print_debug("Headers:\n\n", data[2])

		for header in data[2] as PackedStringArray:
			if header.split(": ", false, 1)[0] == "refresh":
				return header.split(": ", false, 1)[1].lstrip("1;url=")

		return ""

	var headers: = PackedStringArray()

	match OS.get_name():
		"macOS":
			headers = ["User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"]
		"Android", "Linux":
			headers = ["User-Agent: Mozilla/5.0 (Android 15; Mobile; rv:128.0) Gecko/128.0 Firefox/128.0"]
		"Windows", _:
			headers = ["User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"]

	var url: String = Settings.get_setting("Blender Versions", "download_page", "https://www.blender.org/download")
	var body: PackedByteArray = (await Helper.fetch_request(%Body, url, headers)).body
	#print_debug("Header:\n\n", body[2], "\n\n")
	#print_debug("Body:\n\n", (body[3] as PackedByteArray).get_string_from_utf8())

	var bl_data: = BlenderData.new()
	bl_data.type = BlenderData.Stability.STABLE
	var xml: = XMLParser.new()
	xml.open_buffer(body)
	while xml.read() != ERR_FILE_EOF:
		if xml.get_node_type() == XMLParser.NODE_ELEMENT:
			#var attributes: = {}
			#for idx in xml.get_attribute_count():
				#attributes[xml.get_attribute_name(idx)] = xml.get_attribute_value(idx)
			#print("<%s> : " % xml.get_node_name(), attributes)
			if xml.get_node_name() == "div" and xml.has_attribute("id"):

				var pre_link = func _get_pre_link_from_os(os: StringName) -> void:
					print_debug(xml.get_named_attribute_value("id"), " ", os)
					if xml.get_named_attribute_value("id") == str(os):
						bl_data.os = xml.get_named_attribute_value("id")
						#print_debug(xml.get_node_type(), xml.get_node_name())
						while not (xml.get_node_type() == XMLParser.NODE_ELEMENT and xml.get_node_name() == "a"):
							xml.read()
						#print_debug(xml.get_node_type(), xml.get_node_name())
						bl_data.source = xml.get_named_attribute_value("href") #https://www.blender.org/download/release/Blender4.4/blender-4.4.3-windows-x64.msi

						while not (xml.get_node_type() == XMLParser.NODE_ELEMENT and xml.get_node_name() == "ul" and xml.get_named_attribute_value("class") == "dl-build-details mt-1 mb-0"):
							xml.read()
						while not (xml.get_node_type() == XMLParser.NODE_ELEMENT_END and xml.get_node_name() == "ul"):
							xml.read()
							if xml.get_node_type() == XMLParser.NODE_ELEMENT and \
							xml.get_node_name() == "li":
								var title: = xml.get_named_attribute_value("title")
								xml.read()
								if title == "Tiny isn't?":
									bl_data.size = xml.get_node_data()
								elif title == "Release date":
									bl_data.timestamp = xml.get_node_data()
					else:
						printerr("Invalid OS name!")

				match OS.get_name():
					"Linux":
						pre_link.call(&"linux")
					"macOS":
						pre_link.call(&"macos" if OS.get_processor_name().contains("Intel") else &"macos-apple-silicon")
					"Windows", _:
						pre_link.call(&"windows-arm" if OS.has_feature("arm") else &"windows")

				if bl_data.source.is_empty():
					continue

				var regex: = RegEx.create_from_string(r"\d+(\.\d)+")
				var regex_match: = regex.search(bl_data.source)
				if regex_match:
					bl_data.version = regex_match.get_string()

				bl_data.source = await thanks_page.call(bl_data.source)

	print_debug(bl_data)
	return bl_data


func get_specific_version(_version: String, _os: = OS.get_name(), _architecture: = Engine.get_architecture_name()):
	var url: String = Settings.get_setting("Blender Versions", "download_repository", "https://download.blender.org/release/")
	var body: PackedByteArray = (await Helper.fetch_request(%Body, url)).body
	print_debug(body.get_string_from_utf8())

	var xml: = XML.new(body)
	while not (xml.xml.get_node_type() == XMLParser.NODE_ELEMENT and xml.xml.get_node_name() == "pre"):
		xml.xml.read()

	#print_debug(JSON.stringify(xml.get_children(xml.xml.get_node_offset()), "\t", false, true))

	print_debug(JSON.stringify(xml.get_head(), "\t"))


func _set_tags_container(table: Table) -> void:
	#print_debug(table.get_nodes_in_column("Stability"))
	#print_tree_pretty()
	for type in table.get_nodes_in_column("Stability"):
		if type is Label:
			var button: = %TagsContainer.get_child(0).duplicate()
			button.text = type.text
			if not %TagsContainer.has_node(type.text):
				%TagsContainer.add_child(button)
