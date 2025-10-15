extends Area2D

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_pc()

func show_pc():
	var ui_layer = get_tree().current_scene.get_node("UI")  # ton CanvasLayer
	var pc = preload("res://scene/mainScene.tscn").instantiate()
	
	ui_layer.add_child(pc)  # ajoute au-dessus de la scène
	
	var tween = create_tween()
	tween.tween_property(self,"position",Vector2(0, get_viewport_rect().size.y),0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "queue_free")).set_delay(0.5)
	
