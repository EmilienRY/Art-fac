class_name TextParser

var InstructionSetScript = load("res://scripts/InstructionSet.gd")

var object = null
var param = null

func parse(text):
	match text:
		'help':
			return InstructionSet.HELP
		'reset':
			return InstructionSet.RESET
		'quit':
			return InstructionSet.QUIT
		'exit':
			return InstructionSet.QUIT
		'clear':
			return InstructionSet.CLEAR

	if text.begins_with('seuil'):
		param=null
		var regex = RegEx.new()
		regex.compile("seuil\\s(?<param>.*(\\s.*)?)")
		var results = regex.search(text)

		if results == null:
			param = ''
			return InstructionSet.SEUIL

		param = results.get_string('param')
		return InstructionSet.SEUIL

	return InstructionSet.NOT_FOUND

func get_param():
	return param

func get_object():
	return object
