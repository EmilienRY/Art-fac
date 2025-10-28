extends Control

var currentLevel=1

var consigneEx=["res://images/chat.jpg","res://images/chien.jpg"]

func set_current_level(level: int) -> void:
	currentLevel = level
	set_consigne(currentLevel)

func set_consigne(level : int) -> void:
	var consigne=$ContenuTab
	var texture_path = consigneEx[level - 1]
	consigne.texture = load(texture_path)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		transitionTableau_PC()

func transitionTableau_PC():
	var ui_layer = get_tree().current_scene.get_node("UI")
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/down_transition.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var player = transition.get_node("VideoStreamPlayer")
	player.finished.connect(func():_on_transition_finished())

func _on_transition_finished():
	queue_free()
