class_name MagicBlastSkill
extends Skill

const max_projectile_lifetime: float = 2
const base_projectile_speed: float = 20

const base_projectile_radius := 0.2
const base_explosion_radius := 0.5

const base_damage: float = 30

func initialize() -> void:
	startup = 0.2
	endlag = 0.2


func start_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	action.active = true
	action.poll_continue = true
	action.poll_stop = true
	tool.lock(action)
	
	params.origin = tool.get_action_origin()
	params.charge = 0
	data.start_time = GameTime.get_unpaused_elapsed_time()
	data.team = tool_user.team
	action.startup_end_time = data.start_time + get_startup()


func continue_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	var time := GameTime.get_unpaused_elapsed_time()
	var charge_time: float = time - data.start_time - get_startup()
	
	params.origin = tool.get_action_origin()
	params.charge = clamp(charge_time/SkillCharge.MAX_CHARGE_TIME, 0, 1)


func stop_local(params: Dictionary):
	if not check_skill_valid():
		return
	
	var time := GameTime.get_unpaused_elapsed_time()
	var charge_time: float = time - data.start_time - get_startup()
	
	action.poll_continue = false
	action.poll_stop = false
	
	params.origin = tool.get_action_origin()
	params.charge = clamp(charge_time/SkillCharge.MAX_CHARGE_TIME, 0, 1)
	
	await get_tree().create_timer(get_endlag()).timeout
	
	if is_instance_valid(tool) and action.active:
		action.active = false
		tool.unlock()


func start_server(params: Dictionary):
	if not check_skill_valid():
		return
	
	call_replicated(start_replicated, params)


func continue_server(params: Dictionary):
	if not check_skill_valid():
		return
	
	call_replicated(continue_replicated, params)


func stop_server(params: Dictionary):
	if not check_skill_valid():
		return
	
	call_replicated(stop_replicated, params)
	
	var stats := MagicStats.stats[data.magic]
	var damage_multiplier = stats.damage * lerp(1.0, SkillCharge.DAMAGE_MULTIPLIER, params.charge)
	var speed_multiplier = stats.speed * lerp(1.0, SkillCharge.SPEED_MULTIPLIER, params.charge)
	var size_multiplier = stats.size * lerp(1.0, SkillCharge.SIZE_MULTIPLIER, params.charge)
	
	var origin: Vector3 = params.origin
	var direction: Vector3 = (params.target_position - params.origin).normalized()
	
	var excluded_rids := []
	var update_excluded_rids := func():
		excluded_rids.clear()
		for entity_id: String in Entity.current_entities:
			var entity = Entity.current_entities[entity_id]
			if entity == tool_user or not Entity.can_teams_damage(data.team, entity.team):
				excluded_rids.append(entity)
	update_excluded_rids.call()
	
	var start_time: float = GameTime.get_unpaused_elapsed_time()
	
	var space_state := tool.get_world_3d().direct_space_state
	
	var projectile_query_shape := SphereShape3D.new()
	projectile_query_shape.radius = base_projectile_radius * size_multiplier
	var projectile_query_params := PhysicsShapeQueryParameters3D.new()
	projectile_query_params.shape = projectile_query_shape
	projectile_query_params.exclude = excluded_rids
	
	var last_projectile_position: Vector3 = origin
	
	while is_skill_valid():
		var projectile_lifetime = GameTime.get_unpaused_elapsed_time() - start_time
		if projectile_lifetime > max_projectile_lifetime:
			break
		
		var stop = false
		
		var projectile_position = origin + (
			direction * base_projectile_speed * speed_multiplier * projectile_lifetime)
		
		projectile_query_params.motion = projectile_position - last_projectile_position
		projectile_query_params.transform = Transform3D(Basis.IDENTITY, last_projectile_position)
		update_excluded_rids.call()
		projectile_query_params.exclude = excluded_rids
		
		# stationary cast in case it starts the frame inside a target
		if space_state.intersect_shape(projectile_query_params, 1).size() > 0:
			last_projectile_position = projectile_position
			stop = true
			break
		
		var motion_cast = space_state.cast_motion(projectile_query_params)
		if motion_cast[0] < 1:
			last_projectile_position = (projectile_query_params.transform.origin
				+ projectile_query_params.motion * motion_cast[0])
			stop = true
			break
		
		if stop:
			break
		
		last_projectile_position = projectile_position
		
		await get_tree().physics_frame
	
	if not check_skill_valid():
		return
	
	# explode projectile
	
	var explode_position: Vector3 = last_projectile_position
	
	call_replicated(explode_projectile_replicated, explode_position)
	
	var hit_entities: Dictionary[Entity, bool] = {}
	
	var explosion_query_shape := SphereShape3D.new()
	explosion_query_shape.radius = base_explosion_radius * size_multiplier
	var explosion_query_params := PhysicsShapeQueryParameters3D.new()
	explosion_query_params.shape = explosion_query_shape
	explosion_query_params.transform = Transform3D(Basis.IDENTITY, explode_position)
	update_excluded_rids.call()
	explosion_query_params.exclude = excluded_rids
	
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
	
	var preview_pos: Vector3 = params.origin
	var preview_basis: Basis = Basis.looking_at(params.target_position - params.origin)
	if not data.get("hide_circle"):
		var circle: MagicCircle = MagicCircle.create_magic_circle(data.magic)
		circle.position = preview_pos
		circle.basis = preview_basis
		circle.scale = Vector3.ONE * 2 * base_projectile_radius * 1.5
		add_child(circle)
		circle.fade_in(get_startup()/2)
	
		data.magic_circle = circle
	else:
		var projectile: MagicProjectileVFX = MagicVFX.create_projectile_sphere(data.magic, base_projectile_radius)
		projectile.position = preview_pos
		projectile.basis = preview_basis
		add_child(projectile)
		
		data.charge_projectile = projectile


func continue_replicated(params: Dictionary):
	if not check_skill_valid():
		return
	
	var preview_pos: Vector3 = params.origin
	var target_delta: Vector3 = params.target_position - preview_pos
	var charge_size_multiplier: float = SkillCharge.get_size_multiplier(params.charge)
	if not data.get("hide_circle"):
		var circle: Node3D = data.magic_circle
		circle.position = preview_pos
		circle.basis = Basis.looking_at(target_delta, circle.basis.y)
		circle.scale = Vector3.ONE * 2 * base_projectile_radius * 1.5 * charge_size_multiplier
	else:
		var projectile: MagicProjectileVFX = data.projectile
		projectile.position = preview_pos
		projectile.basis = Basis.looking_at(target_delta)
		
		var stats := MagicStats.stats[data.magic]
		var size_multiplier = stats.size * SkillCharge.get_size_multiplier(params.charge)
		projectile.set_radius(base_projectile_radius * size_multiplier)


func stop_replicated(params: Dictionary):
	if not check_skill_valid():
		return
	
	var stats := MagicStats.stats[data.magic]
	var speed_multiplier = stats.speed * SkillCharge.get_speed_multiplier(params.charge)
	var size_multiplier = stats.size * SkillCharge.get_size_multiplier(params.charge)
	
	data.charge = params.charge
	
	var origin: Vector3 = params.origin
	var direction: Vector3 = (params.target_position - origin).normalized()
	
	var circle: MagicCircle = data.get("magic_circle")
	if circle:
		circle.fade_out(get_endlag()/2, get_endlag()/2)
		circle.faded_out.connect(circle.queue_free)
		data.erase("magic_circle")
	
	var projectile_radius = base_projectile_radius * size_multiplier
	
	var projectile: MagicProjectileVFX = data.get("charge_projectile")
	data.erase("charge_projectile")
	if not projectile:
		projectile = MagicVFX.create_projectile_sphere(data.magic, projectile_radius)
		projectile.visible = false
		(func():
			await get_tree().process_frame
			projectile.visible = true).call_deferred()
		add_child(projectile)
	data.projectile = projectile
	projectile.position = origin
	projectile.basis = Basis.looking_at(direction)
	
	var start_time: float = GameTime.get_unpaused_elapsed_time()
	
	while data.projectile and is_skill_valid():
		var projectile_lifetime: float = GameTime.get_unpaused_elapsed_time() - start_time
		if projectile_lifetime > max_projectile_lifetime:
			break
		
		var projectile_position = origin + (
			direction * base_projectile_speed * speed_multiplier * projectile_lifetime)
		projectile.global_position = projectile_position
		
		await get_tree().process_frame
	
	# projectile still exists is checked inside this function
	explode_projectile_replicated(origin + 
		direction * base_projectile_speed * speed_multiplier * max_projectile_lifetime)


@rpc("authority", "call_local")
func explode_projectile_replicated(explode_position: Vector3):
	if not check_skill_valid():
		return
	
	var projectile: MagicProjectileVFX = data.projectile
	
	# explosion already replicated
	if not projectile:
		return
	
	data.projectile = null
	
	var stats := MagicStats.stats[data.magic]
	var size_multiplier = stats.size * lerp(1.0, SkillCharge.SIZE_MULTIPLIER, data.charge)
	
	var explosion_radius = base_explosion_radius * size_multiplier
	
	projectile.fade_out()
	
	# explosion effects
	
	var explosion: MagicExplosionVFX = MagicVFX.create_explosion_sphere(data.magic, explosion_radius)
	explosion.position = explode_position
	add_child(explosion)
	
	explosion.fade_out.call_deferred()
	explosion.tree_exited.connect(queue_free)


func cancel():
	if not data.get("projectile"):
		queue_free()


func get_aimbot_target_position(params: Dictionary) -> Vector3:
	var target_entity: Entity = params.get("target_entity")
	if target_entity:
		var origin: Vector3 = params.origin
		var speed: float = base_projectile_speed * MagicStats.stats[data.magic].speed
		var target_origin: Vector3 = target_entity.position
		var target_velocity: Vector3 = target_entity.estimated_velocity
		return intersect_projectile(origin, speed, target_origin, target_velocity)
	else:
		push_error("params does not contain a target_entity to target " + str(params))
		return Vector3.ZERO
