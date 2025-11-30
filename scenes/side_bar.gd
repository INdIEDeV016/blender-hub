extends Control
class_name SideBar


const DOWNLOAD_CARD_SCENE: = preload("uid://0crrnrocw1ao")

@export var tween_speed: float = 2.0
@export_group("Slide In")
@export var slide_in_transition: = Tween.TRANS_QUART
@export var slide_in_ease: = Tween.EASE_OUT
@export_group("Slide Out")
@export var slide_out_transition: = Tween.TRANS_QUART
@export var slide_out_ease: = Tween.EASE_OUT

var tween: Tween

@onready var download_container: = %DownloadContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not FileAccess.file_exists("user://7za.exe"):
		DirAccess.copy_absolute("res://7za.exe", "user://7za.exe")

	get_tree().current_scene.side_bar = self


func _on_side_bar_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_sidebar()
	else:
		hide_sidebar()


func download_and_install(url: String, installation_path: String) -> Error:
	return await _download_and_install(url, installation_path)


func install(download_file: String, installation_path: String) -> Error:
	return await _download_and_install(download_file, installation_path)


func show_sidebar() -> void:
	%SideBarButton.button_pressed = true
	if tween:
		tween.kill()

	tween = create_tween().set_trans(slide_in_transition).set_ease(slide_in_ease)
	tween.tween_property(self, "position:x", get_parent_control().size.x - size.x, 1/tween_speed)


func hide_sidebar() -> void:
	%SideBarButton.button_pressed = false
	if tween:
		tween.kill()

	tween = create_tween().set_trans(slide_out_transition).set_ease(slide_out_ease)
	tween.tween_property(self, "position:x", get_parent_control().size.x, 1/tween_speed)


func _on_cancel_all_pressed():
	for download_card in %DownloadContainer.get_children():
		download_card.cancel()


func _on_pause_all_toggled(toggled_on: bool) -> void:
	%PauseAll.text = "Resume All" if toggled_on else "Pause All"
	for download_card in %DownloadContainer.get_children():
		download_card.toggle_pause(toggled_on)


func _download_and_install(source: String, installation_path: String) -> Error:
	show_sidebar()
	var download_card: DownloadCard = DOWNLOAD_CARD_SCENE.instantiate()
	download_card.status_update.connect(_on_download_card_status_update)
	download_container.add_child(download_card)
	if Helper.is_valid_url(source):
		var data: Dictionary = await download_card.download(source)
		if data.has("file") and not data.file.is_empty():
			return await download_card.install(data.file, installation_path)
		return data.error
	else:
		return await download_card.install(source, installation_path)


func _on_download_card_status_update(status: DownloadCard.Status) -> void:
	if status == DownloadCard.Status.INSTALL_COMPLETE:
		for page in get_tree().current_scene.pages:
			for table_section in page.table_sections:
				if table_section == "InstalledBlenders":
					page.table_sections[table_section].refresh()


func _on_download_container_child_exiting_tree(node: Node) -> void:
	await node.tree_exited
	if %DownloadContainer.get_child_count() == 0:
		hide_sidebar()
