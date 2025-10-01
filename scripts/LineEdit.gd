extends LineEdit

const TextParserScript = preload("res://scripts/TextParser.gd")
const GameDataProcessorScript = preload("res://scripts/GameDataProcessor.gd")
const ImageManager = preload("res://scripts/ImageManager.gd")

@export var img_path: NodePath

var gameText: RichTextLabel
var text_parser = null
var game_data_processor = null
var img = null
var t
func _ready():
	gameText = get_parent().get_parent().get_node("GameText")

	img = get_node_or_null(img_path) as Sprite2D

	t = load("res://assets/chat.jpg") as Texture2D

	text_parser = TextParserScript.new()
	game_data_processor = GameDataProcessorScript.new()

	var output_text = game_data_processor.process_action(InstructionSet.HELP)

	gameText.append_text(output_text + "\n")
	self.grab_focus()

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

			var im = ImageManager.new()
			var source_path = "res://images/chat.jpg"
			var new_tex = im.texture_threshold_from_file(source_path, thresh_val)
			if new_tex != null and img != null:
				img.texture = new_tex

		InstructionSet.CLEAR:
			gameText.clear()
			self.set_text('')

		_:
			var output_text = ''
			output_text += " > " + new_text + "\n\n"
			output_text += game_data_processor.process_action(instruction, text_parser.get_object())
			output_text += "\n"
			gameText.append_text(output_text)
