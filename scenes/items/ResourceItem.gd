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
	
	print("Trying to pick up:", data.item_name)
	
	if player.inventory.insert_item(data, player.selected_slot):
		print("Picked up:", data.item_name)
		queue_free()
	else:
		print("Inventory full!")

func get_type_name() -> String:
	if data != null:
		return data.item_name
	return "NO_DATA"
