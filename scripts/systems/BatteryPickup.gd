extends Node2D
class_name BatteryPickup

var battery: Battery

func _ready():
	add_to_group("interactable")
	
	if battery == null:
		print("ERROR: BatteryPickup has no battery!")

func interact(player):
	if battery == null:
		return
	
	# Try insert into battery slot
	if player.inventory.insert_battery(battery):
		print("Picked battery (Tier", battery.tier, ")")
		queue_free()
	else:
		print("Battery slot occupied!")
