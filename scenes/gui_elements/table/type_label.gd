@tool
extends Label
class_name LabelStability


@export var current_type: = BlenderData.Stability.STABLE:
	set(new):
		current_type = new
		text = BlenderData.get_string_from_stability(new)
		add_theme_color_override("font_color", type_color[new])
		if stylebox:
			var new_stylebox = stylebox.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
			new_stylebox.bg_color = type_color[new]
			new_stylebox.bg_color.a = 0.3
			add_theme_stylebox_override("normal", new_stylebox)

@export var stylebox: StyleBoxFlat

@export var type_color: Dictionary[BlenderData.Stability, Color] = {
	BlenderData.Stability.ALPHA : Color(0.937, 0.329, 0.329, 1.0),
	BlenderData.Stability.BETA : Color(0.89, 0.643, 0.063, 1.0),
	BlenderData.Stability.RELEASE_CANDIDATE : Color("059affff"),
	BlenderData.Stability.STABLE : Color(0.357, 0.573, 0.137, 1.0),
	BlenderData.Stability.EXPERIMENTAL : Color(0.571, 0.335, 0.967, 1.0),
	BlenderData.Stability.CUSTOM : Color(0.07, 0.07, 0.07, 1.0),
	BlenderData.Stability.UNKNOWN : Color(0.33, 0.33, 0.33, 1.0),
}
