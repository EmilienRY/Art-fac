extends Node
class_name LevelManager

const GameDataProcessorScript = preload("res://scripts/GameDataProcessor.gd")
const ImageManagerScript = preload("res://scripts/ImageManager.gd")

var game_data_processor = null
var img_manager = null
var _last_goal_texture = null

func _init():
	game_data_processor = GameDataProcessorScript.new()

func _ready():
	img_manager = get_node_or_null("/root/ImageManager")
	load_current_level()

func get_current_config():
	return game_data_processor.get_current_level_config()

func load_current_level() -> bool:

	var cfg = get_current_config()
	_last_goal_texture = null
	img_manager.reset()
	img_manager.load_image(cfg['source'])
	_last_goal_texture = ResourceLoader.load(cfg['goal'])

	return true

func get_goal_texture():
	return _last_goal_texture

func check_psnr() -> float:

	var cur = img_manager.get_image()
	var goal_tex = get_goal_texture()
	var goal_img = goal_tex.get_image()
	var psnr_val = img_manager.compute_psnr(cur, goal_img)
	return psnr_val

func submit() -> Dictionary:
	var cfg = get_current_config()
	var psnr_val = check_psnr()

	var threshold = float(cfg.get('psnr_threshold_db', 0.0))
	if psnr_val >= threshold:
		var next_key = game_data_processor.get_next_level_key()
		if next_key != null:
			var ok = game_data_processor.set_current_level(next_key)
			if ok:
				load_current_level()
				return {"passed": true, "next_key": next_key, "new_cfg": get_current_config(), "psnr": psnr_val, "threshold": threshold}
		return {"passed": true, "next_key": null, "psnr": psnr_val, "threshold": threshold}
	return {"passed": false, "psnr": psnr_val, "threshold": threshold}
