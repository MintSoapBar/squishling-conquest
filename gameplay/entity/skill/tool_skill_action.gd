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
	
	var skill_id = -1
	while (skill_id == -1 
		or Skill.current_skills.get(Skill.get_string(peer, skill_id))):
		skill_id = randi()
	
	var args = [
		action_name, 
		peer, 
		skill_id, 
		tool.get_path(), 
		action_key,
		skill_data,
	]
	
	cur_skill = Entity.entities_folder.create_skill.callv(args)
	Entity.entities_folder.create_skill.rpc.callv(args)
	
	for peer_id in tool.multiplayer.get_peers():
		cur_skill.peers[peer_id] = true
	
	cur_skill.start_local(params)


func continue_action(params: Dictionary = {}) -> void:
	if not check_action_valid():
		return
	
	super(params)
	
	cur_skill.continue_local(params)


func stop_action(params: Dictionary = {}) -> void:
	var time := GameTime.get_unpaused_elapsed_time()
	if time < startup_end_time:
		await tool_user.get_tree().create_timer(startup_end_time - time).timeout
	
	if not check_action_valid():
		return
	if not cur_skill:
		return
	
	super(params)
	
	cur_skill.stop_local(params)


func cancel_action() -> void:
	super()
	
	if is_instance_valid(cur_skill):
		cur_skill.cancel.rpc()
