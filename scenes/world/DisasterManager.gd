extends Node2D

var timer: float = 0.0
var state: int = 0
var player: Node2D = null
var hud: CanvasLayer = null

func _ready():
	add_to_group("disaster_manager")

func trigger_disaster():
	if state > 0: return
	print("DISASTER SEQUENCE INITIATED")
	state = 1
	timer = 5.0 # 5 seconds delay after placing relay

func _process(delta):
	if state == 0:
		return
		
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if hud == null:
		hud = get_tree().get_first_node_in_group("hud")
		
	timer -= delta
	
	if state == 1 and timer <= 0:
		# Trigger the dialogue and red alarm
		state = 2
		timer = 3.0 # Dialogue takes a bit, then debris spawns
		
		# Play dialogue
		if StoryManager:
			StoryManager.trigger_event("tutorial_disaster_alert")
			
		# Screen shake / alarm effect
		if hud:
			# We can simulate alarm by adding a flashing red ColorRect to the HUD
			var alarm = ColorRect.new()
			alarm.name = "DisasterAlarm"
			alarm.color = Color(1.0, 0.0, 0.0, 0.3)
			alarm.set_anchors_preset(Control.PRESET_FULL_RECT)
			hud.add_child(alarm)
			
			var audio = AudioStreamPlayer.new()
			audio.name = "DisasterSiren"
			audio.stream = AudioSynth.generate_warning()
			audio.volume_db = 0.0
			hud.add_child(audio)
			audio.play()
			
	elif state == 2 and timer <= 0:
		# Spawn debris
		state = 3
		timer = 2.0 # Time until impact
		
		if player:
			# Spawn generic particles hurtling towards player
			var particles = CPUParticles2D.new()
			particles.name = "DebrisParticles"
			particles.amount = 100
			particles.lifetime = 2.0
			particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			particles.emission_rect_extents = Vector2(100, 500)
			particles.direction = Vector2(-1, 0) # Moving left
			particles.spread = 15.0
			particles.gravity = Vector2(0, 0)
			particles.initial_velocity_min = 2000.0
			particles.initial_velocity_max = 3000.0
			particles.scale_amount_min = 2.0
			particles.scale_amount_max = 8.0
			particles.color = Color(0.6, 0.6, 0.6)
			
			# Spawn far right of the player
			particles.position = player.global_position + Vector2(2500, 0)
			get_parent().add_child(particles)
			
	elif state == 3 and timer <= 0:
		# Impact! Fade to black
		state = 4
		timer = 3.0 # Hold black screen for 3 seconds
		
		var canvas = CanvasLayer.new()
		canvas.layer = 100 # Topmost
		var black = ColorRect.new()
		black.color = Color(0, 0, 0, 1)
		black.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas.add_child(black)
		add_child(canvas)
		
		if hud:
			var alarm = hud.get_node_or_null("DisasterAlarm")
			if alarm: alarm.queue_free()
			var siren = hud.get_node_or_null("DisasterSiren")
			if siren: siren.queue_free()
			
	elif state == 4 and timer <= 0:
		# Transition to Act I
		state = 5
		get_tree().change_scene_to_file("res://scenes/world/Act1.tscn")
