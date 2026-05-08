extends CharacterBody2D

@export var thrust: float = 400.0
@export var max_speed: float = 200.0
@export var sliding: float = 0.985
@export var brake_strength: float = 0.9

@onready var boost_system = $Boost
@onready var inventory = $Inventory
@onready var thruster = $GPUParticles2D

var nearby_object = null
var selected_slot := 0

var debug_timer := 0.0
var node_to_tether_from: OxygenRelay = null
var interact_hold_timer: float = 0.0

@export var max_oxygen: float = 100.0
var current_oxygen: float = 100.0
var nearest_relay: OxygenRelay = null
var nearest_relay_distance: float = 0.0

func _ready():
	add_to_group("player")
	
	# Test battery input
	var tier1 = preload("res://scripts/data/tier1battery.tres")
	
	var generator = BatteryGenerator.new()
	var battery = generator.generate_from_tier(tier1)
	
	$Inventory.insert_battery(battery)
		
	print("Generated Battery:")
	print("Tier:", battery.tier)
	print("Boost:", battery.boost_multiplier)
	print("Drain:", battery.drain_rate)

func _physics_process(delta):
	handle_movement(delta)
	handle_effects()
	find_nearest_interactable()
	handle_item()
	handle_interact_hold(delta)
	check_oxygen_relay_nearby(delta)
	
	# I hate debugging
	debug_timer += delta
	
	if debug_timer >= 1.0:
		debug_timer = 0.0
		
		print("Boosting:", boost_system.is_boosting())
		print("Speed:", int(velocity.length()))
		
		if inventory.has_battery():
			var b = inventory.battery
			print("Energy:", int(b.current_energy))
			print("Boost Multiplier:", b.boost_multiplier)
			print("Drain:", b.drain_rate)
		else:
			print("No Battery")

	move_and_slide()
	
	# Request to redraw lines if we are holding a tether
	if node_to_tether_from != null:
		queue_redraw()

func _draw():
	if node_to_tether_from != null:
		# Draw a semi-transparent line from the player to the relay they grabbed the tether from
		var c = node_to_tether_from.tether_color
		var w = node_to_tether_from.tether_width
		draw_line(Vector2.ZERO, to_local(node_to_tether_from.global_position), Color(c.r, c.g, c.b, 1), w)

# Main movement
func handle_movement(delta):
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	# Get boost multiplier from system
	var current_thrust = thrust * boost_system.get_boost_multiplier()
	
	# Apply acceleration
	velocity += input_dir * current_thrust * delta

	# Brake
	if Input.is_action_pressed("brake"):
		velocity *= brake_strength

	# Get dynamic max speed (boost affects it)
	var current_max_speed = max_speed * boost_system.get_boost_multiplier()

	# Limit speed
	if velocity.length() > current_max_speed:
		velocity = velocity.normalized() * current_max_speed

	# Sliding (low grav feeling)
	velocity *= sliding

	# Character orientation and animation
	var sprite = $AnimatedSprite2D
	if velocity.x > 5:
		sprite.flip_h = false
	elif velocity.x < -5:
		sprite.flip_h = true
		
	if velocity.length() > 10:
		sprite.play("moving")
	else:
		sprite.play("idle")

# Emit particles using godots particle system a great system for making particles
func handle_effects():
	thruster.emitting = boost_system.is_boosting()

# Interact system
func handle_interact_hold(delta):
	if Input.is_action_pressed("interact"):
		if nearby_object != null and nearby_object is OxygenRelay:
			interact_hold_timer += delta
			if interact_hold_timer >= 3.0:
				print("Relay destroyed!")
				# Clear our tether if we were holding one connected to this relay
				if node_to_tether_from == nearby_object:
					node_to_tether_from = null
					queue_redraw()
				nearby_object.break_relay()
				nearby_object = null
				interact_hold_timer = 0.0
		else:
			interact_hold_timer = 0.0
	else:
		interact_hold_timer = 0.0

func find_nearest_interactable():
	var closest = null
	var closest_dist = 99999
	
	for obj in get_tree().get_nodes_in_group("interactable"):
		var dist = global_position.distance_to(obj.global_position)
		
		if dist < 150 and dist < closest_dist:
			closest = obj
			closest_dist = dist
	
	nearby_object = closest

func spawn_dropped_battery(battery):
	if battery == null:
		return
	
	var obj = BatteryPickup.new()
	obj.battery = battery
	
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/dummyitem2.png")
	sprite.scale = Vector2(2, 2)
	obj.add_child(sprite)
	
	var drop_dir = -1 if $AnimatedSprite2D.flip_h else 1
	var drop_offset = Vector2(50 * drop_dir, 0)
	obj.position = position + drop_offset
	
	get_parent().add_child(obj)
	
	print("Dropped battery (Tier", battery.tier, ")")
	
func spawn_dropped_item(data):
	var scene: PackedScene = null
	
	# Hardcode because I cant figure ts out for the life of me
	match data.item_name:
		"oxygen mat":
			scene = preload("res://scenes/items/DummyLoot1.tscn")
		"battery mat":
			scene = preload("res://scenes/items/DummyLoot2.tscn")
		"hybrid mat":
			scene = preload("res://scenes/items/DummyLoot3.tscn")
	
	if scene == null:
		print("ERROR: No scene for item:", data.item_name)
		return
	
	var obj = scene.instantiate()
	obj.data = data
	
	var drop_dir = -1 if $AnimatedSprite2D.flip_h else 1
	var drop_offset = Vector2(50 * drop_dir, 0)
	obj.position = position + drop_offset
	
	get_parent().add_child(obj)
	
	print("Dropped:", data.item_name)

# Inventory system
func handle_item():
	if Input.is_action_just_pressed("slot_1"):
		selected_slot = 0   # battery only
		print("Selected slot:", selected_slot)
	if Input.is_action_just_pressed("slot_2"):
		selected_slot = 1
		print("Selected slot:", selected_slot)
	if Input.is_action_just_pressed("slot_3"):
		selected_slot = 2
		print("Selected slot:", selected_slot)
	if Input.is_action_just_pressed("slot_4"):
		selected_slot = 3
		print("Selected slot:", selected_slot)
	if Input.is_action_just_pressed("slot_5"):
		selected_slot = 4
		print("Selected slot:", selected_slot)
	if Input.is_action_just_pressed("slot_6"):
		selected_slot = 5
		print("Selected slot:", selected_slot)
	
	if Input.is_action_just_pressed("interact"):
		print("Interact pressed! Nearby object: ", nearby_object)
		if nearby_object != null:
			nearby_object.interact(self)
			# Debug helper
			$Inventory.print_inventory()
	if Input.is_action_just_pressed("drop_item"):
		# If holding a tether, drop it first
		if node_to_tether_from != null:
			node_to_tether_from = null
			queue_redraw() # Clear the drawn line
			print("Tether cancelled.")
			return
			
		if inventory == null:
			print("Error: Inventory node not found!")
			return
			
		var item = inventory.remove_from_slot(selected_slot)
		
		if item == null:
			print("Slot empty!")
			return
		
		# Battery slot
		if selected_slot == 0:
			spawn_dropped_battery(item)
		else:
			spawn_dropped_item(item)

func check_oxygen_relay_nearby(delta):
	var in_oxygen = false
	nearest_relay = null
	var min_dist = INF
	
	# Check all oxygen relays in the scene
	for relay in get_tree().get_nodes_in_group("oxygen_nodes"):
		# Check for nearest relay for the compass
		var dist = global_position.distance_to(relay.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_relay = relay
			nearest_relay_distance = dist
			
		# If the relay has oxygen and the player's body is inside its Area2D
		if relay.has_oxygen and relay.overlaps_body(self):
			print("Player is in oxygen relay area!")
			in_oxygen = true
			
	if in_oxygen:
		# Recharge oxygen
		current_oxygen += 5.0 * delta
	else:
		# Drain oxygen
		current_oxygen -= 0.55 * delta
		
	current_oxygen = clamp(current_oxygen, 0.0, max_oxygen)
