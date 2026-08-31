class_name SkillCharge

static var MAX_CHARGE_TIME: float = 5

static var stat_multipliers: Dictionary[String, float] = {
	damage = 2.0,
	speed = 1.5,
	size = 2.0,
}


static func get_stat_multiplier(stat: String, charge: float) -> float:
	var multiplier = stat_multipliers.get(stat)
	assert(multiplier, stat + " not found in charge stat_multipliers")
	return lerp(1.0, multiplier, charge)
