extends Area2D
class_name StoryTrigger

@export var event_id: String = ""
@export var trigger_once: bool = true
@export var objective_to_set: String = ""
var triggered: bool = false

func _ready():
	add_to_group("tutorial_objectives")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not triggered and body.is_in_group("player"):
		triggered = true
		if StoryManager:
			if event_id != "":
				StoryManager.trigger_event(event_id)
			if objective_to_set != "":
				StoryManager.set_objective(objective_to_set)
			if trigger_once:
				queue_free()
