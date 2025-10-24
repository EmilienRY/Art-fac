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
	$VideoStreamPlayer.size = get_viewport_rect().size

func _on_video_finished():
	queue_free()
	print("video fini")
