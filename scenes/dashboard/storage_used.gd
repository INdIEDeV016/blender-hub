extends VBoxContainer


@export var danger_gradient: = Gradient.new()
@export_group("Tween")
@export var tween_speed: float = 0.3
@export var tween_transition: Tween.TransitionType = Tween.TRANS_EXPO
@export var tween_easing: Tween.EaseType = Tween.EASE_OUT

var tween: Tween


func _ready():
	await get_tree().current_scene.ready
	refresh()


func refresh() -> void:
	var dir: = DirAccess.open(Settings.get_setting("Projects", "default_project_repository", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Blender/Projects")))
	if DirAccess.get_open_error() == OK:
		var drive_letter: = DirAccess.get_drive_name(dir.get_current_drive())
		%DriveName.text = "%s Drive:" % drive_letter.remove_char(ord(":"))
		var drive: = Helper.get_drive_space_availability(drive_letter)
		drive.space_used = drive.size - drive.free_space

		var storage_percentage: = float(drive.space_used)/float(drive.size) * 100

		if tween and tween.is_running():
			tween.kill()

		tween = create_tween().set_trans(tween_transition).set_ease(tween_easing).set_parallel()
		tween.tween_property(%StorageProgress, "value", storage_percentage, 1/tween_speed).from(0.0)
		tween.tween_property(%StorageAmount, "text", String.humanize_size(drive.space_used) + " / " + String.humanize_size(drive.size) + "  (%s Free)" % String.humanize_size(drive.free_space), 1/tween_speed)
	else:
		hide()


func _on_storage_progress_value_changed(value: float) -> void:
	%StoragePercentage.text = str(value) + " %"
	%StoragePercentage.self_modulate = danger_gradient.sample(value / 100)
