extends Resource
class_name Battery

@export var max_energy: float = 100.0
@export var current_energy: float = 100.0

@export var boost_multiplier: float
@export var drain_rate: float

@export var tier: int

var tier_data

# UI implement here later
# Show tier
# Show boost_multiplier
# Show drain_rate
# Show current_energy
# DO NOT show max_energy
