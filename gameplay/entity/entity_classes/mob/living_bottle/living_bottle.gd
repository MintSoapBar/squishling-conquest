class_name LivingBottle
extends Mob

func initialize(_data: Dictionary) -> void:
	var magic = _data.get_or_add("magic", ["fire", "water"].pick_random())
	
	super(_data)
	
	attack_charge_time_min = 0.5
	attack_charge_time_max = 0.5
	
	next_attack_time = GameTime.get_unpaused_elapsed_time() + randf_range(1, 5)
	
	inventory.add_stack(Stack.new("living_bottle_tool", 1))
	equip_tool(0)
	
	if magic == "fire":
		sprite.bottle_color = Color("ff5e00ff")
	elif magic == "water":
		sprite.bottle_color = Color("007bc2ff")
	
	ToolSkillAction.new("magic_explosion_skill", 
	"skill_1", equipped_tool, self, 
	{"magic" = magic, "hide_circle" = true})
