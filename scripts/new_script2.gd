extends Control

@onready var stop_timer = $Timer

var gameText: RichTextLabel
var progress_label: Label
var text_parser = TextParser.new()
var game_data_processor = GameDataProcessor.new()
var img_manager: ImageManager
var start_node: TextureRect
var level_manager: LevelManager

func _ready():
	gameText = get_parent().get_parent().get_node("GameText")
	start_node = _find_node_by_name(get_tree().get_root(), "Start")

	call_deferred("_setup_managers")
	grab_focus()

func _setup_managers():
	img_manager = ImageManager.new()
	img_manager.name = "ImageManager"
	get_tree().get_root().add_child(img_manager)
	img_manager.connect("image_changed", Callable(self, "_on_image_changed"))
	img_manager.connect("progress_changed", Callable(self, "_on_progress_changed"))

	var rows = gameText.get_parent() 
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
