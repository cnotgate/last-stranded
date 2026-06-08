extends Node

signal input_device_changed(is_gamepad: bool)

var is_gamepad: bool = false:
	set(val):
		if is_gamepad != val:
			is_gamepad = val
			input_device_changed.emit(is_gamepad)
			_update_mouse_mode()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start with visible mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent):
	if is_gamepad:
		# Detect Keyboard/Mouse input
		if event is InputEventKey or event is InputEventMouseButton:
			is_gamepad = false
		elif event is InputEventMouseMotion:
			# Only trigger if the mouse actually moved significantly (preventing drift noise)
			if event.velocity.length() > 5.0:
				is_gamepad = false
	else:
		# Detect Controller/Gamepad input
		if event is InputEventJoypadButton:
			is_gamepad = true
		elif event is InputEventJoypadMotion:
			# Detect analog movement beyond a deadzone threshold
			if abs(event.axis_value) > 0.4:
				is_gamepad = true

func _update_mouse_mode():
	if is_gamepad:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
