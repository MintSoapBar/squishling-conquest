@abstract
class_name Sprite
extends Node3D

var entity: Entity

var tool: Tool

@onready var status_bar_billboard: StatusBarBillboard = $StatusBarBillboard
@onready var model: Node3D = $Model
@onready var hand: Node3D = $Hand

var default_hand_transform: Transform3D
var update_hand_transform_per_frame: bool = true
var recalculate_hand_transform_per_frame: bool = true
var target_hand_transform: Transform3D
var point_direction: Vector3
var point_distance: float
var point_direction_up: Vector3
var point_lerp_alpha: float

func _ready() -> void:
	default_hand_transform = hand.transform
	point_at(Vector3.ZERO)


func lerp_dt(a: Variant, b: Variant, weight: Variant, delta_time: float):
	var per_sec := pow(1.0 - weight, 60)
	var decay := pow(per_sec, delta_time)
	return lerp(a, b, 1.0 - decay)


func _process(delta: float) -> void:
	if recalculate_hand_transform_per_frame:
		target_hand_transform = calculate_target_hand_transform()
	if update_hand_transform_per_frame:
		hand.transform = lerp_dt(hand.transform, target_hand_transform, point_lerp_alpha, delta)


@rpc("any_peer", "call_local")
func equip_tool(new_tool):
	if tool:
		tool.queue_free()
	
	tool = new_tool
	
	if tool:
		tool.tool_user = entity
		hand.add_child(tool)
		
		var handle: Node3D = tool.get_node_or_null("Handle")
		if handle:
			tool.position = -handle.position


func point_at(direction: Vector3 = Vector3.ZERO, distance: float = 1, 
	direction_up: Vector3 = Vector3.UP, lerp_alpha: float = 0.3):
	
	point_direction = direction
	point_distance = distance
	point_direction_up = direction_up
	point_lerp_alpha = lerp_alpha
	
	target_hand_transform = calculate_target_hand_transform()


func point_at_local(direction: Vector3 = Vector3.ZERO, distance: float = 1, 
	direction_up: Vector3 = Vector3.UP, lerp_alpha: float = 0.3):
	
	point_at(global_basis * direction, distance, direction_up, lerp_alpha)


func swing(direction: Vector3 = Vector3.ZERO, swing_direction_up: Vector3 = Vector3.UP,
	half_angle: float = PI/2, distance: float = 1,
	swing_time: float = 0.5, hold_time: float = 0.5):
	
	var start_time := GameTime.get_unpaused_scaled_elapsed_time()
	var cur_time := start_time
	
	update_hand_transform_per_frame = false
	recalculate_hand_transform_per_frame = false
	point_distance = distance
	
	while true:
		var t: float = clamp((cur_time - start_time) / swing_time, 0, 1)
		var cur_angle = lerp(-half_angle, half_angle, t)
		
		point_direction = direction.rotated(swing_direction_up, cur_angle)
		point_direction_up = point_direction.cross(swing_direction_up)
		
		target_hand_transform = calculate_target_hand_transform()
		hand.transform = target_hand_transform
		
		if t >= 1:
			break
		
		await get_tree().process_frame
		cur_time = GameTime.get_unpaused_scaled_elapsed_time()
	
	await get_tree().create_timer(hold_time).timeout
	
	update_hand_transform_per_frame = true
	recalculate_hand_transform_per_frame = true
	point_direction = Vector3.ZERO
	target_hand_transform = calculate_target_hand_transform()


func calculate_target_hand_transform() -> Transform3D:
	if point_direction.is_equal_approx(Vector3.ZERO):
		return default_hand_transform
	else:
		var hand_basis = Basis.looking_at(point_direction, point_direction_up)
		var hand_position = get_chest_origin() - hand_basis.z * point_distance
		hand_basis *= Basis.from_euler(Vector3(-PI/2, 0, 0))
		var hand_global_transform = Transform3D(hand_basis, hand_position)
		return global_transform.inverse() * hand_global_transform


func get_chest_origin() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)
