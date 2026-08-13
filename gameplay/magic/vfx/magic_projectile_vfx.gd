@tool
class_name MagicProjectileVFX
extends MagicVFX

@export var test: bool = false:
	set(val):
		animating = false
		await get_tree().process_frame
		await get_tree().process_frame
		animate_test()
@export var distance: float = 30
@export var lifetime: float = 1
@export var rotation_speed: Vector3 = Vector3(0, 0, 0)

var animating = true


func _ready() -> void:
	rotation += Vector3(
		randf_range(-rotation_speed.x, rotation_speed.x), 
		randf_range(-rotation_speed.y, rotation_speed.y), 
		randf_range(-rotation_speed.z, rotation_speed.z), 
	)


func _process(delta: float) -> void:
	rotation += rotation_speed * PI * delta


func animate_test() -> void:
	var particles: CPUParticles3D = get_node_or_null("Particles3D")
	var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
	
	var start_position = position
	animating = true
	
	var start_time: float = GameTime.get_unpaused_elapsed_time()
	var cur_time = start_time
	
	position = start_position + Vector3(0, 0, distance)
	particles.emitting = true
	if mesh_instance:
		mesh_instance.visible = true
	while cur_time - start_time < lifetime and animating == true:
		position = start_position + Vector3(0, 0, distance * (1 - (cur_time - start_time)/lifetime))
		await get_tree().process_frame
		cur_time = GameTime.get_unpaused_elapsed_time()
	
	position = start_position
	particles.emitting = false
	if mesh_instance:
		mesh_instance.visible = false
	
	animating = false


func set_radius(radius: float):
	for child in get_children():
		child.scale = Vector3.ONE * radius / MODELED_PROJECTILE_RADIUS
		if child is CPUParticles3D:
			var particles = child as CPUParticles3D
			var mesh = particles.mesh.duplicate()
			particles.mesh = mesh
			if not mesh.has_meta("initial_size"):
				mesh.set_meta("initial_size", particles.mesh.size)
			mesh.size = mesh.get_meta("initial_size") * radius / MODELED_PROJECTILE_RADIUS
		elif child is AudioStreamPlayer3D:
			continue
