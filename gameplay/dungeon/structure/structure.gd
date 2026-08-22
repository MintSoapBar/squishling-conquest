@abstract
class_name Structure
extends Node3D

signal player_entered_area(player: Player)
signal player_entered_interior_area(player: Player)
signal state_changed(new_state: StructureState)

enum StructureState {UNEXPLORED, ACTIVE, EXPLORED}

var area: Area3D
var interior_area: Area3D
var attachment_points: Array[Node3D] = []

var state: StructureState = StructureState.UNEXPLORED

var biome: String = "cellar"
var world: int = 1
var level: int = 1


var area_leeway_margin = 2 * ProjectSettings.get_setting(
	"physics/jolt_physics_3d/collisions/collision_margin_fraction")
var interior_area_margin: float = 1


static func snap_vector3(v: Vector3, step: float) -> Vector3:
	return (v / step).round() * step


static func snap_transform3d(t: Transform3D, origin_step: float, rotation_step: float) -> Transform3D:
	var new_t = Transform3D.IDENTITY
	new_t.origin = Structure.snap_vector3(t.origin, origin_step)
	new_t.basis = Basis.from_euler(Structure.snap_vector3(t.basis.get_euler(), rotation_step))
	return new_t


static func get_shape_floor_area(shape: Shape3D) -> float:
	if shape is BoxShape3D:
		var box_shape = shape as BoxShape3D
		return box_shape.size.x * box_shape.size.z
	else:
		assert(false, str(shape) + " shape is not supported yet for getting floor area")
		return 0


static func get_shape_random_floor_position(shape: Shape3D) -> Vector3:
	if shape is BoxShape3D:
		var box_shape := shape as BoxShape3D
		
		var half_x := box_shape.size.x * 0.5
		var half_z := box_shape.size.z * 0.5

		return Vector3(
			randf_range(-half_x, half_x),
			-box_shape.size.y * 0.5,
			randf_range(-half_z, half_z)
		)
	else:
		assert(false, str(shape) + " shape is not supported yet for getting random floor position")
		return Vector3.ZERO


static func resize_shape(shape: Shape3D, boundary_change: float):
	if shape is BoxShape3D:
		var box_shape := shape as BoxShape3D
		box_shape.size = box_shape.size + Vector3.ONE * boundary_change * 2
	else:
		assert(false, str(shape) + " shape is not supported yet for resizing")


var initialized = false
func _ready() -> void:
	if not initialized:
		initialize()


func initialize() -> void:
	area = $Area3D
	
	area.collision_layer = Collision.STRUCTURE_AREA_LAYER
	area.collision_mask = Collision.STRUCTURE_AREA_MASK
	
	for collision_shape: CollisionShape3D in area.get_children():
		collision_shape.shape = collision_shape.shape.duplicate()
	
	generate_interior_area()
	
	area.body_entered.connect(on_area_body_entered)
	
	initialized = true


func get_data() -> Dictionary:
	var data = {}
	data.state = state
	return data


func load_data(structure_data := {}):
	set_state(structure_data.get("state", StructureState.UNEXPLORED))


func on_area_body_entered(body: Node3D):
	if body is Player:
		player_entered_area.emit(body)


func on_interior_area_body_entered(body: Node3D):
	if body is Player:
		player_entered_interior_area.emit(body)
		
		if Dungeon.is_server():
			set_state.rpc(StructureState.EXPLORED)


func get_area_query_params() -> Array[PhysicsShapeQueryParameters3D]:
	var arr: Array[PhysicsShapeQueryParameters3D] = []
	
	for collision_shape: CollisionShape3D in area.get_children():
		var params = PhysicsShapeQueryParameters3D.new()
		params.transform = collision_shape.transform
		params.collide_with_areas = true
		params.collide_with_bodies = false
		params.collision_mask = Collision.STRUCTURE_AREA_LAYER
		
		var shape = collision_shape.shape.duplicate()
		resize_shape(shape, -area_leeway_margin)
		
		params.shape = shape
		
		arr.push_back(params)
	
	return arr


@rpc("authority", "call_local")
func set_state(new_state: StructureState):
	state = new_state
	state_changed.emit(state)


func is_colliding(space_state: PhysicsDirectSpaceState3D, _transform: Transform3D = transform):
	for query: PhysicsShapeQueryParameters3D in get_area_query_params():
		query.transform = _transform * query.transform
		var result = space_state.intersect_shape(query)
		if result.size() > 0:
			return true
	return false


func generate_interior_area():
	if interior_area:
		interior_area.queue_free()
	
	interior_area = area.duplicate()
	interior_area.name = "InteriorArea3D"
	
	for collision_shape: CollisionShape3D in interior_area.get_children():
		collision_shape.shape = collision_shape.shape.duplicate()
		resize_shape(collision_shape.shape, -interior_area_margin)
	
	add_child(interior_area)
	interior_area.body_entered.connect(on_interior_area_body_entered)


func get_interior_floor_area() -> float:
	assert(interior_area, "interior_area must exist before calling get interior floor area")
	
	var floor_area = 0
	
	for collision_shape: CollisionShape3D in interior_area.get_children():
		floor_area += get_shape_floor_area(collision_shape.shape)
	
	return floor_area


func get_random_floor_position() -> Vector3:
	assert(interior_area, "interior_area must exist before calling get random floor position")
	
	var shape_info: Array[Dictionary] = []

	for child: CollisionShape3D in interior_area.get_children():
		shape_info.append({
			shape = child.shape,
			transform = child.global_transform,
			weight = get_shape_floor_area(child.shape),
		})

	if shape_info.is_empty():
		assert(false, "No collision shapes in interior_area")
		return Vector3.ZERO

	var total_weight := 0.0
	for info in shape_info:
		total_weight += info.weight

	var choice := randf() * total_weight
	var selected_info = shape_info[0]

	for info in shape_info:
		choice -= info.weight
		if choice <= 0:
			selected_info = info
			break
	
	var selected_transform := selected_info.transform as Transform3D
	var random_pos = get_shape_random_floor_position(selected_info.shape)
	return selected_transform * random_pos
