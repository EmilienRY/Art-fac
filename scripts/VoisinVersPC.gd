extends Control

var currentLevel=1
var nbFois=0
var imgInter=[["res://images/chat.jpg","res://images/Yoshi.png","res://images/YoshiYukata.png"],
["res://images/chien.jpg","res://images/YoshiYukata.png","res://images/Yoshi.png"]]

func set_current_level(level: int, appelVoisin : int) -> void:
	currentLevel = level
	nbFois+=appelVoisin
	set_imgAide(currentLevel)

func set_imgAide(level : int) -> void:
	var consigne=$imgIntermediaire
	var texture_path
	if nbFois<=imgInter[level - 1].size():
		texture_path = imgInter[level - 1][nbFois-1]
		consigne.texture = load(texture_path)
	else :
		#texture_path = imgInter[level - 1][0]
		#consigne.texture = load(texture_path)
		consigne.visible=false
		var imgScene=$imgSceneVoisin
		imgScene.texture = load("res://assets/voisinPasContent.png")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		transitionVoisin_PC()

func transitionVoisin_PC():
	var ui_layer = get_tree().current_scene.get_node("UI")
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/transitionVoisin_PC.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var player = transition.get_node("VideoStreamPlayer")
	player.finished.connect(func():_on_transition_finished())

func _on_transition_finished():
	queue_free()
