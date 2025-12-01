extends Node


var installed_blenders: Array[BlenderData] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#check_running_blenders()


func check_running_blenders() -> PackedStringArray:
	var blenders: = PackedStringArray()

	var output: = []
	var err: = OS.execute("CMD.exe", ["/C", "wmic process where name='blender.exe' get ProcessID,ExecutablePath"], output)
	if err != -1:
		print(output)

	return blenders


func query_blender_data(blender_exec_file: String) -> BlenderData:
	var blender: = BlenderData.new()

	var output = []
	OS.execute(blender_exec_file, ["-v"], output)
	output = output[0]

	var lines: = (output as String).remove_chars("\t").split("\r\n")
	var version: = Array(lines[0].split(" ", false))
	version.remove_at(0)
	blender.version = version.pop_front()
	blender.stability = BlenderData.get_stability_from_string(" ".join(PackedStringArray(version)))

	var build_data: = {}
	for line in lines:
		if line.begins_with("build"):
			build_data[line.get_slice(": ", 0).to_snake_case()] = line.get_slice(": ", 1)
	#print_debug(JSON.stringify(build_data, "\t", false))

	blender.branch = build_data.build_branch
	blender.build_hash = build_data.build_hash
	blender.timestamp = build_data.build_date + "T" + build_data.build_time + "+00:00"
	blender.installation_path = blender_exec_file.get_base_dir()
	blender.os = build_data.build_platform

	blender.architecture = (build_data.build_link_flags as String).get_slice("  ", 0).get_slice(":", 1).to_lower()

	return blender


func get_installed_blenders() -> Array[BlenderData]:
	var blenders: Array[BlenderData] = []
	var install_folder: String = Settings.get_setting("Blender Versions", "default_install_location", "C:/Program Files/Blender Foundation")
	var d: = DirAccess.open(install_folder)
	if DirAccess.get_open_error() == OK:
		for folder in d.get_directories():
			if Helper.is_following_pattern(r"Blender \d\.(\d|x)", folder) and FileAccess.file_exists(install_folder.path_join(folder).path_join("blender.exe")):
				blenders.append(query_blender_data(install_folder.path_join(folder).path_join("blender.exe").replace("/", "\\")))
	else:
		push_warning("Directory doesn't exists yet. -> ", install_folder)
	return blenders


func get_daily_builds() -> Array[BlenderData]:
	var blenders: Array[BlenderData] = []
	var data: = await Helper.fetch_request(self, Settings.get_setting("Blender Versions", "link_blender_daily", "https://builder.blender.org/download/daily/"))
	var os: = OS.get_name()
	match os:
		"macOS":
			os = "darwin"
		"Linux":
			os = "linux"
		"Windows", _:
			os = "windows"
	var architecture: = Engine.get_architecture_name()
	match architecture:
		"arm64":
			architecture = "arm64"
		"x86_64", _:
			architecture = "amd64" if os == "windows" else "x86_64"

	#if OS.is_debug_build():
		#var f: = FileAccess.open("res://output.html", FileAccess.WRITE)
		#f.store_string(data.body.get_string_from_utf8())
		#f.close()

	var xml: = XML.new(data.body)
	var offsets: = xml.find_nodes_with_attributes("li", {"class" = "t-row build is-{os} is-arch-{architecture}".format({"os" = os, "architecture" = architecture})})
	#print_debug(offsets.size())
	#print_debug(JSON.stringify(xml.get_children_of_node(offsets[0]), "\t", false))

	for offset in offsets:
		var blender: = BlenderData.new()
		var item: = xml.get_children_of_node(offset)
		blender.version = item.children[0].text.replace("Blender ", "")
		blender.source = (item.children[0].attributes.href as String).strip_edges()
		blender.build_hash = (item.children[2].text as String).strip_edges()
		blender.timestamp = item.children[4].attributes.title
		blender.stability = BlenderData.get_stability_from_string(item.children[1].text)
		blender.size = item.children[6].children[0].attributes.title.replace("Download ", "").replace("(", "").replace(")", "")
		blender.os = item.children[5].children[0].text
		blender.architecture = item.children[5].text.strip_edges()

		blenders.append(blender)

	return blenders
