class_name SkillCharge

static var MAX_CHARGE_TIME: float = 5
static var DAMAGE_MULTIPLIER: float = 2.0
static var SPEED_MULTIPLIER: float = 1.5
static var SIZE_MULTIPLIER: float = 2.0

static func get_damage_multiplier(charge: float) -> float:
	return lerp(1.0, SkillCharge.DAMAGE_MULTIPLIER, charge)

static func get_speed_multiplier(charge: float) -> float:
	return lerp(1.0, SkillCharge.SPEED_MULTIPLIER, charge)

static func get_size_multiplier(charge: float) -> float:
	return lerp(1.0, SkillCharge.SIZE_MULTIPLIER, charge)
