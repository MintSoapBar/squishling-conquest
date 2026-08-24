@tool
class_name crate_sprite
extends Node3D

var modeled_size: Vector3 = Vector3(2, 2, 2)

@export var size: Vector3 = Vector3(2, 2, 2):
	set(val):
		size = val
		if is_node_ready():
			update_size()

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $Collider/CollisionShape
var box_shape: BoxShape3D


func _ready() -> void:
	box_shape = collision_shape.shape.duplicate()
	collision_shape.shape = box_shape
	
	update_size()


func update_size():
	model.scale = size / modeled_size
	box_shape.size = size
