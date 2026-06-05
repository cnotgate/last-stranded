extends MarginContainer

@export var star_scene: PackedScene
@onready var start_button: LinkButton = $VBoxContainer/StartButton
@onready var link_button: LinkButton = $VBoxContainer/LinkButton2
@onready var exit_button: LinkButton = $VBoxContainer/ExitButton
@onready var button_hover_audio: AudioStreamPlayer = $ButtonHoverAudio
@onready var button_clicked_audio: AudioStreamPlayer = $ButtonClickedAudio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_button.mouse_entered.connect(func(): _on_button_hover())
	link_button.mouse_entered.connect(func(): _on_button_hover())
	exit_button.mouse_entered.connect(func(): _on_button_hover())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_timer_timeout() -> void:
	var star = star_scene.instantiate()
	
	var screen_height = get_viewport_rect().size.y
	star.position = Vector2(-50, randf_range(0, screen_height))
	
	add_child(star)

func _on_button_hover() -> void:
	button_hover_audio.play()

func _on_link_button_pressed() -> void:
	pass
