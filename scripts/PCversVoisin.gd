extends Area2D

var appelVoisin=0

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		transitionPC_Voisin()

func transitionPC_Voisin():
	var ui_layer = get_tree().current_scene.get_node("UI")
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/right_transition.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var player = transition.get_node("VideoStreamPlayer")
	player.finished.connect(func():_on_transition_finished(ui_layer))



func _on_transition_finished(ui_layer):
	#var voisin = preload("res://scene/voisin.tscn").instantiate()
	var voisin = preload("res://scene/voisin.tscn").instantiate()
	# Récupérer le niveau actuel depuis le LevelManager
	var level_manager = get_node("/root/LevelManager")
	if level_manager:
		level_manager.set_appel()
		appelVoisin = level_manager.get_appel()
		var current_level = level_manager.get_current_level_number()
		var indiceTermi= level_manager._get_indiceTerminal()
		var indiceLigne = level_manager._get_indiceLigneEdit()
		var imgPath = level_manager._get_img_Indice()
		var maxAppel = level_manager._get_MaxappelVoisin()
		
		voisin.set_current_level(current_level,appelVoisin,indiceTermi,indiceLigne,imgPath,maxAppel)

	ui_layer.add_child(voisin)
