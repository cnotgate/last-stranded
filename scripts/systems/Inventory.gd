extends Node2D

# 6 item slots (no dedicated battery slot)
# Each slot is null or {"data": ResourceData, "count": int}
var items: Array = [null, null, null, null, null, null]

# Auto-insert: first try to stack with same type, then find empty slot
func insert_item_auto(new_data) -> bool:
	for i in range(items.size()):
		if items[i] != null and items[i]["data"].item_name == new_data.item_name:
			items[i]["count"] += 1
			return true
	for i in range(items.size()):
		if items[i] == null:
			items[i] = {"data": new_data, "count": 1}
			return true
	return false

# Insert into specific slot (or stack if same type)
func insert_item(new_data, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= items.size():
		return false
	if items[slot_index] != null:
		if items[slot_index]["data"].item_name == new_data.item_name:
			items[slot_index]["count"] += 1
			return true
		return false
	items[slot_index] = {"data": new_data, "count": 1}
	return true

# Consume one item from slot, returns ResourceData or null
func consume_from_slot(index: int):
	if index < 0 or index >= items.size() or items[index] == null:
		return null
	var data = items[index]["data"]
	items[index]["count"] -= 1
	if items[index]["count"] <= 0:
		items[index] = null
	return data

# Remove all from slot, returns {data, count} or null
func remove_from_slot(index: int):
	if index < 0 or index >= items.size() or items[index] == null:
		return null
	var slot = items[index]
	items[index] = null
	return slot

func has_item_in_slot(index: int) -> bool:
	return index >= 0 and index < items.size() and items[index] != null

func get_item_count(index: int) -> int:
	if index < 0 or index >= items.size() or items[index] == null:
		return 0
	return items[index]["count"]

func get_item_data(index: int):
	if index < 0 or index >= items.size() or items[index] == null:
		return null
	return items[index]["data"]

func print_inventory():
	print("\nINVENTORY:")
	for i in range(items.size()):
		if items[i] != null:
			print("Slot", i, ":", items[i]["data"].item_name, "x", items[i]["count"])
		else:
			print("Slot", i, ": EMPTY")

func has_item(item_name: String) -> bool:
	for i in range(items.size()):
		if items[i] != null and items[i]["data"].item_name == item_name:
			return true
	return false

func consume_item(item_name: String, count: int) -> bool:
	# First check if we have enough
	var total = 0
	for item in items:
		if item != null and item["data"].item_name == item_name:
			total += item["count"]
			
	if total < count:
		return false
		
	# Consume them
	var remaining_to_consume = count
	for i in range(items.size()):
		if items[i] != null and items[i]["data"].item_name == item_name:
			if items[i]["count"] <= remaining_to_consume:
				remaining_to_consume -= items[i]["count"]
				items[i] = null
			else:
				items[i]["count"] -= remaining_to_consume
				remaining_to_consume = 0
				
			if remaining_to_consume <= 0:
				break
	return true

func add_item(data, count: int = 1) -> bool:
	# Try to find an existing stack first (optional for stackable items)
	for i in range(items.size()):
		if items[i] != null and items[i]["data"].item_name == data.item_name:
			items[i]["count"] += count
			return true
			
	# Find empty slot
	for i in range(items.size()):
		if items[i] == null:
			items[i] = {
				"data": data,
				"count": count
			}
			return true
			
	print("Inventory full!")
	return false
