extends Control


@export var height: = 50.0:
	set(new):
		height = new
		%Mover.position.y = -height - %Mover.size.y
@export var min_width: = 15.0:
	set(new):
		if not is_inside_tree():
			await ready
		min_width = new
		%Mover.custom_minimum_size.x = min_width
@export var padding: = 30
@export_group("Light")
@export var light_color: = Color("21262dff")
@export var light_brightness: = 0.5
@export_group("Tweens")
@export var tween_speed: = 3.0

var tween: Tween
var notification_queue: = PackedStringArray()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Notification.notifcation_created.connect(_on_notification_recieved)


func pop_in(text: = notification_queue[0]) -> void:
	%NotificationText.text = text
	%NotificationText.size.x = 0
	%NotificationText.position.x = padding
	var label_size: float = %NotificationText.get_combined_minimum_size().x
	if tween and tween.is_running():
		await tween.finished

	tween = create_tween().set_trans(Tween.TRANS_BACK)

	tween.tween_callback(%WaitTimer.start)
	tween.tween_callback(%WaitTimer.set_paused.bind(true))

	tween.tween_property(%Mover, "position:y", -%Mover.size.y - height, 1/tween_speed)

	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(%Mover, "position:x", -label_size/2.0 - padding, 1/tween_speed)
	#tween.parallel().tween_callback(print.bind(label_size))
	tween.parallel().tween_property(%Mover, "size:x", label_size + padding*2.0, 1/tween_speed)
	tween.tween_callback(%NotificationText.set_position.bind(Vector2(padding, %NotificationText.position.y)))
	tween.parallel().tween_callback(%NotificationText.set_size.bind(Vector2(0, %NotificationText.size.y)))

	tween.tween_property(%NotificationText, "modulate:a", 1.0, 1/tween_speed)

	tween.tween_callback(%WaitTimer.set_paused.bind(false))
	tween.tween_callback(notification_queue.remove_at.bind(0))


func pop_out() -> void:
	if tween and tween.is_running():
		await tween.finished

	tween = create_tween().set_trans(Tween.TransitionType.TRANS_CUBIC)
	tween.tween_callback(%WaitTimer.set_paused.bind(true))

	tween.tween_property(%NotificationText, "modulate:a", 0.0, 1/tween_speed)
	tween.parallel().tween_property(%Mover, "position:x", min_width/2, 1/tween_speed)
	tween.parallel().tween_property(%Mover, "size:x", min_width, 1/tween_speed)

	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(%Mover, "position:y", size.y, 1/tween_speed)

	tween.tween_callback(%NotificationText.set_text.bind(""))
	tween.tween_callback(%WaitTimer.set_paused.bind(false))


func _on_notification_recieved(text: String) -> void:
	notification_queue.append(text)
	pop_in()


func _on_timer_timeout() -> void:
	pop_out()
	if not notification_queue.is_empty():
		pop_in()
