class_name MagicStats

static var stats: Dictionary[String, AttackStatBlock] = {
	air = AttackStatBlock.new({
		damage = 0.8,
		speed = 1.3,
		size = 1.2,
	}),
	
	earth = AttackStatBlock.new({
		damage = 1.15,
		speed = 0.7,
		size = 1.1,
	}),
	
	fire = AttackStatBlock.new({
		damage = 0.8,
		speed = 1.0,
		size = 1.0,
	}),
	
	light = AttackStatBlock.new({
		damage = 0.8,
		speed = 1.8,
		size = 0.8,
	}),
	
	poison = AttackStatBlock.new({
		damage = 0.75,
		speed = 1.0,
		size = 1.1,
	}),
	
	shadow = AttackStatBlock.new({
		damage = 0.9,
		speed = 0.8,
		size = 1.4,
	}),
	
	water = AttackStatBlock.new({
		damage = 1.0,
		speed = 1.0,
		size = 1.1,
	}),
}
