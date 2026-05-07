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

func _ready():
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

	# Rotation
	if velocity.length() > 5:
		rotation = velocity.angle()

# Emit particles using godots particle system a great system for making particles
func handle_effects():
	thruster.emitting = boost_system.is_boosting()

# Interact system
func find_nearest_interactable():
	var closest = null
	var closest_dist = 99999
	
	for obj in get_tree().get_nodes_in_group("interactable"):
		var dist = position.distance_to(obj.position)
		
		if dist < 100 and dist < closest_dist:
			closest = obj
			closest_dist = dist
	
	nearby_object = closest

func spawn_dropped_battery(battery):
	if battery.tier_data == null:
		print("ERROR: Battery has no tier data")
		return
	
	var scene = battery.tier_data.pickup_scene
	
	if scene == null:
		print("ERROR: No pickup scene for this tier")
		return
	
	var obj = scene.instantiate()
	obj.battery = battery
	
	var drop_offset = Vector2(50, 0).rotated(rotation)
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
	
	var drop_offset = Vector2(50, 0).rotated(rotation)
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
		if nearby_object != null:
			nearby_object.interact(self)
			# Debug helper
			$Inventory.print_inventory()
	if Input.is_action_just_pressed("drop_item"):
		var obj = inventory.remove_from_slot(selected_slot)
		
		if obj == null:
			print("Slot empty!")
			return
		
		# Battery slot
		if selected_slot == 0:
			spawn_dropped_battery(obj)
		else:
			spawn_dropped_item(obj)
