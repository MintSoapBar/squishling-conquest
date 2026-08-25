class_name OrbitalCamera
extends Node3D

signal camera_translated
signal camera_rotated
signal first_person_changed(bool)
signal mouse_lock_changed(bool)
signal camera_lock_changed(bool)
signal camera_temp_lock_changed(bool)

@export_category("General Settings")
@export var min_distance: float = 0.0
@export var max_distance: float = 2048.0
@export var sensitivity: float = 0.003
@export var position_lerp_alpha: float = 0.3
@export var camera_third_person_offset: Vector3 = Vector3(0, 0, 0)

@export_category("Zoom")
@export var min_zoom_step: float = 1
@export var zoom_in_step_ratio: float = 0.25
@export var zoom_lerp_min_dist: float = 0.05

@export_category("Poppercam")
@export var popper_cam_offset: float = 0.1

@export_category("Focus")
@export var focus := Vector3(0, 0, 0)
@export var focused_node: Node3D:
	set(val):
		if is_node_ready():
			if focused_node:
				sight_raycast.remove_exception(focused_node)
			focused_node = val
			if focused_node:
				sight_raycast.add_exception(focused_node)
		
		focused_node = val
@export var focused_node_path: NodePath:
	set(val):
		focused_node_path = val
		focused_node = get_node_or_null(val)
@export var focus_offset := Vector3(0, 0, 0)

@export_category("Camera State")
@export var target_distance: float = 3
var cur_distance: float = 3
@export var orientation_x: float = -PI/32
@export var orientation_y: float = 0.0

@export_category("Locking")
@export var camera_lock_toggle := true:
	set(val):
		camera_lock_toggle = val
		if camera_lock_toggle == false:
			camera_temp_locked = false
@export var camera_locked := false
@export var camera_temp_locked := false
var cur_pos := Vector3.ZERO
var first_person_active := false
var mouse_move_delta := Vector2.ZERO
var temp_lock_start_mouse_pos := Vector2.ZERO

func get_mouse_pos() -> Vector2:
	if OS.has_feature("mobile"):
		return get_viewport().get_visible_rect().size/2
	if not camera_locked and camera_temp_locked:
		return temp_lock_start_mouse_pos
	return get_viewport().get_mouse_position()

@onready var camera_3d: Camera3D = $Camera3D
@onready var sight_raycast: RayCast3D = $SightRaycast


static func get_raycast_target_distance(raycast: RayCast3D) -> float:
	if raycast.is_colliding():
		var collision_point: Vector3 = raycast.get_collision_point()
		return (collision_point - raycast.global_position).length()
	else:
		return raycast.target_position.length()


static func get_raycast_target_point(raycast: RayCast3D, distance_offset: float) -> Vector3:
	var distance = get_raycast_target_distance(raycast)
	return raycast.global_position + raycast.target_position.normalized() \
		* (distance + distance_offset)


func _ready() -> void:
	if OS.has_feature("mobile"):
		camera_locked = true
		sensitivity *= 0.75
	
	focused_node = focused_node # force an update
	update_transform()
	update_mouse_lock()
	
	#var window = get_window()
	#window.focus_entered.connect(update_mouse_lock)
	#window.focus_exited.connect(update_mouse_lock)


func _process(_delta: float) -> void:
	var delta_y = -mouse_move_delta.x * sensitivity
	var delta_x = -mouse_move_delta.y * sensitivity
	
	var new_x = clamp(orientation_x + delta_x, -PI/2, PI/2)
	
	if delta_y != 0 or new_x != orientation_x: 
		orientation_y += delta_y
		orientation_x = new_x
	
	mouse_move_delta = Vector2.ZERO
	
	update_transform()


func is_locked():
	return camera_locked or camera_temp_locked


func update_mouse_lock():
	#if not is_inside_tree():
		#return
	#
	#if not get_window().has_focus():
		#return
	
	if is_locked():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_lock_changed.emit(true)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_lock_changed.emit(false)


func _unhandled_input(event):
	if event.is_echo():
		return
	
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				var temp_lock = event.pressed
				camera_temp_locked = temp_lock
				
				if temp_lock:
					temp_lock_start_mouse_pos = get_viewport().get_mouse_position()
				else:
					update_mouse_lock()
					Input.warp_mouse(temp_lock_start_mouse_pos)
				
				camera_temp_lock_changed.emit(temp_lock)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					var zoom_step = target_distance * zoom_in_step_ratio
					target_distance = max(target_distance - max(min_zoom_step, zoom_step), min_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					var zoom_step = target_distance * (1 - 1/(1 + zoom_in_step_ratio))
					target_distance = min(target_distance + max(min_zoom_step, zoom_step), max_distance)
			
		if target_distance == 0 and not first_person_active:
			first_person_active = true
			first_person_changed.emit(true)
		elif target_distance > 0 and first_person_active:
			first_person_active = false
			first_person_changed.emit(false)
		
		update_mouse_lock()
		
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_locked():
		mouse_move_delta += event.screen_relative
	elif event is InputEventKey:
		var key_event = event as InputEventKey
		
		if key_event.keycode == KEY_ALT:
			if camera_lock_toggle:
				if event.pressed:
					camera_locked = not camera_locked
			else:
				camera_locked = not event.pressed
			camera_lock_changed.emit(camera_locked)
			update_mouse_lock()


func update_transform() -> void:
	var cur_basis = Basis.from_euler(Vector3(orientation_x, orientation_y, 0))
	var cur_focus: Vector3 = (
			focused_node.global_position if focused_node != null 
			else focus
		) + focus_offset
	
	if basis != cur_basis:
		camera_rotated.emit()
	var translated = transform.origin != cur_focus
	transform = Transform3D(cur_basis, cur_focus)
	
	var cam_offset := camera_third_person_offset if not first_person_active else Vector3.ZERO
	
	#cur_distance = lerp(cur_distance, target_distance, position_lerp_alpha)
	var target_pos := cam_offset + Vector3(0, 0, target_distance)
	cur_pos = cur_pos.lerp(
		target_pos, 
		position_lerp_alpha
	)
	
	sight_raycast.position = Vector3.ZERO
	sight_raycast.target_position = cur_pos
	sight_raycast.force_update_transform()
	sight_raycast.force_raycast_update()
	
	if sight_raycast.is_colliding():
		cur_pos = sight_raycast.global_transform.inverse() * sight_raycast.get_collision_point()
	
	var popped_pos = cur_pos
	if not first_person_active:
		popped_pos -= target_pos.normalized() * popper_cam_offset
	
	if translated or camera_3d.position != popped_pos:
		camera_3d.position = popped_pos
		camera_translated.emit()
