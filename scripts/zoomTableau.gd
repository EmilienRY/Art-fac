extends Control

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		transitionTableau_PC()

func transitionTableau_PC():
	var ui_layer = get_tree().current_scene.get_node("UI")
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/transitionTableau_PC.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var player = transition.get_node("VideoStreamPlayer")
	player.finished.connect(func():_on_transition_finished(ui_layer))



func _on_transition_finished(ui_layer):
	queue_free()
