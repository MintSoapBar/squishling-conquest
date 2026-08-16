@abstract
class_name Room
extends Structure

const DOOR_WIDTH: int = 2

var visited: bool = false


func initialize() -> void:
	super()
	
	for door: Door in $Doors.get_children():
		door.initialize(self)
		attachment_points.append(door)


func set_doors_state(state: Door.DoorState):
	for door: Door in attachment_points:
		door.set_state(state)


func set_doors_open(open: bool):
	for door: Door in attachment_points:
		if door.state != Door.DoorState.BLOCKED:
			door.set_state(Door.DoorState.OPEN if open else Door.DoorState.CLOSED)
