class_name Player
extends Entity

enum BlockState {NONE, BLOCK, PARRY}

const PLAYER_ENTITY_ID_PREFIX = "player_"

static var current_players: Dictionary[String, Player] = {}
static var local_player: Player

@export var walk_speed := 4.0
@export var sprint_speed := 8.0
@export var jump_velocity := 8.0
@export var coyote_time := 0.2

@export var rotate_on_move := true

var peer_id: int

var equipped_tool_stack_index: int = -1

var body_color: Color

var sprinting: bool = false
var sprint_toggle: bool = true

var last_direction: Vector3 = Vector3.FORWARD
var jumped: bool = false
var air_time: float = 0.0

var blocking: bool = false
var block_key_down: bool = false
var block_start_time: float = 0
var parry_window: float = 0.1

var can_unequip: bool = false

static func create_player(peer_id_: int = 1) -> Player:
	var data_ = {
		entity_name = "player",
		entity_id = PLAYER_ENTITY_ID_PREFIX + str(peer_id_),
		peer_id = peer_id_,
		max_health = 100,
		max_shield = 100,
		shield_enabled = true,
	}
	
	var new_player: Player = create_entity(data_)
	
	return new_player


static func destroy_player(_peer_id: int) -> void:
	var plr: Player = current_entities.get(PLAYER_ENTITY_ID_PREFIX + str(_peer_id))
	if plr:
		plr.destroy.rpc()


static func set_local_player(player: Player):
	local_player = player
	entities_folder.local_player_changed.emit(local_player)


static var orbital_camera
static func set_orbital_camera(camera):
	orbital_camera = camera
	
	camera.camera_third_person_offset = Vector3(0.8, 0.8, 0)
	
	entities_folder.local_player_changed.connect(func(plr: Player):
		camera.focused_node = plr
		
		if plr:
			await plr.ready
			
			plr.sprite.model.visible = not camera.first_person_active
			plr.rotate_on_move = not camera.camera_locked
			if plr.rotate_on_move:
				plr.last_direction = -plr.transform.basis.z
	)
	
	camera.camera_rotated.connect(func():
		if (camera.camera_locked and not camera.camera_temp_locked 
			and local_player and local_player.is_alive()):
			local_player.rotation = camera.rotation * Vector3.UP
	)
	
	camera.first_person_changed.connect(func(first_person_active: bool):
		if local_player:
			local_player.sprite.model.visible = not first_person_active
	)
	
	var lock_changed = func(_param):
		if local_player:
			local_player.rotate_on_move = not camera.camera_locked
			local_player.last_direction = -local_player.transform.basis.z
			if camera.camera_locked and not camera.camera_temp_locked and local_player.is_alive():
				local_player.rotation = camera.rotation * Vector3.UP
	
	camera.camera_lock_changed.connect(lock_changed)
	camera.camera_temp_lock_changed.connect(lock_changed)
	
	entities_folder.local_player_changed.connect(lock_changed)


func initialize(_data: Dictionary) -> void:
	sprite = entities_folder.player_sprite.instantiate() as Sprite
	add_child(sprite)
	
	peer_id = _data.get("peer_id")
	body_color = _data.get_or_add("body_color", Color(randf(), randf(), randf()))
	
	team = Team.PLAYER
	
	if not _data.get("position"):
		_data.position = Vector3(0, 0.35, 0)
	
	super(_data)
	
	set_multiplayer_authority(peer_id, false)
	var multiplayer_synchronizer: MultiplayerSynchronizer = get_node("MultiplayerSynchronizer")
	multiplayer_synchronizer.set_multiplayer_authority(peer_id, false)
	
	if not network or peer_id == entities_folder.multiplayer.get_unique_id():
		set_local_player(self)
	
	current_players[str(self)] = self
	
	died.connect(func():
		await tree_exited
		if not entities_folder.get_tree():
			return
		if network:
			if not network.is_multiplayer_connected():
				return
			if (entities_folder.multiplayer.get_unique_id() != peer_id
			and entities_folder.multiplayer.get_peers().find(peer_id) == -1):
				return
		create_player(peer_id))


func _ready() -> void:
	super()
	
	if sprite.set_body_color:
		sprite.set_body_color(body_color)
	inventory.add_stack(Stack.new("magic_staff", 1))
	equip_tool(0)


func event_is_action(event: InputEvent, action: String):
	return InputMap.has_action(action) and event.is_action(action)


func event_is_key(key_event: InputEventKey, key: Key):
	return not key_event.is_echo() and key_event.keycode == key


func event_is_mouse_button(button_event: InputEventMouseButton, button: MouseButton):
	return not button_event.is_echo() and button_event.button_index == button


func event_is_action_or_input(event: InputEvent, action: String, input: int):
	if InputMap.has_action(action):
		return event.is_action(action)
	
	if event is InputEventKey:
		return event_is_key(event, input)
	elif event is InputEventMouseButton:
		return event_is_mouse_button(event, input)
	return false


func is_action_or_key_pressed(action: String, key: Key):
	return InputMap.has_action(action) and Input.is_action_pressed(action) or Input.is_key_pressed(key)


func _unhandled_input(event: InputEvent):
	if event.is_echo():
		return
	if not is_alive():
		return
	if not can_move_network():
		return
	
	if event_is_action_or_input(event, "sprint", KEY_CTRL):
		if sprint_toggle and not OS.has_feature("mobile"):
			if event.is_pressed():
				sprinting = not sprinting
		else:
			sprinting = event.is_pressed()
		get_viewport().set_input_as_handled()
		return
	
	if event_is_action_or_input(event, "block", KEY_F):
		var pressed = event.is_pressed()
		block_key_down = pressed
		if pressed:
			if not blocking and (not equipped_tool or not equipped_tool.is_locked()):
				block.rpc()
		else:
			if blocking:
				unblock.rpc()
		get_viewport().set_input_as_handled()
		return
	
	for i in range(1, 10):
		if self == local_player and event.is_pressed() and not event.is_echo():
			if event_is_action_or_input(event, "hotbar" + str(i), KEY_1 + i - 1):
				var stack_index = i-1
				var stack = inventory.groups.hotbar.stacks[stack_index]
				
				if equipped_tool_stack_index == stack_index:
					equip_tool.rpc(-1)
				elif stack:
					equip_tool.rpc(stack_index)
				else:
					equip_tool.rpc(-1)
				
				get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not can_move_network():
		return
	
	var move_speed: float = sprint_speed if sprinting else walk_speed
	
	if is_on_floor():
		air_time = 0
		jumped = false
	else:
		air_time += delta
		velocity += get_gravity() * delta
	
	if (
		is_alive()
		and is_action_or_key_pressed("jump", KEY_SPACE) 
		and not jumped and air_time <= coyote_time
		):
		
		jumped = true
		velocity.y = jump_velocity
	
	var input_direction: Vector3 = get_input_direction()
	
	if is_alive():
		if input_direction.length() > 0:
			velocity.x = input_direction.x * move_speed
			velocity.z = input_direction.z * move_speed
			last_direction = input_direction
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	
		if rotate_on_move:
			transform.basis = transform.basis.orthonormalized().slerp(
				Basis.looking_at(last_direction * Vector3(1, 0, 1)).orthonormalized(), 0.2)
	
	move_and_slide()
	data.position = global_position


func on_tool_unlocked():
	if not is_multiplayer_authority():
		return
	if not is_alive():
		return
	
	if not blocking and block_key_down:
		block.rpc()


@rpc("any_peer", "call_local")
func destroy():
	super()
	current_players.erase(str(self))


@rpc("authority", "call_local")
func block():
	block_start_time = GameTime.get_ticks_sec()
	blocking = true
	sprite.set_shield_visible(true)


@rpc("authority", "call_local")
func unblock():
	blocking = false
	sprite.set_shield_visible(false)


@rpc("any_peer", "call_local")
func request_damage(amount: float, attributes: Dictionary[String, bool] = {}):
	if blocking:
		if GameTime.get_ticks_sec() - block_start_time <= parry_window:
			amount *= 0.1
		else:
			amount *= 0.5
	
	super(amount, attributes)


func kill():
	if blocking:
		unblock.rpc()
	
	super()


func equip_tool(stack_index: int) -> void:
	var stacks = inventory.groups.hotbar.stacks
	if stack_index < 0 or stack_index >= stacks.size():
		return
	if not stacks.get(stack_index):
		return
	
	equipped_tool_stack_index = stack_index
	super(stack_index)
	
	if equipped_tool:
		equipped_tool.unlocked.connect(on_tool_unlocked)


func get_input_direction() -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d()
	
	var local_direction: Vector3
	
	if (InputMap.has_action("move_forward") and InputMap.has_action("move_backward")
	and InputMap.has_action("move_left") and InputMap.has_action("move_right")):
		
		var input_vector := Input.get_vector(
			"move_left", "move_right", "move_forward", "move_backward"
		)
		local_direction = Vector3(input_vector.x, 0, input_vector.y)
	else:
		local_direction = Vector3.ZERO
		if Input.is_key_pressed(KEY_W): local_direction += Vector3.FORWARD
		if Input.is_key_pressed(KEY_S): local_direction += Vector3.BACK
		if Input.is_key_pressed(KEY_A): local_direction += Vector3.LEFT
		if Input.is_key_pressed(KEY_D): local_direction += Vector3.RIGHT
	
	var facing_basis = camera.global_basis if camera != null else Basis.IDENTITY
	var global_direction: Vector3
	
	if camera.global_basis.z.is_equal_approx(Vector3.UP):
		global_direction = facing_basis.rotated(facing_basis.x, PI/2) * local_direction
	else:
		global_direction = facing_basis * local_direction
	global_direction = (global_direction * Vector3(1, 0, 1)).normalized()
	
	return global_direction
