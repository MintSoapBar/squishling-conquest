class_name MagicExplosionSkill
extends StandardChargeSkill

const base_damage: float = 30

const base_explosion_radius := 1.5


func initialize() -> void:
	base_charge_startup = 0.6
	base_startup = 0.3
	base_endlag = 0.6


func start_local(params: Dictionary):
	super(params)
	
	action.active = true
	
	params.tool_origin = tool.get_action_origin()
	if not params.get("target_position"):
		params.target_position = get_aimbot_target_position(params)
	
	tool.lock(action)
	
	call_replicated(start_replicated, params)


func continue_local(params: Dictionary):
	super(params)
	
	params.tool_origin = tool.get_action_origin()
	if not params.get("target_position"):
		params.target_position = get_aimbot_target_position(params)
	
	call_replicated(continue_replicated, params)


func stop_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	super(params)
	
	params.tool_origin = tool.get_action_origin()
	if not params.get("target_position"):
		params.target_position = get_aimbot_target_position(params)
	
	call_replicated(stop_replicated, params)
	
	await get_tree().create_timer(get_startup()).timeout
	
	var damage_multiplier = get_skill_stat_multiplier("damage", params)
	var size_multiplier = get_skill_stat_multiplier("size", params)
	
	var space_state := get_world_3d().direct_space_state
	
	var hit_entities: Dictionary[Entity, bool] = {}
	
	var explosion_query_shape := SphereShape3D.new()
	explosion_query_shape.radius = base_explosion_radius * size_multiplier
	var explosion_query_params := PhysicsShapeQueryParameters3D.new()
	explosion_query_params.shape = explosion_query_shape
	explosion_query_params.transform = Transform3D(Basis.IDENTITY, params.target_position)
	explosion_query_params.exclude = get_excluded_rids()
	
	for result in space_state.intersect_shape(explosion_query_params):
		var hit_body = result.collider
		if hit_body is Entity:
			var hit_entity = hit_body as Entity
			hit_entities[hit_entity] = true
	
	for hit_entity in hit_entities:
		if Entity.can_teams_damage(team, hit_entity.team):
			hit_entity.damage(base_damage * damage_multiplier, {data.magic: true})


func start_replicated(params: Dictionary):
	if not check_skill_valid():
		return
	
	var preview_pos: Vector3 = params.target_position
	var preview_basis: Basis = Basis.IDENTITY.rotated(Vector3.RIGHT, PI/2)
	if not data.get("hide_circle"):
		var circle: MagicCircle = MagicCircle.create_magic_circle(data.magic)
		circle.position = preview_pos
		circle.basis = preview_basis
		circle.scale = Vector3.ONE * 2 * base_explosion_radius * 0.5
		add_child(circle)
		circle.fade_in(get_charge_startup()/2)
	
		data.magic_circle = circle
	else:
		var projectile: MagicProjectileVFX = MagicVFX.create_projectile_sphere(
			data.magic, 
			base_explosion_radius * 0.5
		)
		projectile.position = preview_pos
		projectile.basis = preview_basis
		add_child(projectile)
		
		data.charge_projectile = projectile


func continue_replicated(params: Dictionary):
	if not check_skill_valid():
		return
	
	var preview_pos: Vector3 = params.target_position
	var charge_size_multiplier: float = SkillCharge.get_stat_multiplier("size", params.charge)
	if not data.get("hide_circle"):
		var circle: Node3D = data.magic_circle
		circle.position = preview_pos
		circle.scale = Vector3.ONE * 2 * base_explosion_radius * 0.5 * charge_size_multiplier
	else:
		var projectile: MagicProjectileVFX = data.charge_projectile
		projectile.position = preview_pos
		
		var size_multiplier = get_skill_stat_multiplier("size", params)
		projectile.set_radius(base_explosion_radius * 0.5 * size_multiplier)


func stop_replicated(params: Dictionary):
	if not check_skill_valid():
		return
	
	data.charge = params.charge
	
	var size_multiplier = get_skill_stat_multiplier("size", params)
	
	#var origin: Vector3 = params.tool_origin
	var target_position: Vector3 = params.target_position
	
	await get_tree().create_timer(get_startup()).timeout
	
	var circle: MagicCircle = data.get("magic_circle")
	if circle:
		circle.fade_out(get_endlag()/2, get_endlag()/2)
		circle.faded_out.connect(circle.queue_free)
		data.erase("magic_circle")
	
	var charge_projectile: MagicProjectileVFX = data.get("charge_projectile")
	data.erase("charge_projectile")
	if charge_projectile:
		charge_projectile.fade_out()
	
	var explosion_radius = base_explosion_radius * size_multiplier
	
	var explosion: MagicExplosionVFX = MagicVFX.create_explosion_sphere(data.magic, explosion_radius)
	data.set("explosion", explosion)
	explosion.position = target_position
	add_child(explosion)
	
	explosion.fade_out()
	explosion.tree_exited.connect(queue_free)


func cancel():
	if not data.get("explosion"):
		queue_free()


func get_aimbot_target_position(params: Dictionary) -> Vector3:
	var target_entity: Entity = params.get("target_entity")
	if target_entity:
		return target_entity.get_aim_target_position()
	else:
		push_error("params does not contain a target_entity to target " + str(params))
		return Vector3.ZERO
