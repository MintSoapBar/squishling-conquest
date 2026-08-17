class_name MobStats

static var stats: Dictionary[String, MobStatBlock] = {
	
	living_mushroom = MobStatBlock.new({
		max_health = 30,
		walk_speed = 0,
	}),
	
	rig = MobStatBlock.new({
		max_health = 50,
		walk_speed = 4,
	}),
	
	dummy = MobStatBlock.new({
		max_health = INF,
		walk_speed = 0,
	}),
	
}
