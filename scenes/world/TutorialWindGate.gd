extends Area2D

@export_enum("umbilical", "disconnect", "scanning", "crafting") var required_condition: String = "umbilical"
@export var reminder_event_id: String = ""
@export var push_direction: Vector2 = Vector2(-1, 0)
@export var push_strength: float = 600.0

var player_in_zone: Node2D = null
var reminder_cooldown: float = 0.0

func _ready():
	add_to_group("tutorial_objectives")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = body

func _on_body_exited(body):
	if body == player_in_zone:
		player_in_zone = null

func _process(delta):
	if reminder_cooldown > 0:
		reminder_cooldown -= delta
		
	if player_in_zone == null: return
	
	# Check if condition is met
	var is_condition_met = false
	
	match required_condition:
		"umbilical":
			is_condition_met = (player_in_zone.node_to_tether_from != null)
		"disconnect":
			is_condition_met = (player_in_zone.node_to_tether_from == null)
		"scanning":
			is_condition_met = player_in_zone.is_scanner_active
		"crafting":
			var inv = player_in_zone.get_node_or_null("Inventory")
			if inv:
				# Check if they have the material OR the crafted relay itself
				is_condition_met = inv.has_item("hybrid mat") or inv.has_item("oxygen_relay")
				
	if not is_condition_met:
		# Apply wind force
		player_in_zone.velocity += push_direction * push_strength * delta
		
		# Play reminder dialogue occasionally
		if reminder_cooldown <= 0.0 and reminder_event_id != "":
			if StoryManager and not StoryManager.is_dialogue_playing:
				StoryManager.trigger_event(reminder_event_id)
				reminder_cooldown = 10.0 # Don't spam the dialogue
