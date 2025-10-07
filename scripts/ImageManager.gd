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

func _init():
	current_image = null
	current_texture = null
	history = []
	history_index = -1

func load_image(file_path: String) -> bool:
	var res = ResourceLoader.load(file_path)
	if res != null:
		current_texture = res
		current_image = current_texture.get_image()
		emit_signal("image_changed", current_texture)
		push_snapshot( current_image.duplicate())
		return true
	return false

func get_image() -> Image:
	return current_image.duplicate()

func get_texture() -> Texture2D:
	return current_texture

func apply_threshold(threshold_value: float) -> bool:
	if current_image == null:
		push_error("ImageManager: no image loaded")
		return false

	var w = current_image.get_width()
	var h = current_image.get_height()
	for y in range(h):
		for x in range(w):
			var c: Color = current_image.get_pixel(x, y)
			var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			var lum255 = lum * 255.0
			if lum255 >= threshold_value:
				current_image.set_pixel(x, y, Color(1, 1, 1, c.a))
			else:
				current_image.set_pixel(x, y, Color(0, 0, 0, c.a))

	_finalize_image_update()
	return true

func _finalize_image_update():
	if current_image == null:
		current_texture = null
		emit_signal("image_changed", null)
		return
	current_texture = ImageTexture.create_from_image(current_image)
	push_snapshot()
	emit_signal("image_changed", current_texture)

func _update_texture() -> void:
	if current_image == null:
		current_texture = null
		emit_signal("image_changed", null)
		return
	current_texture = ImageTexture.create_from_image(current_image)
	emit_signal("image_changed", current_texture)

func push_snapshot(img: Image = null) -> void:
	var to_save = img if img != null else current_image
	if to_save == null:
		return
	var copy = to_save.duplicate()
	if history_index < history.size() - 1:
		while history.size() - 1 > history_index:
			history.pop_back()
	history.append(copy)
	history_index = history.size() - 1
	if history.size() > max_history:
		history.remove_at(0)
		history_index = history.size() - 1
	emit_signal("history_changed", can_undo(), can_redo())

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
	emit_signal("history_changed", can_undo(), can_redo())
	return true

func redo() -> bool:
	if not can_redo():
		return false
	history_index += 1
	current_image = history[history_index].duplicate()
	_update_texture()
	emit_signal("history_changed", can_undo(), can_redo())
	return true

func clear_history() -> void:
	history = []
	history_index = -1
	emit_signal("history_changed", can_undo(), can_redo())

func reset() -> void:
	current_image = null
	current_texture = null
	clear_history()
	emit_signal("image_changed", null)

func compute_mse(a, b) -> float:
	var img_a: Image
	var img_b: Image

	if typeof(a) == TYPE_OBJECT and a is Texture2D:
		img_a = a.get_image()
	elif a is Image:
		img_a = a
	else:
		push_error("compute_mse: unsupported type for first argument")
		return INF

	if typeof(b) == TYPE_OBJECT and b is Texture2D:
		img_b = b.get_image()
	elif b is Image:
		img_b = b
	else:
		push_error("compute_mse: unsupported type for second argument")
		return INF

	if img_a.get_size() != img_b.get_size():
		push_error("compute_mse: image sizes differ")
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
		return -INF
	var max_i = 255.0
	return 10.0 * (log((max_i * max_i) / mse) / log(10.0))

func save_png(path: String) -> bool:
	if current_image == null:
		push_error("save_png: no image loaded")
		return false
	var err = current_image.save_png(path)
	if err != OK:
		push_error("save_png failed: %s" % str(err))
		return false
	return true
