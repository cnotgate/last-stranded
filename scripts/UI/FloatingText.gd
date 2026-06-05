extends Label
class_name FloatingText

var velocity: Vector2 = Vector2(0, -60) # Moves up in pixels per second
var lifetime: float = 1.5
var max_lifetime: float = 1.5

func _ready():
	# Configure text settings for premium look
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # Warning red/coral
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	add_theme_constant_override("outline_size", 5)
	
	# Make it center-anchored
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	
	z_index = 100

func _process(delta):
	position += velocity * delta
	lifetime -= delta
	
	# Fade out
	if lifetime <= max_lifetime * 0.5:
		modulate.a = lifetime / (max_lifetime * 0.5)
		
	if lifetime <= 0:
		queue_free()
