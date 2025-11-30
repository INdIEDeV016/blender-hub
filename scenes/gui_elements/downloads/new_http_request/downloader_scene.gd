extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Downloader.download_file = "user://downloads/test.msi"
	$Downloader.request("https://download.blender.org/release/Blender4.5/blender-4.5.4-windows-x64.msi")


func _process(_delta: float) -> void:
	%ProgressBar.value = %Downloader.get_downloaded_bytes() / float(%Downloader.get_body_size()) * 100.0
