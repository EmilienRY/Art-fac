extends Control

var currentLevel=1
var nbFois=0
var imgInter=[["res://images/chat.jpg","res://images/Yoshi.png","res://images/YoshiYukata.png"],
["res://images/chien.jpg","res://images/YoshiYukata.png","res://images/Yoshi.png"]]
var video = ["res://video/neighbor_mad1.ogv","res://video/neighbor_mad2.ogv","res://video/neighbor_mad3.ogv"]

func set_current_level(level: int, appelVoisin : int) -> void:
	currentLevel = level
	nbFois+=appelVoisin
	set_imgAide(currentLevel)

func set_imgAide(level : int) -> void:
	var indice=$imgIntermediaire
	var player = $VideoStreamPlayer
	var texture_path
	if nbFois<=imgInter[level - 1].size():
		texture_path = imgInter[level - 1][nbFois-1]
		indice.texture = load(texture_path)
	else :
		indice.visible=false
		var imgScene=$RightIdle
		#imgScene.texture = load("res://assets/voisinPasContent.png")
		imgScene.visible=false
		player.visible=true
		player.size = get_viewport_rect().size
		player.stream = load(video[randi_range(0,2)])
		player.play()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		transitionVoisin_PC()

func transitionVoisin_PC():
	var ui_layer = get_tree().current_scene.get_node("UI")
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/left_transition.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var player = transition.get_node("VideoStreamPlayer")
	player.finished.connect(func():_on_transition_finished())

func _on_transition_finished():
	queue_free()
