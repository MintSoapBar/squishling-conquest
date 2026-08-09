@tool
class_name BlockPart
extends Part


@export var block_size: Vector3 = Vector3.ONE:
	set(value):
		block_size = value
		if Engine.is_editor_hint() and box_mesh and box_shape:
			resize()


var box_mesh: BoxMesh
var box_shape: BoxShape3D


func _ready() -> void:
	super()
	
	box_mesh = BoxMesh.new()
	mesh_instance.mesh = box_mesh
	
	box_shape = BoxShape3D.new()
	collision_shape.shape = box_shape
	
	resize()


func resize() -> void:
	box_mesh.size = block_size
	box_shape.size = block_size.abs()
