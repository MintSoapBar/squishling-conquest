class_name Dungeon
extends Node3D

signal loading_start
signal loaded
signal player_entered_exit_gate(player: Player)

const CORRIDOR = preload("uid://drm1iw4x7b3gp")
const ENTRANCE_ROOM = preload("uid://bk7tfm8cm78ju")
const EXIT_ROOM = preload("uid://b866e31dkc26r")
const BOX_ROOM = preload("uid://cm1xc38vhcbjo")

static var network

var structures: Array[Structure] = []
var rooms: Array[Room] = []
var entities: Dictionary[String, Entity] = {}

var dungeon_seed: int = 0
var room_count: int = 12
var biome: String = "cellar"
var world: int = 1
var level: int = 1

var loading: bool = false


static func set_network(_network):
	network = _network

static func is_server() -> bool:
	return (not network 
		or not network.is_multiplayer_connected() or network.multiplayer.get_unique_id() == 1)


@rpc("authority", "call_local")
func generate(_dungeon_seed := dungeon_seed, _room_count := room_count, 
	_biome := biome, _world := world, _level := level) -> void:
	
	assert(room_count > 0, "Room count must be above 0")
	
	loading = true
	loading_start.emit()
	
	dungeon_seed = _dungeon_seed
	seed(dungeon_seed)
	room_count = _room_count
	biome = _biome
	world = _world
	level = _level
	
	await clear_dungeon()
	
	##
	
	var doors: Array[Door] = []
	
	var entrance_room: EntranceRoom = ENTRANCE_ROOM.instantiate()
	entrance_room.initialize()
	entrance_room.set_doors_state(Door.DoorState.BLOCKED)
	entrance_room.visited = true
	entrance_room.biome = biome
	entrance_room.world = world
	entrance_room.level = level
	rooms.append(entrance_room)
	structures.append(entrance_room)
	#doors.append_array(entrance_room.attachment_points)
	doors.append(entrance_room.attachment_points.pick_random())
	add_child(entrance_room)
	
	var room_id = 0
	
	while room_id < room_count:
		room_id += 1
		
		if doors.size() == 0:
			push_error("No more doors left to attach to")
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
	
	loading = false
	loaded.emit()


func clear_dungeon_entities():
	for entity_id in entities:
		entities[entity_id].destroy()


func clear_dungeon():
	for child in get_children():
		child.queue_free()
	
	rooms.clear()
	structures.clear()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func get_dungeon_progress() -> Dictionary:
	var progress := {}
	
	var structure_data = []
	progress.structure_data = structure_data
	for structure in structures:
		structure_data.append(structure.get_data())
	
	return progress


func load_dungeon_progress(progress: Dictionary):
	var structure_data = progress.get("structure_data", [])
	
	for structure_index in structure_data.size():
		structures[structure_index].load_data(structure_data[structure_index])


@rpc("authority", "call_local")
func set_dungeon_seed(new_seed: int):
	dungeon_seed = new_seed


@rpc("authority", "call_local")
func set_room_count(new_room_count: int):
	room_count = new_room_count


@rpc("authority", "call_local")
func set_biome(new_biome: String):
	biome = new_biome


@rpc("authority", "call_local")
func set_world(new_world: int):
	world = new_world


@rpc("authority", "call_local")
func set_level(new_level: int):
	level = new_level


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


func generate_corridor(length: int, _biome := biome, _world := world, _level := level) -> Corridor:
	var new_corridor: Corridor = CORRIDOR.instantiate()
	new_corridor.initialize()
	new_corridor.length = length
	new_corridor.biome = _biome
	new_corridor.world = _world
	new_corridor.level = _level
	new_corridor.update_corridor()
	
	return new_corridor


func generate_box_room(_biome := biome, _world := world, _level := level) -> BoxRoom:
	var new_room_size = Vector3i(randi_range(4, 8) * 4, randi_range(6, 12), randi_range(4, 8) * 4)
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
	new_room.biome = _biome
	new_room.world = _world
	new_room.level = _level
	new_room.update_room()
	
	return new_room


## The "connection" is between the two front faces of the transforms
func get_attaching_transform(attached_transform: Transform3D, attaching_transform: Transform3D) -> Transform3D:
	var new_basis = (
		attaching_transform.basis.inverse() * attached_transform.basis
	).rotated(Vector3.UP, PI)
	var new_pos = attached_transform.origin - new_basis * attaching_transform.origin
	return Transform3D(new_basis, new_pos)
