class_name EntitiesFolder
extends Node3D

@warning_ignore("unused_signal")
signal local_player_changed(Player)


@export var friendly_fire: bool = false
@export var player_friendly_fire: bool = false
@export var player_sprite = preload("uid://bta3jvdrwrxf6")
@export var aimbot_vertical_velocity_weight := 0.0


@rpc("authority", "call_remote")
func create_entity(data: Dictionary):
	var entity_name = data.get("entity_name")
	assert(entity_name, "No entity name provided in data " + str(data))
	
	var scene = Entity.entity_registry.get(entity_name)
	assert(scene, "No entity scene found for name " + str(entity_name))
	
	var entity: Entity = scene.instantiate()
	entity.initialize(data)
	
	if Entity.network:
		Entity.debug_prints("Entity replicated", entity.entity_id)
	
	return entity


@rpc("any_peer", "call_local")
func create_skill_rpc(
	skill_name: String, 
	network_origin: int, skill_id: int, 
	tool_path: NodePath, action_key: String,
	data := {},
	team: Entity.Team = Entity.Team.NULL, player_peer_id: int = -1):
	
	if not Entity.check_is_authority(-1, network_origin):
		return
	
	create_skill(
		skill_name, 
		network_origin, skill_id, 
		tool_path, action_key,
		data,
		team, player_peer_id
	)

func create_skill(
	skill_name: String, 
	network_origin: int, skill_id: int, 
	tool_path: NodePath, action_key: String,
	data := {},
	team: Entity.Team = Entity.Team.NULL, player_peer_id: int = -1):
	
	var authority: int = 1 if Entity.server_authority_enabled() else network_origin
	
	assert(Skill.skill_registry.size() > 0, "Initialize skill registry before creating any skills")
	
	# the server user is firing off a skill, a "local" skill already exists
	var existing_skill = Skill.current_skills.get(Skill.get_string(network_origin, skill_id))
	if existing_skill != null:
		return existing_skill
	
	while (skill_id == -1 
		or Skill.current_skills.get(Skill.get_string(network_origin, skill_id))):
		skill_id = randi()
	
	var new_node = Node3D.new()
	new_node.set_script(Skill.skill_registry[skill_name])
	
	var tool: Tool = get_tree().current_scene.get_node(tool_path)
	var tool_user: Entity = tool.tool_user
	var action: ToolAction = tool.tool_actions[action_key]
	
	var new_skill: Skill = new_node as Skill
	new_skill.network_origin = network_origin
	new_skill.skill_id = skill_id
	new_skill.tool = tool
	new_skill.data = data
	
	new_skill.tool_user = tool_user
	new_skill.action = action
	
	if team == Entity.Team.NULL:
		team = tool_user.team
	if player_peer_id == -1 and tool_user is Player:
		player_peer_id = tool_user.peer_id
		
	new_skill.team = team
	new_skill.player_peer_id = player_peer_id
	
	Skill.current_skills[str(new_skill)] = new_skill
	new_skill.name = str(new_skill)
	new_skill.set_multiplayer_authority(authority)
	new_skill.initialize()
	add_child(new_skill)
	
	return new_skill
