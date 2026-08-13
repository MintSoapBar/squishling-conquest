class_name Dungeon
extends Node3D

signal loaded

const CORRIDOR = preload("uid://drm1iw4x7b3gp")
const START_ROOM = preload("uid://bk7tfm8cm78ju")
const BOX_ROOM = preload("uid://cm1xc38vhcbjo")

var structures: Array[Structure] = []
var rooms: Array[Room] = []


func generate(dungeon_seed: int = 0, room_count: int = 12) -> void:
	if dungeon_seed == 0:
		seed(Time.get_ticks_msec())
	else:
		seed(dungeon_seed)
	
	var entities_to_destroy: Array[Entity] = []
	for entity_id in Entity.current_entities:
		var entity = Entity.current_entities[entity_id]
		if entity is Player:
			entity.global_position = Vector3(0, 0, 0)
		else:
			entities_to_destroy.append(entity)
	for entity in entities_to_destroy:
		entity.destroy()
	
	for child in get_children():
		child.free()
	
	rooms.clear()
	structures.clear()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	##
	
	Entity.create_entity({entity_name = "dummy", position = Vector3(0, 0.5, 0)})
	
	var doors = []
	
	var start_room: StartRoom = START_ROOM.instantiate()
	start_room.initialize()
	start_room.set_doors_state(Door.DoorState.BLOCKED)
	start_room.visited = true
	rooms.append(start_room)
	structures.append(start_room)
	doors.append_array(start_room.attachment_points)
	add_child(start_room)
	
	var room_id = 1
	
	while room_id < room_count:
		room_id += 1
		
		if doors.size() == 0:
			print("No more doors left to attach to")
			break
			
		var space_state = get_world_3d().direct_space_state
		
		var attached_door_index = randi_range(0, doors.size() - 1)
		var attached_door: Door = doors[attached_door_index]
		
		# remove attached door from array
		if doors.back() == attached_door:
			doors.pop_back()
		else:
			doors[attached_door_index] = doors.pop_back()
		
		var new_corridor_length = randi_range(4, 10)
		var new_corridor: Corridor = CORRIDOR.instantiate()
		new_corridor.initialize()
		new_corridor.length = new_corridor_length
		new_corridor.update_corridor()
		
		var corridor_transform = Structure.snap_transform3D(get_attaching_transform(
			attached_door.global_transform, 
			new_corridor.attachment_points[0].transform
		), 0.5)
		new_corridor.transform = corridor_transform
		
		if new_corridor.is_colliding(space_state):
			new_corridor.free()
			room_id -= 1
			continue
		
		var new_room: BoxRoom = generate_box_room()
		var attaching_door: Door = new_room.attachment_points.pick_random()
		
		var new_transform = get_attaching_transform(
			corridor_transform * new_corridor.attachment_points[1].transform, 
			attaching_door.transform)
		new_room.transform = new_transform
		
		if new_room.is_colliding(space_state):
			new_corridor.free()
			new_room.free()
			room_id -= 1
			continue
		
		new_room.set_doors_state(Door.DoorState.BLOCKED)
		attached_door.set_state(Door.DoorState.OPEN)
		attaching_door.set_state(Door.DoorState.OPEN)
		
		rooms.append(new_room)
		structures.append(new_corridor)
		structures.append(new_room)
		
		var new_doors = new_room.attachment_points.duplicate()
		new_doors.erase(attaching_door)
		doors.append_array(new_doors)
		
		add_child(new_corridor)
		add_child(new_room)
	
	
	loaded.emit()


func generate_box_room() -> BoxRoom:
	var new_room_size = Vector3i(randi_range(3, 8) * 4, randi_range(6, 12), randi_range(3, 8) * 4)
	var new_door_positions: Array[int] = [
		randi_range(0, new_room_size.x - 4),
		randi_range(0, new_room_size.x - 4),
		randi_range(0, new_room_size.z - 4),
		randi_range(0, new_room_size.z - 4),
	]
	
	var new_room: BoxRoom = BOX_ROOM.instantiate()
	new_room.initialize()
	new_room.room_size = new_room_size
	new_room.door_positions = new_door_positions
	new_room.update_room()
	
	return new_room


## The "connection" is between the two front faces of the transforms
func get_attaching_transform(attached_transform: Transform3D, attaching_transform: Transform3D):
		var new_basis = (
			attaching_transform.basis.inverse() * attached_transform.basis
		).rotated(Vector3.UP, PI)
		var new_pos = attached_transform.origin - new_basis * attaching_transform.origin
		return Transform3D(new_basis, new_pos)
