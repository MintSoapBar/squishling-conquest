@abstract
class_name Entity
extends CharacterBody3D

signal died

enum Team {
	NULL,
	NEUTRAL,
	PLAYER,
	MOB,
}

const CORPSE_LIFETIME: float = 3

static var entity_registry: Dictionary = {}
static var current_entities: Dictionary[String, Entity] = {}

static var entities_folder: EntitiesFolder
static var network
static var debug_printer = null

static var rng = RandomNumberGenerator.new()

var data: Dictionary

var entity_name: String
var entity_id: String
var status: Status

var team: Team = Team.NEUTRAL
var sprite: Sprite
var inventory: Inventory = Inventory.new({hotbar = 9})
var equipped_tool: Tool

var last_positions: Array[Array]
var estimated_velocity: Vector3
var velocity_estimate_frame_buffer: int = 2

static func server_authority_enabled():
	return network and network.server_authority


## [code]sender[/code] is set to multiplayer.get_remote_sender_id() if equal to -1
static func check_is_authority(sender: int = -1, authority_peer: int = -1) -> bool:
	if sender == -1:
		sender = entities_folder.multiplayer.get_remote_sender_id()
	
	if sender == 0:
		return true
	
	var peer: int = entities_folder.multiplayer.get_unique_id()
	
	if server_authority_enabled():
		if sender != 1:
			assert(false, 
				str(sender) + " tried to send request despite server authority to " + str(peer))
			return false
	else:
		if sender != 1 and sender != authority_peer:
			assert(false, 
				str(sender) + " tried to send request for the authority peer, " 
				+ str(authority_peer) + " to " + str(peer))
			return false
	return true


static func set_debug_printer(printer):
	debug_printer = printer


static func debug_prints(...vals: Array):
	if debug_printer:
		(debug_printer.prints_ as Callable).callv(vals)
	else:
		if network and network.is_multiplayer_connected():
			vals.push_front(str(entities_folder.multiplayer.get_unique_id()) + ":")
		prints.callv(vals)


static func set_folder(entities_folder_: EntitiesFolder):
	entities_folder = entities_folder_


static func set_network(network_):
	network = network_


static func initialize_registry():
	var entity_classes_path := (Entity as GDScript).resource_path.replace("entity.gd", "entity_classes")
	register_scenes(
		entity_registry, 
		entity_classes_path, 
		scene_inherits_entity
	)
	debug_prints("Registered entity scenes:", entity_registry.keys())

static func register_scenes(registry: Dictionary, path: String, callback := Callable(), 
	file_suffix := ".tscn"):
	
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Directory not found: " + path)
		return

	dir.list_dir_begin()
	var file := dir.get_next()

	while file != "":
		if file == "." or file == "..":
			file = dir.get_next()
			continue
		
		var full_path := path + "/" + file
		
		if dir.current_is_dir():
			register_scenes(registry, full_path, callback, file_suffix)
		elif file.contains(file_suffix) and not file.contains(".uid"):
			var stripped_path = full_path.replace(".remap", "").replace(".import", "")
			var resource: Resource = load(stripped_path)
			assert(resource, "Resource could not be loaded for " + stripped_path)
			
			var key = file.substr(0, file.find("."))
			if resource is PackedScene:
				var instance = resource.instantiate()
				if callback.is_null() or callback.call(instance) == true:
					registry[key] = resource
				instance.queue_free()
			elif resource is GDScript:
				if callback.is_null() or callback.call(resource) == true:
					registry[key] = resource
		
		file = dir.get_next()
	
	dir.list_dir_end()


static var entity_script = Entity as Script
static func script_inherits_entity(script: Script) -> bool:
	var current = script
	while current != null:
		if current == entity_script:
			return true
		current = current.get_base_script()
	return false


static func scene_inherits_entity(scene: Node) -> bool:
	return script_inherits_entity(scene.get_script())


static func create_entity(data_: Dictionary) -> Entity:
	assert(entities_folder != null, "Set entities folder before creating any entities")
	assert(entity_registry.size() > 0, "Initialize entity registry before creating any entities")
	
	var new_entity = entities_folder.create_entity(data_)
	Entity.entities_folder.create_entity.rpc(new_entity.data)
	#debug_prints("Entity created", data_, new_entity)
	
	return new_entity


static func from_name(_entity_name: String) -> Entity:
	return create_entity({entity_name = _entity_name})


static func create_entities(entities_data: Array[Dictionary]) -> Array[Entity]:
	var arr = []
	
	for i in entities_data.size():
		arr[i] = create_entity(entities_data[i])
	
	return arr


static func clear_entities():
	for entity: Entity in current_entities.values():
		entity.destroy()


static func can_teams_damage(a: Team, b: Team) -> bool:
	if a == Team.NEUTRAL or b == Team.NEUTRAL:
		return true
	if entities_folder.friendly_fire:
		return true
	if entities_folder.player_friendly_fire and a == Team.PLAYER and b == Team.PLAYER:
		return true
	return a != b


static func generate_guid(length := 8) -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result := ""
	
	for i in range(length):
		var index = rng.randi_range(0, chars.length() - 1)
		result += chars[index]
	
	return result


func initialize(_data: Dictionary) -> void:
	data = _data
	
	# set entity name
	
	entity_name = data.get("entity_name")
	
	# Set or generate id
	var new_id = data.get("entity_id")
	
	assert(new_id == null or current_entities.get(new_id) == null, 
		"Existing entity found with id " + str(new_id))
	
	while new_id == null or current_entities.get(new_id) != null:
		new_id = generate_guid()
	
	entity_id = new_id
	data.entity_id = entity_id
	
	# Setup status component
	var max_health: float = data.get("max_health", 100)
	var cur_health: float = data.get("cur_health", max_health)
	var max_shield: float = data.get("max_shield", 0)
	var cur_shield: float = data.get("cur_shield", max_shield)
	var shield_enabled: float = data.get("shield_enabled", false)
	
	status = Status.create_status()
	status.max_health = max_health
	status.cur_health = cur_health
	status.max_shield = max_shield
	status.cur_shield = cur_shield
	status.shield_enabled = shield_enabled
	add_child(status)
	
	# collision layer & mask
	
	collision_layer = Collision.ENTITY_LAYER
	collision_mask = Collision.ENTITY_MASK
	
	# load position data
	
	position = data.get_or_add("position", Vector3.ZERO)
	
	# set up sprite
	
	if not sprite:
		set_sprite()
	assert(sprite, "No sprite found in entity with data " + str(data))
	
	sprite.entity = self
	
	# multiplayer synchronizer
	var scene_replication_config = SceneReplicationConfig.new()
	var position_path = ".:position"
	var rotation_path = ".:rotation"
	scene_replication_config.add_property(position_path)
	scene_replication_config.property_set_replication_mode(
		position_path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	scene_replication_config.add_property(rotation_path)
	scene_replication_config.property_set_replication_mode(
		rotation_path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	
	var multiplayer_synchronizer = MultiplayerSynchronizer.new()
	multiplayer_synchronizer.replication_config = scene_replication_config
	multiplayer_synchronizer.name = "MultiplayerSynchronizer"
	self.add_child(multiplayer_synchronizer)
	
	# finish setup
	
	self.name = entity_id
	current_entities[str(self)] = self
	entities_folder.add_child(self)


func _ready() -> void:
	# set up status hit indicators
	
	status.damaged.connect(on_damaged)
	status.healed.connect(on_healed)
	
	# set up sprite status bar billboard
	
	var status_bar_billboard := sprite.get_node_or_null("StatusBarBillboard") as StatusBarBillboard
	if status_bar_billboard:
		status_bar_billboard.connect_status(status)
	
	# set last position for velocity check
	
	last_positions.resize(velocity_estimate_frame_buffer)
	last_positions.fill([position, 0])


func _process(delta: float) -> void:
	last_positions.push_front([position, delta])
	last_positions.pop_back()
	
	var cumulative_estimated_velocity: Vector3 = Vector3.ZERO
	var cumulative_weight: float = 0
	for i in range(1, velocity_estimate_frame_buffer):
		var delta_position: Vector3 = last_positions[i-1][0] - last_positions[i][0]
		cumulative_estimated_velocity += delta_position
		cumulative_weight += last_positions[i-1][1]
	
	if cumulative_weight == 0:
		estimated_velocity = Vector3.ZERO
	else:
		cumulative_estimated_velocity.y *= entities_folder.aimbot_vertical_velocity_weight
		estimated_velocity = cumulative_estimated_velocity / cumulative_weight

@rpc("any_peer", "call_local")
func destroy():
	if not check_is_authority(-1, get_multiplayer_authority()):
		return
	
	
	if equipped_tool:
		for action_key in equipped_tool.tool_actions:
			var action = equipped_tool.tool_actions[action_key]
			
			if action.active:
				action.cancel_action()
	
	
	current_entities.erase(str(self))
	queue_free()


func _to_string():
	return entity_id


# Checks hotbar at stack_index
# Input -1 for unequip
@rpc("any_peer", "call_local")
func equip_tool(stack_index: int) -> void:
	var hotbar_stacks = inventory.groups.hotbar.stacks
	var stack = (hotbar_stacks.get(stack_index) 
		if stack_index >= 0 and stack_index < hotbar_stacks.size()
		else null)
	var new_tool: Tool = Tool.from_stack(stack) if stack else null
	sprite.equip_tool(new_tool)
	equipped_tool = new_tool


func set_sprite():
	for child in get_children():
		if child is Sprite:
			sprite = child


func can_move_network() -> bool:
	if network and not network.is_multiplayer_connected():
		return false
	if network and not is_multiplayer_authority():
		return false
	return true


func is_alive() -> bool:
	return status.cur_health > 0


func can_move() -> bool:
	return can_move_network() and is_alive()


func get_aim_target_position() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)


@rpc("any_peer", "call_local")
func request_damage(amount: float, attributes: Dictionary[String, bool] = {}) -> void:
	status.damage.rpc(amount, attributes)


func damage(amount: float, attributes: Dictionary[String, bool] = {}) -> void:
	request_damage.rpc_id(get_multiplayer_authority(), amount, attributes)


func kill():
	status.dead = true
	
	var fling_direction = velocity.normalized()
	fling_direction = fling_direction * Vector3(1, 0.2, 1) + Vector3(0, 0.8, 0)
	
	collision_layer = 0
	# removes collisions with other entities
	#collision_mask = Collision.ENTITY_MASK & (-1 ^ Collision.ENTITY_LAYER)
	
	if equipped_tool:
		for action_key in equipped_tool.tool_actions:
			var action = equipped_tool.tool_actions[action_key]
			
			if action.active:
				action.cancel_action()
	
	
	await get_tree().physics_frame
	
	velocity = fling_direction * 20
	
	var rotation_tween = create_tween()
	rotation_tween.tween_property(self, "rotation", Vector3(
		randf_range(-50, 50), randf_range(-50, 50), randf_range(-50, 50)), 5)
	
	died.emit()
	
	await get_tree().create_timer(CORPSE_LIFETIME).timeout
	
	if not network or is_multiplayer_authority():
		destroy.rpc()


func on_damaged(amount: float, attributes: Dictionary):
	data.cur_health = status.cur_health
	
	var indicator = Status.create_hit_indicator(-amount, attributes)
	entities_folder.add_child(indicator)
	indicator.global_position = position
	
	if status.cur_health <= 0:
		kill()


func on_healed(amount: float, attributes: Dictionary):
	data.cur_health = status.cur_health
	
	var indicator = Status.create_hit_indicator(amount, attributes)
	entities_folder.add_child(indicator)
	indicator.global_position = position
