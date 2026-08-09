extends Node3D

@onready var entities_folder: EntitiesFolder = $EntitiesFolder
@onready var core_interface := $CoreInterface
@onready var dungeon: Dungeon = $Dungeon
@onready var minimap: DungeonMinimap = $Minimap


func _ready() -> void:
	Entity.initialize_registry()
	Entity.set_folder(entities_folder)
	Tool.initialize_registry()
	Skill.initialize_registry()
	core_interface.initialize()
	
	dungeon.generate()
	minimap.load_dungeon_shapes(dungeon)
	
	Player.create_player()


func _process(_delta: float) -> void:
	if Player.local_player:
		var camera := get_viewport().get_camera_3d()
		minimap.update_player_location(camera.global_rotation, Player.local_player.position)
