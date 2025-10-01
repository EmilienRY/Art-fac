class_name ImageManager

extends Node

func texture_threshold_from_file(file_path: String, threshold_value: float) -> Texture2D:
	var img := Image.new()
	var err := img.load(file_path)
	if err != OK:
		push_error("ImageManager: impossible de charger %s" % file_path)
		return null

	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			var lum255 = lum * 255.0
			if lum255 >= threshold_value:
				img.set_pixel(x, y, Color(1, 1, 1, c.a))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, c.a))

	var tex := ImageTexture.create_from_image(img)
	return tex
