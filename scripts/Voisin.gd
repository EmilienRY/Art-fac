extends Control

var currentLevel=1
var videoAngry = ["res://video/neighbor_mad1.ogv","res://video/neighbor_mad2.ogv","res://video/neighbor_mad3.ogv"]
var grognement = ["res://sound/grognement1.mp3","res://sound/grognement2.mp3","res://sound/grognement3.mp3"]
var soundAngry = ["res://sound/mad1.mp3","res://sound/mad2.mp3","res://sound/mad3.mp3"]

var indiceTerminal
var indiceEcrit
var imgPath

var played=false
var current_index = 0
var playerAngry

var player
var screen
var loop=1

var timerRegard : Timer
var tempsEntreVideo = 5.0
var tempsRestant : int
var label : Label

func set_current_level(level: int, appelVoisin : int, indiceTer : String, indiceEdit : String, img_Path : String) -> void:
	currentLevel = level
	tempsRestant=appelVoisin
	indiceTerminal = indiceTer
	indiceEcrit = indiceEdit
	imgPath=img_Path
	set_indice(indiceTerminal,imgPath)
	if tempsRestant<=0:
		_setVideoAngry()
		played = true
		tempsEntreVideo=0.0

func set_indice(indiceTer : String, img_path : String) -> void :
	$Screen/Terminal/Background/MarginContainer/Rows/indiceCommande1.text=indiceTer
	$ecranVoisin/imgIndice.texture=load(img_path)

func _setVideoAngry():
	playerAngry = $CenterIdle/typing
	playerAngry.loop=false
	$ecranVoisin.visible=false
	$Screen.visible=false
	$CenterIdle/keyBoard.autoplay=false
	$CenterIdle/keyBoard.stop()
	playerAngry.finished.connect(_on_video_finished)
	_play_current_video()


func _play_current_video():
	if current_index < videoAngry.size():
		var stream = load(videoAngry[current_index])
		if stream:
			$CenterIdle/Grognement.stream = load(soundAngry[current_index])
			$CenterIdle/Grognement.play()
			playerAngry.stream = stream
			playerAngry.play()

func _on_video_finished():
	current_index += 1
	if current_index < videoAngry.size():
		if tempsEntreVideo > 0 :
			await get_tree().create_timer(tempsEntreVideo).timeout
			tempsEntreVideo -= 3
		_play_current_video()

func _ready() -> void:
	player = $CenterIdle/typing
	player.play()
	screen=$Screen
	_label_anim()
	timerRegard=$Timer
	timerRegard.timeout.connect(_on_timer_timeout)
	timerRegard.start()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player.is_playing() :
			player.stop()
		screen.visible=false
		$ecranVoisin.visible=false
		transitionVoisin_PC()

func transitionVoisin_PC():
	var ui_layer = get_tree().current_scene.get_node("UI")
	if TutoTimer.running:
		var tuto2_layer = get_tree().current_scene.get_node("TutoVoisin")
		tuto2_layer.visible = false
	var transition = preload("res://scene/transition.tscn").instantiate()
	transition.video_path= "res://video/left_transition.ogv"
	ui_layer.add_child(transition)
	
	# Connecter un callback à la fin de la vidéo
	var playerTransition = transition.get_node("VideoStreamPlayer")
	playerTransition.finished.connect(func():_on_transition_finished())

func _on_transition_finished():
	var level_manager = get_node("/root/LevelManager")
	if TutoTimer.running:
		var tuto_layer = get_tree().current_scene.get_node("TutoCenter")
		tuto_layer.visible = true
	if level_manager:
		level_manager.update_timer(tempsRestant)
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

func _on_timer_timeout():
	var s = 10
	tempsRestant -= 1
	if tempsRestant <= 0:
		timerRegard.stop()
		if !played :
			_setVideoAngry()
	else:
		if tempsRestant <20 :
			s=5
		if tempsRestant % s  == 0:
			var numSound = randi_range(0,2)
			$CenterIdle/Grognement.stream=load(grognement[numSound])
			$CenterIdle/Grognement.play()
