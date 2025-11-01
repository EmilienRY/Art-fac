extends Node
class_name LevelManager

var game_data_processor = GameDataProcessor.new()
var img_manager: ImageManager
var _goal_texture: Texture2D
var tempsVoisin : int

var indiceTerminal
var indiceLigneEdit
var imgIndicePath

func get_timer() -> int :
	return tempsVoisin

func update_timer(temps : int) -> void:
	tempsVoisin=temps

func _get_indiceTerminal() -> String:
	return indiceTerminal

func _get_indiceLigneEdit() -> String:
	return indiceLigneEdit

func _get_img_Indice() -> String:
	return imgIndicePath

func _ready():
	call_deferred("_initialize")

func _initialize():
	img_manager = get_node("/root/ImageManager")
	load_current_level()

func get_current_config() -> Dictionary:
	return game_data_processor.get_current_level_config()

func load_current_level() -> bool:
	var cfg = get_current_config()
		
	img_manager.reset()
	img_manager.load_image(cfg.source)
	_goal_texture = ResourceLoader.load(cfg.goal)
	
	var loaded_images = cfg.get("loaded_images", [])

	if loaded_images.size() > 0:
		for image_path in loaded_images:
			img_manager.loadToImageSaved(image_path)

	indiceTerminal = cfg.indice_terminal
	indiceLigneEdit = cfg.indice_ligne
	tempsVoisin = cfg.tempsMax
	imgIndicePath=cfg.img_indice
	return true

func get_goal_texture() -> Texture2D:
	return _goal_texture

func check_psnr() -> float:
		
	var current_image = img_manager.get_image()
	var goal_image = _goal_texture.get_image()
	return img_manager.compute_psnr(current_image, goal_image)

func get_current_level_number() -> int:
	var level_key = game_data_processor.current_level_key
	# Extraire le numéro du niveau depuis la clé (ex: "TP1" -> 1, "TP2" -> 2)
	var number_str = level_key.substr(2) # Enlever "TP"
	if number_str.is_valid_int():
		return number_str.to_int()
	return 1 # Par défaut niveau 1

func submit() -> Dictionary:
	var cfg = get_current_config()
	var psnr_value = check_psnr()
	var threshold = cfg.get('psnr_threshold_db', 0.0)
	
	var result = {
		"passed": psnr_value >= threshold,
		"psnr": psnr_value,
		"threshold": threshold
	}
	
	if result.passed:
		var next_key = game_data_processor.get_next_level_key()
		if next_key:
			game_data_processor.set_current_level(next_key)
			load_current_level()
			result["next_key"] = next_key
			result["new_cfg"] = get_current_config()
	
	return result
