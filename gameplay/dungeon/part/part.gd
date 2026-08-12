@tool
@abstract
class_name Part
extends Node3D


@export var material: Material = preload("uid://qlygdhst0g7t"):
	set(value):
		material = value
		if is_node_ready():
			update_material()

var substitute := func(node: Node, new_parent: Node, new_name: String, new_transform: Transform3D):
	name = &"DO NOT SET ANY NODE'S NAME TO THIS STRING. BAU BAU!"
	new_parent.add_child(node)
	node.name = new_name
	node.transform = new_transform
	node.owner = new_parent.owner
	for child in node.get_children():
		child.owner = new_parent.owner
@export var to_localized_scene: bool = false:
	set(val):
		to_localized_scene = val
		if Engine.is_editor_hint():
			scene_file_path = ""
			var root = get_tree().get_edited_scene_root()
			if not is_instance_valid(root):
				root = get_tree().current_scene
			set_owner_recursive(self, root)
			set_script(null)
			
@export var to_mesh: bool = false:
	set(val):
		to_mesh = val
		if Engine.is_editor_hint() and mesh_instance:
			var new_mesh = mesh_instance.duplicate()
			substitute.call_deferred(new_mesh, get_parent(), name, transform)
			queue_free()
@export var to_static_body: bool = false:
	set(val):
		to_static_body = val
		if Engine.is_editor_hint() and static_body:
			var new_body = static_body.duplicate()
			substitute.call_deferred(new_body, get_parent(), name, transform)
			queue_free()


var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D


static func set_owner_recursive(node: Node, new_owner: Node) -> void:
	node.owner = new_owner
	for child in node.get_children():
		set_owner_recursive(child, new_owner)


func _ready():
	mesh_instance = $MeshInstance3D
	static_body = $StaticBody3D
	collision_shape = $StaticBody3D/CollisionShape3D
	
	update_material()


func update_material() -> void:
	mesh_instance.set_surface_override_material(0, material)
