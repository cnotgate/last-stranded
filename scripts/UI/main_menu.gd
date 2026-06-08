extends MarginContainer

@export var star_scene: PackedScene

var station_rect: TextureRect
var time_elapsed: float = 0.0

var settings_modal: PanelContainer
var credits_modal: PanelContainer
var modals_center: CenterContainer

# Button and Close button references for controller focus navigation
var btn_start: MenuButtonContainer
var btn_settings: MenuButtonContainer
var btn_credits: MenuButtonContainer
var btn_exit: MenuButtonContainer

var settings_close_btn: Button
var credits_close_btn: Button

# Custom MenuButtonContainer class for interactive, animated menu buttons
class MenuButtonContainer extends HBoxContainer:
	var label: Button
	var indicator: Label
	var spacer: Control
	var tween: Tween
	
	func _init(text_val: String):
		add_theme_constant_override("separation", 8)
		alignment = BoxContainer.ALIGNMENT_BEGIN
		
		# Spacer for container-safe sliding animation
		spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 0)
		add_child(spacer)
		
		indicator = Label.new()
		indicator.text = "▶"
		indicator.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 1.0))
		indicator.add_theme_font_size_override("font_size", 14)
		indicator.modulate.a = 0.0
		indicator.custom_minimum_size = Vector2(16, 0)
		indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(indicator)
		
		label = Button.new()
		label.text = text_val
		label.flat = true
		label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.85))
		label.add_theme_color_override("font_hover_color", Color(0.0, 0.85, 1.0, 1.0))
		label.add_theme_color_override("font_focus_color", Color(0.0, 0.85, 1.0, 1.0))
		label.add_theme_color_override("font_pressed_color", Color(0.0, 0.6, 0.85, 1.0))
		label.add_theme_font_size_override("font_size", 20)
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.pivot_offset = Vector2(0, 15) # Pivot at left-center
		
		var font_reg = SystemFont.new()
		font_reg.font_names = PackedStringArray(["Inter", "Segoe UI", "Helvetica Neue", "Arial", "sans-serif"])
		font_reg.font_weight = 500
		label.add_theme_font_override("font", font_reg)
		
		var empty_sb = StyleBoxEmpty.new()
		label.add_theme_stylebox_override("normal", empty_sb)
		label.add_theme_stylebox_override("hover", empty_sb)
		label.add_theme_stylebox_override("pressed", empty_sb)
		label.add_theme_stylebox_override("focus", empty_sb)
		
		add_child(label)
		
		label.mouse_entered.connect(func():
			label.grab_focus()
		)
		label.mouse_exited.connect(func():
			var input_mgr = label.get_node_or_null("/root/InputManager")
			if input_mgr == null or not input_mgr.is_gamepad:
				label.release_focus()
		)
		label.focus_entered.connect(_on_hover)
		label.focus_exited.connect(_on_unhover)
		
	func _on_hover():
		if tween: tween.kill()
		tween = create_tween().set_parallel(true)
		tween.tween_property(indicator, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(spacer, "custom_minimum_size", Vector2(12.0, 0.0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	func _on_unhover():
		if tween: tween.kill()
		tween = create_tween().set_parallel(true)
		tween.tween_property(indicator, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(spacer, "custom_minimum_size", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide default simple editor nodes
	var old_bg = get_node_or_null("ColorRect")
	if old_bg: old_bg.visible = false
	var old_vbox = get_node_or_null("VBoxContainer")
	if old_vbox: old_vbox.visible = false
	var old_timer = get_node_or_null("Timer")
	if old_timer: old_timer.stop()

	# 1. Custom Diagonal Gradient Background
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.01, 0.02, 0.04, 1.0),
		Color(0.04, 0.06, 0.12, 1.0),
		Color(0.08, 0.03, 0.14, 1.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.0, 0.0)
	grad_tex.fill_to = Vector2(1.0, 1.0)
	
	var bg_gradient = TextureRect.new()
	bg_gradient.texture = grad_tex
	bg_gradient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_gradient.stretch_mode = TextureRect.STRETCH_SCALE
	bg_gradient.anchors_preset = 15
	bg_gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_gradient)
	move_child(bg_gradient, 0)
	
	# 2. Starry Background Overlay
	var starry_bg = TextureRect.new()
	starry_bg.texture = preload("res://assets/background/starry-background.jpg")
	starry_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	starry_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	starry_bg.modulate = Color(1.0, 1.0, 1.0, 0.22)
	starry_bg.anchors_preset = 15
	starry_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(starry_bg)
	move_child(starry_bg, 1)

	# 3. Ambient Space Dust Particles
	var dust = CPUParticles2D.new()
	dust.amount = 40
	dust.lifetime = 8.0
	dust.preprocess = 8.0
	dust.speed_scale = 0.4
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(960, 540)
	dust.direction = Vector2(1.0, -0.25)
	dust.spread = 15.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 12.0
	dust.initial_velocity_max = 24.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 6.0
	
	var p_grad = Gradient.new()
	p_grad.colors = PackedColorArray([
		Color(0.0, 0.85, 1.0, 0.0),
		Color(0.0, 0.85, 1.0, 0.15),
		Color(0.5, 0.0, 0.8, 0.15),
		Color(0.5, 0.0, 0.8, 0.0)
	])
	p_grad.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	dust.color_ramp = p_grad
	
	add_child(dust)
	move_child(dust, 2)
	
	# 4. Main HBox Layout (Left Menu / Right Spacestation)
	var main_hbox = HBoxContainer.new()
	main_hbox.anchors_preset = 15
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_hbox)
	
	# 4a. Left Panel (Menu Column Container)
	var left_margin = MarginContainer.new()
	left_margin.custom_minimum_size = Vector2(550, 0)
	left_margin.add_theme_constant_override("margin_left", 80)
	left_margin.add_theme_constant_override("margin_top", 120)
	left_margin.add_theme_constant_override("margin_bottom", 120)
	main_hbox.add_child(left_margin)
	
	var menu_vbox = VBoxContainer.new()
	menu_vbox.add_theme_constant_override("separation", 12)
	menu_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	left_margin.add_child(menu_vbox)
	
	# Title Block Container (for animations and glow)
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 6)
	menu_vbox.add_child(header_container)
	
	# HBox to split title words "LAST" and "STRANDED"
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 16)
	header_container.add_child(title_hbox)
	
	var font_title = SystemFont.new()
	font_title.font_names = PackedStringArray(["Inter", "Segoe UI", "Helvetica Neue", "Arial", "sans-serif"])
	font_title.font_weight = 800 # Extra bold/Black
	
	# "LAST" label
	var last_label = Label.new()
	last_label.text = "LAST"
	last_label.add_theme_font_size_override("font_size", 60)
	last_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0)) # Crisp white
	last_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.85, 1.0, 0.3)) # Neon cyan shadow
	last_label.add_theme_constant_override("shadow_offset_x", 0)
	last_label.add_theme_constant_override("shadow_offset_y", 0)
	last_label.add_theme_constant_override("shadow_outline_size", 16)
	last_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.9))
	last_label.add_theme_constant_override("outline_size", 8)
	last_label.add_theme_font_override("font", font_title)
	title_hbox.add_child(last_label)
	
	# "LIGHT" label
	var light_label = Label.new()
	light_label.text = "LIGHT"
	light_label.add_theme_font_size_override("font_size", 60)
	light_label.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 1.0)) # Neon cyan
	light_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.85, 1.0, 0.5)) # Neon cyan shadow
	light_label.add_theme_constant_override("shadow_offset_x", 0)
	light_label.add_theme_constant_override("shadow_offset_y", 0)
	light_label.add_theme_constant_override("shadow_outline_size", 20)
	light_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.9))
	light_label.add_theme_constant_override("outline_size", 8)
	light_label.add_theme_font_override("font", font_title)
	title_hbox.add_child(light_label)
	
	# Subtitle
	var subtitle_label = Label.new()
	subtitle_label.text = "S U R V I V E   T H E   V O I D"
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.9)) # Silver-blue
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 1)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 1)
	header_container.add_child(subtitle_label)
	
	# Modern Glowing Divider
	var div_grad = Gradient.new()
	div_grad.colors = PackedColorArray([
		Color(0.0, 0.85, 1.0, 0.0),
		Color(0.0, 0.85, 1.0, 0.8),
		Color(0.0, 0.85, 1.0, 0.0)
	])
	div_grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	
	var div_tex = GradientTexture2D.new()
	div_tex.gradient = div_grad
	div_tex.fill = GradientTexture2D.FILL_LINEAR
	div_tex.fill_from = Vector2(0.0, 0.5)
	div_tex.fill_to = Vector2(1.0, 0.5)
	
	var divider = TextureRect.new()
	divider.texture = div_tex
	divider.custom_minimum_size = Vector2(400, 3)
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	header_container.add_child(divider)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 32)
	menu_vbox.add_child(spacer)
	
	# Container-safe entrance fade & scale
	header_container.pivot_offset = Vector2(0, 50)
	header_container.scale = Vector2(0.9, 0.9)
	header_container.modulate.a = 0.0
	
	var title_tween = create_tween().set_parallel(true)
	title_tween.tween_property(header_container, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.tween_property(header_container, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Button Container
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.add_theme_constant_override("separation", 16)
	menu_vbox.add_child(buttons_vbox)
	
	# START button
	btn_start = MenuButtonContainer.new("START MISSION")
	btn_start.label.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/world/TestStage.tscn"))
	buttons_vbox.add_child(btn_start)
	
	# SETTINGS button
	btn_settings = MenuButtonContainer.new("SETTINGS")
	btn_settings.label.pressed.connect(func(): open_modal(settings_modal))
	buttons_vbox.add_child(btn_settings)
	
	# CREDITS button
	btn_credits = MenuButtonContainer.new("CREDITS")
	btn_credits.label.pressed.connect(func(): open_modal(credits_modal))
	buttons_vbox.add_child(btn_credits)
	
	# EXIT button
	btn_exit = MenuButtonContainer.new("EXIT TO DESKTOP")
	btn_exit.label.pressed.connect(func(): get_tree().quit())
	buttons_vbox.add_child(btn_exit)
	
	# 4b. Right Panel (Space Station Drifting)
	var right_center = CenterContainer.new()
	right_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_center)
	
	var station_anchor = Control.new()
	station_anchor.custom_minimum_size = Vector2(380, 380)
	right_center.add_child(station_anchor)
	
	station_rect = TextureRect.new()
	station_rect.texture = preload("res://assets/spacestation/spacestation.png")
	station_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	station_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	station_rect.custom_minimum_size = Vector2(380, 380)
	station_rect.pivot_offset = Vector2(190, 190)
	station_anchor.add_child(station_rect)
	
	# 5. Modals Overlay
	modals_center = CenterContainer.new()
	modals_center.anchors_preset = 15
	modals_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modals_center.visible = false
	add_child(modals_center)
	
	# Build Settings Modal
	build_settings_modal()
	# Build Credits Modal
	build_credits_modal()
	
	setup_controller_inputs()
	
	# Seamless input transition setup
	var input_mgr = get_node_or_null("/root/InputManager")
	if input_mgr:
		input_mgr.input_device_changed.connect(_on_input_device_changed)
		_on_input_device_changed(input_mgr.is_gamepad)
	else:
		if is_instance_valid(btn_start) and is_instance_valid(btn_start.label):
			btn_start.label.grab_focus()

func build_settings_modal():
	settings_modal = PanelContainer.new()
	settings_modal.custom_minimum_size = Vector2(400, 300)
	settings_modal.visible = false
	modals_center.add_child(settings_modal)
	
	var modal_style = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	modal_style.border_width_left = 1
	modal_style.border_width_right = 1
	modal_style.border_width_top = 1
	modal_style.border_width_bottom = 1
	modal_style.border_color = Color(0.0, 0.85, 1.0, 0.3)
	modal_style.corner_radius_top_left = 12
	modal_style.corner_radius_top_right = 12
	modal_style.corner_radius_bottom_left = 12
	modal_style.corner_radius_bottom_right = 12
	modal_style.shadow_color = Color(0.0, 0.85, 1.0, 0.15)
	modal_style.shadow_size = 20
	modal_style.content_margin_left = 24
	modal_style.content_margin_right = 24
	modal_style.content_margin_top = 24
	modal_style.content_margin_bottom = 24
	settings_modal.add_theme_stylebox_override("panel", modal_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	settings_modal.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_title = SystemFont.new()
	font_title.font_names = PackedStringArray(["Inter", "Segoe UI", "Helvetica Neue", "Arial", "sans-serif"])
	font_title.font_weight = 700
	title.add_theme_font_override("font", font_title)
	vbox.add_child(title)
	
	# Master Volume Slider
	var vol_hbox = HBoxContainer.new()
	vbox.add_child(vol_hbox)
	
	var vol_label = Label.new()
	vol_label.text = "Master Volume"
	vol_label.custom_minimum_size = Vector2(120, 0)
	vol_label.add_theme_font_size_override("font_size", 14)
	vol_hbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	var master_bus = AudioServer.get_bus_index("Master")
	vol_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	vol_slider.value_changed.connect(func(val):
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(val))
	)
	vol_hbox.add_child(vol_slider)
	
	# Fullscreen Toggle
	var fs_hbox = HBoxContainer.new()
	vbox.add_child(fs_hbox)
	
	var fs_label = Label.new()
	fs_label.text = "Fullscreen Mode"
	fs_label.custom_minimum_size = Vector2(120, 0)
	fs_label.add_theme_font_size_override("font_size", 14)
	fs_hbox.add_child(fs_label)
	
	var fs_check = CheckButton.new()
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	fs_hbox.add_child(fs_check)
	
	# Close Button
	var btn_close = Button.new()
	btn_close.text = "CLOSE"
	btn_close.custom_minimum_size = Vector2(0, 35)
	btn_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.08, 0.1, 0.16, 1.0)
	close_style.border_width_left = 1
	close_style.border_width_right = 1
	close_style.border_width_top = 1
	close_style.border_width_bottom = 1
	close_style.border_color = Color(0.0, 0.85, 1.0, 0.3)
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	
	var close_style_hover = close_style.duplicate()
	close_style_hover.bg_color = Color(0.12, 0.16, 0.25, 1.0)
	close_style_hover.border_color = Color(0.0, 0.85, 1.0, 0.8)
	
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_stylebox_override("hover", close_style_hover)
	btn_close.add_theme_stylebox_override("pressed", close_style)
	btn_close.add_theme_stylebox_override("focus", close_style_hover)
	
	btn_close.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.9))
	btn_close.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn_close.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn_close.add_theme_font_size_override("font_size", 14)
	
	btn_close.pressed.connect(func(): close_modal(settings_modal))
	settings_close_btn = btn_close
	vbox.add_child(btn_close)

func build_credits_modal():
	credits_modal = PanelContainer.new()
	credits_modal.custom_minimum_size = Vector2(400, 320)
	credits_modal.visible = false
	modals_center.add_child(credits_modal)
	
	var modal_style = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	modal_style.border_width_left = 1
	modal_style.border_width_right = 1
	modal_style.border_width_top = 1
	modal_style.border_width_bottom = 1
	modal_style.border_color = Color(0.0, 0.85, 1.0, 0.3)
	modal_style.corner_radius_top_left = 12
	modal_style.corner_radius_top_right = 12
	modal_style.corner_radius_bottom_left = 12
	modal_style.corner_radius_bottom_right = 12
	modal_style.shadow_color = Color(0.0, 0.85, 1.0, 0.15)
	modal_style.shadow_size = 20
	modal_style.content_margin_left = 24
	modal_style.content_margin_right = 24
	modal_style.content_margin_top = 24
	modal_style.content_margin_bottom = 24
	credits_modal.add_theme_stylebox_override("panel", modal_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	credits_modal.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "CREDITS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_title = SystemFont.new()
	font_title.font_names = PackedStringArray(["Inter", "Segoe UI", "Helvetica Neue", "Arial", "sans-serif"])
	font_title.font_weight = 700
	title.add_theme_font_override("font", font_title)
	vbox.add_child(title)
	
	# Credits Text
	var text = Label.new()
	text.text = "LAST LIGHT\n\nA 2D Space Survival & Physics Game\n\nDeveloped as a Game Design project.\nPowered by Godot Engine 4.x\nFeaturing GDExtension RopeSim physics."
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.85))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(text)
	
	# Close Button
	var btn_close = Button.new()
	btn_close.text = "CLOSE"
	btn_close.custom_minimum_size = Vector2(0, 35)
	btn_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.08, 0.1, 0.16, 1.0)
	close_style.border_width_left = 1
	close_style.border_width_right = 1
	close_style.border_width_top = 1
	close_style.border_width_bottom = 1
	close_style.border_color = Color(0.0, 0.85, 1.0, 0.3)
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	
	var close_style_hover = close_style.duplicate()
	close_style_hover.bg_color = Color(0.12, 0.16, 0.25, 1.0)
	close_style_hover.border_color = Color(0.0, 0.85, 1.0, 0.8)
	
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_stylebox_override("hover", close_style_hover)
	btn_close.add_theme_stylebox_override("pressed", close_style)
	btn_close.add_theme_stylebox_override("focus", close_style_hover)
	
	btn_close.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.9))
	btn_close.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn_close.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn_close.add_theme_font_size_override("font_size", 14)
	
	btn_close.pressed.connect(func(): close_modal(credits_modal))
	credits_close_btn = btn_close
	vbox.add_child(btn_close)

func open_modal(modal: PanelContainer):
	set_menu_buttons_focus_enabled(false)
	modals_center.visible = true
	modal.visible = true
	
	# Reset scale & opacity
	modal.pivot_offset = modal.custom_minimum_size / 2.0
	modal.scale = Vector2(0.8, 0.8)
	modal.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(modal, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Grab focus of close button inside the modal for controller support
	if modal == settings_modal and is_instance_valid(settings_close_btn):
		settings_close_btn.grab_focus()
	elif modal == credits_modal and is_instance_valid(credits_close_btn):
		credits_close_btn.grab_focus()

func close_modal(modal: PanelContainer):
	modal.pivot_offset = modal.custom_minimum_size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(modal, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(modal, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	modal.visible = false
	# If no modals are open, hide center overlay
	if not settings_modal.visible and not credits_modal.visible:
		modals_center.visible = false
	
	set_menu_buttons_focus_enabled(true)
		
	# Restore focus to respective button on main menu
	if modal == settings_modal and is_instance_valid(btn_settings):
		btn_settings.label.grab_focus()
	elif modal == credits_modal and is_instance_valid(btn_credits):
		btn_credits.label.grab_focus()

func set_menu_buttons_focus_enabled(enabled: bool):
	var mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if is_instance_valid(btn_start) and is_instance_valid(btn_start.label):
		btn_start.label.focus_mode = mode
	if is_instance_valid(btn_settings) and is_instance_valid(btn_settings.label):
		btn_settings.label.focus_mode = mode
	if is_instance_valid(btn_credits) and is_instance_valid(btn_credits.label):
		btn_credits.label.focus_mode = mode
	if is_instance_valid(btn_exit) and is_instance_valid(btn_exit.label):
		btn_exit.label.focus_mode = mode

# Process animations for Space Station
func _process(delta: float) -> void:
	time_elapsed += delta
	
	if is_instance_valid(station_rect):
		station_rect.position = Vector2(0, sin(time_elapsed * 0.8) * 16.0)
		station_rect.rotation = sin(time_elapsed * 0.4) * 0.05

func _on_timer_timeout() -> void:
	pass

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

	# Ensure JOY_BUTTON_A is bound to ui_accept programmatically
	if not InputMap.has_action("ui_accept"):
		InputMap.add_action("ui_accept")
	var ui_accept_events = InputMap.action_get_events("ui_accept")
	var ui_accept_has_joy_a = false
	for ev in ui_accept_events:
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_A:
			ui_accept_has_joy_a = true
			break
	if not ui_accept_has_joy_a:
		var ev_joy_a = InputEventJoypadButton.new()
		ev_joy_a.button_index = JOY_BUTTON_A
		InputMap.action_add_event("ui_accept", ev_joy_a)

func _input(event: InputEvent) -> void:
	var is_joy_event = false
	if event is InputEventJoypadButton:
		is_joy_event = true
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.4:
		is_joy_event = true

	if is_joy_event:
		var input_mgr = get_node_or_null("/root/InputManager")
		if input_mgr:
			input_mgr.is_gamepad = true
		
		# If focus is lost or not in the menu hierarchy, restore it immediately
		var focused = get_viewport().gui_get_focus_owner()
		if focused == null or not is_ancestor_of(focused):
			if settings_modal and settings_modal.visible:
				if is_instance_valid(settings_close_btn):
					settings_close_btn.grab_focus()
			elif credits_modal and credits_modal.visible:
				if is_instance_valid(credits_close_btn):
					credits_close_btn.grab_focus()
			else:
				if is_instance_valid(btn_start) and is_instance_valid(btn_start.label):
					btn_start.label.grab_focus()

	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is Button:
				var vp = get_viewport()
				if vp:
					vp.set_input_as_handled()
				focused.pressed.emit()
		elif event.button_index == JOY_BUTTON_B:
			var vp = get_viewport()
			if vp:
				vp.set_input_as_handled()
			if settings_modal and settings_modal.visible:
				close_modal(settings_modal)
			elif credits_modal and credits_modal.visible:
				close_modal(credits_modal)

func _on_input_device_changed(is_gamepad_mode: bool):
	if is_gamepad_mode:
		# Dynamic focus grab
		if settings_modal and settings_modal.visible:
			if is_instance_valid(settings_close_btn):
				settings_close_btn.grab_focus()
		elif credits_modal and credits_modal.visible:
			if is_instance_valid(credits_close_btn):
				credits_close_btn.grab_focus()
		else:
			var focused = get_viewport().gui_get_focus_owner()
			if focused == null or not is_ancestor_of(focused):
				if is_instance_valid(btn_start) and is_instance_valid(btn_start.label):
					btn_start.label.grab_focus()
	else:
		# Mouse/Keyboard mode: release focus from any currently focused button to prevent stuck highlights
		var focused = get_viewport().gui_get_focus_owner()
		if focused and is_ancestor_of(focused):
			focused.release_focus()
