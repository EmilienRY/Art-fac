class_name TextParser

var InstructionSetScript = load("res://scripts/InstructionSet.gd")

var object = null
var param: PackedStringArray = []

func parse(text):
	match text:
		'png':
			return InstructionSet.PNG
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
		'steve':
			return InstructionSet.STEVE
		'send':
			return InstructionSet.SEND
		'grey':
			return InstructionSet.GREY
		'see':
			return InstructionSet.SEE
		'equalize':
			return InstructionSet.EQUALIZE
		'gradient':
			return InstructionSet.GRADIENT
		'fnaf':
			return InstructionSet.FNAF

	if text.begins_with('erosion'):
		param = text.split(' ', false)
		return InstructionSet.EROSION

	if text.begins_with('dilatation'):
		param = text.split(' ', false)
		return InstructionSet.DILATATION


	if text.begins_with('diff'):
		param = text.split(' ', false)
		return InstructionSet.DIFF

	if text.begins_with('blur'):
		param = text.split(' ', false)
		return InstructionSet.BLUR

	if text.begins_with('save'):
		param = text.split(' ', false)
		return InstructionSet.SAVE

	if text.begins_with('load'):
		param = text.split(' ', false)
		return InstructionSet.LOAD

	if text.begins_with('seuil'):
		param = text.split(' ', false)
		return InstructionSet.SEUIL
	
	if text.begins_with('histogram'):
		param = text.split(' ', false)
		return InstructionSet.HISTOGRAM

	return InstructionSet.NOT_FOUND

func get_param():
	return param

func get_object():
	return object
