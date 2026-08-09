extends CollisionShape3D


static func find_parent_of_type(node: Node, type: Variant) -> Node:
	var current = node.get_parent()

	while current:
		if is_instance_of(current, type):
			return current
		current = current.get_parent()

	return null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reparent_to_collision_object_3d.call_deferred()


func reparent_to_collision_object_3d() -> void:
	var old_parent := get_parent()
	var new_parent := find_parent_of_type(self, CollisionObject3D)
	var old_transform := transform
	reparent(new_parent)
	
	var remote_transform = RemoteTransform3D.new()
	remote_transform.transform = old_transform
	remote_transform.name = self.name + "RemoteTransform3D"
	old_parent.add_child(remote_transform)
	remote_transform.remote_path = remote_transform.get_path_to(self)
