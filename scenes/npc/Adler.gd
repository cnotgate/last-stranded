extends Node2D

@export var follow_speed: float = 120.0
@export var follow_distance: float = 150.0

var player: Node2D = null

@onready var leg_r_target = $"PlayerSkeleton/IK Targets/LegR Target"
@onready var leg_l_target = $"PlayerSkeleton/IK Targets/LegL Target"
@onready var arm_r_target = $"PlayerSkeleton/IK Targets/ArmR Target"
@onready var arm_l_target = $"PlayerSkeleton/IK Targets/ArmL Target"
@onready var char_container = $"PlayerSkeleton"

var leg_r_base: Vector2
var leg_l_base: Vector2
var arm_r_base: Vector2
var arm_l_base: Vector2
var current_facing: float = 1.0

func _ready():
	leg_r_base = leg_r_target.position
	leg_l_base = leg_l_target.position
	arm_r_base = arm_r_target.position
	arm_l_base = arm_l_target.position

func _process(delta):
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p:
			player = p
		else:
			return
			
	var dist = global_position.distance_to(player.global_position)
	var velocity = Vector2.ZERO
	
	if dist > follow_distance:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * follow_speed
		
		# Move towards player
		global_position += velocity * delta
		
	# Procedural IK Animation
	var ik_offset_amount = 8.0
	var speed_ratio = 0.0
	if follow_speed > 0:
		speed_ratio = velocity.length() / follow_speed
	
	if abs(velocity.x) > 1.0:
		var new_facing = sign(velocity.x)
		if new_facing != current_facing:
			current_facing = new_facing
		char_container.scale.x = current_facing
		
	var offset = velocity.normalized() * (-ik_offset_amount * speed_ratio)
	var adjusted_offset = Vector2(offset.x * current_facing, offset.y)
	
	leg_r_target.position = leg_r_target.position.move_toward(leg_r_base + adjusted_offset, 0.5)
	leg_l_target.position = leg_l_target.position.move_toward(leg_l_base + adjusted_offset, 0.5)
	arm_r_target.position = arm_r_target.position.move_toward(arm_r_base + adjusted_offset, 0.5)
	arm_l_target.position = arm_l_target.position.move_toward(arm_l_base + adjusted_offset, 0.5)
