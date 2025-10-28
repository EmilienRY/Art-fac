class_name GameDataProcessor

var InstructionSetScript = load("res://scripts/InstructionSet.gd")

var data = {}
var current_level_key: String = "TP1"

func _init():
	data = load_all_json_data("res://data")

func load_json_data(file_name):
	var file = FileAccess.open(file_name, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func load_all_json_data(dir_path: String) -> Dictionary:
	var result := {}
	var da = DirAccess.open(dir_path)
	if da == null:
		return result
	da.list_dir_begin()
	var fname = da.get_next()
	while fname != "":
		if fname.to_lower().ends_with(".json"):
			var fpath = dir_path + "/" + fname
			var file = FileAccess.open(fpath, FileAccess.READ)
			var s = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(s) == OK and typeof(json.data) == TYPE_DICTIONARY:
				for k in json.data.keys():
					result[k] = json.data[k]
		fname = da.get_next()
	da.list_dir_end()
	return result

func process_action(action, param = null):

	if action == InstructionSet.HELP:
		var helpText = ''
		helpText += 'Instructions:' + "\n"
		helpText += '- Utilisez les commandes pour le traitement d\'images.' + "\n"
		helpText += '- Commandes disponibles: clear, save, load, see, send, exit' + "\n"
		helpText += '						 undo, redo' + "\n"

		return helpText

	if action == InstructionSet.RESET:
		data = load_all_json_data("res://data")
		return process_action(null)

	if action == InstructionSet.QUIT:
		Engine.get_main_loop().quit()
		return 'Bye...'

	if action == InstructionSet.SEUIL:
		var new_text = ''
		if param == null or param.size() < 2:
			new_text += "Appel invalide, usage: seuil <valeur> (-r / -g / -b)\n\n"
			return new_text
		var seuil_value = param[1].to_int()
		if seuil_value < 0 or seuil_value > 255:
			new_text += "Seuil invalide, valeur en dehors de la plage (0-255)\n\n"
			return new_text
		var color_mode = param[2] if param.size() > 2 else "all"
		if color_mode not in ["all", "-r", "-g", "-b"]:
			new_text += "Mode de couleur invalide, utilisez 'seuil <valeur> -r / -g / -b'\n\n"
			return new_text
		return ''

	if action == InstructionSet.NOT_FOUND:
		return 'Fonction inconnue' + "\n"
	if action == null:
		var rendered = ''
		for level_key in data.keys():
			var entry = data[level_key]
			rendered += level_key + "\n"
			if entry.has('intro'):
				rendered += entry['intro'] + "\n"
			if entry.has('description'):
				rendered += entry['description'] + "\n"
			rendered += "\n"
		return rendered

	return 'Commande non implémentée.\n'

func get_current_level_config():
	if data.has(current_level_key):
		return data[current_level_key]
	return null

func get_next_level_key():
	var keys = data.keys()
	for i in range(keys.size()):
		if keys[i] == current_level_key and i < keys.size() - 1:
			return keys[i + 1]
	return null

func set_current_level(key: String) -> bool:
	if data.has(key):
		current_level_key = key
		return true
	return false
