class_name Rig
extends Mob

var first_fire_delay_min: float = 1
var first_fire_delay_max: float = 2
var charge_time_min: float = 0.5
var charge_time_max: float = 1
var fire_interval_min: float = 1
var fire_interval_max: float = 3

var next_fire: float = GameTime.get_unpaused_elapsed_time() + (
	randf_range(first_fire_delay_min, first_fire_delay_max))


func _ready() -> void:
	super()
	
	inventory.add_stack(Stack.new("magic_staff", 1))
	equip_tool(0)


func _physics_process(delta: float) -> void:
	super(delta)
	
	
	if not can_move_network():
		return
	if is_alive():
		tick_target_attack()


func tick_target_attack():
	update_target()
	
	if is_instance_valid(target):
		movement_target_position = target.global_position
		
		var cur_time = GameTime.get_unpaused_elapsed_time()
		if cur_time >= next_fire:
			if equipped_tool.locking_action:
				if equipped_tool.locking_action.poll_continue:
					equipped_tool.locking_action.stop_action({target_entity = target})
				
				next_fire = cur_time + randf_range(fire_interval_min, fire_interval_max)
			else:
				var chosen_key = equipped_tool.tool_actions.keys().pick_random()
				if chosen_key:
					equipped_tool.tool_actions[chosen_key].start_action({target_entity = target})
					
					var charge_time_range := charge_time_max - charge_time_min
					next_fire = cur_time + charge_time_min + randf() ** 2 * charge_time_range
				else:
					print("No tool actions in rig's tool")
		else:
			if equipped_tool.locking_action and equipped_tool.locking_action.poll_continue:
				equipped_tool.locking_action.continue_action({target_entity = target})
	else:
		if equipped_tool.locking_action and equipped_tool.locking_action.active:
			equipped_tool.locking_action.cancel_action()
