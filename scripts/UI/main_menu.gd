extends MarginContainer

@export var star_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	var star = star_scene.instantiate()
	
	var screen_height = get_viewport_rect().size.y
	star.position = Vector2(-50, randf_range(0, screen_height))
	
	add_child(star)


func _on_link_button_pressed() -> void:
	pass # Replace with function body.
