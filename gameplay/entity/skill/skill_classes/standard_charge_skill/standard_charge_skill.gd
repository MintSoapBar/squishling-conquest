class_name StandardChargeSkill
extends Skill


func start_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	action.active = true
	action.poll_continue = true
	action.poll_stop = true
	tool.lock(action)
	
	params.origin = tool.get_action_origin()
	params.charge = 0
	data.start_time = GameTime.get_unpaused_elapsed_time()
	data.team = tool_user.team
	action.startup_end_time = data.start_time + get_startup()


func continue_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	var time := GameTime.get_unpaused_elapsed_time()
	var charge_time: float = time - data.start_time - get_startup()
	
	params.origin = tool.get_action_origin()
	params.charge = clamp(charge_time/SkillCharge.MAX_CHARGE_TIME, 0, 1)


func stop_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	var time := GameTime.get_unpaused_elapsed_time()
	var charge_time: float = time - data.start_time - get_startup()
	
	action.poll_continue = false
	action.poll_stop = false
	
	params.origin = tool.get_action_origin()
	params.charge = clamp(charge_time/SkillCharge.MAX_CHARGE_TIME, 0, 1)
	
	await get_tree().create_timer(get_endlag()).timeout
	
	if is_instance_valid(tool) and action.active:
		action.active = false
		tool.unlock()


func start_server(params: Dictionary):
	if not check_skill_valid():
		return
	
	call_replicated(start_replicated, params)


func continue_server(params: Dictionary):
	if not check_skill_valid():
		return
	
	call_replicated(continue_replicated, params)


func get_magic_skill_damage_multiplier(params: Dictionary = {}) -> float:
	var stats := MagicStats.stats[data.magic]
	# checks in data because some stop_replicated stores it there 
	# (eg. magic blasts's stop_replicated stores it for explode_projectile)
	var charge = params.get("charge", data.get("charge", 1))
	var damage_multiplier = stats.damage * SkillCharge.get_damage_multiplier(charge)
	damage_multiplier *= data.get("damage_multiplier", 1)
	return damage_multiplier


func get_magic_skill_speed_multiplier(params: Dictionary = {}) -> float:
	var stats := MagicStats.stats[data.magic]
	var charge = params.get("charge", data.get("charge", 1))
	var speed_multiplier = stats.speed * SkillCharge.get_speed_multiplier(charge)
	speed_multiplier *= data.get("speed_multiplier", 1)
	return speed_multiplier


func get_magic_skill_size_multiplier(params: Dictionary = {}) -> float:
	var stats := MagicStats.stats[data.magic]
	var charge = params.get("charge", data.get("charge", 1))
	var size_multiplier = stats.size * SkillCharge.get_size_multiplier(charge)
	size_multiplier *= data.get("size_multiplier", 1)
	return size_multiplier
