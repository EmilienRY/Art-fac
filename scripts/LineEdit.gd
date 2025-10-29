extends LineEdit

@onready var typing_sound =_find_node_by_name(get_tree().get_root(), "keyBoard")
@onready var enter_sound =_find_node_by_name(get_tree().get_root(), "enter")

var typing_video_path := "res://video/typing.ogv"
@onready var typing_video_player: VideoStreamPlayer = _find_node_by_name(get_tree().get_root(), "typing")

@onready var winScreen = _find_node_by_name(get_tree().get_root(), "scoreScreen")
@onready var ui = _find_node_by_name(get_tree().get_root(), "UI")
@onready var screen = _find_node_by_name(get_tree().get_root(), "Screen")
@onready var tableau = _find_node_by_name(get_tree().get_root(), "TableauArea")
@onready var voisin = _find_node_by_name(get_tree().get_root(), "VoisinArea")
@onready var feuille = _find_node_by_name(get_tree().get_root(), "Feuille")
@onready var btn = _find_node_by_name(get_tree().get_root(), "NextLvlButton")

@onready var lutz1 = _find_node_by_name(get_tree().get_root(), "Lutz1")
@onready var lutz2 = _find_node_by_name(get_tree().get_root(), "Lutz2")
@onready var lutz3 = _find_node_by_name(get_tree().get_root(), "Lutz3")


@onready var stop_timer = $Timer

var gameText: RichTextLabel
var progress_label: Label
var text_parser = TextParser.new()
var game_data_processor = GameDataProcessor.new()
var img_manager: ImageManager
var start_node: TextureRect
var goal_node: TextureRect
var level_manager: LevelManager

func _ready():
	gameText = get_parent().get_parent().get_node("GameText")
	start_node = _find_node_by_name(get_tree().get_root(), "Start")
	goal_node = _find_node_by_name(get_tree().get_root(), "Goal")
	connect("text_changed", Callable(self, "_on_text_changed"))

	stop_timer.connect("timeout", Callable(self, "_on_stop_timer_timeout"))

	var stream = ResourceLoader.load(typing_video_path)
	typing_video_player.stream = stream
	typing_video_player.autoplay = false
	typing_video_player.loop = true
	call_deferred("_setup_managers")
	grab_focus()
	btn.connect("pressed", Callable(self, "_on_next_level_pressed"))

func _setup_managers():
	img_manager = ImageManager.new()
	img_manager.name = "ImageManager"
	get_tree().get_root().add_child(img_manager)
	img_manager.connect("image_changed", Callable(self, "_on_image_changed"))
	img_manager.connect("progress_changed", Callable(self, "_on_progress_changed"))

	progress_label = _find_node_by_name(get_tree().get_root(), "ProgressLabel")
	progress_label.theme = gameText.theme if gameText.has_method("theme") else null
	progress_label.modulate = Color(0, 0.8, 0.2)
	progress_label.size_flags_horizontal = 3

	level_manager = LevelManager.new()
	level_manager.name = "LevelManager"
	get_tree().get_root().add_child(level_manager)
	
	call_deferred("_load_initial_level")

func _load_initial_level():
	var cfg = game_data_processor.get_current_level_config()

	if cfg.has('source'):
		var src_tex = ResourceLoader.load(cfg.source)
		start_node.texture = src_tex
		
	if cfg.has('goal'):
		var goal_tex = ResourceLoader.load(cfg.goal)
		goal_node.texture = goal_tex
	
	if cfg.has('intro'):
		gameText.append_text(cfg.intro + "\n")
	if cfg.has('description'):
		gameText.append_text(cfg.description + "\n\n")

func _find_node_by_name(root_node: Node, name_to_find: String) -> Node:
	if not root_node or root_node.name == name_to_find:
		return root_node
		
	for child in root_node.get_children():
		var result = _find_node_by_name(child, name_to_find)
		if result:
			return result
	return null


func _on_text_submitted(new_text: String):
	if new_text.is_empty():
		return

	enter_sound.play()

	text = ""
	var instruction = text_parser.parse(new_text)

	match instruction:
		InstructionSet.SEUIL:
			_process_seuil_command(new_text)
		InstructionSet.CLEAR:
			gameText.clear()
		InstructionSet.UNDO:
			_process_undo_command()
		InstructionSet.REDO:
			_process_redo_command()
		InstructionSet.PSNR:
			_process_psnr_command(new_text)
		InstructionSet.SEND:
			_process_send_command()
		InstructionSet.GREY:
			_process_grey_command(new_text) 
		InstructionSet.EROSION:
			_process_erosion_command(new_text)
		InstructionSet.DILATATION:
			_process_dilatation_command(new_text)
		InstructionSet.HISTOGRAM:
			_process_histogram_command(new_text)
		InstructionSet.SAVE:
			_process_save_command(new_text)
		InstructionSet.LOAD:
			_process_load_command(new_text)
		InstructionSet.SEE:
			_process_see_command(new_text)
		InstructionSet.EQUALIZE:
			_process_equalize_command(new_text)
		_:
			_process_generic_command(new_text, instruction)


func _process_equalize_command(command_text: String):
	var output = " > " + command_text + "\n\n"

	var success = img_manager.equalize_histogram()
	if(!success):
		gameText.append_text(output+"Erreur lors de l'égalisation de l'histogramme.\n\n")
	else:
		gameText.append_text(output+"Égalisation en cours.\n\n")

func _process_save_command(command_text: String):
	var output = " > " + command_text + "\n\n"

	var param = text_parser.get_param()

	if param == null or param.size() < 2:
		output += "Appel invalide, usage: save <nom>\n\n"
		gameText.append_text(output)
		return

	var save_name = param[1]
	var success = img_manager.save(save_name)
	if success:
		output += "Image enregistrée sous le nom: %s\n\n" % save_name
	else:
		output += "Nom invalide ou nom déjà utilisé.\n\n"
	gameText.append_text(output)

func _process_load_command(command_text: String):
	var output = " > " + command_text + "\n\n"
	var param = text_parser.get_param()

	if param == null or param.size() < 2:
		output += "Appel invalide, usage: load <nom>\n\n"
		gameText.append_text(output)
		return

	var load_name = param[1]
	var success = img_manager.set_image_from_saved(load_name)
	if success:
		output += "Image chargée depuis le nom: %s\n\n" % load_name
	else:
		output += "Nom invalide ou image introuvable.\n\n"
	gameText.append_text(output)

func _process_see_command(command_text: String):
	var output = " > " + command_text + "\n\n"

	var images = img_manager.get_all_saved_images()

	for key in images.keys():
		output += "- %s\n" % key

	gameText.append_text(output)



func _process_seuil_command(command_text: String):
	var output = " > " + command_text + "\n\n"
	var param = text_parser.get_param()

	if param == null or param.size() < 2 || not param[1].is_valid_int():
		output += "Appel invalide, usage: seuil <valeur> (-r / -g / -b)\n\n"
		gameText.append_text(output)
		return
	var seuil_value = param[1].to_int()

	if seuil_value < 0 or seuil_value > 255:
		output += "Seuil invalide, valeur en dehors de la plage (0-255)\n\n"
		gameText.append_text(output)
		return 
	var color_mode = param[2] if param.size() > 2 else "all"
	if color_mode not in ["all", "-r", "-g", "-b"]:
		output += "Mode de couleur invalide, utilisez 'seuil <valeur> -r / -g / -b'\n\n"
		gameText.append_text(output)
		return 

	if color_mode == "-r":
		color_mode = 0
	elif color_mode == "-g":
		color_mode = 1
	elif color_mode == "-b":
		color_mode = 2
	else:
		color_mode = -1
	
	var success = img_manager.apply_threshold(seuil_value, color_mode)
	if(!success):
		gameText.append_text("Erreur, l'image n'est pas seuillée.\n\n")
	else:

		output += "Seuil défini à %s" % seuil_value + (" sur tous les canaux.\n\n" if color_mode == -1 else 
			(" sur le canal rouge.\n\n" if color_mode == 0 else 
			(" sur le canal vert.\n\n" if color_mode == 1 else 
			" sur le canal bleu.\n\n")))
		gameText.append_text(output)

func _process_grey_command(command_text: String):
	var output = " > " + command_text + "\n\n"

	var success = img_manager.transform_to_grayscale()
	if(!success):
		gameText.append_text(output+"Erreur lors de la conversion en niveaux de gris.\n\n")
	else:
		gameText.append_text(output+"Image convertie en niveaux de gris avec succès.\n\n")

func _process_erosion_command(command_text: String):
	var output = " > " + command_text + "\n\n"

	if img_manager and img_manager.is_processing:
		gameText.append_text(output+"Un traitement est déjà en cours. Attendez la fin.\n\n")
		return

	var success = img_manager.erosionPPM_mat3x3()
	if(!success):
		gameText.append_text(output+"Erreur lors de l'érosion de l'image.\n\n")
	else:
		self.editable = false
		gameText.append_text(output+"Érosion en cours...\n\n")

func _process_dilatation_command(command_text: String):
	var output = " > " + command_text + "\n\n"

	if img_manager and img_manager.is_processing:
		gameText.append_text(output+"Un traitement est déjà en cours. Attendez la fin.\n\n")
		return

	var success = img_manager.dilatationPPM_mat3x3()
	if(!success):
		gameText.append_text(output+"Erreur lors de la dilatation de l'image.\n\n")
	else:
		self.editable = false
		gameText.append_text(output+"Dilatation en cours...\n\n")

func _process_undo_command():	
	var success = img_manager.undo()
	var message = "> undo\n\n" if success else "> rien à annuler\n\n"
	gameText.append_text(message)

func _process_redo_command():

	var success = img_manager.redo()
	var message = "> redo\n\n" if success else "> rien à refaire\n\n"
	gameText.append_text(message)

func _process_psnr_command(command_text: String):
	var output = " > " + command_text + "\n\n"
	var psnr_value = level_manager.check_psnr()
	gameText.append_text(output+"PSNR = %s dB\n\n" % str(psnr_value))

func _show_win_screen(result: Dictionary):
	winScreen.visible = true
	ui.visible = false
	screen.visible = false
	tableau.visible = false
	voisin.visible = false
	feuille.visible = false

	var psnr = result.get('psnr')
	var threshold = result.get('threshold')

	if psnr < threshold+15:
		lutz1.visible = true
		lutz2.visible = false
		lutz3.visible = false
	elif psnr < threshold+30:
		lutz1.visible = true
		lutz2.visible = true
		lutz3.visible = false
	else:
		lutz1.visible = true
		lutz2.visible = true
		lutz3.visible = true


func _on_next_level_pressed():
	winScreen.visible = false
	ui.visible = true
	screen.visible = true
	tableau.visible = true
	voisin.visible = true
	feuille.visible = true
	btn.visible = false

func _process_send_command():
	var result = level_manager.submit()
		
	var new_cfg = result.get('new_cfg')
	if new_cfg:
		gameText.clear()
		gameText.append_text("Niveau réussi! Maintenant sur %s\n\n" % str(result.get('next_key', '')))
		gameText.append_text(new_cfg.intro + "\n" + new_cfg.description + "\n\n")
		goal_node.texture = ResourceLoader.load(new_cfg.goal)
		_show_win_screen(result)

	else:
		gameText.append_text("Mauvais résultat.\n\n")

func _process_generic_command(command_text: String, instruction: String):
	var output = " > " + command_text + "\n\n"
	output += game_data_processor.process_action(instruction, text_parser.get_object()) + "\n"
	gameText.append_text(output)

func _process_histogram_command(command_text: String):

	var output = " > " + command_text + "\n\n"
	var param = text_parser.get_param()
	var channel = param[1] if param.size() > 1 else "all"

	var channelMode = 0
	if channel == "-r":
		channelMode = 1
	elif channel == "-g":
		channelMode = 2
	elif channel == "-b":
		channelMode = 3

	var tex = img_manager.get_histogram_texture(channelMode)
	if tex == null:
		gameText.append_text(output+"Impossible de calculer l'histogramme.\n\n")
		return

	var histogram_win := Window.new()
	histogram_win.name = "HistogramWindow"
	histogram_win.size = Vector2i(512, 230)
	histogram_win.min_size = Vector2i(512, 230)
	histogram_win.max_size = Vector2i(512, 230)
	histogram_win.position = Vector2i(200, 150)
	histogram_win.title = "Histogramme"
	get_tree().root.add_child(histogram_win)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	histogram_win.add_child(vbox)

	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(512, 180)
	vbox.add_child(tex_rect)

	var scale_control := Control.new()
	scale_control.custom_minimum_size = Vector2(490, 20)
	vbox.add_child(scale_control)

	var tex_width = 490
	var graduations = [20,40,60,80,100,120,140,160,180,200,220,240,255]
	for grad in graduations:
		var label := Label.new()
		label.label_settings = LabelSettings.new()
		label.label_settings.font_size = 10
		label.text = str(grad)
		label.position = Vector2((grad / 255.0 * tex_width) - label.get_minimum_size().x / 2, 0)
		scale_control.add_child(label)

	histogram_win.connect("close_requested", Callable(self, "_on_histogram_close").bind(histogram_win))

	histogram_win.visible = true
	histogram_win.popup()
	histogram_win.grab_focus()
	gameText.append_text(output)



func _on_histogram_close(win: Window):
	if is_instance_valid(win):
		win.queue_free()
	gameText.append_text("Histogramme fermé.\n\n")


func _on_image_changed(new_texture: Texture2D):
	start_node.texture = new_texture
	self.editable = true
	if progress_label:
		progress_label.text = ""

func _on_progress_changed(progress: float) -> void:
	var percent = int(round(progress * 100.0))
	if percent >= 100:
		progress_label.text = "progression: 100%"
	else:
		progress_label.text = "progression: %s%%" % str(percent)

func _on_text_changed(new_text):

	stop_timer.start()

	if not typing_sound.playing:
		typing_sound.play()
		
	if typing_video_player:
		if not typing_video_player.visible:
			typing_video_player.visible = true
		if not typing_video_player.is_playing():
			typing_video_player.play()

func _on_stop_timer_timeout():
	typing_sound.stop()
	
	if typing_video_player and typing_video_player.is_playing():
		typing_video_player.stop()
	if typing_video_player:
		typing_video_player.visible = false
