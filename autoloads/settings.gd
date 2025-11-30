extends Node
## The class for handling settings of a game/app.
##
## This class has a configuration file associated to it.
## Therefore, the settings are saved in the format of configuration files (ini, cfg, etc.).
## This means that the files are saved as section -> key -> value.
## The settings are loaded once on [signal Node.ready] from the file, and later when [method get_setting] or [method set_setting] are called,
## the settings are loaded from [member cfg].

## When a settings changes this signal is called.
## [param section] is the section defined in [member cfg] file.
signal setting_changed(section: StringName, key: StringName, value)
## The complete path of the file where it will be saved and loaded from.
@export var path: = "user://settings.ini"

## The [ConfigFile] class for the file that is used for saving and managing the settings.
var cfg: = ConfigFile.new()
## Variable only used when extremely needed to get the scene associated with the main settings scene.
## Set this variable to the scene that is mainly considered to be the settings scene for the game/app.
var setting_scene: Control


func _ready() -> void:
	var err: = cfg.load(path)
	if err != OK:
		printerr("Error loading Settings file. Error: ", error_string(err))

## Checks whether the setting exists in [member cfg] based on the given [param section] and [param key].
func has_setting(section: StringName, key: StringName) -> bool:
	return cfg.has_section_key(section, key)

## Gets the value of the desired setting. Raises a warning or an error if a default value is provided or not provided respectively.
func get_setting(section: StringName, key: StringName, default_value: Variant = null):
	if not has_setting(section, key):
		if default_value != null:
			push_warning("The setting doesn't exist. Returning default value instead -> ", default_value)
		else:
			printerr("The setting doesn't exist. No default value set returning null!")
	return cfg.get_value(section, key, default_value)

## Sets the value of the desired setting. Passing a null value deletes the setting.
func set_setting(section: StringName, key: StringName, value: Variant, save_setting: = false):
	setting_changed.emit(section, key, value)
	cfg.set_value(section, key, value)
	if save_setting:
		save()

## Checks whether the provided [param section] exists in the [member cfg].
func has_section(section: StringName) -> bool:
	return cfg.has_section(section)

## Get the names of all the sections available in [member cfg].
func get_sections() -> PackedStringArray:
	return cfg.get_sections()

## Get the contents of the desired [param section] from the [member cfg] in a dictionary format with key-value.
func get_section(section: StringName) -> Dictionary:
	var dict: = {}
	for key in cfg.get_section_keys(section):
		dict[key] = cfg.get_value(section, key)
	return dict

## Sets the settings of a [param section] using [param dict] where all the values are in key-value format.
func set_section(section: StringName, dict: Dictionary) -> void:
	for key in dict.keys():
		cfg.set_value(section, key, dict[key])

## Saves the settings to the file on demand at the path provided in [member path]. Returns other than [constant @GlobalScope.OK] when failing to do so
func save() -> Error:
	return cfg.save(path)

## Resets the settings by copying the given [param file] to the saved location specified in [member path] and overwrites the file. Then [method reload]s the file.
func reset(file: String) -> void:
	var d: = DirAccess.open(file.get_base_dir())
	if DirAccess.get_open_error() == OK:
		var err: = d.copy(file, path)
		if err != OK:
			printerr("Couldn't overwrite file from %s to %s | Error: %s" % [file, path, error_string(err)])
		reload()
	else:
		printerr("Couldn't open directory %s | Error: %s" % [file.get_base_dir(), error_string(DirAccess.get_open_error())])

## Loads the settings from the file and puts the values in [member cfg]
func reload() -> Error:
	return cfg.load(path)
