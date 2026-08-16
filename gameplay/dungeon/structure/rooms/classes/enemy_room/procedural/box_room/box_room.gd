@tool
class_name BoxRoom
extends EnemyRoom

@export var room_size := Vector3i(16, 6, 16):
	set(val):
		val = val.max(Vector3i(4, 4, 4))
		room_size = val
		if Engine.is_editor_hint():
			update_room()
@export var door_positions: Array[int] = [6, 6, 6, 6]:
	set(val):
		door_positions = val
		if Engine.is_editor_hint():
			update_room()
@export var generate_ceiling: bool = true:
	set(val):
		generate_ceiling = val
		if Engine.is_editor_hint():
			update_room()

enum {FRONT, BACK, LEFT, RIGHT}
enum {X_AXIS, Y_AXIS, Z_AXIS}


func _ready() -> void:
	super()


func initialize():
	super()
	
	var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
	collision_shape.shape = collision_shape.shape.duplicate()
	
	if Engine.is_editor_hint():
		update_room()


func update_room():
	#for child in $Props.get_children():
		#child.queue_free()
	
	var faces = ["Front", "Back", "Left", "Right"]
	for face_id in faces.size():
		var face: String = faces[face_id]
		
		# 0 for left/right, 1 for front/back
		var axis = Z_AXIS if face_id == FRONT or face_id == BACK else X_AXIS
		
		var side_length = room_size.x if axis == Z_AXIS else room_size.z
		var adjacent_side_length = room_size.z if axis == Z_AXIS else room_size.x
		var size_1 = door_positions[face_id]
		var size_2 = side_length - 2 - size_1 - DOOR_WIDTH + 1
		var height = room_size.y - 2
		
		# initialize positions as front face positions, then rotate
		var adjacent_axis_shift = -(adjacent_side_length/2.0 - 0.5)
		
		var pos_1 = Vector3(
			-(side_length/2.0 - 1) + size_1/2.0, 
			height/2.0, 
			adjacent_axis_shift
		)
		
		var pos_2 = Vector3(
			(side_length/2.0) - size_2/2.0, 
			height/2.0, 
			adjacent_axis_shift
		)
		
		var pos_3 = Vector3(
			-(side_length/2.0 - 1) + size_1 + 1, 
			2 + (height - 2)/2.0,
			adjacent_axis_shift
		)
		
		var door_pos = Vector3(
			-(side_length/2.0 - 1) + size_1 + 1, 
			0,
			-adjacent_side_length/2.0
		)
		
		var face_rotation_offset = (
			0.0 if face_id == FRONT 
			else PI if face_id == BACK 
			else PI/2 if face_id == LEFT 
			else -PI/2)
		var trans_1 = Transform3D(Basis.IDENTITY, snap_vector3(pos_1, 0.5)).rotated(Vector3.UP, face_rotation_offset)
		var trans_2 = Transform3D(Basis.IDENTITY, snap_vector3(pos_2, 0.5)).rotated(Vector3.UP, face_rotation_offset)
		var trans_3 = Transform3D(Basis.IDENTITY, snap_vector3(pos_3, 0.5)).rotated(Vector3.UP, face_rotation_offset)
		var door_trans = Transform3D(Basis.IDENTITY, snap_vector3(door_pos, 0.5)).rotated(Vector3.UP, face_rotation_offset)
		
		var wall_1: BlockPart = $Structure/Walls.get_node(face + "1")
		var wall_2: BlockPart = $Structure/Walls.get_node(face + "2")
		var wall_3: BlockPart = $Structure/Walls.get_node(face + "3")
		wall_1.block_size = Vector3(size_1, height, 1)
		wall_1.transform = trans_1
		wall_2.block_size = Vector3(size_2, height, 1)
		wall_2.transform = trans_2
		wall_3.block_size = Vector3(2, height - 2, 1)
		wall_3.transform = trans_3
		
		var door = $Doors.get_node(face)
		door.transform = door_trans
		
		#var torch: Node3D = WALL_TORCH.instantiate()
		#torch.transform = door_trans
		#torch.basis = torch.basis.rotated(Vector3.UP, PI)
		#torch.position += door_trans.basis.z + door_trans.basis.y * 3
		#$Props.add_child(torch)
		
	$Structure/Floor.block_size = Vector3(room_size.x, 1, room_size.z)
	
	var ceiling = $Structure.get_node_or_null("Ceiling")
	if generate_ceiling:
		if not ceiling:
			ceiling = $Structure/Floor.duplicate()
			ceiling.name = "Ceiling"
			$Structure.add_child(ceiling)
		ceiling.transform = Transform3D(Basis.IDENTITY, Vector3(0, room_size.y - 1.5, 0))
		ceiling.block_size = Vector3(room_size.x, 1, room_size.z)
	else:
		if ceiling:
			ceiling.queue_free()
	
	var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
	collision_shape.position = Vector3(0, room_size.y/2.0 - 1, 0)
	collision_shape.shape.size = room_size
	
	if initialized:
		var interior_collision_shape: CollisionShape3D = interior_area.get_node("CollisionShape3D")
		interior_collision_shape.position = collision_shape.position
		interior_collision_shape.shape.size = room_size - Vector3i.ONE * 2
