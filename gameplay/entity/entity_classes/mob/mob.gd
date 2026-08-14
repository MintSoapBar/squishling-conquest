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


func update_target():
	if not is_instance_valid(target) or not target.is_alive():
		target = null
	
	if not target:
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
