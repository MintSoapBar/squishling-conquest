@tool
class_name Gate
extends Node3D

signal player_entered(player: Player)

@export var color: Color = Color(0, 0, 0):
	set(val):
		color = val
		if mesh_material and particle_material:
			update_color()

@onready var area: Area3D = $Area3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var cpu_particles: CPUParticles3D = $CPUParticles3D
var mesh_material: StandardMaterial3D
var particle_material: StandardMaterial3D


func _ready() -> void:
	area.collision_layer = 0
	area.collision_mask = Collision.ENTITY_LAYER
	area.body_entered.connect(on_area_body_entered)
	
	mesh_material = mesh_instance.get_surface_override_material(0).duplicate()
	mesh_instance.set_surface_override_material(0, mesh_material)
	
	particle_material = cpu_particles.mesh.surface_get_material(0).duplicate()
	cpu_particles.mesh.surface_set_material(0, particle_material)
	
	update_color()


func on_area_body_entered(body: Node3D):
	if body is Player:
		player_entered.emit(body)


func update_color():
	mesh_material.albedo_color = color
	particle_material.albedo_color = color
