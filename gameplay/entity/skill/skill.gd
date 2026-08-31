@abstract
class_name Skill
extends Node3D

static var skill_registry: Dictionary[String, GDScript] = {}

static var current_skills: Dictionary[String, Skill] = {}

static var startup: float = 0.2
static var endlag: float = 0.2

var network_origin: int
var skill_id: int
var tool: Tool
var tool_user: Entity
var action: ToolAction

var team: Entity.Team
var player_peer_id: int

var data: Dictionary
var peers: Dictionary[int, bool] = {}


static func initialize_registry():
	var skill_classes_path := (Skill as GDScript).resource_path.replace("skill.gd", "skill_classes")
	Entity.register_scenes(
		skill_registry, 
		skill_classes_path, 
		script_inherits_skill, 
		".gd"
	)
	Entity.debug_prints("Registered skill scenes:", skill_registry.keys())
	
	# preload everything
	Entity.register_scenes({}, skill_classes_path)


static var skill_script = Skill as Script
static func script_inherits_skill(script: Script) -> bool:
	var current = script
	while current != null:
		if current == skill_script:
			return true
		current = current.get_base_script()
	return false


func initialize() -> void:
	pass


func call_replicated(callable: Callable, arg: Variant) -> void:
	for peer in multiplayer.get_peers():
		if peers.get(peer):
			callable.rpc_id(peer, arg)
	callable.call_deferred(arg)


func call_replicated_2(callable: Callable, arg1: Variant, arg2: Variant) -> void:
	for peer in multiplayer.get_peers():
		if peers.get(peer):
			callable.rpc_id(peer, arg1, arg2)
	callable.call_deferred(arg1, arg2)


func is_skill_valid() -> bool:
	return is_instance_valid(self) and is_inside_tree()


## Also removes the skill if not valid
func check_skill_valid() -> bool:
	if is_skill_valid():
		return true
	else:
		if is_instance_valid(self):
			queue_free()
		return false


func start_local(_params: Dictionary) -> void:
	pass
func continue_local(_params: Dictionary) -> void:
	pass
func stop_local(_params: Dictionary) -> void:
	pass


#func start_server(_params: Dictionary) -> void:
	#pass
#func continue_server(_params: Dictionary) -> void:
	#pass
#func stop_server(_params: Dictionary) -> void:
	#pass


@rpc("authority", "call_local")
func cancel() -> void:
	pass


@rpc("authority", "call_local")
func start_replicated(_params: Dictionary) -> void:
	pass
@rpc("authority", "call_local", "unreliable_ordered")
func continue_replicated(_params: Dictionary) -> void:
	pass
@rpc("authority", "call_local")
func stop_replicated(_params: Dictionary) -> void:
	pass
@rpc("authority", "call_local")
func cancel_replicated() -> void:
	pass


static func get_string(_network_origin: int, _skill_id: int) -> String:
	return "skill_%d_%d" % [_network_origin, _skill_id]


func _to_string() -> String:
	return get_string(network_origin, skill_id)


func _exit_tree() -> void:
	current_skills.erase(str(self))


func get_startup():
	var stats := MagicStats.stats[data.magic]
	return startup / stats.speed


func get_endlag():
	var stats := MagicStats.stats[data.magic]
	return endlag / stats.speed


func get_aimbot_target_position(_params: Dictionary):
	pass


func get_excluded_rids() -> Array[RID]:
	var excluded_rids: Array[RID] = []
	for entity_id: String in Entity.current_entities:
		var entity = Entity.current_entities[entity_id]
		if entity == tool_user or not Entity.can_teams_damage(team, entity.team):
			excluded_rids.append(entity.get_rid())
	return excluded_rids


func get_skill_stat_multiplier(stat: String, params: Dictionary = {}) -> float:
	var stat_multiplier: float = data.get(stat + "_multiplier", 1)
	
	var charge = params.get("charge", data.get("charge", 1))
	stat_multiplier *= SkillCharge.get_stat_multiplier(stat, charge)
	
	var magic = data.get("magic")
	if magic:
		var magic_stats := MagicStats.stats[magic]
		stat_multiplier *= magic_stats[stat]
	
	return stat_multiplier


func intersect_projectile(projectile_origin: Vector3, projectile_speed: float,
	target_origin: Vector3, target_velocity: Vector3, max_time: float = INF) -> Vector3:
	
	var pos_diff := target_origin - projectile_origin
	
	var a := target_velocity.dot(target_velocity) - projectile_speed ** 2
	var b := 2.0 * pos_diff.dot(target_velocity)
	var c := pos_diff.dot(pos_diff)
	
	var t := -1.0
	
	var discrim := b*b - 4 * a * c
	
	if discrim > 0:
		var sqrt_d := sqrt(discrim)
		var t1 := (-b - sqrt_d) / (2.0 * a)
		var t2 := (-b + sqrt_d) / (2.0 * a)
		
		if t1 > 0 and t2 > 0:
			t = min(t1, t2)
		else:
			t = max(t1, t2)
	
	t = min(t, max_time)
	
	if t < 0:
		# no valid pos
		return target_origin
	else:
		# target can be hit or inside projectile origin
		var predicted_pos := target_origin + target_velocity * t
		return predicted_pos
