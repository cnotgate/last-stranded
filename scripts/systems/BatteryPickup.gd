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
	
	var charge_amount = battery.current_energy
	player.recharge_battery(charge_amount)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_log_message("Battery recharged by +%.1f kW." % charge_amount, "info")
	queue_free()
