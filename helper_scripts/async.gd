extends Node
class_name Async

signal completed

var _thread: = Thread.new()
var _lines: = PackedStringArray()
var _process: = {}


func execute(command: String) -> PackedStringArray:
	#print_debug(command)
	_process = OS.execute_with_pipe("cmd.exe", ["/C", command])
	_thread.start(_loop)
	await completed
	return _lines


func _loop():
	var stdio: FileAccess = _process.stdio
	while stdio.get_error() == OK:
		var line: = stdio.get_line()
		if not line.is_empty():
			_lines.append(line)

	completed.emit.call_deferred()


func clean():
	_exit_tree()


func _exit_tree() -> void:
	if _thread.is_started():
		_thread.wait_to_finish()
