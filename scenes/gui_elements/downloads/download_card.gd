extends PanelContainer
class_name DownloadCard


const LOGS_FOLDER: = "user://installation_logs"
const DOWNLOAD_FOLDER: = "user://downloads/"

enum Status {
	DOWNLOAD_COMPLETE,
	DOWNLOAD_PAUSED,
	DOWNLOAD_FAILED,
	INSTALL_COMPLETE,
	INSTALL_PAUSED,
	INSTALL_FAILED,
}

signal status_update(current_state: Status)
signal thread_complete

var thread: = Thread.new()
var f: FileAccess
var download_file: = ""
var installation_location: = ""
var process: = {}
var stdout_line: = ""
var retry_function: Callable
var cancel_function: Callable
var pause_function: Callable
var _downloaded_bytes: int

@onready var http: HTTPRequest = %HTTPRequest


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not DirAccess.dir_exists_absolute(DOWNLOAD_FOLDER):
		DirAccess.make_dir_recursive_absolute(DOWNLOAD_FOLDER)
		print("Created temporary installation folder at: ", DOWNLOAD_FOLDER)
	set_process(false)


func _process(_delta: float) -> void:
	_downloaded_bytes = http.get_downloaded_bytes()
	%Downloaded.text = String.humanize_size(_downloaded_bytes)
	%ProgressBar.value = float(_downloaded_bytes) / http.get_body_size() * 100
	%Total.text = String.humanize_size(http.get_body_size())

	if http.get_http_client_status() != HTTPClient.STATUS_CONNECTED:
		%Error.text = ""
		match http.get_http_client_status():
			HTTPClient.STATUS_CONNECTING:
				%Status.text = "Connecting..."
			HTTPClient.STATUS_CANT_CONNECT:
				%Status.hide()
				%Error.text = "Can't connect to server, check your internet connection and try again!"
			HTTPClient.STATUS_RESOLVING:
				%Status.text = "Resolving hostname..."
			HTTPClient.STATUS_REQUESTING, HTTPClient.STATUS_BODY:
				%Status.text = "Downloading..."
			HTTPClient.STATUS_CANT_RESOLVE:
				%Status.hide()
				%Error.text = "Can't resolve hostname, check your internet connection and try again!"
		if not %Error.text.is_empty():
			%Error.show()

	if not stdout_line.is_empty():
		var percentage: float

		var matched: = Helper.match_pattern(r"(?<percentage>\d+)\%", stdout_line, ["percentage"])
		if not matched.is_empty():
			percentage = matched[0].to_float()

		%ProgressBar.value = percentage
		%Downloaded.text = "%d%%" % percentage
		%Total.text = "100%"


func download(url: String, headers: = PackedStringArray()) -> Dictionary:
	retry_function = download.bind(url)
	cancel_function = func cancel_request():
		if http.get_http_client_status() != HTTPClient.STATUS_BODY:
			queue_free()
		else:
			http.cancel_request()
			set_process(false)
			%Status.text = "Cancelled!"
			%ProgressBar.get_parent().hide()
			if not http.download_file.is_empty() and FileAccess.file_exists(http.download_file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(http.download_file))
			%Retry.show()
			%Cancel.tooltip_text = "Remove"
	%Retry.hide()
	pause_function = func pause_request(paused: bool):
		if paused and http.get_http_client_status() == HTTPClient.STATUS_BODY:
			http.cancel_request()
		elif not paused and http.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			http.request(url, ["Range: bytes=%s-" % _downloaded_bytes])
		set_process(not paused)

	var dict: = {
		"result" = HTTPRequest.RESULT_SUCCESS,
		"response_error" = HTTPClient.RESPONSE_OK,
		"file" = "",
	}
	%Name.text = url.get_file()
	%Name.tooltip_text = url.get_file()
	%ProgressBar.get_parent().show()
	%Error.hide()
	http.download_file = DOWNLOAD_FOLDER.path_join(%Name.text)

	var err: = http.request(url, headers)

	if err == OK:
		set_process(true)
		var data: Array = await http.request_completed
		set_process(false)
		dict.result = data[0]
		dict.response_error = data[1]
		dict.file = http.download_file
	else:
		dict.error = err

	#print_debug(dict)
	if dict.result != HTTPRequest.RESULT_SUCCESS:
		dict.file = ""
		%Error.show()
		%ProgressBar.get_parent().hide()
		%Error.text = "ERROR:\n%s (%s)" % [_get_result_error_message(dict.result), dict.result]
		%Cancel.hide()
		%Retry.show()
	elif dict.response_error != HTTPClient.RESPONSE_OK:
		dict.file = ""
		%Error.show()
		%ProgressBar.get_parent().hide()
		%Error.text = "RESPONSE_ERROR: %s" % dict.response_error
		%Cancel.hide()
		%Retry.show()

	download_file = dict.file
	status_update.emit(Status.DOWNLOAD_COMPLETE)
	return dict


func install(_download_file: String, installation_path: String) -> Error:
	download_file = _download_file
	installation_location = installation_path
	download_file = ProjectSettings.globalize_path(download_file)
	retry_function = install.bind(download_file, installation_path)
	#cancel_function = func cancel_installation():
		#pass

	%Retry.hide()
	%Cancel.hide()

	var async: = Async.new()
	add_child(async)
	var output: PackedStringArray = await async.execute("wmic process where name='blender.exe' get ProcessId,ExecutablePath")
	#print_debug(output)
	async.queue_free()

	if output.size() > 0:
		status_update.emit(Status.INSTALL_PAUSED)
		output.remove_at(0)
		for line in output:
			var running_blender: = line.substr(0, line.length() - "ProcessID  ".length()).strip_edges().get_base_dir().replace("\\", "/")

			if running_blender == installation_path:
				%Status.text = "Installation Paused:\nPlease close Blender before installing."
				push_warning(%Status.text)
				%Retry.show()
				return ERR_FILE_ALREADY_IN_USE

	FileAccess.open(download_file, FileAccess.READ)
	var err: = FileAccess.get_open_error()
	if err != OK:
		%Error.text = "Invalid file recieved for installation. File: %s -> Error: %s (%s)" % [download_file, error_string(err), err]
		printerr(%Error.text)
		return err
	else:
		%Status.text = "Installing..."
		%Retry.hide()
		print("Installing file: ", download_file)
	match download_file.get_extension():
		"zip":
			process = OS.execute_with_pipe(
				ProjectSettings.globalize_path("user://7za.exe"),
				[
					"x", download_file.replace("/", "\\"),
					"-o%s" % installation_path.get_base_dir().replace("/", "\\"),
					"-y",
					"-bsp1",
				]
			)

			thread.start(_continue_thread)
			set_process(true)

			await thread_complete

			set_process(false)
			if DirAccess.dir_exists_absolute(installation_path):
				Helper.remove_dir_recursive(installation_path)

			print("Renaming \"%s\" -> \"%s\"" % [installation_path.get_base_dir().path_join(download_file.get_file().replace("." + download_file.get_extension(), "")), installation_path])
			DirAccess.rename_absolute(installation_path.get_base_dir().path_join(download_file.get_file().replace("." + download_file.get_extension(), "")), installation_path)
			DirAccess.remove_absolute(download_file)
			call_thread_safe(&"emit_signal", "status_update", Status.INSTALL_COMPLETE)
			queue_free()
		"msi":
			%ProgressBar.indeterminate = true
			if OS.get_name() == "Windows":
				installation_path = installation_path.replace("/", "\\")
				OS.execute(
					"msiexec",
					[
						"/package", installation_path,
						"/log", LOGS_FOLDER.path_join(download_file.get_file()).path_join(Time.get_datetime_string_from_system(false, true)),
						"/passive",
						"/norestart"
					]
				)
			else:
				printerr("msi files can only be used in Windows.")
				return ERR_UNCONFIGURED
		_:
			printerr("Unknown file format %s. Only zip or msi can be used")
			return ERR_FILE_UNRECOGNIZED

	return OK


func retry() -> void:
	retry_function.call()


func pause(toggled: bool) -> void:
	if toggled:
		%Pause.icon = preload("res://assets/icons/play.svg")
	else:
		%Pause.icon = preload("res://assets/icons/pause.svg")

	pause_function.call(toggled)


func cancel() -> void:
	cancel_function.call()


func _continue_thread() -> void:
	var stdio: FileAccess = process.stdio
	while stdio.get_error() == OK:
		var next_length: = (stdio as FileAccess).get_length()
		if next_length > 0:
			stdout_line = stdio.get_buffer(next_length).get_string_from_ascii()
			#print_debug(stdout_line)
		stdio.get_line()

	call_thread_safe(&"emit_signal", "thread_complete")


func _on_tree_exiting() -> void:
	if thread.is_started():
		thread.wait_to_finish()


func _get_result_error_message(result: HTTPRequest.Result) -> String:
	match result:
		HTTPRequest.RESULT_SUCCESS:
			return "Request successful"
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "Request failed due to a mismatch between the expected and actual chunked body size during transfer. Possible causes include network errors, server misconfiguration, or issues with chunked encoding."
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Request failed while connecting. Check your internet connection."
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Request failed while resolving. Check your internet connection."
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Request failed due to connection (read/write) error."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "Request failed on TLS handshake."
		HTTPRequest.RESULT_NO_RESPONSE:
			return "Request does not have a response (yet)."
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "Request exceeded its maximum size limit, see body_size_limit."
		HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
			return "Request failed due to an error while decompressing the response body. Possible causes include unsupported or incorrect compression format, corrupted data, or incomplete transfer."
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "Request failed (currently unused)."
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "Couldn't open the download file."
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "Couldn't write to download file."
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "Request reached its maximum redirect limit, see max_redirects."
		HTTPRequest.RESULT_TIMEOUT:
			return "Request failed due to a timeout. If you expect requests to take a long time, try increasing the value of timeout or setting it to 0.0 to remove the timeout completely."
		_:
			return ""
