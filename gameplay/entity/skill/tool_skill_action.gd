class_name ToolSkillAction
extends ToolAction

var cur_skill: Skill = null


func start_action(params: Dictionary = {}):
	if not check_action_valid():
		return
	if not tool_user.is_alive():
		cancel_action()
		return
	
	super(params)
	
	var peer: int = tool_user.get_multiplayer_authority()
	
	var skill_data = data.duplicate()
	
	cur_skill = Entity.entities_folder.create_skill(
		action_name, 
		peer, 
		-1, 
		tool.get_path(), 
		action_key,
		skill_data,
	)
	
	cur_skill.start_local(params)
	if params.get("target_position") == null:
		params.target_position = cur_skill.get_aimbot_target_position(params)
	
	params.skill_id = cur_skill.skill_id
	
	var authority: int = 1 if Entity.server_authority_enabled() else peer
	
	tool.request_tool_action_call.rpc_id(authority, 
		ToolAction.ToolActionCallType.START, 
		action_key, 
		params)


func continue_action(params: Dictionary = {}) -> void:
	if not check_action_valid():
		return
	
	super(params)
	
	cur_skill.continue_local(params)
	if not params.get("target_position"):
		params.target_position = cur_skill.get_aimbot_target_position(params)
	
	var authority: int = (1 if Entity.server_authority_enabled() 
		else tool_user.get_multiplayer_authority())
	
	tool.request_tool_action_call.rpc_id(authority, 
		ToolAction.ToolActionCallType.CONTINUE, 
		action_key, 
		params)


func stop_action(params: Dictionary = {}) -> void:
	var time := GameTime.get_ticks_sec()
	if time < startup_end_time:
		await tool_user.get_tree().create_timer(startup_end_time - time).timeout
	
	if not check_action_valid():
		return
	if not cur_skill:
		return
	
	super(params)
	
	cur_skill.stop_local(params)
	if not params.get("target_position"):
		params.target_position = cur_skill.get_aimbot_target_position(params)
	
	var authority: int = (1 if Entity.server_authority_enabled() 
		else tool_user.get_multiplayer_authority())
	
	tool.request_tool_action_call.rpc_id(authority, 
		ToolAction.ToolActionCallType.STOP, 
		action_key, 
		params)


func start_action_server(params: Dictionary = {}):
	super(params)
	
	var network_origin: int = tool_user.get_multiplayer_authority()
	var authority: int = 1 if Entity.server_authority_enabled() else network_origin
	
	var skill_data = data.duplicate()
	
	var args = [
		action_name, 
		network_origin, 
		params.skill_id, 
		tool.get_path(), 
		action_key,
		skill_data,
	]
	
	cur_skill = Entity.entities_folder.create_skill.callv(args)
	
	if Entity.network:
		cur_skill.peers[tool.multiplayer.get_unique_id()] = true
		for peer_id in tool.multiplayer.get_peers():
			cur_skill.peers[peer_id] = true
			if peer_id == authority or peer_id == network_origin:
				continue
			Entity.entities_folder.create_skill_rpc.rpc_id.bindv(args).call(peer_id)
	else:
		cur_skill.peers[0] = true
	
	data.skill = cur_skill
	cur_skill.start_server(params)


func continue_action_server(params: Dictionary = {}) -> void:
	super(params)
	
	cur_skill.continue_server(params)


func stop_action_server(params: Dictionary = {}) -> void:
	super(params)
	
	cur_skill.stop_server(params)


func cancel_action() -> void:
	super()
	
	if is_instance_valid(cur_skill):
		cur_skill.cancel.rpc()
