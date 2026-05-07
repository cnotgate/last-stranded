extends AnimatedSprite2D


@export var pulse_speed: float = 5.0

var time_passed: float = 0.0
var speed: float = 0.0
var vspeed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speed = randf_range(50, 70)
	vspeed = randf_range(-30,30)
	play("star_rotate")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += speed * delta
	position.y += vspeed * delta
	
	time_passed += delta
	var alpha = (sin(time_passed * pulse_speed) + 1.0) / 2.0
	modulate.a = lerp(0.3, 1.0, alpha)
	
	if position.x > 1250:
		queue_free()
