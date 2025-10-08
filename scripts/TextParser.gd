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
		'undo':
			return InstructionSet.UNDO
		'redo':
			return InstructionSet.REDO
		'psnr':
			return InstructionSet.PSNR
		'send':
			return InstructionSet.SEND

	if text.begins_with('seuil'):
		param = text.get_slice(' ', 1)
		return InstructionSet.SEUIL

	return InstructionSet.NOT_FOUND

func get_param():
	return param

func get_object():
	return object
