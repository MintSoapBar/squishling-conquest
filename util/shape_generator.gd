@tool
class_name ShapeGenerator


static var curve_1 = Curve.new()

static func _static_init() -> void:
	curve_1.add_point(Vector2(0, 1))


static func generate_circular_segment_from_angle(radius: float, half_angle: float, 
	depth: float, segments: int = 10, depth_curve: Curve = curve_1) -> ConvexPolygonShape3D:
	
	var verts: PackedVector3Array = []
	
	var end_position = cos(half_angle)
	
	for i in range(segments + 1):
		var t := float(i) / segments
		var cur_angle: float = lerp(-half_angle, half_angle, t)
		
		var x_pos = radius * cos(cur_angle)
		var y_pos = radius * sin(cur_angle)
		
		var curved_depth: float = 0.5 * depth * depth_curve.sample_baked(
			(1 - x_pos) / (1 - end_position))
		
		verts.append(Vector3(x_pos, y_pos, -curved_depth))
		verts.append(Vector3(x_pos, y_pos, curved_depth))
	
	var polygon := ConvexPolygonShape3D.new()
	
	polygon.points = verts
	
	return polygon


static func generate_circular_sector_from_angle(radius: float, angle0: float, angle1: float, 
	depth: float, segments: int = 10, depth_curve: Curve = curve_1) -> ConvexPolygonShape3D:
	
	var verts: PackedVector3Array = []
	
	var end_position: float = min(cos(angle0), cos(angle1))
	
	for i in range(segments + 1):
		var t := float(i) / segments
		var cur_angle: float = lerp(angle0, angle1, t)
		
		var x_pos = radius * cos(cur_angle)
		var y_pos = radius * sin(cur_angle)
		
		var curved_depth: float = 0.5 * depth * depth_curve.sample_baked(
			(1 - x_pos) / (1 - end_position))
		
		verts.append(Vector3(x_pos, y_pos, -curved_depth))
		verts.append(Vector3(x_pos, y_pos, curved_depth))
		
	var curved_depth_center: float = 0.5 * depth * depth_curve.sample_baked(
		1 / (1 - end_position))
	
	verts.append(Vector3(0, 0, -curved_depth_center))
	verts.append(Vector3(0, 0, curved_depth_center))
	
	var polygon := ConvexPolygonShape3D.new()
	polygon.points = verts
	
	return polygon
