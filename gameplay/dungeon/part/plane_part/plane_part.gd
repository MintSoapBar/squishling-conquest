@tool
class_name PlanePart
extends Part


@export var plane_size: Vector2 = Vector2.ONE:
	set(value):
		plane_size = value
		if box_mesh and box_shape:
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
	var size = Vector3(plane_size.x, 0, plane_size.y)
	box_mesh.size = size
	box_shape.size = size
