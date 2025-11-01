extends Area2D

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		transitionPC_Tableau()

func transitionPC_Tableau():
	var ui_layer = get_tree().current_scene.get_node("UI")
	if TutoTimer.running:
		var tuto_layer = get_tree().current_scene.get_node("TutoCenter")
		tuto_layer.visible = false
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/up_transition.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var player = transition.get_node("VideoStreamPlayer")
	player.finished.connect(func():_on_transition_finished(ui_layer))



func _on_transition_finished(ui_layer):
	var tableau = preload("res://scene/tableau.tscn").instantiate()
	# Récupérer le niveau actuel depuis le LevelManager
	var level_manager = get_node("/root/LevelManager")
	if level_manager:
		var current_level = level_manager.get_current_level_number()
		tableau.set_current_level(current_level)
	ui_layer.add_child(tableau)
