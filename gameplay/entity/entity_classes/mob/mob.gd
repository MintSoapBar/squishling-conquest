@abstract
class_name Mob
extends Entity

var target_teams = [
	Team.PLAYER,
]

var walk_speed: float = 0

var controls: Dictionary[String, Goal] = {}
var target: Entity
var movement_target_position: Vector3 = Vector3(0, 0, 0)

var attack_interval_min: float = 3
var attack_interval_max: float = 5
var attack_charge_time_min: float = 0.5
var attack_charge_time_max: float = 1
var next_attack_skill_key: String = ""
var current_attack_action: ToolSkillAction = null

var next_attack_time: float = GameTime.get_unpaused_elapsed_time() + (
	randf_range(2, 5))


func initialize(_data: Dictionary) -> void:
	var stat_block: MobStatBlock = MobStats.stats[_data.entity_name]
	
	team = Team.MOB
	_data.max_health = stat_block.max_health
	walk_speed = stat_block.walk_speed
	super(_data)


var facing_direction = Vector3.MODEL_FRONT
func _physics_process(delta: float) -> void:
	if not can_move_network():
		return
	
	if is_on_floor():
		velocity.y = max(velocity.y, 0)
	else:
		velocity += get_gravity() * delta
	
	if is_alive():
		var move_delta = (movement_target_position - global_position) * Vector3(1, 0, 1)
		
		if move_delta.length() > 0.2:
			var move_velocity = move_delta.normalized() * min(move_delta.length() * 2, walk_speed)
			velocity.x = move_velocity.x
			velocity.z = move_velocity.z
			facing_direction = move_delta.normalized()
		
		transform.basis = transform.basis.orthonormalized().slerp(
			Basis.looking_at(facing_direction).orthonormalized(), 0.2)
	
	move_and_slide()
	
	data.position = global_position


func step_attack():
	var cur_time = GameTime.get_unpaused_elapsed_time()
	if not current_attack_action:
		if cur_time >= next_attack_time:
			var chosen_key = next_attack_skill_key
			if not chosen_key or chosen_key.is_empty():
				chosen_key = equipped_tool.tool_actions.keys().pick_random()
			
			if chosen_key and not chosen_key.is_empty():
				current_attack_action = equipped_tool.tool_actions[chosen_key]
				current_attack_action.start_action({target_entity = target})
				
				var charge_time: float = max(
					randf_range(attack_charge_time_min, attack_charge_time_max),
					current_attack_action.cur_skill.get_startup(),
				)
				
				await get_tree().create_timer(charge_time).timeout
				update_target()
				
				if target:
					if current_attack_action.poll_stop:
						var endlag = current_attack_action.cur_skill.get_endlag()
						current_attack_action.stop_action({target_entity = target})
						await get_tree().create_timer(endlag).timeout
				else:
					current_attack_action.cancel_action()
				current_attack_action = null
			
			next_attack_time = cur_time + randf_range(attack_interval_min, attack_interval_max)
	else:
		if current_attack_action.poll_continue and target:
			current_attack_action.continue_action({target_entity = target})


func update_target():
	if not is_instance_valid(target) or not target.is_alive():
		target = null
		target = find_target()


func find_target() -> Entity:
	var closest_target_dist: float = INF
	
	for potential_target_id in current_entities:
		var potential_target: Entity = current_entities.get(potential_target_id)
		
		if potential_target == self or not potential_target.is_alive():
			continue
		if target_teams.find(potential_target.team) == -1:
			continue
		
		var target_dist = (potential_target.global_position - global_position).length()
		if target_dist < closest_target_dist:
			return potential_target
	
	return null
