class_name GameDataProcessor

var InstructionSetScript = load("res://scripts/InstructionSet.gd")

var data = {}

func _init():
	data = load_json_data("res://data/game1.json")

func load_json_data(file_name):
	var file = FileAccess.open(file_name, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_DICTIONARY:
			return data_received
		else:
			assert(false, "Unexpected data in JSON output")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		assert(false, "JSON Parse Error")

func process_action(action, object = null):

	if action == InstructionSet.HELP:
		var helpText = ''
		helpText += 'Instructions:' + "\n"
		helpText += '- Utilisez les commandes pour le traitement d\'images.' + "\n"
		helpText += '- Commandes disponibles: clear, reset, quit, seuil <valeur>' + "\n"
		return helpText

	if action == InstructionSet.RESET:
		data = load_json_data("res://data/game1.json")
		return process_action(null)

	if action == InstructionSet.QUIT:
		Engine.get_main_loop().quit()
		return 'Bye...'

	if action == InstructionSet.SEUIL:
		var new_text = ''
		if object == null or object == '':
			new_text += "appel invalide, usage: seuil <valeur>\n\n"
			return new_text
		if typeof(object) == TYPE_STRING and object.is_valid_float():
			var seuil_value = object.to_float()
			if seuil_value < 0 or seuil_value > 255:
				new_text += "seuil invalide, valeur en dehors de la plage (0-255)\n\n"
				return new_text
			new_text += "Seuil défini à: %s\n" % seuil_value

			return new_text
		else:
			return "Valeur de seuil invalide. Utilisez un nombre.\n"

	if action == InstructionSet.NOT_FOUND:
		return 'I don\'t understand!' + "\n"

	if action == null:
		var rendered = ''
		for key in data.keys():
			var entry = data[key]
			rendered += key + "\n"
			if entry.has('intro'):
				rendered += entry['intro'] + "\n"
			if entry.has('description'):
				rendered += entry['description'] + "\n"
			rendered += "\n"
		return rendered

	return 'Commande non implémentée.\n'
