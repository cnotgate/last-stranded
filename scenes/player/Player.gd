extends CharacterBody2D

@export var thrust: float = 400.0
@export var max_speed: float = 200.0
@export var sliding: float = 0.985
@export var brake_strength: float = 0.9
@export var ik_offset_amount: float = 5.0


@onready var boost_system = $Boost
@onready var inventory = $Inventory
@onready var thruster = $GPUParticles2D

# Character IK
@onready var leg_r_target = $"Character Container/IK Targets/LegR Target"
@onready var leg_l_target = $"Character Container/IK Targets/LegL Target"
@onready var arm_r_target = $"Character Container/IK Targets/ArmR Target"
@onready var arm_l_target = $"Character Container/IK Targets/ArmL Target"
@onready var char_container = $"Character Container"

var leg_r_base: Vector2
var leg_l_base: Vector2
var arm_r_base: Vector2
var arm_l_base: Vector2
var current_facing: float = 1.0

var nearby_object = null
var selected_slot := 0

var debug_timer := 0.0
var node_to_tether_from: OxygenRelay = null
var interact_hold_timer: float = 0.0

var player_tether_renderer: Line2D = null
var player_tether_rope: Rope = null
var player_handle_start: RopeHandle = null
var player_handle_end: RopeHandle = null
var tether_was_taut: bool = false

func destroy_active_tether_rope():
	if is_instance_valid(player_handle_start):
		player_handle_start.queue_free()
		player_handle_start = null
	if is_instance_valid(player_handle_end):
		player_handle_end.queue_free()
		player_handle_end = null
	if is_instance_valid(player_tether_renderer):
		player_tether_renderer.queue_free()
		player_tether_renderer = null
	if is_instance_valid(player_tether_rope):
		player_tether_rope.queue_free()
		player_tether_rope = null

func set_tether_source(relay: OxygenRelay):
	var had_tether = (node_to_tether_from != null)
	destroy_active_tether_rope()
	node_to_tether_from = relay
	queue_redraw()
	
	var hud = get_tree().get_first_node_in_group("hud")
	if node_to_tether_from != null:
		if hud:
			hud.add_log_message("Umbilical connected to Relay.", "info")
		# 1. Base Rope setup
		var rope2d = Rope.new()
		rope2d.name = "PlayerTetherPipe"
		rope2d.render_line = false # Disable default line drawing
		rope2d.fixate_begin = false
		
		var distance = global_position.distance_to(node_to_tether_from.global_position)
		var target_length = min(node_to_tether_from.max_tether_distance, max(40.0, distance * 1.15))
		rope2d.rope_length = target_length
		
		rope2d.gravity = 0.0
		rope2d.z_index = -1
		rope2d.damping = 3.0
		rope2d.num_constraint_iterations = 12
		rope2d.num_segments = 70
		rope2d.line_width = node_to_tether_from.tether_width
		rope2d.color = node_to_tether_from.tether_color
		
		# Add rope to the level/parent scene first so _enter_tree does not overwrite our custom points
		if get_parent():
			get_parent().add_child(rope2d)
		player_tether_rope = rope2d

		# 1b. Textured Renderer Setup using umbilical_segment.png
		var renderer = Line2D.new()
		renderer.name = "TetherRenderer"
		renderer.texture = preload("res://assets/umbilical_segment.png")
		renderer.texture_mode = Line2D.LINE_TEXTURE_TILE
		renderer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		renderer.width = 16.0 # Match thickness for the umbilical cord (actual cable is 12px wide)
		renderer.default_color = Color(1.0, 1.0, 1.0, 1.0)
		renderer.z_index = -1
		if get_parent():
			get_parent().add_child(renderer)
		player_tether_renderer = renderer
 
		# Initialize points with a slight initial sag curve to prevent compression spasm
		var points = PackedVector2Array()
		var dir = node_to_tether_from.global_position - global_position
		var normal = Vector2(-dir.y, dir.x).normalized()
		var sag_amount = 0.0
		if distance > 10.0:
			sag_amount = (target_length - distance) * 0.75
		
		for i in range(71):
			var t = float(i) / 70.0
			var straight_pos = global_position.lerp(node_to_tether_from.global_position, t)
			var curve_offset = normal * sin(t * PI) * sag_amount
			points.append(straight_pos + curve_offset)
		rope2d.set_points(points)
		rope2d.set_old_points(points)

		# 2. Start Handle (pinned to Player)
		var h_start = RopeHandle.new()
		h_start.name = "PlayerStartHandle"
		add_child(h_start)
		h_start.rope_path = rope2d.get_path()
		h_start._helper.target_rope = rope2d
		h_start.rope_position = 0.0
		h_start.strength = 1.0
		player_handle_start = h_start

		# 3. End Handle (pinned to target Relay)
		var h_end = RopeHandle.new()
		h_end.name = "PlayerEndHandle"
		node_to_tether_from.add_child(h_end)
		h_end.rope_path = rope2d.get_path()
		h_end._helper.target_rope = rope2d
		h_end.rope_position = 1.0
		h_end.strength = 1.0
		player_handle_end = h_end
	else:
		if had_tether and hud:
			hud.add_log_message("Umbilical disconnected.", "warning")

@export var max_oxygen: float = 100.0
var current_oxygen: float = 100.0
var nearest_relay: OxygenRelay = null
var nearest_relay_distance: float = 0.0

var is_dead: bool = false
var in_dialogue: bool = false
var initial_spawn_pos: Vector2
var last_safe_relay: OxygenRelay = null

@export var max_tether_material: float = 5000.0
var current_tether_material: float = 5000.0

# Internal battery (not in inventory)
var battery_energy: float = 100.0
var battery_max: float = 100.0
var battery_drain_rate: float = 2.5 # 2.5 kW/s → depletes in 40 seconds
var battery_boost_multiplier: float = 1.7

func recharge_battery(amount: float):
	battery_energy = min(battery_energy + amount, battery_max)

func is_battery_full() -> bool:
	return battery_energy >= battery_max

# Sprint Battery system
var is_sprint_active: bool = false
var sprint_timer: float = 0.0
var sprint_duration: float = 60.0
var sprint_boost_bonus: float = 0.75  # +75% boost
var sprint_drain_per_sec: float = 0.5

# Scanner system
var is_scanner_active: bool = false
var scanner_timer: float = 0.0
var scanner_duration: float = 15.0

# Placement system
var is_placing_relay: bool = false
var place_relay_timer: float = 0.0

var is_disconnecting_tether: bool = false
var disconnect_tether_timer: float = 0.0

# Flashlight system
var flashlight: PointLight2D = null
var is_flashlight_on: bool = false
var flashlight_drain_rate: float = 100.0 / 180.0 # 3 minutes from full

func _ready():
	# Ensure the scanner action exists
	if not InputMap.has_action("scanner"):
		InputMap.add_action("scanner")
		var ev = InputEventKey.new()
		ev.physical_keycode = KEY_F
		InputMap.action_add_event("scanner", ev)
		
	if not InputMap.has_action("crafting_menu"):
		InputMap.add_action("crafting_menu")
		var ev2 = InputEventKey.new()
		ev2.physical_keycode = KEY_C
		InputMap.action_add_event("crafting_menu", ev2)
		
	if not InputMap.has_action("place_item"):
		InputMap.add_action("place_item")
		var ev3 = InputEventKey.new()
		ev3.physical_keycode = KEY_E
		InputMap.action_add_event("place_item", ev3)
		
	if not InputMap.has_action("disconnect_tether"):
		InputMap.add_action("disconnect_tether")
		var ev4 = InputEventKey.new()
		ev4.physical_keycode = KEY_X
		InputMap.action_add_event("disconnect_tether", ev4)
		
	if not InputMap.has_action("toggle_flashlight"):
		InputMap.add_action("toggle_flashlight")
		var ev5 = InputEventKey.new()
		ev5.physical_keycode = KEY_T
		InputMap.action_add_event("toggle_flashlight", ev5)

	add_to_group("player")
	setup_controller_inputs()
	
	initial_spawn_pos = global_position
	
	if StoryManager != null:
		StoryManager.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
		StoryManager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
	
	leg_r_base = leg_r_target.position
	leg_l_base = leg_l_target.position
	arm_r_base = arm_r_target.position
	arm_l_base = arm_l_target.position

	# Instantiate and add the orbital player compass/pointer
	var compass_scene = Node2D.new()
	compass_scene.set_script(preload("res://scripts/ui/PlayerCompass.gd"))
	compass_scene.player = self
	add_child(compass_scene)

	# Procedural breath audio
	var breath_player = AudioStreamPlayer.new()
	breath_player.name = "BreathPlayer"
	breath_player.stream = AudioSynth.generate_breath(5.0)
	breath_player.volume_db = -25.0 # Keep it quiet
	breath_player.bus = "Master"
	add_child(breath_player)
	breath_player.play()
	
	# Procedural heartbeat audio
	var heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.name = "HeartbeatPlayer"
	heartbeat_player.stream = AudioSynth.generate_heartbeat(1.0)
	heartbeat_player.volume_db = -80.0 # Silent by default
	heartbeat_player.bus = "Master"
	add_child(heartbeat_player)
	heartbeat_player.play()
	
	# Setup Flashlight
	flashlight = PointLight2D.new()
	var gradient = Gradient.new()
	# Replace default points
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 700
	texture.height = 700
	flashlight.texture = texture
	flashlight.energy = 0.0
	flashlight.shadow_enabled = true
	add_child(flashlight)

func _on_dialogue_started():
	in_dialogue = true

func _on_dialogue_finished():
	in_dialogue = false

func _physics_process(delta):
	if is_dead:
		return
		
	handle_movement(delta)
	handle_effects()
	handle_audio()
	find_nearest_interactable()
	handle_item()
	handle_interact_hold(delta)
	check_oxygen_relay_nearby(delta)
	handle_sprint(delta)
	handle_scanner(delta)
	handle_flashlight(delta)
	
	# I hate debugging
	debug_timer += delta
	
	if debug_timer >= 1.0:
		debug_timer = 0.0
		
		print("Boosting:", boost_system.is_boosting())
		print("Speed:", int(velocity.length()))
		print("Battery:", snapped(battery_energy, 0.1), "/", battery_max, "kW")

	# Relay placement timer
	if is_placing_relay:
		place_relay_timer -= delta
		if place_relay_timer <= 0:
			is_placing_relay = false
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				hud.add_log_message("Placement cancelled.", "warning")
				
	# Tether disconnect timer
	if is_disconnecting_tether:
		disconnect_tether_timer -= delta
		if disconnect_tether_timer <= 0:
			is_disconnecting_tether = false
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				hud.add_log_message("Tether disconnect cancelled.", "warning")

	# Oxygen consumption
	# Constrain player position and velocity to tether limits BEFORE moving
	if is_instance_valid(player_tether_rope) and is_instance_valid(node_to_tether_from):
		var dist = global_position.distance_to(node_to_tether_from.global_position)
		var max_allowed_dist = min(node_to_tether_from.max_tether_distance, current_tether_material)
		
		var hud = get_tree().get_first_node_in_group("hud")
		var is_taut = (dist >= max_allowed_dist - 5.0)
		if is_taut and not tether_was_taut:
			if hud:
				hud.add_log_message("Umbilical max length reached!", "warning")
			tether_was_taut = true
		elif not is_taut:
			tether_was_taut = false
		
		if dist > max_allowed_dist:
			var to_relay = node_to_tether_from.global_position - global_position
			var dir = to_relay.normalized()
			global_position = node_to_tether_from.global_position - dir * max_allowed_dist
			
			# Kill any velocity moving away from the relay
			var outward_vel = velocity.dot(-dir)
			if outward_vel > 0:
				velocity -= -dir * outward_vel

	move_and_slide()
	
	# Dynamically update the active tether rope length based on final position
	if is_instance_valid(player_tether_rope) and is_instance_valid(node_to_tether_from):
		var dist = global_position.distance_to(node_to_tether_from.global_position)
		var max_allowed_dist = min(node_to_tether_from.max_tether_distance, current_tether_material)
		player_tether_rope.rope_length = min(max_allowed_dist, max(40.0, dist * 1.15))
		
		# Update Line2D points dynamically
		if is_instance_valid(player_tether_renderer):
			player_tether_renderer.points = player_tether_rope.get_points()
		


func handle_flashlight(delta):
	if Input.is_action_just_pressed("toggle_flashlight"):
		if battery_energy > 0:
			is_flashlight_on = !is_flashlight_on
			flashlight.energy = 1.0 if is_flashlight_on else 0.0
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				hud.add_log_message("Flashlight " + ("ON" if is_flashlight_on else "OFF"), "info")
		else:
			is_flashlight_on = false
			flashlight.energy = 0.0
			
	if is_flashlight_on:
		battery_energy -= flashlight_drain_rate * delta
		if battery_energy <= 0.0:
			battery_energy = 0.0
			is_flashlight_on = false
			flashlight.energy = 0.0
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				hud.add_log_message("Flashlight battery depleted.", "warning")

# Main movement
func handle_movement(delta):
	if in_dialogue:
		# Apply heavy, smooth braking during dialogue
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
		
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
		velocity -= velocity * (1 - brake_strength)

	# Get dynamic max speed (boost affects it)
	var current_max_speed = max_speed * boost_system.get_boost_multiplier()

	# Limit speed
	if velocity.length() > current_max_speed:
		velocity = velocity.normalized() * current_max_speed
	elif velocity.length() < 1.0:
		velocity = Vector2.ZERO

	# Sliding (low grav feeling)
	velocity *= sliding
	
	## Character orientation and skeleton animation
	var new_ik_offset
	if boost_system.is_boosting():
		new_ik_offset = ik_offset_amount * 2
	else:
		new_ik_offset = ik_offset_amount
	
	if abs(velocity.x) > 1.0:
		var new_facing = sign(velocity.x)
		if new_facing != current_facing:
			current_facing = new_facing
		char_container.scale.x = current_facing
	
	var speed_ratio = velocity.length() / current_max_speed
	var offset = velocity.normalized() * (-new_ik_offset * speed_ratio)
	var adjusted_offset = Vector2(offset.x * current_facing, offset.y)
	
	leg_r_target.position = leg_r_target.position.move_toward(leg_r_base + adjusted_offset, 0.5)
	leg_l_target.position = leg_l_target.position.move_toward(leg_l_base + adjusted_offset, 0.5)
	arm_r_target.position = arm_r_target.position.move_toward(arm_r_base + adjusted_offset, 0.5)
	arm_l_target.position = arm_l_target.position.move_toward(arm_l_base + adjusted_offset, 0.5)
	
	## Character orientation and animation
	#var sprite = $AnimatedSprite2D
	#if velocity.x > 5:
		#sprite.flip_h = false
	#elif velocity.x < -5:
		#sprite.flip_h = true
		#
	#if velocity.length() > 10:
		#sprite.play("moving")
	#else:
		#sprite.play("idle")

# Emit particles using godots particle system a great system for making particles
func handle_effects():
	thruster.emitting = boost_system.is_boosting()

# Adjust procedural audio based on player state
func handle_audio():
	var breath = get_node_or_null("BreathPlayer")
	var heartbeat = get_node_or_null("HeartbeatPlayer")
	
	if not breath or not heartbeat:
		return
		
	var is_connected = false
	if is_instance_valid(player_tether_rope) and is_instance_valid(node_to_tether_from):
		# Only calm down if the relay actually has oxygen!
		if "has_oxygen" in node_to_tether_from:
			is_connected = node_to_tether_from.has_oxygen
		else:
			is_connected = true # Fallback if it's not a relay but something else
			
	var o2_ratio = clamp(current_oxygen / max_oxygen, 0.0, 1.0)
	
	if is_connected:
		# Connected to umbilical: safe, extremely faint breath, no heartbeat
		breath.volume_db = lerp(breath.volume_db, -35.0, 0.05)
		heartbeat.volume_db = lerp(heartbeat.volume_db, -80.0, 0.05)
		breath.pitch_scale = lerp(breath.pitch_scale, 1.0, 0.05)
		heartbeat.pitch_scale = lerp(heartbeat.pitch_scale, 1.0, 0.05)
	else:
		# Disconnected: stressed, faint breath but audible heartbeat
		breath.volume_db = lerp(breath.volume_db, -22.0, 0.05)
		
		# Heartbeat gets louder as O2 drops
		var target_hb_vol = lerp(-6.0, -20.0, o2_ratio)
		heartbeat.volume_db = lerp(heartbeat.volume_db, target_hb_vol, 0.05)
		
		# Faster breathing and heartbeat as O2 drops
		var target_pitch = lerp(1.7, 1.0, o2_ratio)
		breath.pitch_scale = lerp(breath.pitch_scale, target_pitch, 0.05)
		heartbeat.pitch_scale = lerp(heartbeat.pitch_scale, target_pitch, 0.05)

# Interact system
func handle_interact_hold(delta):
	if Input.is_action_pressed("interact"):
		if nearby_object != null and nearby_object is OxygenRelay:
			interact_hold_timer += delta
			if interact_hold_timer >= 3.0:
				print("Relay destroyed!")
				# Clear our tether if we were holding one connected to this relay
				if node_to_tether_from == nearby_object:
					set_tether_source(null)
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
		"oxygen_relay":
			scene = preload("res://scenes/objects/OxygenRelay/OxygenRelay.tscn")
	
	if scene == null:
		print("ERROR: No scene for item:", data.item_name)
		return
	
	var obj = scene.instantiate()
	if "data" in obj:
		obj.data = data
	
	var drop_dir = -1 if $AnimatedSprite2D.flip_h else 1
	var drop_offset = Vector2(50 * drop_dir, 0)
	obj.position = position + drop_offset
	
	get_parent().add_child(obj)
	
	if data.item_name == "oxygen_relay":
		var dm = get_tree().get_first_node_in_group("disaster_manager")
		if dm: dm.trigger_disaster()
	
	print("Dropped/Placed:", data.item_name)

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
	
	if Input.is_action_just_pressed("prev_slot"):
		selected_slot = (selected_slot - 1 + 6) % 6
		print("Selected slot:", selected_slot)
	if Input.is_action_just_pressed("next_slot"):
		selected_slot = (selected_slot + 1) % 6
		print("Selected slot:", selected_slot)
		
	if Input.is_action_just_pressed("scanner"):
		activate_scanner()
		
	if Input.is_action_just_pressed("crafting_menu"):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("toggle_crafting_menu"):
			hud.toggle_crafting_menu()
			
	var interacted = false
	if Input.is_action_just_pressed("interact"):
		print("Interact pressed! Nearby object: ", nearby_object)
		if nearby_object != null:
			nearby_object.interact(self)
			$Inventory.print_inventory()
			interacted = true
		else:
			# Use selected item from inventory when no world object nearby
			var item_data = inventory.get_item_data(selected_slot)
			if item_data != null and item_data.item_name == "battery mat":
				if not is_battery_full():
					inventory.consume_from_slot(selected_slot)
					recharge_battery(25.0)
					var hud = get_tree().get_first_node_in_group("hud")
					if hud:
						hud.add_log_message("Battery recharged +25.0 kW.", "info")
				else:
					var hud = get_tree().get_first_node_in_group("hud")
					if hud:
						hud.add_log_message("Battery already full!", "warning")

	if Input.is_action_just_pressed("place_item") and not interacted:
		if inventory:
			var item_data = inventory.get_item_data(selected_slot)
			if item_data != null and item_data.item_name == "oxygen_relay":
				if is_placing_relay:
					# Confirmed!
					is_placing_relay = false
					inventory.consume_from_slot(selected_slot)
					spawn_dropped_item(item_data)
					var hud = get_tree().get_first_node_in_group("hud")
					if hud: hud.add_log_message("Oxygen Relay deployed.", "info")
				else:
					# Initiate
					is_placing_relay = true
					place_relay_timer = 5.0
					var hud = get_tree().get_first_node_in_group("hud")
					if hud: hud.add_log_message("Press E again to deploy Oxygen Relay.", "warning")
	if Input.is_action_just_pressed("disconnect_tether"):
		if node_to_tether_from != null:
			if is_disconnecting_tether:
				# Confirmed
				is_disconnecting_tether = false
				set_tether_source(null)
				print("Tether cancelled.")
				var hud = get_tree().get_first_node_in_group("hud")
				if hud: hud.add_log_message("Umbilical disconnected.", "info")
			else:
				# Initiate
				is_disconnecting_tether = true
				disconnect_tether_timer = 5.0
				var hud = get_tree().get_first_node_in_group("hud")
				if hud: hud.add_log_message("Press X again to disconnect umbilical.", "warning")
				
	if Input.is_action_just_pressed("drop_item"):
		if inventory == null:
			print("Error: Inventory node not found!")
			return
			
		var item_data_to_drop = inventory.get_item_data(selected_slot)
		if item_data_to_drop != null and item_data_to_drop.item_name == "oxygen_relay":
			var hud = get_tree().get_first_node_in_group("hud")
			if hud: hud.add_log_message("Press 'E' to deploy structures.", "warning")
			return
			
		# Drop one item from the stack
		var item_data = inventory.consume_from_slot(selected_slot)
		if item_data == null:
			print("Slot empty!")
			return
		spawn_dropped_item(item_data)

func check_oxygen_relay_nearby(delta):
	var in_oxygen = false
	nearest_relay = null
	var min_dist = INF
	
	# Check all oxygen relays in the scene to update compass targets
	for relay in get_tree().get_nodes_in_group("oxygen_nodes"):
		if is_instance_valid(relay):
			var dist = global_position.distance_to(relay.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_relay = relay
				nearest_relay_distance = dist
				
	# Umbilical recharge: player only gets oxygen if actively connected to a relay that has oxygen
	if node_to_tether_from != null and is_instance_valid(node_to_tether_from):
		if "has_oxygen" in node_to_tether_from and node_to_tether_from.has_oxygen:
			in_oxygen = true
			last_safe_relay = node_to_tether_from
		elif not "has_oxygen" in node_to_tether_from:
			in_oxygen = true # Fallback
			
	if in_oxygen:
		# Recharge oxygen
		current_oxygen += 5.0 * delta
	else:
		# Drain oxygen
		current_oxygen -= 0.55 * delta
		
	current_oxygen = clamp(current_oxygen, 0.0, max_oxygen)
	
	if current_oxygen <= 0.0 and not is_dead:
		die()

func die():
	is_dead = true
	set_physics_process(false)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_rescue_screen()
		
	# Wait for 5 seconds for rescue protocol to "finish"
	await get_tree().create_timer(5.0).timeout
	respawn()
	
func respawn():
	# Reset resources
	current_oxygen = max_oxygen
	battery_energy = battery_max
	
	# Clear any old tethers
	set_tether_source(null)
	
	# Determine respawn location
	if is_instance_valid(last_safe_relay) and last_safe_relay.has_oxygen:
		global_position = last_safe_relay.global_position
		# Auto tether to it
		set_tether_source(last_safe_relay)
	else:
		global_position = initial_spawn_pos
		
	# Resume gameplay
	is_dead = false
	set_physics_process(true)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.hide_rescue_screen()

func activate_sprint():
	is_sprint_active = true
	sprint_timer = sprint_duration
	print("Sprint activated! Duration:", sprint_duration, "s")

func handle_sprint(delta):
	if not is_sprint_active:
		return
	
	sprint_timer -= delta
	
	if sprint_timer <= 0:
		is_sprint_active = false
		sprint_timer = 0.0
		print("Sprint expired!")

func activate_scanner():
	if battery_energy >= 15.0:
		battery_energy -= 15.0
		is_scanner_active = true
		scanner_timer = scanner_duration
		print("Scanner activated! Duration:", scanner_duration, "s")
	else:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.add_log_message("Not enough power for Scanner! Needs 15.0 kW.", "warning")
		print("Scanner failed: Not enough battery!")

func handle_scanner(delta):
	if not is_scanner_active:
		return
	
	scanner_timer -= delta
	
	if StoryManager != null:
		StoryManager.current_objective_node = StoryManager.get_current_objective_node(global_position)
	
	if scanner_timer <= 0:
		is_scanner_active = false
		scanner_timer = 0.0
		print("Scanner expired!")

# Programmatic Xbox Controller binding configuration
func setup_controller_inputs():
	var actions = {
		"move_up": [
			{"type": "axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0},
			{"type": "button", "btn": JOY_BUTTON_DPAD_UP}
		],
		"move_down": [
			{"type": "axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0},
			{"type": "button", "btn": JOY_BUTTON_DPAD_DOWN}
		],
		"move_left": [
			{"type": "axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0},
			{"type": "button", "btn": JOY_BUTTON_DPAD_LEFT}
		],
		"move_right": [
			{"type": "axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0},
			{"type": "button", "btn": JOY_BUTTON_DPAD_RIGHT}
		],
		"boost": [
			{"type": "button", "btn": JOY_BUTTON_A},
			{"type": "axis", "axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}
		],
		"brake": [
			{"type": "button", "btn": JOY_BUTTON_B},
			{"type": "axis", "axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0}
		],
		"interact": [
			{"type": "button", "btn": JOY_BUTTON_X}
		],
		"drop_item": [
			{"type": "button", "btn": JOY_BUTTON_Y}
		],
		"prev_slot": [
			{"type": "button", "btn": JOY_BUTTON_LEFT_SHOULDER}
		],
		"next_slot": [
			{"type": "button", "btn": JOY_BUTTON_RIGHT_SHOULDER}
		]
	}

	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		var existing = InputMap.action_get_events(action)
		for binding in actions[action]:
			var already_bound = false
			if binding["type"] == "button":
				for e in existing:
					if e is InputEventJoypadButton and e.button_index == binding["btn"]:
						already_bound = true
						break
				if not already_bound:
					var ev = InputEventJoypadButton.new()
					ev.button_index = binding["btn"]
					InputMap.action_add_event(action, ev)
			elif binding["type"] == "axis":
				for e in existing:
					if e is InputEventJoypadMotion and e.axis == binding["axis"] and sign(e.axis_value) == sign(binding["value"]):
						already_bound = true
						break
				if not already_bound:
					var ev = InputEventJoypadMotion.new()
					ev.axis = binding["axis"]
					ev.axis_value = binding["value"]
					InputMap.action_add_event(action, ev)
