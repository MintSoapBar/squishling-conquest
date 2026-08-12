class_name Gate
extends Node3D

signal player_entered_gate(player: Player)

@onready var area: Area3D = $Area3D


func _ready() -> void:
	area.collision_layer = 0
	area.collision_mask = Collision.ENTITY_LAYER
	area.body_entered.connect(on_area_body_entered)


func on_area_body_entered(body: Node3D):
	if body is Player:
		player_entered_gate.emit(body)
