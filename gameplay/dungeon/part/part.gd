@tool
@abstract
class_name Part
extends Node3D

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D


@export var material: Material = preload("uid://qlygdhst0g7t"):
	set(value):
		material = value
		if is_node_ready():
			update_material()


func _ready():
	mesh_instance = $MeshInstance3D
	collision_shape = $StaticBody3D/CollisionShape3D
	
	update_material()


func update_material() -> void:
	mesh_instance.set_surface_override_material(0, material)
