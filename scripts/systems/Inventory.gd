extends Node2D

# Battery slot (only one)
var battery = null

# Generic item slot
var items: Array = [null, null, null, null, null]

# Battery Functions
func insert_battery(new_battery) -> bool:
	if battery != null:
		print("Battery slot occupied!")
		return false
	
	battery = new_battery
	print("Inserted battery")
	return true

# Item Slot Functions
func insert_item(new_item, slot_index: int) -> bool:
	# Prevent inserting into battery slot
	if slot_index == 0:
		print("Cannot store item in battery slot!")
		return false
	
	var index = slot_index - 1  # convert to items array
	
	if index < 0 or index >= items.size():
		print("Invalid slot")
		return false
	
	if items[index] != null:
		print("Selected slot occupied!")
		return false
	
	items[index] = new_item
	
	print("Stored item in slot", slot_index, ":", new_item.item_name)
	return true

func remove_from_slot(index: int):
	# Battery slot
	if index == 0:
		if battery == null:
			print("Battery slot empty")
			return null
		
		var temp = battery
		battery = null
		
		print("Removed battery")
		return temp
	
	# Item slots
	var item_index = index - 1
	
	if item_index < 0 or item_index >= items.size():
		print("Invalid slot")
		return null
	
	if items[item_index] == null:
		print("Slot", index, "empty")
		return null
	
	var temp = items[item_index]
	items[item_index] = null
	
	print("Removed from slot", index, ":", temp.item_name)
	return temp

func has_battery() -> bool:
	return battery != null
	
# Debugger remove when we arent fried
func print_inventory():
	print("\nINVENTORY:")
	
	if battery != null:
		print("Slot 0 (Battery):", battery)
	else:
		print("Slot 0 (Battery): EMPTY")
	
	for i in range(items.size()):
		if items[i] != null:
			print("Slot", i + 1, ":", items[i].item_name)
		else:
			print("Slot", i + 1, ": EMPTY")
