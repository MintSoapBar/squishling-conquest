@tool
class_name Corridor
extends Structure

@export var length: int = 4:
	set(value):
		length = value
		if Engine.is_editor_hint():
			update_corridor()

@export var height: int = 6:
	set(value):
		height = value
		if Engine.is_editor_hint():
			update_corridor()

@export var width: int = 6:
	set(value):
		width = value
		if Engine.is_editor_hint():
			update_corridor()

@export var generate_ceiling: bool = true:
	set(value):
		length = value
		if Engine.is_editor_hint():
			update_corridor()


func initialize() -> void:
	super()
	
	attachment_points.append($AttachmentPoints/Front)
	attachment_points.append($AttachmentPoints/Back)


func update_corridor():
	$Structure/Floor.block_size = Vector3(width, 1, length)
	$Structure/LeftWall.block_size = Vector3(1, height, length)
	$Structure/RightWall.block_size = Vector3(1, height, length)
	$Structure/LeftWall.position = Vector3(-(width/2.0 - 0.5), height/2.0 - 1, 0)
	$Structure/RightWall.position = Vector3((width/2.0 - 0.5), height/2.0 - 1, 0)
	
	$AttachmentPoints/Front.position = Vector3(0, 0, -length/2.0)
	$AttachmentPoints/Back.position = Vector3(0, 0, length/2.0)
	
	$Area3D/CollisionShape3D.shape.size = Vector3(width, height, length)
	
	var ceiling = $Structure.get_node_or_null("Ceiling")
	if generate_ceiling:
		if not ceiling:
			ceiling = $Structure/Floor.duplicate()
			ceiling.name = "Ceiling"
			$Structure.add_child(ceiling)
		ceiling.transform = Transform3D(Basis.IDENTITY, Vector3(0, height - 1.5, 0))
		ceiling.block_size = Vector3(width, 1, length)
	else:
		if ceiling:
			ceiling.queue_free()
	
	generate_interior_area()
	interior_area.get_node("CollisionShape3D").shape.size.z = length
