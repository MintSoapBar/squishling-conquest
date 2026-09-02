@tool
class_name CrescentMesh
extends MeshInstance3D

@export var test_update: bool = false:
	set(val):
		test_update = val
		if test_update and Engine.is_editor_hint() and is_node_ready():
			update()
		test_update = false

@export_category("Dimensions")
@export var radius: float = 1:
	set(val):
		radius = val
		if Engine.is_editor_hint() and is_node_ready():
			update()
@export var depth: float = 0.1:
	set(val):
		depth = val
		if Engine.is_editor_hint() and is_node_ready():
			update()
@export var depth_curve: Curve = Curve.new():
	set(val):
		depth_curve = val
		if Engine.is_editor_hint() and is_node_ready():
			update()

@export_category("Fill")
@export var end_angle: float = 2.0/3 * PI:
	set(val):
		end_angle = val
		if end_angle != acos(end_position):
			end_position = cos(end_angle)
			if Engine.is_editor_hint() and is_node_ready():
				update()
@export var end_position: float = -0.5:
	set(val):
		end_position = val
		if end_position != cos(end_angle):
			end_angle = acos(end_position)
			if Engine.is_editor_hint() and is_node_ready():
				update()
@export var thickness: float = 0.3:
	set(val):
		thickness = val
		if Engine.is_editor_hint() and is_node_ready():
			update()

@export_category("Meshing")
@export var segments: int = 16:
	set(val):
		segments = val
		if Engine.is_editor_hint() and is_node_ready():
			update()


func _ready() -> void:
	update()


func curve_lerp_weight(x: float) -> float:
	return 0.5 * sin(PI * (x - 0.5)) + 0.5


func update() -> void:
	var verts: Array[Vector2] = []
	
	for i in range(segments + 1):
		var t := float(i) / segments
		var cur_angle: float = lerp(-end_angle, end_angle, t)

		verts.append(Vector2(cos(cur_angle), sin(cur_angle)))
	
	var segment_length: float = (2*end_angle / segments)
	# https://www.desmos.com/calculator/l1bysa3egd <-- cutout_center = h
	var cutout_center = (2*thickness - thickness**2) \
		/ (-2 + 2*thickness + 2*end_position)
	var cutout_radius: float = (1 - thickness) - cutout_center
	
	var cutout_end_angle: float = acos(end_position - cutout_center)
	var cutout_circumference: float = 2 * PI * cutout_radius
	var cutout_sector_circumference: float = cutout_circumference * cutout_end_angle/PI
	var cutout_segments: int = int(cutout_sector_circumference / segment_length) + 1
	
	for i in range(cutout_segments - 1, 0, -1):
		var t := float(i) / cutout_segments
		var cur_angle: float = lerp(-cutout_end_angle, cutout_end_angle, t)
		
		verts.append(Vector2(
			cutout_center + cutout_radius * cos(cur_angle), 
			cutout_radius * sin(cur_angle)
		))
	
	# triangulate
	
	var indices := Geometry2D.triangulate_polygon(
		PackedVector2Array(verts)
	)

	if indices.is_empty():
		mesh = null
		return
	
	# build array mesh
	
	var verts_num = verts.size()
	
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var triangles := PackedInt32Array()
	
	positions.resize(verts_num*2)
	normals.resize(verts_num*2)
	uvs.resize(verts_num*2)
	
	# convert polygon vertices to 3d vertices and populate ArrayMesh arrays
	
	for i in verts_num:
		var vertex = verts[i]
		
		var curved_depth: float = 0.5 * depth * depth_curve.sample_baked(
			(1 - vertex.x) / (1 - end_position))
		
		positions[i] = Vector3(radius * vertex.x, radius * vertex.y, curved_depth)
		normals[i] = Vector3(0, 1, 0)
		
		positions[i + verts_num] = Vector3(radius * vertex.x, radius * vertex.y, -curved_depth)
		normals[i + verts_num] = Vector3(0, -1, 0)

		uvs[i] = Vector2(
			vertex.x * 0.5 + 0.5,
			vertex.y * 0.5 + 0.5
		)
		uvs[i + verts_num] = uvs[i]
	
	for index in indices:
		triangles.append(index)
	for i in range(indices.size() - 1, -1, -1):
		triangles.append(verts.size() + indices[i])
	
	for i in verts.size():
		triangles.append(i)
		triangles.append(i + verts.size())
		triangles.append((i + 1) % verts.size() + verts.size())
		
		triangles.append(i)
		triangles.append((i + 1) % verts.size() + verts.size())
		triangles.append((i + 1) % verts.size())

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = triangles

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)

	mesh = array_mesh
