class_name Home
extends Node3D


signal player_entered_dungeon_gate(player: Player)


@onready var dungeon_gate: Gate = $Gate
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	dungeon_gate.player_entered_gate.connect(func(player: Player):
		player_entered_dungeon_gate.emit(player)
	)
	world_environment.queue_free()
