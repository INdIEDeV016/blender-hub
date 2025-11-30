class_name Helper


static var month: = [
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December"
]

static var day: = [
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday",
	"Sunday"
]

## Output: {
## error_code = Error,
## response_code = HTTPClient.ResponseCode,
## header = PackedStringArray,
## body = PackedByteArray
## }
static func fetch_request(parent_node: Node, url: String, headers: = PackedStringArray()) -> Dictionary:
	if url.is_empty():
		printerr("url not provided!")
		assert(not url.is_empty(), "url not provided!")
		return {}

	var http: = HTTPRequest.new()
	http.use_threads = true
	parent_node.add_child(http)

	http.request(url, headers)
	var data: Array = await http.request_completed
	http.queue_free()
	assert(data[0] == OK, "Request Error! %s" % error_string(data[0]))
	assert(data[1] == HTTPClient.RESPONSE_OK, "Response Error! Error Code: %s" % data[1])
	return {
		error_code = data[0],
		response_code = data[1],
		headers = data[2],
		body = data[3]
	}


static func is_valid_url(string: String) -> bool:
	if string.is_empty():
		push_warning("String is empty!")
		return false

	var regex: = RegEx.create_from_string(r"(?xi)\b(?:(?:https?|ftp):\/\/|www\.)[\w-]+(?:\.[\w-]+)+(?:\:(?<port_number>\d{1,5}))?(?:\/[\S]*)?\b")
	var regex_match: RegExMatch
	if regex.is_valid():
		regex_match = regex.search(string)

		if regex_match and not regex_match.get_string().is_empty():
			return true
	else:
		printerr("Regex is invalid!")
	return false


static func get_drive_space_availability(drive_letter: = "C:") -> Dictionary:
	var dict: Dictionary[StringName, int] = {}

	var drive_size = []
	OS.execute("cmd.exe", ["/C", "wmic logicaldisk where \"DeviceID='%s'\" get Size" % drive_letter], drive_size)
	dict.size = (drive_size[0] as String).to_int()

	var drive_free_space = []
	OS.execute("cmd.exe", ["/C", "wmic logicaldisk where \"DeviceID='%s'\" get FreeSpace" % drive_letter], drive_free_space)
	dict.free_space = (drive_free_space[0] as String).to_int()

	return dict


static func remove_dir_recursive(path: String, delete_root: = true) -> Error:
	var err: = DirAccess.get_open_error()
	if err != OK:
		printerr("Failed to open directory: ", path, " | Error: ", error_string(err))
		return err

	# Iterate over subdirectories and recursively delete them
	for subdir in DirAccess.get_directories_at(path):
		err = remove_dir_recursive(path.path_join(subdir))

	# Delete all files in this directory
	for file in DirAccess.get_files_at(path):
		var file_path = path.path_join(file)
		err = DirAccess.remove_absolute(file_path)
		if err != OK:
			printerr("Failed to delete file: " + file_path)

	# Delete the empty directory itself based on `leave_root`
	if delete_root:
		err = DirAccess.remove_absolute(path)
		if err != OK:
			printerr("Failed to delete directory: " + path)
			return err

	return err


static func is_following_pattern(pattern: String, subject: String) -> bool:
	var regex: = RegEx.create_from_string(pattern)
	if regex.is_valid():
		var regex_match: = regex.search(subject)
		return is_instance_valid(regex_match) and not regex_match.strings.is_empty()
	else:
		printerr("Invalid regex pattern")
		return false


static func match_pattern(pattern: String, subject: String, capture_groups: = [0]) -> PackedStringArray:
	var regex: = RegEx.create_from_string(pattern)
	var matches: = PackedStringArray()
	if regex.is_valid():
		var regex_match: = regex.search(subject)
		if regex_match:
			for group in capture_groups:
				matches.append(regex_match.get_string(group))
	else:
		printerr("Invalid regex pattern")

	return matches

static func match_pattern_dict(pattern: String, subject: String) -> Array:
	var regex: = RegEx.create_from_string(pattern)
	var regex_match: RegExMatch
	var capturing_groups: = {}
	var matched: = []
	if regex.is_valid():
		regex_match = regex.search(subject)
		if regex_match:
			var group_names: = regex_match.names
			swap_dictionary(group_names)
			print_debug(group_names)
			for index in regex.get_group_count():
				capturing_groups[group_names.get_or_add(index + 1, index + 1)] = regex_match.get_string(index + 1)
			matched.append(regex_match.get_string(0))
			matched.append(capturing_groups)
		else:
			printerr("No matches found!")
	else:
		printerr("Failed to compile regex! Error:")
	return matched

static func match_pattern_dict_all(pattern: String, subject: String) -> Array[Array]:
	var regex: = RegEx.create_from_string(pattern)
	var matches: Array[Array] = []
	if regex.is_valid():
		var regex_matches: = regex.search_all(subject)
		if regex_matches.size() > 0:
			for regex_match in regex_matches:
				var capturing_groups: = {}
				var group_names: = regex_match.names
				swap_dictionary(group_names)
				#print_debug(group_names, " Group Count: ", regex.get_group_count())
				for index in regex.get_group_count():
					capturing_groups[group_names.get_or_add(index + 1, index + 1)] = regex_match.get_string(index + 1)
				matches.append([regex_match.get_string(0), capturing_groups])
		else:
			printerr("No matches found!")
	else:
		printerr("Failed to compile regex! Error:")
	return matches


## datetime: is ISO 8601 Timestamp
static func get_friendly_date(datetime: String, format: String = "{day} {month}, {year}", use_format_always: = false) -> String:
	var datetime_dict: = Time.get_datetime_dict_from_datetime_string(datetime, false)
	var unix_datetime: = Time.get_unix_time_from_datetime_string(datetime)
	var unix_system: = int(Time.get_unix_time_from_datetime_string(Time.get_date_string_from_system()))

	#print_debug(datetime_dict)
	if not use_format_always:
		var difference: = (unix_datetime - unix_system) / float(60 * 60 * 24)
		#print_debug(difference)
		match roundi(difference):
			-1:
				return "Yesterday"
			0:
				return "Today"
			1:
				return "Tomorrow"

	var friendly_date: String
	var suffix: = ""
	match datetime_dict.day:
		1, 21, 31:
			suffix = "st"
		2, 22:
			suffix = "nd"
		3, 23:
			suffix = "rd"
		_:
			suffix = "th"
	friendly_date = format.format(
		{
			day = str(datetime_dict.day) + suffix,
			month = month[datetime_dict.month - 1],
			year = datetime_dict.year
		}
	)
	return friendly_date

## This method swaps the keys and values to be the corresponding "values" and "keys" respectively
## and also returns a copy of the swaped dictionary (Deep Duplicate - Mode 2)[br][br]
## For example:
## [br][codeblock]
## {
## 	"Key" : 0,
## 	"Value" : 1
## }
## [/codeblock]
## [br]
## becomes
## [br]
## [codeblock]
## {
## 	0 : "Key",
## 	1 : "Value"
## }
## [/codeblock]
static func swap_dictionary(dict: Dictionary, deep_duplicate: Resource.DeepDuplicateMode = Resource.DEEP_DUPLICATE_INTERNAL) -> Dictionary:
	for key in dict.keys():
		dict[dict[key]] = key
		dict.erase(key)

	return dict.duplicate_deep(deep_duplicate)


static func is_dictionary_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false

	var is_equal: = false
	for key in a:
		if b.has(key):
			is_equal = a[key] == b[key]

	return is_equal

#class Async:
#
	#signal completed
#
	#var _thread: = Thread.new()
	#var _lines: = PackedStringArray()
	#var _process: = {}
#
	#func _init() -> void:
		#completed.connect(_on_completed)
#
	#func execute(command: String) -> PackedStringArray:
		#_process = OS.execute_with_pipe("cmd.exe", ["/C", command])
		#_thread.start(_loop)
		#await completed
		#return _lines
#
#
	#func _loop():
		#var stdio: FileAccess = _process.stdio
		#while stdio.get_error() == OK:
			#var line: = stdio.get_line()
			#if not line.is_empty():
				#_lines.append(line)
#
		#completed.emit()
#
#
	#func _on_completed() -> void:
		#_thread.wait_to_finish()
