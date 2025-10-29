extends Control

var currentLevel=1
var nbFois=0
var imgInter=[["res://images/chat.jpg","res://images/Yoshi.png","res://images/YoshiYukata.png"],
["res://images/chien.jpg","res://images/YoshiYukata.png","res://images/Yoshi.png"]]

var gameText: RichTextLabel
var progress_label: Label
var text_parser = TextParser.new()
var game_data_processor = GameDataProcessor.new()
var img_manager: ImageManager
var start_node: TextureRect
var level_manager: LevelManager
var player
var screen
var loop=1

var indiceEcrit = ">seuil 100"

func set_current_level(level: int, appelVoisin : int) -> void:
	currentLevel = level
	nbFois+=appelVoisin
	#set_imgAide(currentLevel)

func set_imgAide(level : int) -> void:
	var indice=$imgIntermediaire
	var texture_path
	if nbFois<=imgInter[level - 1].size():
		texture_path = imgInter[level - 1][nbFois-1]
		indice.texture = load(texture_path)
	else :
		indice.visible=false
		var imgScene=$RightIdle
		imgScene.texture = load("res://assets/voisinPasContent.png")
		#imgScene.visible=false
		#player.visible=true
		#player.size = get_viewport_rect().size
		#player.stream = load(video[randi_range(0,2)])
		#player.play()
		
func _ready() -> void:
	player = $CenterIdle/typing
	player.play()
	screen=$Screen
	_label_anim()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player.is_playing() :
			player.stop()
		print("test")
		screen.visible=false
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
