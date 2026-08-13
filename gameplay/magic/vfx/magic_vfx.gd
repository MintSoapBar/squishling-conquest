class_name MagicVFX
extends Node3D

const MODELED_PROJECTILE_RADIUS: float = 0.3
const MODELED_EXPLOSION_RADIUS: float = 2.5

enum AttackShape {SPHERE}


static func get_magic_vfx_path(magic: String) -> String:
	return (MagicVFX as GDScript).resource_path.replace("magic_vfx.gd", "magics/") + magic


static func create_projectile_sphere(magic: String, radius: float) -> MagicVFX:
	var projectile: Node3D = load(get_magic_vfx_path(magic) + "/%s_projectile.tscn" % magic).instantiate()
	projectile.scale = Vector3.ONE * radius / MODELED_PROJECTILE_RADIUS
	
	if not projectile.get_script():
		projectile.set_script(MagicProjectileVFX)
	
	projectile.set_radius(radius)
	
	return projectile


static func create_explosion_sphere(magic: String, radius: float) -> MagicVFX:
	var explosion = load(get_magic_vfx_path(magic) + "/%s_explosion.tscn" % magic).instantiate()
	explosion.scale = Vector3.ONE * radius / MODELED_EXPLOSION_RADIUS
	
	if not explosion.get_script():
		explosion.set_script(MagicExplosionVFX)
	
	for child in explosion.get_children():
		if child is CPUParticles3D:
			var particles = child as CPUParticles3D
			particles.mesh = particles.mesh.duplicate()
			particles.mesh.size *= radius / MODELED_EXPLOSION_RADIUS
		elif child is AudioStreamPlayer3D:
			child.autoplay = true
	
	return explosion


func fade_out():
	var state = {active_children = 0}
	
	var decrement_active_projectile_children := func():
		state.active_children -= 1
		if state.active_children <= 0 and is_instance_valid(self):
			queue_free()
	
	for child in get_children():
		if child is CPUParticles3D:
			var particles := child as CPUParticles3D
			if not particles.one_shot:
				particles.emitting = false
			state.active_children += 1
			particles.finished.connect(decrement_active_projectile_children, CONNECT_ONE_SHOT)
		elif child is AudioStreamPlayer3D:
			var audio := child as AudioStreamPlayer3D
			state.active_children += 1
			if audio.stream.loop:
				var audio_fade_out_tween = create_tween()
				audio_fade_out_tween.tween_property(audio, "volume_db", audio.volume_db - 30, 1)
				audio_fade_out_tween.finished.connect(decrement_active_projectile_children, CONNECT_ONE_SHOT)
			else:
				audio.finished.connect(decrement_active_projectile_children, CONNECT_ONE_SHOT)
		elif child is MeshInstance3D:
			child.queue_free()
	if state.active_children <= 0:
		queue_free()
