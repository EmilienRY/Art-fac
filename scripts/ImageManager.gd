class_name ImageManager

extends Node

signal image_changed(new_texture)
signal history_changed(can_undo, can_redo)

const INF = 1e30
const NEG_INF = -1e30

var current_image: Image = null
var current_texture: Texture2D = null

var history: Array = []
var history_index: int = -1
var max_history: int = 20

func load_image(file_path: String) -> bool:
	var res = ResourceLoader.load(file_path)

	current_texture = res
	current_image = current_texture.get_image()
	push_snapshot(current_image.duplicate())
	_update_texture()
	return true

func get_image() -> Image:
	return current_image.duplicate() if current_image else null

func get_texture() -> Texture2D:
	return current_texture

func apply_threshold(threshold_value: float) -> bool:

	var w = current_image.get_width()
	var h = current_image.get_height()
	for y in range(h):
		for x in range(w):
			var c: Color = current_image.get_pixel(x, y)
			var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			if lum * 255.0 >= threshold_value:
				current_image.set_pixel(x, y, Color(1, 1, 1, c.a))
			else:
				current_image.set_pixel(x, y, Color(0, 0, 0, c.a))

	push_snapshot()
	_update_texture()
	return true

func _update_texture():
	if current_image:
		current_texture = ImageTexture.create_from_image(current_image)
	else:
		current_texture = null
	emit_signal("image_changed", current_texture)

func push_snapshot(img: Image = null):
	var to_save = img if img else current_image
		
	# Supprimer l'historique après l'index actuel
	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)
	
	# Ajouter le nouvel état
	history.append(to_save.duplicate())
	history_index = history.size() - 1
	
	# Limiter la taille de l'historique
	if history.size() > max_history:
		history.remove_at(0)
		history_index = history.size() - 1
		
	_emit_history_changed()

func can_undo() -> bool:
	return history_index > 0

func can_redo() -> bool:
	return history_index < history.size() - 1

func undo() -> bool:
	if not can_undo():
		return false
		
	history_index -= 1
	current_image = history[history_index].duplicate()
	_update_texture()
	_emit_history_changed()
	return true

func redo() -> bool:
	if not can_redo():
		return false
		
	history_index += 1
	current_image = history[history_index].duplicate()
	_update_texture()
	_emit_history_changed()
	return true

func _emit_history_changed():
	emit_signal("history_changed", can_undo(), can_redo())

func clear_history():
	history = []
	history_index = -1
	_emit_history_changed()

func reset():
	current_image = null
	current_texture = null
	clear_history()
	emit_signal("image_changed", null)

func compute_mse(a, b) -> float:
	var img_a = _to_image(a)
	var img_b = _to_image(b)
	
	if not img_a or not img_b or img_a.get_size() != img_b.get_size():
		return INF

	var w = img_a.get_width()
	var h = img_a.get_height()
	var total = 0.0
	
	for y in range(h):
		for x in range(w):
			var pa = img_a.get_pixel(x, y)
			var pb = img_b.get_pixel(x, y)
			var dr = pa.r * 255.0 - pb.r * 255.0
			var dg = pa.g * 255.0 - pb.g * 255.0
			var db = pa.b * 255.0 - pb.b * 255.0
			total += (dr * dr + dg * dg + db * db) / 3.0
	
	return total / float(w * h)

func compute_psnr(a, b) -> float:
	var mse = compute_mse(a, b)
	if mse == 0.0:
		return 1e9
	if mse == INF:
		return NEG_INF
	return 10.0 * log((255.0 * 255.0) / mse) / log(10.0)

func save_png(path: String) -> bool:
	if not current_image:
		return false
	return current_image.save_png(path) == OK

func _to_image(input) -> Image:
	if input is Image:
		return input
	elif input is Texture2D:
		return input.get_image()
	return null
