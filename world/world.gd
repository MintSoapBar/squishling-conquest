extends Node3D

signal game_state_changed(new_game_state: GameState)

enum GameState {HOME, DUNGEON}

const HOME = preload("uid://d2ru382ltbalf")

@onready var network: Network = $Network
@onready var basic_rooms_ui: BasicRoomsUi = $BasicRoomsUi
@onready var entities_folder: EntitiesFolder = $EntitiesFolder
@onready var core_3d_interface: Node = $Core3DInterface
@onready var dungeon: Dungeon = $Dungeon
@onready var minimap: DungeonMinimap = $Minimap

var game_state: GameState = GameState.HOME

var home: Home


func _ready() -> void:
	Entity.initialize_registry()
	Entity.set_folder(entities_folder)
	Entity.set_network(network)
	Tool.initialize_registry()
	Skill.initialize_registry()
	Dungeon.set_network(network)
	core_3d_interface.initialize()
	minimap.set_dungeon(dungeon)
	
	home = HOME.instantiate()
	add_child(home)
	
	var spawn_point: Transform3D = home.get_spawn_point()
	Player.create_player(1, {
		position = spawn_point.origin,
		rotation = spawn_point.basis.get_euler(),
	})
	
	Entity.create_entity({entity_name = "dummy", position = Vector3(6, 0, 6)})
	
	
	home.player_entered_dungeon_gate.connect(func(_player: Player):
		if is_server():
			generate_dungeon_server()
	)
	dungeon.player_entered_exit_gate.connect(func(_player: Player):
		if is_server():
			dungeon.set_level.rpc(dungeon.level % 3 + 1)
			generate_dungeon_server()
	)
	
	
	entities_folder.local_player_changed.connect(on_local_player_changed)
	game_state_changed.connect(on_game_state_changed)
	
	var update_minimap_offset = func():
		if minimap.visible:
			basic_rooms_ui.offset_right = -208
		else:
			basic_rooms_ui.offset_right = -8
	minimap.visibility_changed.connect(update_minimap_offset)
	update_minimap_offset.call()
	
	
	# server
	network.server.room_opened.connect(func():
		pass
	)
	network.server.room_closing.connect(func():
		pass
	)
	
	network.server.peer_connected.connect(func(peer_id: int):
		for entity in Entity.current_entities.values():
			entities_folder.create_entity.rpc_id(peer_id, entity.data)
		
		var new_player_data = {}
		if Player.local_player:
			new_player_data.position = (
				Player.local_player.position 
				+ Vector3(randf()/5, 0, randf()/5)
			)
		Player.create_player(peer_id, new_player_data)
		
		if game_state == GameState.HOME:
			return_home.rpc_id(peer_id)
		elif game_state == GameState.DUNGEON:
			load_dungeon.rpc_id(peer_id, 
				dungeon.dungeon_seed, dungeon.room_count,
				dungeon.biome, dungeon.world, dungeon.level,
				dungeon.get_dungeon_progress()
			)
	)
	network.server.peer_disconnected.connect(func(peer_id: int):
		Player.destroy_player(peer_id)
	)
	
	
	# client
	network.client.room_joining.connect(func():
		Entity.clear_entities()
	)
	network.client.room_joined.connect(func():
		pass
	)
	network.client.room_left.connect(func():
		return_home()
	)
	network.client.room_closed.connect(func():
		return_home()
	)


func _process(_delta: float) -> void:
	if Player.local_player:
		var camera := get_viewport().get_camera_3d()
		minimap.update_player_location(camera.global_rotation, Player.local_player.position)


func is_server() -> bool:
	return not network or not network.is_multiplayer_connected() or multiplayer.get_unique_id() == 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_M and key_event.is_pressed():
			basic_rooms_ui.visible = not basic_rooms_ui.visible
		elif key_event.keycode == KEY_BACKSPACE and key_event.is_pressed():
			if Player.local_player:
				Player.local_player.request_damage(9999)
			get_viewport().set_input_as_handled()
	
	if not is_server():
		return
	
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (key_event.keycode >= KEY_KP_0 and key_event.keycode <= KEY_KP_9 
			and key_event.is_pressed()):
			
			var num: int = key_event.keycode - KEY_KP_0
			
			if num == 0:
				return_home.rpc()
				get_viewport().set_input_as_handled()
				return
			
			if key_event.ctrl_pressed:
				dungeon.set_world.rpc(num)
			else:
				dungeon.set_level.rpc(num)
			generate_dungeon_server()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_DELETE and key_event.is_pressed():
			Entity.clear_entities()


func generate_dungeon_server():
	dungeon.set_dungeon_seed.rpc(int(Time.get_unix_time_from_system() * 1000))
	generate_dungeon.rpc()


@rpc("authority", "call_local")
func generate_dungeon():
	set_game_state(GameState.DUNGEON)
	
	if is_instance_valid(home):
		home.queue_free()
	
	while dungeon.loading:
		await dungeon.loaded
	await dungeon.generate()
	
	if Player.local_player:
		Player.local_player.position = Vector3.ZERO


@rpc("authority", "call_local")
func load_dungeon(dungeon_seed, room_count, biome, world, level, progress):
	set_game_state(GameState.DUNGEON)
	
	if is_instance_valid(home):
		home.queue_free()
	
	while dungeon.loading:
		await dungeon.loaded
	
	await dungeon.generate(
		dungeon_seed, room_count,
		biome, world, level)
	dungeon.load_dungeon_progress(progress)


@rpc("authority", "call_local")
func return_home():
	set_game_state(GameState.HOME)
	
	dungeon.clear_dungeon()
	
	if is_instance_valid(home):
		return
	
	home = HOME.instantiate()
	add_child(home)


func set_game_state(new_state: GameState):
	game_state = new_state
	game_state_changed.emit(new_state)


func on_local_player_changed(player: Player):
	if is_instance_valid(player):
		player.can_unequip = game_state == GameState.HOME
		if not player.can_unequip:
			player.equip_tool(0)


func on_game_state_changed(_new_game_state: GameState):
	if is_instance_valid(Player.local_player):
		Player.local_player.can_unequip = game_state == GameState.HOME
		if not Player.local_player.can_unequip:
			Player.local_player.equip_tool(0)
