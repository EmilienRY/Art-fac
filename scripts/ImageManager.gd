class_name ImageManager

extends Node

signal image_changed(new_texture)
signal history_changed(can_undo, can_redo)
signal progress_changed(progress)

const INF = 1e30
const NEG_INF = -1e30

var current_image: Image = null
var current_texture: Texture2D = null

var history: Array = []
var history_index: int = -1
var max_history: int = 20

var image_saved: Dictionary = {}

var mutex: Mutex
var thread: Thread
var semaphore: Semaphore
var is_processing: bool = false
var _thread_result: Image = null
var _thread_done_flag: bool = false
var _thread_progress: float = 0.0
var _thread_shows_progress: bool = false
var _last_printed_progress: int = -1

func _ready() -> void:
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	is_processing = false
	set_process(true)
	_thread_progress = 0.0
	_thread_shows_progress = false
	_last_printed_progress = -1

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

func transform_to_grayscale() -> bool:
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_shows_progress = false
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("grayscale", img))
	return true

func apply_threshold(t: int, color_mode: int) -> bool:
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_shows_progress = false
	mutex.unlock()

	thread.start(Callable(self, "_thread_worker").bind("threshold", [img, t, color_mode]))
	return true

func erosionPPM_mat3x3() -> bool:
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_progress = 0.0
	_thread_shows_progress = true
	_last_printed_progress = -1
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("erosion", img))

	return true

func dilatationPPM_mat3x3() -> bool:
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_progress = 0.0
	_thread_shows_progress = true
	_last_printed_progress = -1
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("dilatation", img))
	return true

func equalize_histogram() -> bool:
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_progress = 0.0
	_thread_shows_progress = true
	_last_printed_progress = -1
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("equalize", img))
	return true

func gaussian_blur(mask_name: String = "", iterations: int = 1) -> bool:
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var mask_img: Image = null
	if mask_name != "":
		if image_saved.has(mask_name):
			mask_img = image_saved[mask_name].duplicate()
		else:
			return false
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_progress = 0.0
	_thread_shows_progress = true
	_last_printed_progress = -1
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("gaussian", [img, mask_img, iterations]))
	return true

func compute_difference(image_name: String) -> bool:
	if not current_image or is_processing:
		return false
	if not image_saved.has(image_name):
		return false
	var img2 = image_saved[image_name].duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_shows_progress = false
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("difference", [current_image.duplicate(), img2]))
	return true

func compute_gradient():
	if not current_image or is_processing:
		return false
	var img = current_image.duplicate()
	var th = Thread.new()
	is_processing = true
	thread = th
	mutex.lock()
	_thread_progress = 0.0
	_thread_shows_progress = true
	_last_printed_progress = -1
	mutex.unlock()
	thread.start(Callable(self, "_thread_worker").bind("gradient", img))
	return true


func _thread_worker(op, payload = null) -> void:

	var actual_op = op
	var actual_payload = payload
	if op is Array and payload == null:
		if op.size() > 0:
			actual_op = op[0]
		if op.size() > 1:
			actual_payload = op[1]

	var result: Image = null
	match actual_op:
		"grayscale":
			var img: Image = actual_payload
			result = _proc_grayscale(img)
		"threshold":
			var args = actual_payload
			result = _proc_threshold(args[0], args[1], args[2])
		"erosion":
			var img2: Image = actual_payload
			result = _proc_erosion(img2)
		"dilatation":
			var img3: Image = actual_payload
			result = _proc_dilatation(img3)
		"equalize":
			var img4: Image = actual_payload
			result = _proc_equalize(img4)
		"gaussian":
			var args = actual_payload
			var iters = 1
			if args is Array and args.size() > 2:
				iters = int(args[2])
			result = _proc_gaussian_blur(args[0], args[1], iters)
		"difference":
			var args = actual_payload
			result = _proc_difference(args[0], args[1])
		"gradient":
			var img5: Image = actual_payload
			result = _proc_gradient(img5)
		_:
			result = null

	mutex.lock()
	_thread_result = result
	_thread_done_flag = true
	mutex.unlock()

func _process(delta: float) -> void:
	if is_processing and _thread_shows_progress:
		mutex.lock()
		var p = _thread_progress
		mutex.unlock()
		var percent = int(round(p * 100.0))
		if percent != _last_printed_progress:
			_last_printed_progress = percent
			emit_signal("progress_changed", p) 

	mutex.lock()
	var done = _thread_done_flag
	mutex.unlock()
	if done:
		mutex.lock()
		var res = _thread_result
		_thread_result = null
		_thread_done_flag = false
		mutex.unlock()

		if res:
			current_image = res
			push_snapshot(res)
			_update_texture()
			_emit_history_changed()

		if _thread_shows_progress:
			emit_signal("progress_changed", 1.0) 
		_thread_shows_progress = false
		_last_printed_progress = -1
		_thread_progress = 0.0

		is_processing = false
		if thread:
			thread.wait_to_finish()
			thread = null

func _proc_gradient(img: Image) -> Image:
	var w = img.get_width()
	var h = img.get_height()

	var grad_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	grad_img.fill(Color(0, 0, 0, 1))

	for y in range(h):
		for x in range(w):
			var nl = img.get_pixel(clamp(x - 1, 0, w - 1), clamp(y - 1, 0, h - 1))
			var nn = img.get_pixel(x, clamp(y - 1, 0, h - 1))
			var nr = img.get_pixel(clamp(x + 1, 0, w - 1), clamp(y - 1, 0, h - 1))
			var ml = img.get_pixel(clamp(x - 1, 0, w - 1), y)
			var mr = img.get_pixel(clamp(x + 1, 0, w - 1), y)
			var bl = img.get_pixel(clamp(x - 1, 0, w - 1), clamp(y + 1, 0, h - 1))
			var bn = img.get_pixel(x, clamp(y + 1, 0, h - 1))
			var br = img.get_pixel(clamp(x + 1, 0, w - 1), clamp(y + 1, 0, h - 1))

			var nl_r = int(round(nl.r * 255.0)); var nl_g = int(round(nl.g * 255.0)); var nl_b = int(round(nl.b * 255.0))
			var nn_r = int(round(nn.r * 255.0)); var nn_g = int(round(nn.g * 255.0)); var nn_b = int(round(nn.b * 255.0))
			var nr_r = int(round(nr.r * 255.0)); var nr_g = int(round(nr.g * 255.0)); var nr_b = int(round(nr.b * 255.0))
			var ml_r = int(round(ml.r * 255.0)); var ml_g = int(round(ml.g * 255.0)); var ml_b = int(round(ml.b * 255.0))
			var mr_r = int(round(mr.r * 255.0)); var mr_g = int(round(mr.g * 255.0)); var mr_b = int(round(mr.b * 255.0))
			var bl_r = int(round(bl.r * 255.0)); var bl_g = int(round(bl.g * 255.0)); var bl_b = int(round(bl.b * 255.0))
			var bn_r = int(round(bn.r * 255.0)); var bn_g = int(round(bn.g * 255.0)); var bn_b = int(round(bn.b * 255.0))
			var br_r = int(round(br.r * 255.0)); var br_g = int(round(br.g * 255.0)); var br_b = int(round(br.b * 255.0))

			var gx_r = (-1 * nl_r) + (1 * nr_r) + (-2 * ml_r) + (2 * mr_r) + (-1 * bl_r) + (1 * br_r)
			var gy_r = (-1 * nl_r) + (-2 * nn_r) + (-1 * nr_r) + (1 * bl_r) + (2 * bn_r) + (1 * br_r)
			var gx_g = (-1 * nl_g) + (1 * nr_g) + (-2 * ml_g) + (2 * mr_g) + (-1 * bl_g) + (1 * br_g)
			var gy_g = (-1 * nl_g) + (-2 * nn_g) + (-1 * nr_g) + (1 * bl_g) + (2 * bn_g) + (1 * br_g)
			var gx_b = (-1 * nl_b) + (1 * nr_b) + (-2 * ml_b) + (2 * mr_b) + (-1 * bl_b) + (1 * br_b)
			var gy_b = (-1 * nl_b) + (-2 * nn_b) + (-1 * nr_b) + (1 * bl_b) + (2 * bn_b) + (1 * br_b)

			var mag_r = int(round(sqrt(float(gx_r * gx_r + gy_r * gy_r))))
			var mag_g = int(round(sqrt(float(gx_g * gx_g + gy_g * gy_g))))
			var mag_b = int(round(sqrt(float(gx_b * gx_b + gy_b * gy_b))))
			mag_r = clamp(mag_r, 0, 255)
			mag_g = clamp(mag_g, 0, 255)
			mag_b = clamp(mag_b, 0, 255)

			var grey = float(mag_r + mag_g + mag_b) / 3.0 / 255.0
			var alpha = img.get_pixel(x, y).a
			grad_img.set_pixel(x, y, Color(grey, grey, grey, alpha))

		mutex.lock()
		_thread_progress = float(y + 1) / float(h)
		mutex.unlock()

	return grad_img

func _proc_difference(img_a: Image, img_b: Image) -> Image:
	var w = img_a.get_width()
	var h = img_a.get_height()
	if w != img_b.get_width() or h != img_b.get_height():
		return img_a

	for y in range(h):
		for x in range(w):
			var ca: Color = img_a.get_pixel(x, y)
			var cb: Color = img_b.get_pixel(x, y)
			var dr = abs(int(round(ca.r * 255.0)) - int(round(cb.r * 255.0)))
			var dg = abs(int(round(ca.g * 255.0)) - int(round(cb.g * 255.0)))
			var db = abs(int(round(ca.b * 255.0)) - int(round(cb.b * 255.0)))
			img_a.set_pixel(x, y, Color(float(dr) / 255.0, float(dg) / 255.0, float(db) / 255.0, ca.a))
	return img_a

func _proc_grayscale(img: Image) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			img.set_pixel(x, y, Color(lum, lum, lum, c.a))
	return img

func _proc_threshold(img: Image, t: int, color_mode: int) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var c = img.get_pixel(x, y)
			var r = int(round(c.r * 255.0))
			var g = int(round(c.g * 255.0))
			var b = int(round(c.b * 255.0))
			if color_mode == 0: # red
				var nr = 255 if r >= t else 0
				img.set_pixel(x, y, Color(nr / 255.0, g / 255.0, b / 255.0, c.a))
			elif color_mode == 1: # green
				var ng = 255 if g >= t else 0
				img.set_pixel(x, y, Color(r / 255.0, ng / 255.0, b / 255.0, c.a))
			elif color_mode == 2: # blue
				var nb = 255 if b >= t else 0
				img.set_pixel(x, y, Color(r / 255.0, g / 255.0, nb / 255.0, c.a))
			else: # all
				var nr = 255 if r >= t else 0
				var ng = 255 if g >= t else 0
				var nb = 255 if b >= t else 0
				img.set_pixel(x, y, Color(nr / 255.0, ng / 255.0, nb / 255.0, c.a))
	return img

func _proc_erosion(src: Image) -> Image:
	var w = src.get_width()
	var h = src.get_height()
	var copy_src = src.duplicate()
	for y in range(h):
		for x in range(w):
			var minR = 255
			var minG = 255
			var minB = 255
			for j in range(-1, 2):
				for i in range(-1, 2):
					var nx = x + i
					var ny = y + j
					if nx >= 0 and ny >= 0 and nx < w and ny < h:
						var nc = copy_src.get_pixel(nx, ny)
						var vr = int(round(nc.r * 255.0))
						var vg = int(round(nc.g * 255.0))
						var vb = int(round(nc.b * 255.0))
						if vr < minR:
							minR = vr
						if vg < minG:
							minG = vg
						if vb < minB:
							minB = vb
			var a = copy_src.get_pixel(x, y).a
			src.set_pixel(x, y, Color(minR / 255.0, minG / 255.0, minB / 255.0, a))
		mutex.lock()
		_thread_progress = float(y + 1) / float(h)
		mutex.unlock()
	return src

func _proc_dilatation(src: Image) -> Image:
	var w = src.get_width()
	var h = src.get_height()
	var copy_src = src.duplicate()
	for y in range(h):
		for x in range(w):
			var maxR = 0
			var maxG = 0
			var maxB = 0
			for j in range(-1, 2):
				for i in range(-1, 2):
					var nx = x + i
					var ny = y + j
					if nx >= 0 and ny >= 0 and nx < w and ny < h:
						var nc = copy_src.get_pixel(nx, ny)
						var vr = int(round(nc.r * 255.0))
						var vg = int(round(nc.g * 255.0))
						var vb = int(round(nc.b * 255.0))
						if vr > maxR:
							maxR = vr
						if vg > maxG:
							maxG = vg
						if vb > maxB:
							maxB = vb
			var a = copy_src.get_pixel(x, y).a
			src.set_pixel(x, y, Color(maxR / 255.0, maxG / 255.0, maxB / 255.0, a))
		mutex.lock()
		_thread_progress = float(y + 1) / float(h)
		mutex.unlock()
	return src

func build_map(hist: PackedInt32Array) -> PackedInt32Array:
	var n = hist.size()
	var total_pixels = 0
	for i in range(n):
		total_pixels += hist[i]

	var cdf = PackedInt32Array()
	cdf.resize(n)
	var cum = 0
	for i in range(n):
		cum += hist[i]
		cdf[i] = cum

	var cdf_min = 0
	for i in range(n):
		if cdf[i] > 0:
			cdf_min = cdf[i]
			break

	var mp = PackedInt32Array()
	mp.resize(n)
	if total_pixels == 0 or total_pixels == cdf_min:
		for i in range(n):
			mp[i] = i
	else:
		for i in range(n):
			var val = float(cdf[i] - cdf_min) / float(total_pixels - cdf_min)
			var nv = int(round(val * float(n - 1)))
			mp[i] = clamp(nv, 0, n - 1)

	return mp

func _proc_equalize(src: Image) -> Image:
	var w = src.get_width()
	var h = src.get_height()

	var hist_r = PackedInt32Array()
	var hist_g = PackedInt32Array()
	var hist_b = PackedInt32Array()
	hist_r.resize(256)
	hist_g.resize(256)
	hist_b.resize(256)
	for i in range(256):
		hist_r[i] = 0
		hist_g[i] = 0
		hist_b[i] = 0

	for y in range(h):
		for x in range(w):
			var c = src.get_pixel(x, y)
			var ir = int(round(c.r * 255.0))
			var ig = int(round(c.g * 255.0))
			var ib = int(round(c.b * 255.0))
			ir = clamp(ir, 0, 255)
			ig = clamp(ig, 0, 255)
			ib = clamp(ib, 0, 255)
			hist_r[ir] += 1
			hist_g[ig] += 1
			hist_b[ib] += 1


	var map_r = build_map(hist_r)
	var map_g = build_map(hist_g)
	var map_b = build_map(hist_b)

	for y in range(h):
		for x in range(w):
			var c = src.get_pixel(x, y)
			var ir = int(round(c.r * 255.0))
			var ig = int(round(c.g * 255.0))
			var ib = int(round(c.b * 255.0))
			ir = clamp(ir, 0, 255)
			ig = clamp(ig, 0, 255)
			ib = clamp(ib, 0, 255)
			var nr = float(map_r[ir]) / 255.0
			var ng = float(map_g[ig]) / 255.0
			var nb = float(map_b[ib]) / 255.0
			src.set_pixel(x, y, Color(nr, ng, nb, c.a))

		mutex.lock()
		_thread_progress = float(y + 1) / float(h)
		mutex.unlock()

	return src


func _update_texture():

	if current_image:
		current_texture = ImageTexture.create_from_image(current_image)
	else:
		current_texture = null
	emit_signal("image_changed", current_texture)

func push_snapshot(img: Image = null):
	var to_save = img if img else current_image
		
	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)
	
	history.append(to_save.duplicate())
	history_index = history.size() - 1
	
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
	var psnr = 10.0 * log((255.0 * 255.0) / mse) / log(10.0)
	return round(psnr * 100.0) / 100.0

func get_desktop_path() -> String:
	var os_name = OS.get_name()
	var path = ""
	
	match os_name:
		"Windows":
			path = OS.get_environment("USERPROFILE") + "\\Documents"
		"macOS", "Linux", "FreeBSD":
			path = OS.get_environment("HOME") + "/Documents"
		_:
			push_warning("OS non reconnu : " + os_name)
	
	return path



func save_png() -> bool:

	var path = get_desktop_path() + "\\output_image.png"

	print("Saving image to: " + path)

	if not current_image:
		return false
	return current_image.save_png(path) == OK

func save(name_to_save:String) -> bool:
	if not current_image:
		return false
	if image_saved.has(name_to_save) :
		return false
	image_saved[name_to_save] = current_image.duplicate()
	return true

func _to_image(input) -> Image:
	if input is Image:
		return input
	elif input is Texture2D:
		return input.get_image()
	return null

func get_all_saved_images() -> Dictionary:
	return image_saved.duplicate()

func set_image_from_saved(name_to_load:String) -> bool:
	if not image_saved.has(name_to_load):
		return false
	current_image = image_saved[name_to_load].duplicate()
	push_snapshot(current_image)
	_update_texture()
	_emit_history_changed()
	return true

func findMax(array: PackedInt32Array) -> int:
	var max_value = -1
	for i in range(array.size()):
		if array[i] > max_value:
			max_value = array[i]
	return max_value

func get_histogram_texture(channel : int = 1) -> Texture2D:
	if not current_image:
		return null

	var img_src: Image = current_image.duplicate()

	var iw = img_src.get_width()
	var ih = img_src.get_height()

	var hist_r = PackedInt32Array()
	var hist_g = PackedInt32Array()
	var hist_b = PackedInt32Array()

	hist_r.resize(256)
	hist_g.resize(256)
	hist_b.resize(256)

	for y in range(ih):
		for x in range(iw):
			var c: Color = img_src.get_pixel(x, y)
			if channel ==0 || channel ==1 : hist_r[int(c.r * 255.0)] += 1
			if channel ==0 || channel ==2 : hist_g[int(c.g * 255.0)] += 1
			if channel ==0 || channel ==3 : hist_b[int(c.b * 255.0)] += 1

	var maxR = findMax(hist_r)
	var maxG = findMax(hist_g)
	var maxB = findMax(hist_b)

	var max_val = max(maxR, max(maxG, maxB))
	if max_val == 0:
		max_val = 1

	var out_w = 512
	var out_h = 200
	var out_img = Image.create(out_w, out_h, false, Image.FORMAT_RGBA8)
	out_img.fill(Color(0, 0, 0, 1))

	for i in range(256):
		var x = int(float(i) / 256.0 * out_w)
		var h_r = int(hist_r[i] / float(max_val) * out_h)
		var h_g = int(hist_g[i] / float(max_val) * out_h)
		var h_b = int(hist_b[i] / float(max_val) * out_h)

		for y in range(out_h - 1, out_h - h_r, -1):
			out_img.set_pixel(x, y, Color(1, 0, 0)) 
		for y in range(out_h - 1, out_h - h_g, -1):
			out_img.set_pixel(x, y, Color(0, 1, 0)) 
		for y in range(out_h - 1, out_h - h_b, -1):
			out_img.set_pixel(x, y, Color(0, 0.6, 1)) 

	var tex := ImageTexture.create_from_image(out_img)
	return tex

func _proc_gaussian_blur(src: Image, mask: Image = null, iterations: int = 1) -> Image:
	if not src:
		return src

	if iterations < 1:
		iterations = 1

	var w = src.get_width()
	var h = src.get_height()

	var orig_image = src.duplicate()
	var work = orig_image.duplicate()

	for it in range(iterations):
		var temp = Image.create(w, h, false, Image.FORMAT_RGBA8)
		temp.fill(Color(0,0,0,0))
		for y in range(h):
			for x in range(w):
				var xl = clamp(x - 1, 0, w - 1)
				var xr = clamp(x + 1, 0, w - 1)
				var c_l = work.get_pixel(xl, y)
				var c_c = work.get_pixel(x, y)
				var c_r = work.get_pixel(xr, y)
				var sr = (c_l.r + 2.0 * c_c.r + c_r.r) / 4.0
				var sg = (c_l.g + 2.0 * c_c.g + c_r.g) / 4.0
				var sb = (c_l.b + 2.0 * c_c.b + c_r.b) / 4.0
				var sa = (c_l.a + 2.0 * c_c.a + c_r.a) / 4.0
				temp.set_pixel(x, y, Color(sr, sg, sb, sa))

		var out_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		out_img.fill(Color(0,0,0,0))
		for y in range(h):
			for x in range(w):
				var yt = clamp(y - 1, 0, h - 1)
				var yb = clamp(y + 1, 0, h - 1)
				var c_t = temp.get_pixel(x, yt)
				var c_c = temp.get_pixel(x, y)
				var c_b = temp.get_pixel(x, yb)
				var sr = (c_t.r + 2.0 * c_c.r + c_b.r) / 4.0
				var sg = (c_t.g + 2.0 * c_c.g + c_b.g) / 4.0
				var sb = (c_t.b + 2.0 * c_c.b + c_b.b) / 4.0
				var sa = (c_t.a + 2.0 * c_c.a + c_b.a) / 4.0

				var apply_blur = true
				if mask:
					var mc = mask.get_pixel(x, y)
					apply_blur = mc.r > 0.5

				if apply_blur:
					out_img.set_pixel(x, y, Color(sr, sg, sb, sa))
				else:
					var orig = orig_image.get_pixel(x, y)
					out_img.set_pixel(x, y, orig)

			mutex.lock()
			_thread_progress = (float(it) + float(y + 1) / float(h)) / float(iterations)
			mutex.unlock()

		work = out_img.duplicate()

	return work
