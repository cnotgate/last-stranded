extends Area2D
class_name ScannerPickup

func _ready():
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.activate_scanner()
		print("Scanner activated!")
		queue_free()

func get_type_name() -> String:
	return "scanner"
