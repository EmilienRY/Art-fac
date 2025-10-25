extends Node2D

@export var video_path: String = ""  # Chemin de la vidéo à jouer

func _ready():
	var player = $VideoStreamPlayer
	
	if video_path != "":
		player.stream = load(video_path)
	
	player.expand = true
	_update_video_size()
	get_viewport().connect("size_changed", Callable(self, "_update_video_size"))
	player.play()
	player.connect("finished", Callable(self, "_on_video_finished"))

func _update_video_size():
	#adapte la taille de la vidéo à la taille de l'écran
	$VideoStreamPlayer.size = get_viewport_rect().size

func _on_video_finished():
	#Petit délais pour éviter un bug visuel à la fin de la vidéo
	await get_tree().create_timer(0.2).timeout
	queue_free()
