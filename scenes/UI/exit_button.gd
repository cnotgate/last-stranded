extends LinkButton

@export var scene_to_file: String
@onready var button_clicked_audio: AudioStreamPlayer = $ButtonClickedAudio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	#exit the game
	button_clicked_audio.play()
	get_tree().quit()
