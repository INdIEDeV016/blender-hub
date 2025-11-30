extends VBoxContainer



func _ready() -> void:
	%HTabs.tab_container = $TabContainer
	%HTabs.current_tab = 0


func _on_label_meta_clicked(meta: Variant) -> void:
	if meta is String:
		if Helper.is_valid_url(meta):
			OS.shell_open(meta)


func _on_tab_container_child_entered_tree(node: Node) -> void:
	if not node.name.begins_with("@"):
		%HTabs.add_tab(node.name.capitalize())
