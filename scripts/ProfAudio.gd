extends Node

var has_played_intro := false
var player: AudioStreamPlayer

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	player.connect("finished", Callable(self, "_on_audio_finished"))

func play_intro_once():
	if not has_played_intro:
		player.stream = preload("res://sound/intro.mp3")
		player.play()
		has_played_intro = true
		player.autoplay = false
		player.volume_db = -15
		
func mute():
	player.volume_db = -80

func _on_audio_finished():
	var mute_layer = get_tree().current_scene.get_node("MuteProf")
	mute_layer.visible = false
