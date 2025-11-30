extends TableSection


func refresh() -> void:
	await super()
	table.set_empty_message(empty_table_message)
