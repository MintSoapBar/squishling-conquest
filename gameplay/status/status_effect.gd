class_name StatusEffect
extends Node

signal finished

var status: Status
var status_effect_name: String
var stacks: Array[StatusEffectStack] = []


static func create_status_effect(_status: Status, _status_effect_name: String) -> StatusEffect:
	var new_effect = StatusEffect.new()
	new_effect.status = _status
	new_effect.status_effect_name = _status_effect_name
	_status.add_child(new_effect)
	return new_effect


static func compare_status_effect_stack(a: StatusEffectStack, b: StatusEffectStack):
	return abs(a.health_change) - abs(b.health_change) > 0


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	var time = GameTime.get_ticks_sec()
	
	var to_remove: Array[int] = []
	
	for stack_index in stacks.size():
		var stack := stacks[stack_index]
		
		if time >= stack.next_tick:
			stack.next_tick += 1
			if stack == stacks[0]:
				var attributes: Dictionary[String, bool] = {dot = true}
				attributes.merge(StatusEffectBalancing.status_effect_attributes.get(status_effect_name, {}))
				if stack.health_change < 0:
					status.damage.rpc(-stack.health_change, attributes)
				elif stack.health_change > 0:
					status.heal.rpc(stack.health_change, attributes)
		
		if time > stack.end_time:
			to_remove.append(stack_index)
	
	for i in range(to_remove.size() - 1, -1, -1):
		stacks.remove_at(to_remove[i])
	
	if stacks.size() == 0:
		finished.emit()


func add_stack(health_change: float, duration: float):
	var time := GameTime.get_ticks_sec()
	
	var new_stack = StatusEffectStack.new()
	new_stack.health_change = health_change
	new_stack.next_tick = time + 1
	new_stack.end_time = time + duration
	
	stacks.insert(stacks.bsearch_custom(new_stack, compare_status_effect_stack, false), new_stack)


class StatusEffectStack:
	var health_change: float = 0
	var end_time: float
	var next_tick: float = GameTime.get_ticks_sec()
