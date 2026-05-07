extends Resource
class_name LootTable

@export var items: Array[PackedScene]
@export var guaranteed_items: Array[PackedScene] = []
@export var guaranteed_count: int = 0

@export var min_spawns: int = 10
@export var max_spawns: int = 20
