extends CanvasLayer

@export var player: CharacterBody2D
@export var treshold: float

@onready var oxygen_bar = $Control/VBoxContainer/OxygenBar
@onready var battery_bar = $Control/VBoxContainer/BatteryBar
@onready var slot_container = $Control/HBoxContainer
@onready var arrow = $Control/Compass/ArrowIcon
@onready var distance_label = $Control/Compass/DistanceLabel
@onready var color_rect = $ColorRect
@onready var sprint_label = $Control/VBoxContainer/SprintLabel
@onready var scanner_label = $Control/VBoxContainer/ScannerLabel
@onready var minimap = $Control/Minimap

func _process(delta):
	# If player isn't assigned, try to automatically find it
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p != null:
			player = p
		else:
			return
		
	# 1. Update Bars
	oxygen_bar.value = player.current_oxygen
	oxygen_bar.max_value = player.max_oxygen
	var oxygen_percent = oxygen_bar.value / oxygen_bar.max_value
	
	if oxygen_percent < treshold:
		print("oxygen_percent: ", oxygen_percent)
		var intensity = remap(oxygen_percent, 0.0, treshold, 1.0, 0.0)
		intensity = clamp(intensity, 0.0, 1.0)
		
		color_rect.material.set_shader_parameter("blur_amount", intensity)
		color_rect.material.set_shader_parameter("vignette_intensity", intensity)
		
		if oxygen_percent <= 0:
			color_rect.modulate = Color.BLACK
		
	if player.get_node("Inventory").has_battery():
		var battery = player.get_node("Inventory").battery
		battery_bar.value = battery.current_energy
		battery_bar.max_value = battery.max_energy
	else:
		battery_bar.value = 0
		
	# 2. Update Inventory Slots
	for i in range(6):
		var slot_node = slot_container.get_child(i)
		
		# Highlight selected slot
		if i == player.selected_slot:
			if slot_node is Panel or slot_node is ColorRect:
				# Emphasize by tweaking style/color.
				slot_node.modulate = Color(1.5, 1.5, 0.5) # Overdriven yellow
			else:
				slot_node.modulate = Color(1.5, 1.5, 0.5)
		else:
			slot_node.modulate = Color(1, 1, 1) # White
			
		# Check if the slot has an item
		var has_item = false
		if i == 0:
			has_item = player.get_node("Inventory").has_battery()
		else:
			has_item = player.get_node("Inventory").items[i-1] != null
			
		# Dim all slots by default, make full opacity if selected
		if i == player.selected_slot:
			slot_node.modulate.a = 1.0
		else:
			slot_node.modulate.a = 0.5
			
		# If the slot is a Panel/ColorRect, and it has a TextureRect child for the item icon:
		# (Assuming you added a TextureRect inside each Panel as a child)
		var icon_rect = null
		if slot_node.get_child_count() > 0 and slot_node.get_child(0) is TextureRect:
			icon_rect = slot_node.get_child(0)
			
		if icon_rect != null:
			if not has_item:
				icon_rect.texture = null
			else:
				if i == 0:
					# Replace with your actual battery sprite path
					icon_rect.texture = preload("res://assets/dummyitem2.png")
				else:
					var item = player.get_node("Inventory").items[i-1]
					# For now using generic placeholder based on name, or if item has its own icon var:
					# if item.has("icon"): icon_rect.texture = item.icon
					
					# Hardcoded mapping based on your previous loot names
					match item.item_name:
						"oxygen mat":
							icon_rect.texture = preload("res://assets/dummyitem1.png")
						"battery mat":
							icon_rect.texture = preload("res://assets/dummyitem2.png")
						"hybrid mat":
							icon_rect.texture = preload("res://assets/dummyitem3.png")
						_:
							icon_rect.texture = null

	# 4. Update Sprint Timer
	if player.is_sprint_active:
		sprint_label.visible = true
		sprint_label.text = "⚡ SPRINT: " + str(int(ceil(player.sprint_timer))) + "s"
	else:
		sprint_label.visible = false

	# 5. Update Scanner Timer and Minimap
	if player.is_scanner_active:
		scanner_label.visible = true
		scanner_label.text = "📡 SCAN: " + str(int(ceil(player.scanner_timer))) + "s"
		minimap.visible = true
	else:
		scanner_label.visible = false
		minimap.visible = false


	# 3. Update Compass
	if player.nearest_relay != null:
		if arrow: arrow.visible = true
		if distance_label: distance_label.visible = true
		
		# Point the arrow towards the relay
		var direction = player.global_position.direction_to(player.nearest_relay.global_position)
		# Add PI/2 (90 degrees) because direction.angle() assumes 0 is pointing RIGHT (east),
		# but if your art asset by default points UP (north), we need to offset it.
		if arrow: arrow.rotation = direction.angle() + (PI / 2.0)
		
		# Show the distance
		if distance_label: distance_label.text = str(floor(player.nearest_relay_distance)) + "m"
	else:
		if arrow: arrow.visible = false
		if distance_label: distance_label.visible = false
