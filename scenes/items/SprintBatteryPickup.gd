extends Area2D
class_name SprintBatteryPickup

func _ready():
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.recharge_battery(30.0)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.add_log_message("Battery +30.0 kW.", "info")
		queue_free()

func get_type_name() -> String:
	return "sprint_battery"
