class_name SlashSkill
extends Skill

const SLASH_VFX = preload("uid://ccpvm0lk3khw0")

const base_damage = 30
const base_slash_radius: float = 1.5
const base_slash_depth: float = 0.1
const slash_half_angle = PI * 2/3


func initialize() -> void:
	base_startup = 0.3
	base_endlag = 0.3


func start_local(params: Dictionary):
	super(params)
	
	action.active = true
	tool.lock(action)
	
	call_replicated(start_replicated, params)
	
	var damage_multiplier = get_skill_stat_multiplier("damage", params)
	var size_multiplier = get_skill_stat_multiplier("size", params)
	
	await get_tree().create_timer(get_startup()).timeout
	
	var slash_position = tool_user.sprite.get_chest_origin()
	var slash_rotation = tool_user.global_rotation
	var slash_transform = Transform3D(tool_user.global_basis, slash_position)
	
	call_replicated(show_slash, [
		slash_position, 
		slash_rotation,
	])
	
	var hit_entities: Dictionary[Entity, bool] = {}
	
	var slash_query_shape_left := ShapeGenerator.generate_circular_sector_from_angle(
		base_slash_radius * size_multiplier,
		0, slash_half_angle, 
		base_slash_depth * size_multiplier,
		16,
	)
	
	var slash_query_shape_right := ShapeGenerator.generate_circular_sector_from_angle(
		base_slash_radius * size_multiplier,
		-slash_half_angle, 0,
		base_slash_depth * size_multiplier,
		16,
	)
	var query_transform = slash_transform \
		.rotated_local(Vector3.RIGHT, -PI/2) \
		.rotated_local(Vector3.BACK, PI/2)
	
	var space_state = get_world_3d().direct_space_state
	
	for slash_query_shape in [slash_query_shape_left, slash_query_shape_right]:
		var slash_query_params := PhysicsShapeQueryParameters3D.new()
		slash_query_params.transform = query_transform
		slash_query_params.exclude = get_excluded_rids()
		slash_query_params.shape = slash_query_shape
		
		for result in space_state.intersect_shape(slash_query_params):
			var hit_body = result.collider
			if hit_body is Entity:
				var hit_entity = hit_body as Entity
				hit_entities[hit_entity] = true
	
	for hit_entity in hit_entities:
		if Entity.can_teams_damage(team, hit_entity.team):
			hit_entity.damage(base_damage * damage_multiplier)
	
	await get_tree().create_timer(get_endlag()).timeout
	
	if is_instance_valid(tool) and action.active:
		action.active = false
		tool.unlock()


func start_replicated(_params: Dictionary) -> void:
	
	var initial_direction = (-tool_user.basis.z).rotated(Vector3.UP, -slash_half_angle)
	
	tool_user.sprite.point_at(
		initial_direction,
		1.0,
		initial_direction.cross(Vector3.UP)
	)
	
	await get_tree().create_timer(get_startup() * 2/3).timeout
	
	tool_user.sprite.swing(
		-tool_user.basis.z, 
		Vector3.UP, 
		slash_half_angle, 
		1, 
		get_startup() * 1/3,
		get_endlag(),
	)


func show_slash(params: Array):
	var slash_position: Vector3 = params[0]
	var slash_rotation: Vector3 = params[1]
	
	var size_multiplier = get_skill_stat_multiplier("size")
	
	var slash_vfx: SlashVFX = SlashVFX.create_slash(
		base_slash_radius * size_multiplier,
		base_slash_depth * size_multiplier,
		slash_half_angle,
	)
	slash_vfx.visible = false
	slash_vfx.position = slash_position
	slash_vfx.rotation = slash_rotation
	add_child(slash_vfx)
	slash_vfx.visible = true
	
	slash_vfx.fade_out()
	slash_vfx.tree_exited.connect(queue_free)
