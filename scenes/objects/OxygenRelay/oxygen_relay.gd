extends Area2D
class_name OxygenRelay

@export var is_source: bool = false
@export var max_tether_distance: float = 300.0
@export var tether_width = 5.0
@export var tether_color = Color(1.0, 1.0, 1.0, 1.0)

var connected_nodes: Array[OxygenRelay] = []
var has_oxygen: bool = false
var parent_node: OxygenRelay = null # The node providing us oxygen

@onready var tether_line = $Line2D # Make sure your Line2D is set up in the scene

func _ready():
	add_to_group("oxygen_nodes")
	add_to_group("interactable") # So the player can find it
	tether_line.width = tether_width
	tether_line.default_color = tether_color
	
	if is_source:
		has_oxygen = true
		
	update_network() # Initialize visuals safely

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

func creates_cycle(child_node: OxygenRelay, parent_candidate: OxygenRelay) -> bool:
	var current = parent_candidate
	while current != null:
		if current == child_node:
			return true
		current = current.parent_node
	return false

func show_loop_warning():
	var ft = Label.new()
	ft.text = "Loop Connection Blocked!"
	ft.set_script(preload("res://scripts/ui/FloatingText.gd"))
	if get_parent():
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector2(0, -40)

# Connect this node to another node
func connect_to(target_node: OxygenRelay):
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
	
	# Draw the tether line from child to parent
	curr_child.tether_line.clear_points()
	curr_child.tether_line.top_level = true # Make it immune to parent's rotation/scaling
	curr_child.tether_line.add_point(curr_child.global_position) 
	curr_child.tether_line.add_point(curr_parent.global_position)
	curr_child.tether_line.z_index = 0 # Draw on top of background
	curr_child.tether_line.width = curr_child.tether_width # Set width from variable
	curr_child.tether_line.default_color = curr_child.tether_color # Set color from variable
	
	# Update the network from the parent down
	curr_parent.update_network()
	if old_parent != null and old_parent != curr_parent:
		old_parent.update_network()
	return true

func break_relay():
	# Remove this relay from its parent's connected nodes list
	if parent_node != null:
		parent_node.connected_nodes.erase(self)
		
	# Disconnect all children and clear their tether lines
	for child in connected_nodes:
		if is_instance_valid(child):
			child.parent_node = null
			child.tether_line.clear_points()
			child.update_network()
			
	# Remove ourselves from groups and destroy
	remove_from_group("interactable")
	remove_from_group("oxygen_nodes")
	queue_free()

func interact(player):
	if player.node_to_tether_from == null:
		# Start tethering from this relay
		player.node_to_tether_from = self
		print("Tether grabbed from relay!")
	elif player.node_to_tether_from == self:
		# Cancel tethering if clicking the same relay again
		player.node_to_tether_from = null
		player.queue_redraw() # Tell player to clear the line
		print("Tether cancelled.")
	else:
		# Connect the new relay to the one we started from
		# Note: 'self' connects TO 'node_to_tether_from'
		var success = connect_to(player.node_to_tether_from)
		if success:
			print("Tether connected!")
		
		# Drop the cord after trying to connect
		player.node_to_tether_from = null
		player.queue_redraw() # Tell player to clear the line
