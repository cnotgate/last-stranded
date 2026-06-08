extends Node2D
class_name ResourceItem

@export var data: ResourceData
@export var usage_type: String

var spawned_zone: int = -1

func _ready():
	add_to_group("interactable")
	
	if data == null:
		print("ERROR: ResourceItem has NO DATA assigned!")
	else:
		print("Spawned:", data.item_name)

func interact(player):
	if data == null:
		print("ERROR: No data")
		return
	
	if data.item_name == "battery mat":
		var hud = get_tree().get_first_node_in_group("hud")
		if player.battery_energy <= 75.0:
			player.recharge_battery(25.0)
			if hud:
				hud.add_log_message("Battery recharged +25.0 kW.", "info")
			queue_free()
		else:
			# Battery above 75 kW: store in inventory for later
			if player.inventory.insert_item_auto(data):
				if hud:
					hud.add_log_message("Battery stored in inventory.", "info")
				queue_free()
			else:
				if hud:
					hud.add_log_message("Inventory full!", "warning")
		return

	print("Trying to pick up:", data.item_name)
	
	if player.inventory.insert_item(data, player.selected_slot):
		print("Picked up:", data.item_name)
		queue_free()
	else:
		# Try auto-insert if selected slot is occupied
		if player.inventory.insert_item_auto(data):
			print("Picked up (auto):", data.item_name)
			queue_free()
		else:
			print("Inventory full!")

func get_type_name() -> String:
	if data != null:
		return data.item_name
	return "NO_DATA"
