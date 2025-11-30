extends Control


@export var tab_bar_minimum_width: = 200.0
@export var tab_icon_width: = 20

var button_group: = ButtonGroup.new()

@onready var side_bar: SideBar = %SideBar
@onready var pages: Array[Page]

func _ready() -> void:
	button_group.pressed.connect(_on_tab_clicked)
	%App/Name.text = ProjectSettings.get_setting("application/config/name")
	%App/Icon.texture = load(ProjectSettings.get_setting("application/config/icon"))
	set_app_theme(Settings.get_setting("Themes", "app_theme", "System Default")[1])

	#TODO
	add_tab("Projects", "Projects (Coming Soon)", preload("res://assets/icons/project.svg"), -1, "Projects").disabled = true
	(%Tabs.get_child(0) as Button).button_pressed = true

	Settings.setting_changed.connect(_on_settings_change)
	Notification.notify("Welcome to Blender Hub!")


func _on_settings_pressed() -> void:
	%Windows/Settings.popup_centered()


func _on_pages_child_entered_tree(node: Node) -> void:
	if node is Page:
		add_tab(node.name, "", node.tab_icon)


func add_tab(tab_name: String, tooltip: = "", icon: Texture2D = null, at: = -1, internal_name: = "") -> Button:
	var button: = Button.new()
	button.name = tab_name if internal_name.is_empty() else internal_name
	button.text = tab_name.capitalize()
	button.tooltip_text = tooltip if not tooltip.is_empty() else button.text
	button.clip_text = true
	button.icon = icon
	button.add_theme_constant_override("icon_max_width", tab_icon_width)
	button.toggle_mode = true
	button.theme_type_variation = &"NavBarButtons"
	button.button_group = button_group
	%Tabs.add_child(button)
	%Tabs.move_child(button, at)
	return button


func _on_tab_clicked(button: BaseButton) -> void:
	%Pages.current_tab = button.get_index()


func set_app_theme(theme_name: StringName) -> void:
	var app_theme: Theme
	if not theme_name == "System Default":
		app_theme = load("res://assets/themes/%s.theme" % theme_name.to_snake_case())
	elif DisplayServer.is_dark_mode():
		app_theme = load("res://assets/themes/default_dark.theme")
	else:
		app_theme = load("res://assets/themes/default_light.theme")

	get_tree().current_scene.theme = app_theme


func _on_settings_change(section: StringName, key: StringName, value) -> void:
	if section == "Themes" and key == "app_theme":
		set_app_theme(value[1])


func _on_h_split_container_dragged(_offset: int) -> void:
	var tab_bar_size: float = %HSplitContainer.get_child(0).size.x
	if tab_bar_size < tab_bar_minimum_width:
		%App.hide()
	else:
		%App.show()
