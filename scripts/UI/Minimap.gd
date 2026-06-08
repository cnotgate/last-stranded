extends Control

# Minimap renders dots for oxygen relays and powerups when scanner is active

var player = null
var minimap_size := Vector2(180, 180)
var world_range := 12000.0  # visible radius in game units

func _process(_delta):
	if visible:
		queue_redraw()

func _draw():
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	
	var center = minimap_size / 2.0
	var scale_factor = minimap_size.x / (world_range * 2.0)
	
	# Background panel
	draw_rect(Rect2(Vector2.ZERO, minimap_size), Color(0.02, 0.05, 0.12, 0.75))
	
	# Grid lines (subtle)
	var grid_color = Color(0.15, 0.3, 0.5, 0.25)
	for i in range(1, 4):
		var x = minimap_size.x * i / 4.0
		draw_line(Vector2(x, 0), Vector2(x, minimap_size.y), grid_color, 1.0)
		draw_line(Vector2(0, x), Vector2(minimap_size.x, x), grid_color, 1.0)
	
	# Range circle (shows the scan boundary)
	draw_arc(center, minimap_size.x / 2.0 - 2, 0, TAU, 64, Color(0.2, 0.6, 1.0, 0.2), 1.0)
	
	# Draw oxygen relays (cyan pulsing dots)
	for relay in get_tree().get_nodes_in_group("oxygen_nodes"):
		var rel_pos = (relay.global_position - player.global_position) * scale_factor + center
		if _is_in_bounds(rel_pos):
			# Outer glow
			draw_circle(rel_pos, 6.0, Color(0, 0.7, 1.0, 0.2))
			# Core dot
			if relay.has_oxygen:
				draw_circle(rel_pos, 3.5, Color(0, 0.9, 1.0, 0.9))  # Bright cyan = has oxygen
			else:
				draw_circle(rel_pos, 3.5, Color(0.4, 0.4, 0.5, 0.6))  # Gray = no oxygen
	
	# Draw powerup pickups
	for node in get_tree().get_nodes_in_group("powerups"):
		var rel_pos = (node.global_position - player.global_position) * scale_factor + center
		if _is_in_bounds(rel_pos):
			var color = _get_powerup_color(node)
			# Outer glow
			draw_circle(rel_pos, 5.0, Color(color.r, color.g, color.b, 0.25))
			# Core dot
			draw_circle(rel_pos, 3.0, color)
			
	# Draw resource items
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is ResourceItem and is_instance_valid(node):
			var rel_pos = (node.global_position - player.global_position) * scale_factor + center
			if _is_in_bounds(rel_pos):
				var item_color = Color(1.0, 1.0, 1.0, 0.8)
				if node.data != null:
					match node.data.item_name:
						"hybrid mat": item_color = Color(1.0, 0.6, 0.0, 0.9) # Orange
						"battery mat": item_color = Color(0.2, 1.0, 0.2, 0.9) # Green
						"oxygen mat": item_color = Color(0.6, 0.2, 1.0, 0.9) # Purple
						
				draw_circle(rel_pos, 4.0, Color(item_color.r, item_color.g, item_color.b, 0.3))
				draw_circle(rel_pos, 2.5, item_color)
	
	# Draw player at center (white with glow)
	draw_circle(center, 5.0, Color(1, 1, 1, 0.15))
	draw_circle(center, 3.0, Color(1, 1, 1, 1))
	
	# Border
	draw_rect(Rect2(Vector2.ZERO, minimap_size), Color(0.2, 0.6, 1.0, 0.6), false, 2.0)
	
	# Label
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(4, 14), "SCAN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.8, 1.0, 0.8))

func _get_powerup_color(node) -> Color:
	if node is SprintBatteryPickup:
		return Color(1.0, 0.8, 0.1, 0.9)   # Yellow/gold - sprint
	elif node is OxygenCanisterPickup:
		return Color(0.3, 1.0, 0.5, 0.9)   # Green - oxygen
	elif node is ScannerPickup:
		return Color(0.4, 0.7, 1.0, 0.9)   # Blue - scanner
	else:
		return Color(1, 1, 1, 0.7)          # White - unknown

func _is_in_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= minimap_size.x and pos.y >= 0 and pos.y <= minimap_size.y
