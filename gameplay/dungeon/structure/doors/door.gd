class_name Door
extends Node3D

enum DoorState {BLOCKED, CLOSED, OPEN}

var height = 2.0
var closed_height = 0.3

var state: DoorState = DoorState.CLOSED

var bars: Node3D
var bars_collider: StaticBody3D
var bars_collider_shape: CollisionShape3D
var wall: Node3D
var wall_collider: StaticBody3D
var wall_collider_shape: CollisionShape3D

func initialize() -> void:
	bars = $Bars
	bars_collider = $Bars/Collider
	bars_collider_shape = $Bars/Collider/CollisionShape3D
	wall = $Wall
	wall_collider = $Wall/Collider
	wall_collider_shape = $Wall/Collider/CollisionShape3D


func set_state(val: DoorState):
	state = val
	
	var blocked = state == DoorState.BLOCKED
	wall.visible = blocked
	wall_collider_shape.disabled = not blocked
	bars.visible = not blocked
	bars_collider_shape.disabled = blocked
	
	if state != DoorState.BLOCKED:
		if state == DoorState.OPEN:
			bars.position.y = height - closed_height
			bars.scale.y = closed_height/height
		else:
			bars.position.y = 0.0
			bars.scale.y = 1.0
