extends Node

@export var max_enemies: int = 5
@export var size_x: float = 50
@export var size_z: float = 50
@export var enemies_list: Array[String] = ["rig", "mushroom"]

var enemies: Dictionary[String, Entity] = {}

var spawning: bool = false


func _process(_delta: float) -> void:
	while enemies.size() < max_enemies:
		create_enemy()


func enable_spawning():
	spawning = true


func disable_spawning():
	spawning = false


func clear_enemies():
	for enemy: Entity in enemies.values():
		enemy.destroy.rpc()
	enemies.clear()


func create_enemy():
	var new_enemy_pos = Vector3(
		randf_range(-size_x/2, size_x/2), 
		10, 
		randf_range(-size_z/2, size_z/2)
	)
	var new_enemy = Entity.create_entity({
		entity_name = enemies_list.pick_random(),
		position = new_enemy_pos,
	})
	enemies[str(new_enemy)] = new_enemy
	
	Entity.entities_folder.create_entity.rpc(new_enemy.data)
	
	new_enemy.died.connect(func():
		enemies.erase(str(new_enemy))
		create_enemy()
	)
