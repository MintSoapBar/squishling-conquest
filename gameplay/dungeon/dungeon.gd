class_name Dungeon
extends Node3D

signal loaded
signal player_entered_exit_gate(player: Player)

const CORRIDOR = preload("uid://drm1iw4x7b3gp")
const ENTRANCE_ROOM = preload("uid://bk7tfm8cm78ju")
const EXIT_ROOM = preload("uid://b866e31dkc26r")
const BOX_ROOM = preload("uid://cm1xc38vhcbjo")

var structures: Array[Structure] = []
var rooms: Array[Room] = []


func generate(dungeon_seed: int = 0, room_count: int = 12) -> void:
	assert(room_count > 0, "Room count must be above 0")
	
	if dungeon_seed == 0:
		seed(Time.get_ticks_msec())
	else:
		seed(dungeon_seed)
	
	var entities_to_destroy: Array[Entity] = []
	for entity_id in Entity.current_entities:
		var entity = Entity.current_entities[entity_id]
		if entity is Player:
			var player := entity as Player
			player.global_position = Vector3(0, 0, 0)
		else:
			entities_to_destroy.append(entity)
	for entity in entities_to_destroy:
		entity.destroy()
	
	for child in get_children():
		child.queue_free()
	
	rooms.clear()
	structures.clear()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	##
	
	Entity.create_entity({entity_name = "dummy", position = Vector3(6, 0, -6)})
	
	var doors: Array[Door] = []
	
	var entrance_room: EntranceRoom = ENTRANCE_ROOM.instantiate()
	entrance_room.initialize()
	entrance_room.set_doors_state(Door.DoorState.BLOCKED)
	entrance_room.visited = true
	rooms.append(entrance_room)
	structures.append(entrance_room)
	#doors.append_array(entrance_room.attachment_points)
	doors.append(entrance_room.attachment_points.pick_random())
	add_child(entrance_room)
	
	var room_id = 0
	
	while room_id < room_count:
		room_id += 1
		
		if doors.size() == 0:
			print("No more doors left to attach to")
			break
		
		@warning_ignore("integer_division")
		var attached_door_index = max(randi_range(0, doors.size()/3), 0)
		var attached_door: Door = doors[attached_door_index]
		
		# remove attached door from array
		doors.remove_at(attached_door_index)
		#if doors.back() == attached_door:
			#doors.pop_back()
		#else:
			#doors[attached_door_index] = doors.pop_back()
		
		var corridor_length = randi_range(4, 10)
		var new_corridor: Corridor = generate_corridor(corridor_length)
		var new_room: BoxRoom = generate_box_room()
		var attaching_door: Door = new_room.attachment_points.pick_random()
		
		var attach_success = attach_room(attached_door, new_corridor, attaching_door, new_room)
		if not attach_success:
			new_corridor.free()
			new_room.free()
			room_id -= 1
			continue
		
		var new_doors = new_room.attachment_points.duplicate()
		new_doors.erase(attaching_door)
		doors.append_array(new_doors)
		
		new_room.entrance_separation = attached_door.room.entrance_separation + 1
	
	
	var enemy_room_doors: Array[Door] = []
	var sort_doors_by_entrance_separation = func(a: Door, b: Door):
		return a.room.entrance_separation < b.room.entrance_separation
	for door in doors:
		if door.room is EnemyRoom:
			enemy_room_doors.append(door)
	enemy_room_doors.sort_custom(sort_doors_by_entrance_separation)
	
	var exit_corridor_length = randi_range(8, 10)
	var exit_corridor: Corridor = generate_corridor(exit_corridor_length)
	var exit_room: ExitRoom = EXIT_ROOM.instantiate()
	exit_room.initialize()
	var exit_room_attaching_door: Door = exit_room.attachment_points[0]
	
	var success := false
	while enemy_room_doors.size() > 0:
		var exit_room_attached_door = enemy_room_doors.pop_back()
		
		success = attach_room(exit_room_attached_door, exit_corridor, exit_room_attaching_door, exit_room)
		
		if success:
			break
	assert(success, "No more enemy room doors to place exit room")
	
	exit_room.player_entered_gate.connect(player_entered_exit_gate.emit)
	
	loaded.emit()


func attach_room(attached_door: Door, new_corridor: Corridor, attaching_door: Door, new_room: Room) -> bool:
	var corridor_transform = get_attaching_transform(
		attached_door.global_transform, 
		new_corridor.attachment_points[0].transform
	)
	corridor_transform = Structure.snap_transform3d(corridor_transform, 0.5, PI/2)
	new_corridor.transform = corridor_transform
	
	var space_state = get_world_3d().direct_space_state
	
	if new_corridor.is_colliding(space_state, corridor_transform):
		return false
	
	var room_transform = get_attaching_transform(
		corridor_transform * new_corridor.attachment_points[1].transform, 
		attaching_door.transform)
	room_transform = Structure.snap_transform3d(room_transform, 0.5, PI/2)
	new_room.transform = room_transform
	
	if new_room.is_colliding(space_state, room_transform):
		return false
	
	new_room.set_doors_state(Door.DoorState.BLOCKED)
	attached_door.set_state(Door.DoorState.OPEN)
	attaching_door.set_state(Door.DoorState.OPEN)
	
	rooms.append(new_room)
	structures.append(new_corridor)
	structures.append(new_room)
	
	add_child(new_corridor)
	add_child(new_room)
	
	return true


func generate_corridor(length: int) -> Corridor:
	var new_corridor: Corridor = CORRIDOR.instantiate()
	new_corridor.initialize()
	new_corridor.length = length
	new_corridor.update_corridor()
	
	return new_corridor


func generate_box_room() -> BoxRoom:
	var new_room_size = Vector3i(randi_range(3, 8) * 4, randi_range(6, 12), randi_range(3, 8) * 4)
	var new_door_positions: Array[int] = [
		randi_range(1, new_room_size.x - 5),
		randi_range(1, new_room_size.x - 5),
		randi_range(1, new_room_size.z - 5),
		randi_range(1, new_room_size.z - 5),
	]
	
	var new_room: BoxRoom = BOX_ROOM.instantiate()
	new_room.initialize()
	new_room.room_size = new_room_size
	new_room.door_positions = new_door_positions
	new_room.update_room()
	
	return new_room


## The "connection" is between the two front faces of the transforms
func get_attaching_transform(attached_transform: Transform3D, attaching_transform: Transform3D) -> Transform3D:
	var new_basis = (
		attaching_transform.basis.inverse() * attached_transform.basis
	).rotated(Vector3.UP, PI)
	var new_pos = attached_transform.origin - new_basis * attaching_transform.origin
	return Transform3D(new_basis, new_pos)
