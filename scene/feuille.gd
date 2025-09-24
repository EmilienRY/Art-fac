extends Area2D  # ou Node2D si tu détectes le clic manuellement

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_leaf()

func show_leaf():
	var ui_layer = get_tree().current_scene.get_node("UI")  # ton CanvasLayer
	var feuille_zoom = preload("res://scene/FeuilleZoom.tscn").instantiate()
	ui_layer.add_child(feuille_zoom)  # ajoute au-dessus de la scène
