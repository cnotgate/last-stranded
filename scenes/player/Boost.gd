extends Node

func _process(delta):
	if not is_boosting():
		return
	var player = get_parent()
	player.battery_energy -= player.battery_drain_rate * delta
	player.battery_energy = max(player.battery_energy, 0.0)

func is_boosting() -> bool:
	var player = get_parent()
	if not Input.is_action_pressed("boost"):
		return false
	if player.battery_energy <= 0:
		return false
	return true

func get_boost_multiplier() -> float:
	var player = get_parent()
	var base = 1.0
	if is_boosting():
		base = player.battery_boost_multiplier
	if player.is_sprint_active:
		base += player.sprint_boost_bonus
	return base
