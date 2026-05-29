extends Area2D
class_name SprintBatteryPickup

func _ready():
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.activate_sprint()
		print("Sprint Battery activated!")
		queue_free()

func get_type_name() -> String:
	return "sprint_battery"
