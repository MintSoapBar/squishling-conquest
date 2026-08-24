class_name Home
extends Node3D

signal player_entered_dungeon_gate(player: Player)

@onready var dungeon_gate: Gate = $Gate
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var cat_bed: CatBed = $LivingRoom/CatBed


func _ready() -> void:
	dungeon_gate.player_entered.connect(func(player: Player):
		player_entered_dungeon_gate.emit(player)
	)
	world_environment.queue_free()


func get_spawn_point() -> Transform3D:
	return cat_bed.global_transform.translated(Vector3(0, 0.35, 0))
