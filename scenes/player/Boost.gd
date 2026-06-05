extends Node

@onready var inventory = $"../Inventory"

func _process(delta):
	if not is_boosting():
		return
	
	var battery = inventory.battery
	
	if battery == null:
		return  # safety check
	
	battery.current_energy -= battery.drain_rate * delta
	battery.current_energy = max(battery.current_energy, 0)
		
	# UI implement here later
	# update energy bar


func is_boosting() -> bool:
	var battery = inventory.battery
	
	if not Input.is_action_pressed("boost"):
		return false
	
	if battery == null:
		return false
	
	if battery.current_energy <= 0:
		return false
	
	return true


func get_boost_multiplier() -> float:
	var battery = inventory.battery
	var player = get_parent()
	var base = 1.0
	
	if battery != null and is_boosting():
		base = battery.boost_multiplier
	
	# Sprint bonus applies on top of current multiplier
	if player.is_sprint_active:
		base += player.sprint_boost_bonus
	
	return base
