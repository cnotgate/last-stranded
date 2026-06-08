extends Area2D
class_name OxygenRelay

@export var is_source: bool = false
@export var max_tether_distance: float = 5000.0
@export var tether_width = 5.0
@export var tether_color = Color(1.0, 1.0, 1.0, 1.0)

var connected_nodes: Array[OxygenRelay] = []
var has_oxygen: bool = false
var parent_node: OxygenRelay = null # The node providing us oxygen

@onready var tether_line = $Line2D # Make sure your Line2D is set up in the scene

var active_rope: Rope = null
var active_renderer: Line2D = null
var handle_start: RopeHandle = null
var handle_end: RopeHandle = null
var connected_distance: float = 0.0
var flash_time: float = 0.0
var led_indicator: Node2D = null

func destroy_pipe():
	if connected_distance > 0.0:
		var player = get_tree().get_first_node_in_group("player")
		if player and "current_tether_material" in player:
			player.current_tether_material = min(player.max_tether_material, player.current_tether_material + connected_distance)
		
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.add_log_message("Relay link broken. Reclaimed " + str(snapped(connected_distance / 100.0, 0.1)) + "m.", "warning")
			
		connected_distance = 0.0

	if is_instance_valid(handle_start):
		handle_start.queue_free()
		handle_start = null
	if is_instance_valid(handle_end):
		handle_end.queue_free()
		handle_end = null
	if is_instance_valid(active_renderer):
		active_renderer.queue_free()
		active_renderer = null
	if is_instance_valid(active_rope):
		active_rope.queue_free()
		active_rope = null

func _ready():
	add_to_group("oxygen_nodes")
	add_to_group("interactable") # So the player can find it
	tether_line.width = tether_width
	tether_line.default_color = tether_color
	
	if is_source:
		has_oxygen = true
		
	led_indicator = Node2D.new()
	led_indicator.name = "LEDIndicator"
	add_child(led_indicator)
	led_indicator.draw.connect(_draw_led)
		
	update_network() # Initialize visuals safely

func _process(delta):
	flash_time += delta
	if is_instance_valid(led_indicator):
		led_indicator.queue_redraw()

func _physics_process(_delta):
	if is_instance_valid(active_renderer) and is_instance_valid(active_rope):
		active_renderer.points = active_rope.get_points()

func _draw_led():
	if not is_instance_valid(led_indicator):
		return
	# Draw a flashing LED light indicator on the relay (using sine wave oscillation)
	var led_pos = Vector2(0, -20)
	var led_radius = 8.0
	
	var flash_val = (sin(flash_time * 8.0) + 1.0) / 2.0
	var opacity = lerp(0.2, 1.0, flash_val)
	
	var led_color = Color(0.0, 1.0, 0.2, opacity) if has_oxygen else Color(1.0, 0.1, 0.1, opacity)
	
	# Glow effect (larger and slightly more opaque)
	led_indicator.draw_circle(led_pos, led_radius + 14.0, Color(led_color.r, led_color.g, led_color.b, opacity * 0.4))
	# LED Core
	led_indicator.draw_circle(led_pos, led_radius, led_color)
	# High-intensity center highlight
	led_indicator.draw_circle(led_pos, led_radius * 0.4, Color(1.0, 1.0, 1.0, opacity))

# Called to recalculate oxygen across the network
func update_network():
	if is_source:
		has_oxygen = true
	else:
		# We only have oxygen if our parent has oxygen
		has_oxygen = (parent_node != null and parent_node.has_oxygen)
	
	# Update visuals
	if has_oxygen:
		modulate = Color(1, 1, 1) # Normal
	else:
		modulate = Color(0.6, 0.6, 0.6) # Darkened / Off
		
	# Tell all children to update
	for child in connected_nodes:
		child.update_network()

func get_network_root() -> OxygenRelay:
	var current = self
	while current.parent_node != null:
		current = current.parent_node
	return current

func creates_cycle(child_node: OxygenRelay, parent_candidate: OxygenRelay) -> bool:
	return child_node.get_network_root() == parent_candidate.get_network_root()

func show_loop_warning():
	var ft = Label.new()
	ft.text = "Loop Connection Blocked!"
	ft.set_script(preload("res://scripts/ui/FloatingText.gd"))
	if get_parent():
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector2(0, -40)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_log_message("Loop connection blocked! Network cycle detected.", "error")

func show_material_warning():
	var ft = Label.new()
	ft.text = "Out of Tether Material!"
	ft.set_script(preload("res://scripts/ui/FloatingText.gd"))
	if get_parent():
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector2(0, -40)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_log_message("Tether action blocked! Out of tether material.", "error")

func show_already_connected_warning():
	var ft = Label.new()
	ft.text = "Relays Already Connected!"
	ft.set_script(preload("res://scripts/ui/FloatingText.gd"))
	if get_parent():
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector2(0, -40)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_log_message("Connection blocked: Relays are already connected.", "warning")

# Connect this node to another node
func connect_to(target_node: OxygenRelay, active_tether = null):
	if self.parent_node == target_node or target_node.parent_node == self:
		print("Relays already connected!")
		show_already_connected_warning()
		return false

	var distance = global_position.distance_to(target_node.global_position)
	
	if distance > max_tether_distance:
		print("Too far to tether!")
		return false
		
	# Auto-adjust so oxygen flows correctly regardless of click order
	var curr_parent = self
	var curr_child = target_node
	
	if target_node.has_oxygen and not self.has_oxygen:
		curr_parent = target_node
		curr_child = self
	elif self.has_oxygen and not target_node.has_oxygen:
		curr_parent = self
		curr_child = target_node
	else:
		# Default to whatever we clicked first as the parent
		curr_parent = target_node
		curr_child = self
		
	# Check if this connection would create a loop
	if creates_cycle(curr_child, curr_parent):
		print("Loop connection detected!")
		show_loop_warning()
		return false
		
	# If this child already had a parent, remove it from the old parent's children list
	var old_parent = curr_child.parent_node
	if old_parent != null and old_parent != curr_parent:
		old_parent.connected_nodes.erase(curr_child)
		
	# Establish connection
	curr_child.parent_node = curr_parent
	curr_parent.connected_nodes.append(curr_child)
	
	# Clear static tether line
	curr_child.tether_line.clear_points()
	curr_child.tether_line.visible = false
	
	# Destroy any old physical connection first
	curr_child.destroy_pipe()
	
	# 1. Base Rope setup
	var rope2d = Rope.new()
	rope2d.name = "PhysicalOxygenPipe"
	rope2d.render_line = false # Disable default solid color drawing
	rope2d.fixate_begin = false
	var target_length = distance * 1.08
	rope2d.rope_length = target_length
	rope2d.gravity = 0.0
	rope2d.z_index = -1
	rope2d.damping = 3.0
	rope2d.num_constraint_iterations = 12
	var segs = 70
	rope2d.num_segments = segs
	
	# Add the Rope to the parent scene first so _enter_tree does not overwrite our custom points
	if curr_child.get_parent():
		curr_child.get_parent().add_child(rope2d)
	curr_child.active_rope = rope2d

	# 1b. Textured Renderer Setup using umbilical_segment.png (matches player umbilical)
	var renderer = Line2D.new()
	renderer.name = "PhysicalTetherRenderer"
	renderer.texture = preload("res://assets/umbilical_segment.png")
	renderer.texture_mode = Line2D.LINE_TEXTURE_TILE
	renderer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	renderer.width = 16.0 # Match player umbilical thickness
	renderer.default_color = Color(1.0, 1.0, 1.0, 1.0)
	renderer.z_index = -1
	if curr_child.get_parent():
		curr_child.get_parent().add_child(renderer)
	curr_child.active_renderer = renderer

	# Copy points from the active tether if available, otherwise fallback to sag curve
	var points = PackedVector2Array()
	var old_points = PackedVector2Array()
	if active_tether and is_instance_valid(active_tether) and active_tether._points.size() == segs + 1:
		points = active_tether._points.duplicate()
		old_points = active_tether._oldpoints.duplicate()
	else:
		var dir = curr_parent.global_position - curr_child.global_position
		var normal = Vector2(-dir.y, dir.x).normalized()
		var sag_amount = 0.0
		if distance > 10.0:
			sag_amount = (target_length - distance) * 0.75

		for i in range(segs + 1):
			var t = float(i) / segs
			var straight_pos = curr_child.global_position.lerp(curr_parent.global_position, t)
			var curve_offset = normal * sin(t * PI) * sag_amount
			points.append(straight_pos + curve_offset)
		old_points = points.duplicate()

	rope2d.set_points(points)
	rope2d.set_old_points(old_points)

	# 2. Start Handle (pinned to child relay)
	var h_start = RopeHandle.new()
	h_start.name = "StartHandle"
	curr_child.add_child(h_start)
	h_start.rope_path = rope2d.get_path()
	h_start._helper.target_rope = rope2d
	h_start.rope_position = 0.0
	h_start.strength = 1.0
	curr_child.handle_start = h_start

	# 3. End Handle (pinned to parent relay)
	var h_end = RopeHandle.new()
	h_end.name = "EndHandle"
	curr_parent.add_child(h_end)
	h_end.rope_path = rope2d.get_path()
	h_end._helper.target_rope = rope2d
	h_end.rope_position = 1.0
	h_end.strength = 1.0
	curr_child.handle_end = h_end
	
	curr_child.connected_distance = distance
	
	# Consume material from the player
	var player = get_tree().get_first_node_in_group("player")
	if player and "current_tether_material" in player:
		player.current_tether_material = max(0.0, player.current_tether_material - distance)
	
	# Update the network from the parent down
	curr_parent.update_network()
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_log_message("Relay link established: " + str(snapped(distance / 100.0, 0.1)) + "m.", "info")
	if old_parent != null and old_parent != curr_parent:
		old_parent.update_network()
	return true

func break_relay():
	# Remove this relay from its parent's connected nodes list
	if parent_node != null:
		parent_node.connected_nodes.erase(self)
		
	# Clean up our own pipe connection to our parent
	destroy_pipe()
		
	# Disconnect all children and clear their physical tethers/lines
	for child in connected_nodes:
		if is_instance_valid(child):
			child.parent_node = null
			child.tether_line.clear_points()
			child.destroy_pipe()
			child.update_network()
			
	# Remove ourselves from groups and destroy
	remove_from_group("interactable")
	remove_from_group("oxygen_nodes")
	queue_free()

func interact(player):
	if player.node_to_tether_from == null:
		if "current_tether_material" in player and player.current_tether_material < 10.0:
			show_material_warning()
			return
		# Start tethering from this relay
		player.set_tether_source(self)
		print("Tether grabbed from relay!")
	elif player.node_to_tether_from == self:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.add_log_message("Already tethered to this relay. Press X to cancel.", "warning")
	else:
		var success = connect_to(player.node_to_tether_from, player.player_tether_rope)
		if success:
			print("Tether connected!")
			# Drop the cord after successfully connecting
			player.set_tether_source(null)
