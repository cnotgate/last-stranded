extends Node2D

var player: CharacterBody2D
var orbit_radius: float = 75.0
var arrow_color: Color = Color(0.0, 0.85, 1.0, 0.95)
var glow_color: Color = Color(0.0, 0.85, 1.0, 0.3)
var arrow_size: float = 6.0

var default_font: Font

func _ready():
	top_level = true
	z_index = 2 # Draw on top of player sprite
	default_font = ThemeDB.fallback_font
	
	material = CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func _physics_process(_delta):
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	queue_redraw()

func _draw():
	if player == null:
		return
	
	# Find all oxygen nodes
	var relays = get_tree().get_nodes_in_group("oxygen_nodes")
	if relays.is_empty():
		return
		
	# Sort relays by distance to player
	var sorted_relays = []
	for relay in relays:
		if is_instance_valid(relay):
			var dist = player.global_position.distance_to(relay.global_position)
			sorted_relays.append({"relay": relay, "distance": dist})
			
	sorted_relays.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Keep only the 3 nearest relays
	var count = min(3, sorted_relays.size())
	for i in range(count):
		var item = sorted_relays[i]
		var relay = item.relay
		var dist = item.distance
		
		# Define opacities based on distance rank, using fixed arrow and font sizes
		var current_arrow_size = arrow_size
		var alpha = 1.0
		var font_sz = 9
		
		if i == 0:
			alpha = 0.95
		elif i == 1:
			alpha = 0.6
		elif i == 2:
			alpha = 0.3
			
		var current_arrow_color = Color(0.0, 0.85, 1.0, alpha)
		var current_glow_color = Color(0.0, 0.85, 1.0, alpha * 0.3)
		var current_text_color = Color(0.8, 0.95, 1.0, alpha)
		var current_outline_color = Color(0.0, 0.0, 0.0, alpha)
		
		# Calculate direction and position
		var dir = global_position.direction_to(relay.global_position)
		var arrow_pos = dir * orbit_radius
		var angle = dir.angle()
		
		# Equilateral triangle geometry
		# 1. Draw outer glow triangle
		var glow_size = current_arrow_size + 2.0
		var gh = glow_size * 0.866025
		var gp1 = arrow_pos + Vector2(glow_size, 0).rotated(angle)
		var gp2 = arrow_pos + Vector2(-glow_size * 0.5, -gh).rotated(angle)
		var gp3 = arrow_pos + Vector2(-glow_size * 0.5, gh).rotated(angle)
		draw_colored_polygon(PackedVector2Array([gp1, gp2, gp3]), current_glow_color)
		
		# 2. Draw solid inner arrow triangle
		var h = current_arrow_size * 0.866025
		var p1 = arrow_pos + Vector2(current_arrow_size, 0).rotated(angle)
		var p2 = arrow_pos + Vector2(-current_arrow_size * 0.5, -h).rotated(angle)
		var p3 = arrow_pos + Vector2(-current_arrow_size * 0.5, h).rotated(angle)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), current_arrow_color)
		
		# 3. Draw distance text following the arrow
		if default_font:
			var dist_text = str(int(floor(dist / 100.0))) + "m"
			# Place text slightly outside the arrow orbit
			var text_offset = dir * (15.0 + current_arrow_size * 0.8)
			var text_pos = arrow_pos + text_offset + Vector2(0, font_sz * 0.35)
			
			# Draw outline and string
			draw_string_outline(default_font, text_pos, dist_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, 3, current_outline_color)
			draw_string(default_font, text_pos, dist_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, current_text_color)
			
	# --- SCANNER FEATURES ---
	if player.is_scanner_active:
		# --- OBJECTIVE SCANNER COMPASS ---
		if StoryManager and StoryManager.current_objective_node:
			var objective = StoryManager.current_objective_node
			if is_instance_valid(objective):
				var dist = player.global_position.distance_to(objective.global_position)
				var dir = global_position.direction_to(objective.global_position)
				
				# Objective pointer variables
				var obj_orbit = orbit_radius + 15.0 # Orbit slightly further out than relays
				var obj_arrow_size = arrow_size * 1.5 # Bigger triangle
				var obj_color = Color(1.0, 0.75, 0.0, 1.0) # Amber
				var obj_glow = Color(1.0, 0.75, 0.0, 0.4)
				var obj_pos = dir * obj_orbit
				var obj_angle = dir.angle()
				
				# 1. Outer Glow
				var g_size = obj_arrow_size + 3.0
				var gh = g_size * 0.866025
				var gp1 = obj_pos + Vector2(g_size, 0).rotated(obj_angle)
				var gp2 = obj_pos + Vector2(-g_size * 0.5, -gh).rotated(obj_angle)
				var gp3 = obj_pos + Vector2(-g_size * 0.5, gh).rotated(obj_angle)
				draw_colored_polygon(PackedVector2Array([gp1, gp2, gp3]), obj_glow)
				
				# 2. Solid Inner Triangle
				var h = obj_arrow_size * 0.866025
				var p1 = obj_pos + Vector2(obj_arrow_size, 0).rotated(obj_angle)
				var p2 = obj_pos + Vector2(-obj_arrow_size * 0.5, -h).rotated(obj_angle)
				var p3 = obj_pos + Vector2(-obj_arrow_size * 0.5, h).rotated(obj_angle)
				draw_colored_polygon(PackedVector2Array([p1, p2, p3]), obj_color)
				
				# 3. Distance text for objective
				if default_font:
					var dist_text = str(int(floor(dist / 100.0))) + "m"
					var text_offset = dir * (20.0 + obj_arrow_size)
					var text_pos = obj_pos + text_offset + Vector2(0, 4)
					draw_string_outline(default_font, text_pos, dist_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, 4, Color(0,0,0,1))
					draw_string(default_font, text_pos, dist_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, obj_color)
