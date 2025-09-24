extends Control

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		queue_free()
