class_name BiomeEnemies


static var enemies: Dictionary[String, Dictionary] = {
	"cellar": {
		1: {
			1: {
				{entity_name = "living_mushroom"}: 1,
			},
			2: {
				{entity_name = "rig"}: 1,
			},
			3: {
				{entity_name = "living_mushroom"}: 1,
			},
		}
	}
}

static func get_enemy_data_weights(biome: String, world: int, level: int) -> Dictionary:
	return enemies[biome][world][level]


static func pick_enemy_data_from_weights(enemy_data_weights: Dictionary) -> Dictionary:
	var total_weight: float = 0
	var enemy_data_keys: Array = enemy_data_weights.keys()
	
	for enemy_data in enemy_data_keys:
		var weight = enemy_data_weights[enemy_data]
		total_weight += weight
	
	var chosen_weight = randf() * total_weight
	
	for enemy_data: Dictionary in enemy_data_keys:
		var weight = enemy_data_weights[enemy_data]
		if chosen_weight <= weight:
			return enemy_data.duplicate()
		chosen_weight -= weight
	
	assert(false, "Unable to select enemy data " + str(enemy_data_weights) + " " + chosen_weight)
	return (enemy_data_keys.back() as Dictionary).duplicate()


static func pick_enemy_data(biome: String, world: int, level: int) -> Dictionary:
	return pick_enemy_data_from_weights(get_enemy_data_weights(biome, world, level))
