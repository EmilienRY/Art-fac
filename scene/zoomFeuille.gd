extends Control

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var tween = create_tween()
		tween.tween_property(self,"position",Vector2(0, get_viewport_rect().size.y),0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(Callable(self, "queue_free")).set_delay(0.5)
