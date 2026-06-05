extends Area2D
class_name OxygenCanisterPickup

@export var oxygen_amount: float = 50.0

func _ready():
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.current_oxygen += oxygen_amount
		body.current_oxygen = min(body.current_oxygen, body.max_oxygen)
		print("Oxygen refilled! +", oxygen_amount)
		queue_free()

func get_type_name() -> String:
	return "oxygen_canister"
