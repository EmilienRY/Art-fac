extends Control

var currentLevel=1
var nbAppel=0
var videoAngry = ["res://video/neighbor_mad1.ogv","res://video/neighbor_mad2.ogv","res://video/neighbor_mad3.ogv"]

var indiceTerminal
var indiceEcrit
var imgPath
var maxAppel

var player
var screen
var loop=1



func set_current_level(level: int, appelVoisin : int, indiceTer : String, indiceEdit : String, img_Path : String, maxAppelVoisin : int) -> void:
	currentLevel = level
	nbAppel=appelVoisin
	indiceTerminal = indiceTer
	indiceEcrit = indiceEdit
	imgPath=img_Path
	maxAppel=maxAppelVoisin
	set_indice(indiceTerminal,imgPath)
	if nbAppel>maxAppel:
		_setVideoAngry()

func set_indice(indiceTer : String, img_path : String) -> void :
	$Screen/Terminal/Background/MarginContainer/Rows/indiceCommande1.text=indiceTer
	$ecranVoisin/imgIndice.texture=load(img_path)

func _setVideoAngry():
	var numVideo = randi_range(0,2)
	$CenterIdle/typing.stream=load(videoAngry[numVideo])
	$CenterIdle/typing.loop=false
	$ecranVoisin.visible=false
	$Screen.visible=false

func _ready() -> void:
	player = $CenterIdle/typing
	player.play()
	screen=$Screen
	_label_anim()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player.is_playing() :
			player.stop()
		screen.visible=false
		$ecranVoisin.visible=false
		transitionVoisin_PC()

func transitionVoisin_PC():
	var ui_layer = get_tree().current_scene.get_node("UI")
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/left_transition.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var playerTransition = transition.get_node("VideoStreamPlayer")
	playerTransition.finished.connect(func():_on_transition_finished())

func _on_transition_finished():
	queue_free()

func _label_anim():
	var labelCommandeEcrite = $Screen/Terminal/Background/MarginContainer/Rows/HBoxContainer/indiceCommande2
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.autostart = true
	timer.one_shot = false
	labelCommandeEcrite.add_child(timer)
	timer.timeout.connect(func(): update_label(labelCommandeEcrite))

func update_label(labelCommandeEcrite : Label):
	if loop > indiceEcrit.length():
		loop=1
	labelCommandeEcrite.text=indiceEcrit.substr(0,loop)
	loop+=1
