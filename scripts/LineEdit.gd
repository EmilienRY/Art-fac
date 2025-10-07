extends LineEdit

const TextParserScript = preload("res://scripts/TextParser.gd")
const GameDataProcessorScript = preload("res://scripts/GameDataProcessor.gd")
const ImageManagerScript = preload("res://scripts/ImageManager.gd")

@export var img_path: NodePath

var gameText: RichTextLabel
var text_parser = null
var game_data_processor = null
var img = null
var img_manager: ImageManager = null
var start_node = null
var goal_node = null
var level_manager = null

func _ready():
	gameText = get_parent().get_parent().get_node("GameText")

	start_node = _find_node_by_name(get_tree().get_root(), "Start")
	goal_node = _find_node_by_name(get_tree().get_root(), "Goal")

	img = get_node_or_null(img_path) as Sprite2D

	text_parser = TextParserScript.new()
	game_data_processor = GameDataProcessorScript.new()

	img_manager = get_node_or_null("/root/ImageManager")
	if img_manager == null:
		img_manager = ImageManagerScript.new()
		img_manager.name = "ImageManager"
		get_tree().get_root().call_deferred("add_child", img_manager)

	call_deferred("_bind_image_manager")

	level_manager = get_node_or_null("/root/LevelManager")
	if level_manager == null:
		var lm_script = load("res://scripts/LevelManager.gd")
		level_manager = lm_script.new()
		get_tree().get_root().call_deferred("add_child", level_manager)

	var level_cfg = game_data_processor.get_current_level_config()
	if level_cfg != null:
		
		if level_cfg.has('source') and start_node != null:
			var src_tex = ResourceLoader.load(level_cfg['source'])
			if src_tex:
				_set_node_texture(start_node, src_tex)

		if level_cfg.has('source') and img_manager != null:
			img_manager.load_image(level_cfg['source'])

		if level_cfg.has('goal') and goal_node != null:
			var goal_tex = ResourceLoader.load(level_cfg['goal'])
			if goal_tex:
				_set_node_texture(goal_node, goal_tex)

	var cfg = game_data_processor.get_current_level_config()

	if cfg.has('intro'):
		gameText.append_text(cfg['intro'] + "\n")
	if cfg.has('description'):
		gameText.append_text(cfg['description'] + "\n\n")
	
	self.grab_focus()

func _find_node_by_name(root_node, name_to_find):
	if root_node == null:
		return null
	if root_node.name == name_to_find:
		return root_node
	for i in range(root_node.get_child_count()):
		var child = root_node.get_child(i)
		if child == null:
			continue
		var res = _find_node_by_name(child, name_to_find)
		if res != null:
			return res
	return null

func _bind_image_manager():
	for i in range(4):
		img_manager = get_node_or_null("/root/ImageManager")
		if img_manager != null:
			if not img_manager.is_connected("image_changed", Callable(self, "_on_image_changed")):
				img_manager.connect("image_changed", Callable(self, "_on_image_changed"))
				push_warning("LineEdit: connected to ImageManager (attempt %d)" % i)
				var tex = null
				if img_manager.has_method("get_texture"):
					tex = img_manager.get_texture()
				if tex != null:
					_on_image_changed(tex)
			return
		await get_tree().create_timer(0.05).timeout


func _on_text_submitted(new_text):
	if (new_text.is_empty()):
		return

	self.set_text('')
	var instruction = text_parser.parse(new_text)

	match instruction:
		InstructionSet.NOT_FOUND:
			var output_text = ''
			output_text += " > " + new_text  + "\n\n"
			output_text += game_data_processor.process_action(instruction, text_parser.get_object())
			gameText.append_text(output_text)

		InstructionSet.SEUIL:
			var output_text = ''
			output_text += " > " + new_text  + "\n\n"

			output_text += game_data_processor.process_action(instruction, text_parser.get_param())
			output_text += "\n"
			gameText.append_text(output_text)

			var param_text = text_parser.get_param()
			if param_text == null or param_text == '':
				return
			var thresh_val = 0.0
			if typeof(param_text) == TYPE_STRING and param_text.is_valid_float():
				thresh_val = param_text.to_float()
			else:
				return

			var level_cfg = game_data_processor.get_current_level_config()
			var source_path = level_cfg['source']
			var mgr = get_node_or_null("/root/ImageManager")

			if mgr.load_image(source_path):
				mgr.apply_threshold(thresh_val)

		InstructionSet.CLEAR:
			gameText.clear()
			self.set_text('')

		InstructionSet.UNDO:
			var ok = false
			if img_manager != null:
				ok = img_manager.undo()
			if ok:
				gameText.append_text("> undo\n\n")
			else:
				gameText.append_text("> nothing to undo\n\n")

		InstructionSet.REDO:
			var ok2 = false
			if img_manager != null:
				ok2 = img_manager.redo()
			if ok2:
				gameText.append_text("> redo\n\n")
			else:
				gameText.append_text("> nothing to redo\n\n")
		InstructionSet.PSNR:
			var res = level_manager.check_psnr()
			gameText.append_text("PSNR = %s dB\n\n" % str(res))
			
		InstructionSet.SEND:
			var res = level_manager.submit()
			if not res.passed:
				gameText.append_text("Mauvais résultat.\n\n")
				return
			var new_cfg = res.get('new_cfg', null)
			if new_cfg != null:
				gameText.clear()
				gameText.append_text("Level passed! Now on %s\n\n" % str(res.get('next_key', '')))
				gameText.append_text(new_cfg['intro'] + "\n")
				gameText.append_text(new_cfg['description'] + "\n\n")
				var gtex = ResourceLoader.load(new_cfg['goal'])
				_set_node_texture(goal_node, gtex)
		_:
			var output_text = ''
			output_text += " > " + new_text + "\n\n"
			output_text += game_data_processor.process_action(instruction, text_parser.get_object())
			output_text += "\n"
			gameText.append_text(output_text)

func _set_node_texture(target, tex):
	target.texture = tex
	return
	

func _on_image_changed(new_texture):
	start_node.texture = null
	start_node.texture = new_texture
	start_node.queue_redraw()
	return
