class_name LivingMushroom
extends Mob

var first_fire_delay_min: float = 1
var first_fire_delay_max: float = 2
var hold_time: float = 0.5
var fire_interval_min: float = 3
var fire_interval_max: float = 5

var next_fire: float = GameTime.get_unpaused_elapsed_time() + (
	randf_range(first_fire_delay_min, first_fire_delay_max))


func initialize(_data: Dictionary) -> void:
	super(_data)


func _ready() -> void:
	super()
	
	inventory.add_stack(Stack.new("living_mushroom_tool", 1))
	equip_tool(0)


func _physics_process(delta: float) -> void:
	super(delta)
	
	if not can_move_network():
		return
	if is_alive():
		if not is_instance_valid(target) or not target.is_alive():
			target = null
			target = find_target()
		if is_instance_valid(target):
			movement_target_position = target.global_position
		
			var cur_time = GameTime.get_unpaused_elapsed_time()
			if cur_time >= next_fire:
				var chosen_key = equipped_tool.tool_actions.keys().pick_random()
				next_fire = cur_time + randf_range(fire_interval_min, fire_interval_max)
				if chosen_key:
					var chosen_action := equipped_tool.tool_actions[chosen_key]
					chosen_action.start_action({target_entity = target})
					await get_tree().create_timer(hold_time).timeout
					target = find_target()
					if is_instance_valid(target) and target.is_alive():
						chosen_action.stop_action({target_entity = target})
					else:
						chosen_action.cancel_action()
