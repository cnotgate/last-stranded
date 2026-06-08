extends Area2D

var player_in_range: bool = false
var log_played: bool = false

func _ready():
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	var light = get_node_or_null("Light2D")
	if light:
		var tween = create_tween().set_loops()
		tween.tween_property(light, "energy", 0.5, 1.0)
		tween.tween_property(light, "energy", 1.5, 1.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func _process(delta):
	if log_played: return
	
	if player_in_range and Input.is_action_just_pressed("interact"):
		log_played = true
		if StoryManager:
			StoryManager.trigger_event("act1_adler_log")
			StoryManager.set_objective("Reach Horizon")
		
		var light = get_node_or_null("Light2D")
		if light: light.energy = 0.0
		remove_from_group("interactable")
