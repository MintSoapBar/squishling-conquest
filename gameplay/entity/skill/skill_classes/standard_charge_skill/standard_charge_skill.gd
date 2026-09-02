class_name StandardChargeSkill
extends Skill


func start_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	super(params)
	
	action.poll_continue = true
	action.poll_stop = true
	
	params.charge = 0
	action.startup_end_time = data.start_time + get_startup()


func continue_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	super(params)
	
	var time := GameTime.get_unpaused_elapsed_time()
	var charge_time: float = time - data.start_time - get_startup()
	
	params.charge = clamp(charge_time/SkillCharge.MAX_CHARGE_TIME, 0, 1)


func stop_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	super(params)
	
	var time := GameTime.get_unpaused_elapsed_time()
	var charge_time: float = time - data.start_time - get_startup()
	
	action.poll_continue = false
	action.poll_stop = false
	
	params.charge = clamp(charge_time/SkillCharge.MAX_CHARGE_TIME, 0, 1)
	
	await get_tree().create_timer(get_endlag()).timeout
	
	if is_instance_valid(tool) and action.active:
		action.active = false
		tool.unlock()
