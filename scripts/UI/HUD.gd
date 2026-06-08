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

# Colors — unified sci-fi palette
const C_CYAN    = Color(0.0,  0.9,  1.0,  1.0)
const C_AMBER   = Color(1.0,  0.72, 0.0,  1.0)
const C_BLUE    = Color(0.4,  0.75, 1.0,  1.0)
const C_DIM     = Color(0.35, 0.4,  0.5,  0.7)
const C_RED     = Color(1.0,  0.2,  0.2,  1.0)
const C_BG      = Color(0.02, 0.04, 0.07, 0.72)
const C_BORDER  = Color(0.0,  0.55, 0.75, 0.55)
const C_SEL_BG  = Color(0.04, 0.12, 0.18, 0.85)

var slot_bg: StyleBoxFlat
var slot_selected: StyleBoxFlat
var oxygen_label: Label
var battery_label: Label
var tether_label: Label
var umbilical_panel_node: PanelContainer
var umbilical_value_label: Label
var log_panel: PanelContainer
var log_container: VBoxContainer
var log_messages: Array = []
var hud_flash_time: float = 0.0
var beep_player: AudioStreamPlayer
var warning_player: AudioStreamPlayer
var is_warning_playing: bool = false
var persistent_o2_warning_label: Label = null
var rescue_screen: ColorRect
var rescue_label: Label
var rescue_warning_player: AudioStreamPlayer

# RPG Dialog Variables
var dialog_panel: PanelContainer
var dialog_speaker_label: Label
var dialog_text_label: RichTextLabel
var dialog_continue_icon: Label
var is_typing_dialogue: bool = false
var typing_timer: float = 0.0
var target_dialogue_text: String = ""
var type_index: int = 0
var typing_speed: float = 0.03 # 30ms per character

var objective_label: Label

# Crafting UI
var crafting_panel: PanelContainer
var is_crafting_open: bool = false

# --- Helper: build a sci-fi angular panel style ---
func _sci_panel(bg: Color = C_BG, border: Color = C_BORDER, radius: int = 2, pad: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(border.r, border.g, border.b, 0.3)
	s.shadow_size = 6
	s.set_content_margin_all(pad)
	return s

# --- Helper: build a progress bar fill style ---
func _bar_fill(col: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(1)
	s.shadow_color = Color(col.r, col.g, col.b, 0.6)
	s.shadow_size = 8
	return s

# --- Helper: build a progress bar background ---
func _bar_bg() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.06, 0.1, 0.8)
	s.set_corner_radius_all(1)
	s.border_color = Color(0.15, 0.2, 0.3, 0.5)
	s.set_border_width_all(1)
	return s

# --- Helper: make a Label ---
func _lbl(text: String, size: int, col: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _ready():
	var sw = get_viewport().get_visible_rect().size.x
	var sh = get_viewport().get_visible_rect().size.y

	# Setup Procedural UI Beep
	beep_player = AudioStreamPlayer.new()
	beep_player.stream = AudioSynth.generate_beep(1200.0, 0.1) # 1200Hz high pitch beep
	beep_player.volume_db = -12.0
	add_child(beep_player)
	
	# Setup Procedural Oxygen Warning
	warning_player = AudioStreamPlayer.new()
	warning_player.stream = AudioSynth.generate_warning()
	warning_player.volume_db = -8.0
	add_child(warning_player)
	
	# Setup Rescue Screen
	rescue_screen = ColorRect.new()
	rescue_screen.name = "RescueScreen"
	rescue_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	rescue_screen.color = Color.BLACK
	rescue_screen.z_index = 100
	rescue_screen.visible = false
	
	rescue_label = _lbl("ASTRONAUT RESCUE PROTOCOL INITIATED", 32, C_RED)
	rescue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rescue_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	rescue_screen.add_child(rescue_label)
	add_child(rescue_screen)
	
	rescue_warning_player = AudioStreamPlayer.new()
	rescue_warning_player.stream = AudioSynth.generate_rescue_alarm()
	rescue_warning_player.volume_db = 0.0
	rescue_screen.add_child(rescue_warning_player)
	
	# Setup Objective UI
	objective_label = _lbl("CURRENT OBJECTIVE: SURVIVE", 14, C_AMBER)
	objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_label.position = Vector2(16, 16)
	$Control.add_child(objective_label)

	# Setup RPG Dialog UI
	dialog_panel = PanelContainer.new()
	dialog_panel.add_theme_stylebox_override("panel", _sci_panel(Color(0,0,0, 0.85), C_BLUE, 4, 15))
	dialog_panel.custom_minimum_size = Vector2(800, 160)
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialog_panel.position = Vector2((sw - 800) / 2, sh - 200)
	dialog_panel.visible = false
	add_child(dialog_panel)
	
	var d_vbox = VBoxContainer.new()
	dialog_panel.add_child(d_vbox)
	
	dialog_speaker_label = _lbl("SPEAKER", 18, C_BLUE)
	d_vbox.add_child(dialog_speaker_label)
	
	dialog_text_label = RichTextLabel.new()
	dialog_text_label.custom_minimum_size = Vector2(0, 100)
	dialog_text_label.add_theme_font_size_override("normal_font_size", 16)
	dialog_text_label.bbcode_enabled = true
	d_vbox.add_child(dialog_text_label)
	
	dialog_continue_icon = _lbl("▼ Press [SPACE] to continue", 12, Color(1,1,1,0.5))
	dialog_continue_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	d_vbox.add_child(dialog_continue_icon)
	
	# Connect StoryManager Signals
	if StoryManager != null:
		StoryManager.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
		StoryManager.connect("dialogue_advanced", Callable(self, "_on_dialogue_advanced"))
		StoryManager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
		StoryManager.connect("objective_updated", Callable(self, "_on_objective_updated"))

	# ── 1. Progress Bars ──────────────────────────────────────────────────
	var bar_bg = _bar_bg()
	oxygen_bar.add_theme_stylebox_override("background", bar_bg)
	oxygen_bar.add_theme_stylebox_override("fill", _bar_fill(C_CYAN))
	battery_bar.add_theme_stylebox_override("background", bar_bg)
	battery_bar.add_theme_stylebox_override("fill", _bar_fill(C_AMBER))
	oxygen_bar.show_percentage  = false
	battery_bar.show_percentage = false
	battery_bar.visible = true
	oxygen_bar.custom_minimum_size  = Vector2(0, 5)
	battery_bar.custom_minimum_size = Vector2(0, 5)

	# ── 2. Stats Panel (bottom-left, like helmet HUD) ─────────────────────
	var stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	# Left bright accent border — rest dim
	var sp = _sci_panel(C_BG, C_BORDER, 2, 10)
	sp.border_width_left = 2
	stats_panel.add_theme_stylebox_override("panel", sp)
	$Control.add_child(stats_panel)
	var vbox = $Control/VBoxContainer
	vbox.reparent(stats_panel, false)
	vbox.add_theme_constant_override("separation", 4)
	stats_panel.position = Vector2(16, sh - 180)
	stats_panel.custom_minimum_size = Vector2(170, 0)

	# O2 label
	oxygen_label = _lbl("O2  100%", 9, C_CYAN)
	oxygen_label.name = "OxygenLabel"
	vbox.add_child(oxygen_label)
	vbox.move_child(oxygen_label, 0)

	# PWR label
	battery_label = _lbl("PWR  --.- kW", 9, C_AMBER)
	battery_label.name = "BatteryLabel"
	vbox.add_child(battery_label)
	vbox.move_child(battery_label, 2)

	# TETHER label
	tether_label = _lbl("TETHER  --m", 9, C_BLUE)
	tether_label.name = "TetherLabel"
	vbox.add_child(tether_label)

	# Style SprintLabel / ScannerLabel
	sprint_label.add_theme_font_size_override("font_size", 9)
	sprint_label.add_theme_color_override("font_color", C_AMBER)
	scanner_label.add_theme_font_size_override("font_size", 9)
	scanner_label.add_theme_color_override("font_color", C_CYAN)

	# ── 3. Hotbar (top-center, angular) ───────────────────────────────────
	var hotbar_panel = PanelContainer.new()
	hotbar_panel.name = "HotbarPanel"
	hotbar_panel.add_theme_stylebox_override("panel", _sci_panel(C_BG, C_BORDER, 2, 4))
	$Control.add_child(hotbar_panel)
	var hbox = $Control/HBoxContainer
	hbox.reparent(hotbar_panel, false)
	hbox.add_theme_constant_override("separation", 3)
	hotbar_panel.position = Vector2((sw - 290) / 2.0, 12)

	# ── 4. Umbilical panel (top-right) ────────────────────────────────────
	umbilical_panel_node = PanelContainer.new()
	umbilical_panel_node.name = "UmbilicalPanel"
	umbilical_panel_node.add_theme_stylebox_override("panel", _sci_panel(C_BG, C_BORDER, 2, 8))
	$Control.add_child(umbilical_panel_node)
	umbilical_panel_node.custom_minimum_size = Vector2(160, 0)

	var umb_vbox = VBoxContainer.new()
	umbilical_panel_node.add_child(umb_vbox)
	var umb_title = _lbl("◈ UMBILICAL", 7, C_DIM)
	umb_vbox.add_child(umb_title)
	umbilical_value_label = _lbl("NO LINK", 9, C_DIM)
	umbilical_value_label.name = "UmbilicalValueLabel"
	umb_vbox.add_child(umbilical_value_label)
	umbilical_panel_node.position = Vector2(sw - 176, 12)

	add_to_group("hud")

	# ── 5. Log Panel (bottom-right, terminal style) ────────────────────────
	log_panel = PanelContainer.new()
	log_panel.name = "LogPanel"
	log_panel.add_theme_stylebox_override("panel", _sci_panel(Color(0.01, 0.03, 0.05, 0.75), C_BORDER, 2, 10))
	$Control.add_child(log_panel)
	log_panel.custom_minimum_size = Vector2(260, 0)

	var log_inner = VBoxContainer.new()
	log_inner.name = "LogInnerVBox"
	log_panel.add_child(log_inner)

	var log_title = _lbl("▶ SYSLOG", 7, Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.45))
	log_inner.add_child(log_title)

	log_container = VBoxContainer.new()
	log_container.name = "LogContainer"
	log_inner.add_child(log_container)

	log_panel.position = Vector2(sw - 278, sh - 156)

	# ── 5.5. Crafting Panel (center-right, hidden by default) ──────────────
	crafting_panel = PanelContainer.new()
	crafting_panel.name = "CraftingPanel"
	crafting_panel.add_theme_stylebox_override("panel", _sci_panel(Color(0.01, 0.03, 0.05, 0.9), C_AMBER, 2, 12))
	$Control.add_child(crafting_panel)
	crafting_panel.custom_minimum_size = Vector2(240, 0)
	crafting_panel.position = Vector2(sw - 280, 200)
	crafting_panel.visible = false
	
	var craft_vbox = VBoxContainer.new()
	crafting_panel.add_child(craft_vbox)
	
	var craft_title = _lbl("▶ FABRICATOR", 14, C_AMBER)
	craft_vbox.add_child(craft_title)
	
	# Button: Craft Tether
	var btn_tether = Button.new()
	btn_tether.text = "Craft Tether (+500m)\nCost: 1 Hybrid Mat"
	btn_tether.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_tether.add_theme_font_size_override("font_size", 12)
	craft_vbox.add_child(btn_tether)
	btn_tether.pressed.connect(func(): _on_craft_tether())
	
	# Button: Craft Oxygen Relay
	var btn_relay = Button.new()
	btn_relay.text = "Craft Oxygen Relay\nCost: 5 Hybrid Mat"
	btn_relay.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_relay.add_theme_font_size_override("font_size", 12)
	craft_vbox.add_child(btn_relay)
	btn_relay.pressed.connect(func(): _on_craft_relay())

	# ── 6. Slot Styles ────────────────────────────────────────────────────
	slot_bg = _sci_panel(Color(0.03, 0.05, 0.08, 0.6), Color(0.2, 0.28, 0.38, 0.35), 2, 0)
	slot_selected = _sci_panel(C_SEL_BG, C_CYAN, 2, 0)
	slot_selected.shadow_color = Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.45)
	slot_selected.shadow_size = 8

	for i in range(slot_container.get_child_count()):
		var slot_node = slot_container.get_child(i)
		slot_node.custom_minimum_size = Vector2(40, 40)
		if slot_node.get_child_count() > 0 and slot_node.get_child(0) is TextureRect:
			var ir = slot_node.get_child(0)
			ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ir.custom_minimum_size = Vector2(28, 28)
			ir.size = Vector2(28, 28)
			ir.position = Vector2(6, 6)
		var cnt = Label.new()
		cnt.name = "StackCount"
		cnt.add_theme_font_size_override("font_size", 11)
		cnt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		cnt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		cnt.add_theme_constant_override("outline_size", 3)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		cnt.size     = Vector2(28, 28)
		cnt.position = Vector2(6, 6)
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cnt.visible = false
		slot_node.add_child(cnt)

	# ── 7. Compass ────────────────────────────────────────────────────────
	var compass = $Control/Compass
	compass.position = Vector2(sw - 120, 16)
	if distance_label:
		distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _input(event):
	var is_space = false
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		is_space = true
		
	if is_space and dialog_panel.visible:
		if is_typing_dialogue:
			# Skip typing effect and show full text instantly
			is_typing_dialogue = false
			type_index = target_dialogue_text.length()
			dialog_text_label.text = target_dialogue_text
			dialog_continue_icon.visible = true
		else:
			# Advance to next dialogue line
			if StoryManager != null:
				StoryManager.advance_dialogue()

func _process(delta):
	hud_flash_time += delta

	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p != null:
			player = p
		else:
			return

	var sw = get_viewport().get_visible_rect().size.x
	var sh = get_viewport().get_visible_rect().size.y
	
	# Dynamic resize for dialogue box
	if is_instance_valid(dialog_panel) and dialog_panel.visible:
		dialog_panel.position = Vector2((sw - 800) / 2, sh - 200)
		
	# Typewriter effect
	if is_typing_dialogue:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0.0
			type_index += 1
			if type_index >= target_dialogue_text.length():
				type_index = target_dialogue_text.length()
				is_typing_dialogue = false
				dialog_continue_icon.visible = true
			dialog_text_label.text = target_dialogue_text.substr(0, type_index)

	if rescue_screen.visible:
		if rescue_warning_player.playing:
			# Blink the text every 0.5 seconds
			var current_time = Time.get_ticks_msec() / 1000.0
			rescue_label.visible = fmod(current_time, 1.0) < 0.5
		else:
			rescue_label.visible = false
		# We still want to update o2 bar internally, but we can skip drawing things or just let it be hidden
		
	# 1. Oxygen
	oxygen_bar.value     = player.current_oxygen
	oxygen_bar.max_value = player.max_oxygen
	var o2_pct = player.current_oxygen / player.max_oxygen
	if oxygen_label:
		oxygen_label.text = "O2  %d%%" % int(round(o2_pct * 100.0))
		var o2_col = C_CYAN if o2_pct > 0.35 else C_RED.lerp(C_CYAN, o2_pct / 0.35)
		oxygen_label.add_theme_color_override("font_color", o2_col)

	# Low Oxygen Visual Effects
	var blur_threshold = 0.35
	if o2_pct < blur_threshold:
		var intensity = clamp(remap(o2_pct, 0.0, blur_threshold, 1.0, 0.0), 0.0, 1.0)
		# Reduce the max blur effect by multiplying with 0.5 (so it's only half as blurry at 0% O2)
		color_rect.material.set_shader_parameter("blur_amount", intensity * 0.5)
		color_rect.material.set_shader_parameter("vignette_intensity", intensity)
		
		if o2_pct <= 0:
			color_rect.modulate = Color.BLACK
		else:
			color_rect.modulate = Color.WHITE
			
		if not is_warning_playing and not rescue_screen.visible:
			warning_player.play()
			is_warning_playing = true
			
		if not is_instance_valid(persistent_o2_warning_label):
			persistent_o2_warning_label = _lbl("!! CRITICAL: OXYGEN DEPLETED !!", 12, C_RED)
			# Add to the top of the log or bottom
			log_container.add_child(persistent_o2_warning_label)
			log_container.move_child(persistent_o2_warning_label, 0) # Keep it at the top
	else:
		# Reset visuals when oxygen is restored
		color_rect.material.set_shader_parameter("blur_amount", 0.0)
		color_rect.material.set_shader_parameter("vignette_intensity", 0.0)
		color_rect.modulate = Color.WHITE
		
		if is_warning_playing:
			warning_player.stop()
			is_warning_playing = false
			
		if is_instance_valid(persistent_o2_warning_label):
			persistent_o2_warning_label.queue_free()
			persistent_o2_warning_label = null

	# 2. Battery
	var inv = player.get_node("Inventory")
	battery_bar.value     = player.battery_energy
	battery_bar.max_value = player.battery_max
	if battery_label:
		battery_label.text = "PWR  %.1f kW" % player.battery_energy
		var pwr_pct = player.battery_energy / player.battery_max
		var pwr_col = C_AMBER if pwr_pct > 0.25 else C_RED.lerp(C_AMBER, pwr_pct / 0.25)
		battery_label.add_theme_color_override("font_color", pwr_col)

	# 3. Tether
	if tether_label and "current_tether_material" in player:
		tether_label.text = "TETHER  %.1fm" % (player.current_tether_material / 100.0)

	# 4. Umbilical
	if umbilical_panel_node and is_instance_valid(umbilical_panel_node):
		umbilical_panel_node.position = Vector2(sw - 176, 12)
		if umbilical_value_label:
			if player.node_to_tether_from != null and is_instance_valid(player.node_to_tether_from):
				var dist = player.global_position.distance_to(player.node_to_tether_from.global_position)
				umbilical_value_label.text = "◉ LINKED  %.1fm" % (dist / 100.0)
				umbilical_value_label.add_theme_color_override("font_color", C_CYAN)
			else:
				umbilical_value_label.text = "○ NO LINK"
				umbilical_value_label.add_theme_color_override("font_color", C_DIM)

	# 5. Inventory slots
	for i in range(6):
		var slot_node = slot_container.get_child(i)
		if i == player.selected_slot:
			slot_node.add_theme_stylebox_override("panel", slot_selected)
			slot_node.modulate = Color(1, 1, 1, 1)
		else:
			slot_node.add_theme_stylebox_override("panel", slot_bg)
			slot_node.modulate = Color(1, 1, 1, 0.65)

		var has_item = inv.has_item_in_slot(i)
		var icon_rect = null
		if slot_node.get_child_count() > 0 and slot_node.get_child(0) is TextureRect:
			icon_rect = slot_node.get_child(0)
		var count_label = null
		for child in slot_node.get_children():
			if child is Label and child.name == "StackCount":
				count_label = child
				break

		if icon_rect:
			if not has_item:
				icon_rect.texture = null
			else:
				var item_data = inv.get_item_data(i)
				if item_data:
					match item_data.item_name:
						"oxygen mat":    icon_rect.texture = preload("res://assets/oxygen.png")
						"battery mat":   icon_rect.texture = preload("res://assets/battery.png")
						"hybrid mat":    icon_rect.texture = preload("res://assets/crafting_material.png")
						"oxygen_relay":  icon_rect.texture = preload("res://assets/oxygenrelay/oxygenrelay.png")
						_:               icon_rect.texture = null

		if count_label:
			var count = inv.get_item_count(i)
			count_label.text    = str(count) if count > 1 else ""
			count_label.visible = count > 1

	# 6. Sprint / Scanner
	if player.is_sprint_active:
		sprint_label.visible = true
		sprint_label.text = "⚡ BOOST  %ds" % int(ceil(player.sprint_timer))
	else:
		sprint_label.visible = false

	if player.is_scanner_active:
		scanner_label.visible = true
		scanner_label.text = "◎ SCAN  %ds" % int(ceil(player.scanner_timer))
		minimap.visible = true
	else:
		scanner_label.visible = false
		minimap.visible = false

	# 7. Compass
	if arrow:         arrow.visible = false
	if distance_label: distance_label.visible = false

	# 8. Dynamic positioning for resizing
	var stats_panel = $Control.get_node_or_null("StatsPanel")
	if is_instance_valid(stats_panel):
		stats_panel.position = Vector2(16, sh - 156)

	if log_panel and is_instance_valid(log_panel):
		log_panel.position = Vector2(sw - 278, sh - 156)
	if minimap and is_instance_valid(minimap):
		minimap.position = Vector2(16, sh - 348)

	# Fade out old log messages
	if log_panel and is_instance_valid(log_panel):
		var to_remove = []
		for log_info in log_messages:
			log_info.time_left -= delta
			if log_info.time_left <= 1.5:
				log_info.label.modulate.a = max(0.0, log_info.time_left / 1.5)
			if log_info.time_left <= 0.0:
				to_remove.append(log_info)
		for log_info in to_remove:
			log_messages.erase(log_info)
			if is_instance_valid(log_info.label):
				log_info.label.queue_free()


func add_log_message(text: String, type: String = "info"):
	if not is_instance_valid(log_container):
		return
	if log_messages.size() >= 5:
		var oldest = log_messages.pop_front()
		if is_instance_valid(oldest.label):
			oldest.label.queue_free()

	var time_str = Time.get_time_string_from_system().substr(0, 5)
	var log_label = Label.new()
	log_label.name = "LogMsg_" + str(Time.get_ticks_msec())
	log_label.add_theme_font_size_override("font_size", 9)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var prefix = ""
	var color  = C_CYAN
	match type.to_lower():
		"error":
			prefix = "ERR ▸ "
			color  = C_RED
		"warning":
			prefix = "WRN ▸ "
			color  = C_AMBER
		"note", "info":
			prefix = "SYS ▸ "
			color  = C_CYAN

	log_label.text = time_str + "  " + prefix + text
	log_label.add_theme_color_override("font_color", color)
	log_container.add_child(log_label)
	log_messages.append({"label": log_label, "time_left": 6.0})
	
	if is_instance_valid(beep_player):
		beep_player.play()

func set_umbilical_value(value: float, max_val: float):
	if umbilical_value_label:
		if max_val > 0:
			umbilical_value_label.text = "%d / %dm" % [int(value), int(max_val)]
		else:
			umbilical_value_label.text = "ERR / ERR"

func show_rescue_screen():
	if is_instance_valid(persistent_o2_warning_label):
		persistent_o2_warning_label.queue_free()
		persistent_o2_warning_label = null
		
	# Stop the standard critical oxygen beep
	if warning_player.playing:
		warning_player.stop()
		is_warning_playing = false
		
	$Control.visible = false
	color_rect.visible = false
	
	rescue_screen.modulate = Color(1.0, 1.0, 1.0, 1.0)
	rescue_screen.visible = true
	
	rescue_warning_player.volume_db = 0.0
	rescue_warning_player.play()
	
func hide_rescue_screen():
	# Stop audio immediately
	rescue_warning_player.stop()
	
	var tween = create_tween()
	# Stay completely black for 1.5 seconds
	tween.tween_interval(1.5)
	
	tween.tween_callback(func():
		# Reveal normal HUD elements behind the black screen
		$Control.visible = true
		color_rect.visible = true
	)
	
	# Smoothly fade out the black screen over 1.5 seconds
	tween.tween_property(rescue_screen, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.5)
	
	tween.tween_callback(func():
		rescue_screen.visible = false
	)

# --- Story Manager Callbacks ---

func _on_dialogue_started():
	dialog_panel.visible = true

func _on_dialogue_advanced(speaker, text, color):
	dialog_speaker_label.text = speaker
	dialog_speaker_label.add_theme_color_override("font_color", color)
	target_dialogue_text = text
	dialog_text_label.text = ""
	type_index = 0
	is_typing_dialogue = true
	dialog_continue_icon.visible = false

func _on_dialogue_finished():
	dialog_panel.visible = false

func _on_objective_updated(text: String):
	if objective_label:
		objective_label.text = "CURRENT OBJECTIVE: " + text

# --- Crafting Logic ---
func toggle_crafting_menu():
	is_crafting_open = not is_crafting_open
	if crafting_panel:
		crafting_panel.visible = is_crafting_open
		if is_crafting_open:
			add_log_message("Fabricator menu opened.", "info")

func _on_craft_tether():
	if player == null or player.get_node_or_null("Inventory") == null: return
	var inv = player.get_node("Inventory")
	
	if inv.consume_item("hybrid mat", 1):
		player.current_tether_material += 500.0
		player.max_tether_material += 500.0 # Also increase capacity? Yes, usually.
		add_log_message("Crafted Tether. Length increased by +500m.", "info")
		inv.print_inventory()
	else:
		add_log_message("Fabrication failed: Need 1 Hybrid Mat.", "error")

func _on_craft_relay():
	if player == null or player.get_node_or_null("Inventory") == null: return
	var inv = player.get_node("Inventory")
	
	if inv.consume_item("hybrid mat", 5):
		var relay_data = preload("res://scripts/data/oxygen_relay_item.tres")
		if inv.add_item(relay_data, 1):
			add_log_message("Crafted Oxygen Relay. Added to inventory.", "info")
		else:
			# Refund if inventory is full
			var hybrid_data = preload("res://scripts/data/dummyloot3.tres")
			inv.add_item(hybrid_data, 5)
			add_log_message("Fabrication failed: Inventory is full.", "warning")
		inv.print_inventory()
	else:
		add_log_message("Fabrication failed: Need 5 Hybrid Mats.", "error")
