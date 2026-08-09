class_name StatusEffectBalancing

static var damage_attribute_effects: Dictionary[String, Array] = {
	fire = ["burning"],
	poison = ["poisoned"],
}

static var status_effect_attributes: Dictionary[String, Dictionary] = {
	burning = {
		fire = true,
	},
	poisoned = {
		poison = true,
	}
}

static var status_effect_stats: Dictionary[String, StatusEffectStatBlock] = {
	burning = StatusEffectStatBlock.new({
		health_change = -0.5/5,
		duration = 5,
	}),
	poisoned = StatusEffectStatBlock.new({
		health_change = -1.0/20,
		duration = 20,
	}),
}

class StatusEffectStatBlock:
	var health_change: float
	var duration: float
	
	func _init(vals: Dictionary) -> void:
		for key in vals:
			self.set(key, vals.get(key))
