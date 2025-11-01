extends Node

# Durée du timer (modifiable si besoin)
var duration := 10.0
var time_left := 0.0
var running := false

signal timer_started
signal timer_ended
signal timer_updated(time_left)

func start_timer(seconds := duration):
	time_left = seconds
	running = true
	emit_signal("timer_started")

func stop_timer():
	running = false
	time_left = 0.0
	emit_signal("timer_ended")
	var tuto_layer = get_tree().current_scene.get_node("TutoCenter")
	tuto_layer.visible = false
	var tuto2_layer = get_tree().current_scene.get_node("TutoVoisin")
	tuto2_layer.visible = false

func _process(delta):
	if running:
		time_left -= delta
		emit_signal("timer_updated", time_left)
		if time_left <= 0:
			running = false
			time_left = 0
			emit_signal("timer_ended")
			var tuto_layer = get_tree().current_scene.get_node("TutoCenter")
			tuto_layer.visible = false
			var tuto2_layer = get_tree().current_scene.get_node("TutoVoisin")
			tuto2_layer.visible = false
