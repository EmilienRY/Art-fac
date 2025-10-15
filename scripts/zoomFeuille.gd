extends Control
var currentLevel=1

var afficher_labels: bool = false

var labelsCachéTP = [["erosion", "dilatation", "flou", "gradient", "histogramme", "profil", "ouverture", "fermeture"],["erosion", "dilatation", "flou", "gradient", "ouverture", "fermeture"]]

func _ready() -> void:
	_set_labels_visible(afficher_labels)

func set_current_level(level: int) -> void:
	currentLevel = level
	_set_labels_visible(afficher_labels)

func _set_labels_visible(affichage: bool) -> void:
	var labelsCaché=labelsCachéTP[currentLevel-1]
	for child in get_children():
		if child is RichTextLabel:
			for nom in labelsCaché :
				if child.name==nom:
					child.visible = affichage

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var tween = create_tween()
		tween.tween_property(self,"position",Vector2(0, get_viewport_rect().size.y),0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(Callable(self, "queue_free")).set_delay(0.5)
