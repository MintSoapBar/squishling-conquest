class_name EnemyRoom
extends Room

static var trigger_area_margin: float = 1.0

var mobs: Dictionary[String, Mob] = {}


func initialize() -> void:
	super()


func trigger() -> void:
	visited = true
	set_doors_open(false)
	
	#for i in range(max(1, get_interior_floor_area() / 100)):
	for i in 1:
		var data = BiomeEnemies.pick_enemy_data(biome, world, level)
		data.position = get_random_floor_position()
		var mob = Entity.create_entity(data)
		mobs[str(mob)] = mob
		mob.died.connect(func():
			mobs.erase(str(mob))
			if mobs.size() <= 0:
				set_doors_open(true)
		)


func connect_area_body_entered():
	interior_area.body_entered.connect(on_interior_area_body_entered)


func on_interior_area_body_entered(body: Node3D):
	if body is Player:
		if not visited:
			trigger()
		player_entered_interior_area.emit(body)
