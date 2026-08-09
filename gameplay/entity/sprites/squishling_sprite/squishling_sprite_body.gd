class_name SquishlingSpriteBody
extends MeshInstance3D

signal stretched

@onready var left_eye: MeshInstance3D = $LeftEye
@onready var right_eye: MeshInstance3D = $RightEye

var left_eye_default_pos: Vector3
var right_eye_default_pos: Vector3

var entity: Entity

var bottom_vertex_height: float = -0.7

var wobble_strength: float = 0.02
var wobble_speed: float = 5.0

var wobble_y_multiplier: float = 1.0
var wobble_x_multiplier: float = 0.0
var wobble_z_multiplier: float = 0.0

var stretch_multiplier: float = 0.5

var animation_time: float = 0

var last_position: Vector3
var last_velocity: Vector3

var smooth_acceleration: Vector3
var target_acceleration: Vector3

var target_velocity: Vector3
var smooth_velocity: Vector3

var target_stretch: float
var smooth_stretch: float
var stretch_scale: float

var smooth_stretch_direction: Vector3

var body_shader: ShaderMaterial = material_override.duplicate()

@onready var shield := $Shield

func _ready():
	material_override = body_shader
	
	last_position = global_position
	last_velocity = Vector3(0, 0, 0)
	
	left_eye_default_pos = left_eye.position
	right_eye_default_pos = right_eye.position
	
	body_shader.set_shader_parameter("wobble_strength", wobble_strength)
	body_shader.set_shader_parameter("wobble_speed", wobble_speed)
	
	body_shader.set_shader_parameter("wobble_y_multiplier", wobble_y_multiplier)
	body_shader.set_shader_parameter("wobble_x_multiplier", wobble_x_multiplier)
	body_shader.set_shader_parameter("wobble_z_multiplier", wobble_z_multiplier)


func _process(delta):
	if not entity:
		return
	
	animation_time = Time.get_ticks_msec() / 1000.0
	
	var cur_pos = entity.global_position
	var entity_velocity: Vector3 = (cur_pos - last_position) / delta
	if (not Entity.network 
			or Entity.network.is_multiplayer_connected() 
			and entity.get_multiplayer_authority() == multiplayer.get_unique_id()):
		
		entity_velocity = entity.velocity
	
	var velocity: Vector3 = global_basis.inverse() * entity_velocity
	var acceleration: Vector3 = velocity - last_velocity
	
	target_acceleration *= 0.9
	target_acceleration += acceleration
	smooth_acceleration = lerp(smooth_acceleration, target_acceleration, 0.1)
	
	target_velocity *= 0.9
	target_velocity += velocity
	smooth_velocity = lerp(smooth_velocity, target_velocity, 0.1)
	
	#prints("%+.2f, %+.2f" % [target_acceleration.y, smooth_acceleration.y])
	
	last_velocity = velocity
	last_position = cur_pos
	
	# stretch direction
	
	var dot_last_stretch_dir_accel = smooth_acceleration.normalized().dot(smooth_stretch_direction)
	if dot_last_stretch_dir_accel < -0.93:
		smooth_stretch_direction = smooth_acceleration.normalized()
	elif dot_last_stretch_dir_accel < 1:
		smooth_stretch_direction = smooth_stretch_direction.normalized().slerp( 
			smooth_acceleration.normalized(), 0.05)
	
	# stretch raw
	
	target_stretch *= 0.8
	if smooth_velocity.length() > 0:
		target_stretch += 0.1 * smooth_acceleration.dot(smooth_velocity) / smooth_velocity.length()
	else:
		target_stretch += 0.1 * smooth_acceleration.length()
	smooth_stretch = lerp(smooth_stretch, target_stretch, 0.1)
	
	# stretch to scale
	
	var smooth_stretch_modified = clamp(smooth_stretch * stretch_multiplier, -INF, 2)
	if smooth_stretch < 0:
		# make vertical squish more apparent
		smooth_stretch_modified *= abs(smooth_stretch_direction.y ** 4) + 1
		smooth_stretch_modified = -sqrt(-smooth_stretch_modified)
	
	if smooth_stretch >= 0:
		stretch_scale = (smooth_stretch_modified + 1)
	else:
		stretch_scale = (2) ** smooth_stretch_modified
	
	# shader params
	
	body_shader.set_shader_parameter("time", animation_time)
	body_shader.set_shader_parameter("stretch_direction", smooth_stretch_direction)
	body_shader.set_shader_parameter("stretch_scale", stretch_scale)
	
	shield.stretch_direction = smooth_stretch_direction
	shield.stretch_scale = stretch_scale
	
	# repostion nodes
	
	var bottom_pos = get_deformed_vertex_pos(Vector3(0, bottom_vertex_height, 0), Vector3(0, -1, 0),
		animation_time, smooth_stretch_direction, stretch_scale)
	
	position = Vector3(0, -bottom_pos.y + bottom_vertex_height, 0)
	
	var left_eye_pos = get_deformed_vertex_pos(left_eye_default_pos, left_eye_default_pos)
	left_eye.position = left_eye_pos
	
	var right_eye_pos = get_deformed_vertex_pos(right_eye_default_pos, right_eye_default_pos)
	right_eye.position = right_eye_pos
	
	stretched.emit()


func set_color(color: Color):
	#body_shader.set_shader_parameter("multiply_color", lerp(color, Color.WHITE, 0.5))
	body_shader.set_shader_parameter("multiply_color", color)
	body_shader.set_shader_parameter("emission_color", color)
	
	shield.core_color = color
	shield.core_emission = color
	
	var plates_color = Color.from_hsv(
		fmod(color.h - 0.33, 1), 
		color.s + 0.5, 
		color.v + 0.5, 
		1
	)
	shield.plates_color = plates_color
	shield.plates_emission = plates_color

func get_deformed_vertex_pos(vertex: Vector3, normal: Vector3 = Vector3.ZERO, 
	time: float = animation_time, 
	stretch_dir: Vector3 = smooth_stretch_direction, 
	_stretch_scale: float = stretch_scale) -> Vector3:
	
	if normal == Vector3.ZERO:
		normal = vertex.normalized()
	
	var projection = (vertex.dot(stretch_dir)) * stretch_dir
	var parallel = vertex - projection
	
	var v_stretched = parallel * (1.0 / sqrt(_stretch_scale)) + projection * _stretch_scale
	
	var noise = -sin(v_stretched.y * wobble_y_multiplier 
	+ v_stretched.x * wobble_x_multiplier 
	+ v_stretched.z * wobble_z_multiplier 
	+ (time - 0.65) * wobble_speed) * wobble_strength;
	
	return v_stretched + (normal * noise)


func lerp_dt(a: Variant, b: Variant, weight: Variant, delta_time: float):
	var per_sec := pow(1.0 - weight, 60)
	var decay := pow(per_sec, delta_time)
	return lerp(a, b, 1.0 - decay)


func slerp_dt(a: Vector3, b: Vector3, weight: Variant, delta_time: float):
	var per_sec := pow(1.0 - weight, 60)
	var decay := pow(per_sec, delta_time)
	return a.slerp(b, 1.0 - decay)
