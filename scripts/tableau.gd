extends Area2D

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_board()

func show_board():
	var ui_layer = get_tree().current_scene.get_node("UI")  # ton CanvasLayer
	var tableau = preload("res://scene/tableau.tscn").instantiate()
	
	# Récupérer le niveau actuel depuis le LevelManager
	#var level_manager = get_node("/root/LevelManager")
	#if level_manager:
		#var current_level = level_manager.get_current_level_number()
		#tableau.set_current_level(current_level)
	
	ui_layer.add_child(tableau)  # ajoute au-dessus de la scène
	
	tableau.position = Vector2(0, get_viewport_rect().size.y)
	# Tween pour glissement vers le haut
	var tween = create_tween()
	tween.tween_property(tableau,"position",Vector2(0, 0),0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
