extends RefCounted
class_name BatteryGenerator
# Reminder to switch from background to fixed node2d when loot tables are set

func generate_from_tier(tier_data: BatteryTierData) -> Battery:
	var b = Battery.new()
	
	b.tier = tier_data.tier
	b.max_energy = tier_data.max_energy
	
	# Stats
	b.boost_multiplier = round(randf_range(tier_data.min_boost, tier_data.max_boost) * 100) / 100.0
	b.drain_rate = round(randf_range(tier_data.min_drain, tier_data.max_drain) * 100) / 100.0
	b.current_energy = randf_range(0.3 * b.max_energy, b.max_energy)
	
	b.tier_data = tier_data
	
	return b
