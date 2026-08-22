class_name LivingMushroom
extends Mob

func initialize(_data: Dictionary) -> void:
	var magic = _data.get_or_add("magic", ["poison", "air"].pick_random())
	
	super(_data)
	
	attack_charge_time_min = 0.5
	attack_charge_time_max = 0.5
	
	next_attack_time = GameTime.get_unpaused_elapsed_time() + randf_range(1, 5)
	
	inventory.add_stack(Stack.new("living_mushroom_tool", 1))
	equip_tool(0)
	
	if magic == "poison":
		sprite.cap_color = Color("4e016fff")
	elif magic == "air":
		sprite.cap_color = Color("e8e8e8ff")
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_1", equipped_tool, self, 
	{"magic" = magic, "hide_circle" = true})



func _physics_process(delta: float) -> void:
	super(delta)
	
	if not can_move():
		return
	
	update_target()
	if target:
		movement_target_position = target.global_position
		step_attack()
