extends Control

# Reference the UI Label node in your scene
@onready var text: RichTextLabel = $MarginContainer2/MarginContainer/RichTextLabel
@onready var vbox: VBoxContainer = $MarginContainer/MarginContainer/VBoxContainer
@onready var button_hover_audio: AudioStreamPlayer = $ButtonHoverAudio
@onready var button_clicked_audio: AudioStreamPlayer = $ButtonClickedAudio
const LOGS_BUTTON = preload("res://scenes/UI/logs/LogsButton.tscn")

var logs: Array[String] = [
		"Log 1 - Captain Adler",
		"Horizon Blackbox Recording 1",
		"Horizon Blackbox Recording 2",
		"Log 2 - Captain Adler",
		"Sanctuary Meeting Records",
		"Log 3 - Captain Adler",
		"Final Log - Captain Adler"
	]
var file_paths: Array[String] = [
		"res://assets/VoiceLogs/Log1_Adler.txt",
		"res://assets/VoiceLogs/Horizon_Log.txt",
		"res://assets/VoiceLogs/Horizon_Log2.txt",
		"res://assets/VoiceLogs/Log2_Adler.txt",
		"res://assets/VoiceLogs/Sanctuary_Log.txt",
		"res://assets/VoiceLogs/Log3_Adler.txt",
		"res://assets/VoiceLogs/Log4_Adler.txt"
	]
var buttons: Array[Button] = []

func _ready() -> void:
	var temp_button: Button
	for i in range(logs.size()):
		temp_button = LOGS_BUTTON.instantiate()
		temp_button.text = logs[i]
		#if (i != 0):
			#temp_button.visible = false
		temp_button.pressed.connect(func(): read_log(i))
		temp_button.mouse_entered.connect(func(): on_hover_button())
		vbox.add_child(temp_button)
		buttons.append(temp_button)
	
	# Display the text on the screen
	var text_content: String = read_text_file(file_paths[0])
	text.text = text_content

func read_log(index: int):
	button_hover_audio.stop()
	button_clicked_audio.play()
	var text_content: String = read_text_file(file_paths[index])
	text.text = text_content	

func on_hover_button():
	button_hover_audio.play()

# Function dedicated to reading the plain text file
func read_text_file(path: String) -> String:
	# Check if the file exists before trying to open it
	if not FileAccess.file_exists(path):
		print("Error: The file does not exist at path: ", path)
		return "File not found."
		
	# Open the file in read-only mode
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file:
		var content = file.get_as_text() # Reads the entire file into a single string
		file.close() # Always close your files to free system memory
		return content
	else:
		print("Error: Could not open the file. Error code: ", FileAccess.get_open_error())
		return "Failed to open file."
