extends Node2D
class_name World

const UNITS_PER_KM = 1000.0
const WORLD_RADIUS = 6 * UNITS_PER_KM

@export var player: Node2D
@export var zone_loot_tables: Array[LootTable]
@export var zone_chest_tables: Array[LootTable]
@export var zone_enemy_tables: Array[LootTable]

var debug_timer := 0.0
var zone_spawn_data := {}

func get_zone(distance: float) -> int:
	if distance >= WORLD_RADIUS:
		return -1
	
	var zone = int(distance / UNITS_PER_KM)
	return clamp(zone, 0, 5)

func is_out_of_bounds(pos: Vector2) -> bool:
	return pos.length() > WORLD_RADIUS

func get_distance_km(pos: Vector2) -> float:
	return pos.length() / UNITS_PER_KM

# Procedural generation nonsense (wtf is this help me)
# IF anyone touches ts without knowing what it does im sliming u out
func random_point_in_zone(zone: int) -> Vector2:
	var inner = zone * UNITS_PER_KM
	var outer = (zone + 1) * UNITS_PER_KM
	
	var angle = randf() * TAU
	var radius = sqrt(randf()) * (outer - inner) + inner
	
	return Vector2(cos(angle), sin(angle)) * radius

func spawn_and_track(obj, zone: int, category: String):
	# Assign zone if supported
	if obj.has_method("set_spawned_zone"):
		obj.set_spawned_zone(zone)
	elif "spawned_zone" in obj:
		obj.spawned_zone = zone
	
	add_child(obj)
	
	# Ensure category exists
	if not zone_spawn_data[zone].has(category):
		zone_spawn_data[zone][category] = {}
	
	# Get type name safely
	var type_name = "UNKNOWN"
	
	if obj.has_method("get_type_name"):
		type_name = obj.get_type_name()
	else:
		type_name = obj.name  # fallback
	
	# Track
	if not zone_spawn_data[zone][category].has(type_name):
		zone_spawn_data[zone][category][type_name] = 0
	
	zone_spawn_data[zone][category][type_name] += 1

func spawn_from_table(table: LootTable, pos: Vector2, zone: int, category: String):
	if table == null or table.items.is_empty():
		return
	
	var scene = table.items[randi() % table.items.size()]
	
	var obj = scene.instantiate()
	obj.position = pos
	
	spawn_and_track(obj, zone, category)
	
func generate_resources():
	zone_spawn_data.clear()

	for zone in range(zone_loot_tables.size()):
		zone_spawn_data[zone] = {
			"resource": {},
			"chest": {},
			"enemy": {}
		}
		
		var table = zone_loot_tables[zone]
		
		# Anti-softlock
		for item_scene in table.guaranteed_items:
			for i in table.guaranteed_count:
				var pos = random_point_in_zone(zone)
				
				var obj = item_scene.instantiate()
				obj.position = pos
				
				spawn_and_track(obj, zone, "resource")
		
		# Rest of resource spawn
		var spawn_count = randi_range(table.min_spawns, table.max_spawns)
		
		for i in spawn_count:
			var pos = random_point_in_zone(zone)
			spawn_from_table(table, pos, zone, "resource")

func generate_chests():
	for zone in zone_chest_tables.size():
		var table = zone_chest_tables[zone]
		
		if table == null:
			continue
		
		var spawn_count = randi_range(table.min_spawns, table.max_spawns)
		
		for i in spawn_count:
			var pos = random_point_in_zone(zone)
			spawn_from_table(table, pos, zone, "chest")

func generate_enemies():
	for zone in zone_enemy_tables.size():
		var table = zone_enemy_tables[zone]
		
		if table == null:
			continue
		
		var spawn_count = randi_range(table.min_spawns, table.max_spawns)
		
		for i in spawn_count:
			var pos = random_point_in_zone(zone)
			spawn_from_table(table, pos, zone, "enemy")

# Debug helper, remove when we arent fried
func print_spawn_summary():
	print("\nSPAWN SUMMARY")
	for zone in zone_spawn_data.keys():
		print("\nZone", zone)
		for category in zone_spawn_data[zone].keys():
			var data = zone_spawn_data[zone][category]
			if data.is_empty():
				continue
			print(" ", category, ":")
			for type in data.keys():
				print("    ", type, ":", data[type])

func _process(delta):
	if player == null:
		return
	
	# Debug final boss
	debug_timer += delta
	
	if debug_timer >= 1.0:
		debug_timer = 0.0
		
		var distance = player.position.length()
		var dist_km = get_distance_km(player.position)
		var zone = get_zone(distance)
		
		print("Distance (km):", snapped(dist_km, 0.01))
		print("Zone:", zone)
		
		if is_out_of_bounds(player.position):
			print("OUT OF BOUNDS - DEAD ZONE")

func _ready():
	generate_resources()
	print_spawn_summary()
	# generate_chests()
	# generate_enemies()
