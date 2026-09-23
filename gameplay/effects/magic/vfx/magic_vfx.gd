class_name MagicVFX
extends Node3D

const MODELED_PROJECTILE_RADIUS: float = 0.3
const MODELED_EXPLOSION_RADIUS: float = 2.5

enum AttackShape {SPHERE}


@export var magic_vfx_data = {}


## returns a value like "res://gameplay/effects/magic/vfx/magics/fire"
static func get_magic_vfx_path(magic: String) -> String:
	return (MagicVFX as GDScript).resource_path.replace("magic_vfx.gd", "magics/") + magic


static func create_basic_vfx(data: MagicVFXData) -> Node3D:
	var vfx := Node3D.new()
	
	var audio := AudioStreamPlayer3D.new()
	for property in MagicVFXData.base_magic_vfx_data.get_element_data("audio").get_dictionary():
		audio.set(property, data.get_element_data("audio").get_value(property))
	vfx.add_child(audio)
	
	var particles := CPUParticles3D.new()
	for property in MagicVFXData.base_magic_vfx_data.get_element_data("particles").get_dictionary():
		particles.set(property, data.get_element_data("particles").get_value(property))
	vfx.add_child(particles)
	
	return vfx


static func create_projectile_sphere(magic: String, radius: float) -> MagicVFX:
	#var projectile: Node3D = load(get_magic_vfx_path(magic) + \
		#"/%s_projectile.tscn" % magic).instantiate()
	
	var data := MagicVFXData.get_projectile_data(magic)
	var projectile = create_basic_vfx(data)
	
	if not projectile.get_script():
		projectile.set_script(MagicProjectileVFX)
	
	projectile.set_radius(radius)
	
	return projectile


static func create_explosion_sphere(magic: String, radius: float) -> MagicVFX:
	#var explosion = load(get_magic_vfx_path(magic) + "/%s_explosion.tscn" % magic).instantiate()
	#explosion.scale = Vector3.ONE * radius / MODELED_EXPLOSION_RADIUS
	
	var data := MagicVFXData.get_explosion_data(magic)
	var explosion = create_basic_vfx(data)
	
	if not explosion.get_script():
		explosion.set_script(MagicExplosionVFX)
	
	explosion.set_radius(radius)
	
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


func set_radius(radius: float):
	for child in get_children():
		if not child.has_meta("initial_scale"):
			child.set_meta("initial_scale", child.scale)
		child.scale = child.get_meta("initial_scale") * Vector3.ONE * radius * 2
		
		if child is CPUParticles3D:
			var particles = child as CPUParticles3D
			var mesh = particles.mesh.duplicate()
			particles.mesh = mesh
			if not mesh.has_meta("initial_size"):
				mesh.set_meta("initial_size", particles.mesh.size)
			mesh.size = mesh.get_meta("initial_size") * radius * 2
		elif child is AudioStreamPlayer3D:
			continue
