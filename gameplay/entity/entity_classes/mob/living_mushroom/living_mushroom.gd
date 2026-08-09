class_name LivingMushroom
extends Mob

var first_fire_delay_min: float = 1
var first_fire_delay_max: float = 2
var fire_interval_min: float = 1
var fire_interval_max: float = 3

var next_fire: float = Time.get_ticks_msec()/1000.0 + (
	randf_range(first_fire_delay_min, first_fire_delay_max))


func _ready() -> void:
	super()
	
	inventory.add_stack(Stack.new("living_mushroom_tool", 1))
	equip_tool(0)


func _physics_process(delta: float) -> void:
	super(delta)
	
	if not can_move_network():
		return
	if is_alive():
		if not is_instance_valid(target):
			target = find_target()
		if is_instance_valid(target):
			movement_target_position = target.global_position
		
			var cur_time = Time.get_ticks_msec()/1000.0
			if cur_time >= next_fire:
				var chosen_key = equipped_tool.tool_actions.keys().pick_random()
				if chosen_key:
					var chosen_action := equipped_tool.tool_actions[chosen_key]
					chosen_action.start_action({target_entity = target})
					chosen_action.stop_action({target_entity = target})
				next_fire = cur_time + randf_range(fire_interval_min, fire_interval_max)
