class_name XML

var xml: XMLParser

func _init(buffer) -> void:
	xml = XMLParser.new()
	if buffer:
		if buffer is String:
			xml.open(buffer)
		elif buffer is PackedByteArray:
			xml.open_buffer(buffer)

func get_head():
	if xml.seek(0) == OK:
		return get_children(get_node_offset("head"))

func get_body():
	if xml.seek(0) == OK:
		return get_children(get_node_offset("body"))


func get_node(node_offset: int) -> Dictionary:
	var node: = {}
	xml.seek(node_offset)

	match xml.get_node_type():
		XMLParser.NODE_ELEMENT:
			node.name = xml.get_node_name()
			var attributes: Dictionary = {}
			for index in xml.get_attribute_count():
				attributes[xml.get_attribute_name(index)] = xml.get_attribute_value(index)
			node.attributes = attributes
		XMLParser.NODE_ELEMENT_END:
			node.name = xml.get_node_name()
		XMLParser.NODE_TEXT:
			node.text = xml.get_node_data()
		XMLParser.NODE_UNKNOWN, _:
			pass

	node.type = xml.get_node_type()
	node.offset = node_offset
	return node


func get_node_offset(node: String, type: = XMLParser.NODE_ELEMENT) -> int:
	while not (xml.get_node_type() == type and xml.get_node_name() == node):
		xml.read()
	return xml.get_node_offset()


func get_node_info(node_offset: int) -> Dictionary:
	xml.seek(node_offset)
	var dict: = {
		name = xml.get_node_name(),
		attributes = get_attributes_as_dict(),
		text = "",
		offset = node_offset
	}

	var depth: = 1
	while xml.read() != ERR_FILE_EOF:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				if xml.get_node_name() == dict.name:
					depth += 1
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				dict.text += xml.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				depth -= 1
				if depth == 0:
					break

	return dict

func find_nodes_with_attributes(node: String, attributes: Dictionary) -> PackedInt32Array:
	xml.seek(0)
	var offsets: = PackedInt32Array()
	while xml.read() != ERR_FILE_EOF:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var current_node: = xml.get_node_name()
				var current_node_attributes: = get_attributes_as_dict()
				if current_node == node and Helper.is_dictionary_equal(attributes, current_node_attributes):
					offsets.append(xml.get_node_offset())
	return offsets


func get_attributes_as_dict() -> Dictionary:
	var attributes: = {}
	if xml.get_node_type() == XMLParser.NODE_ELEMENT:
		for index in xml.get_attribute_count():
			attributes[xml.get_attribute_name(index)] = xml.get_attribute_value(index)
	else:
		push_warning("Current Node is not an Element Node!")
	return attributes

func get_node_content_as_text(node_offset: int) -> String:
	read_until(xml.get_node_name(), node_offset)

	var text: = "<%s %s>" % [xml.get_node_name(), get_attributes_as_dict()]
	var parent_node: = xml.get_node_name()
	while not (xml.get_node_name() == parent_node and xml.get_node_type() == XMLParser.NODE_ELEMENT_END):
		var err: = xml.read()
		if err == ERR_FILE_EOF:
			return text
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var attributes: = get_attributes_as_dict()
				if xml.is_empty():
					text += "<%s />" % xml.get_node_name()
				else:
					text += "<%s %s>" % [xml.get_node_name(), str(attributes).replace("{ ", "").replace(" }", "")]
			XMLParser.NODE_TEXT:
				text += xml.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				text += "</%s>" % xml.get_node_name()
	return text


func find_nodes_with_content_as_text(node: String, attributes: Dictionary) -> PackedStringArray:
	var nodes_array: = PackedStringArray()
	get_node_content_as_text(find_nodes_with_attributes(node, attributes)[0])
	return nodes_array


func read_until(node: String, seek: int = xml.get_node_offset()) -> Error:
	xml.seek(seek)
	var err: Error = OK
	while not (xml.get_node_type() == XMLParser.NODE_ELEMENT and xml.get_node_name() == node):
		err = xml.read()
	return err


func get_children(node_offset: int) -> Array[Dictionary]:
	xml.seek(node_offset)
	var nodes: Array[Dictionary] = []
	while xml.read() != ERR_FILE_EOF:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				nodes.append(_parse_element())
			XMLParser.NODE_ELEMENT_END:
				break
	return nodes


func _parse_element() -> Dictionary:
	var dict: = {
		name = xml.get_node_name(),
		attributes = get_attributes_as_dict(),
		text = "",
		offset = -1,
		children = []
	}

	while xml.read() != ERR_FILE_EOF:
		var type: = xml.get_node_type()
		var name: = ""
		var text: = ""
		match type:
			XMLParser.NODE_ELEMENT:
				# deeper child: recurse, then continue
				name = xml.get_node_name()
				dict.offset = xml.get_node_offset()
				dict.children.append(_parse_element())
			XMLParser.NODE_ELEMENT_END:
				name = xml.get_node_name()
				if dict.name == xml.get_node_name():
					# fully closed this element
					break
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				# accumulate all text, even if split by child tags
				text = xml.get_node_data()
				dict.text = xml.get_node_data()
			_:
				pass
	return dict


func get_children_of_node(node_offset: int) -> Dictionary:
	var dict: = get_node_info(node_offset)
	dict.children = get_children(node_offset)
	return dict
