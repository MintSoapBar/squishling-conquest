@abstract
class_name ToolAction

static var action_templates: Dictionary[String, ToolAction] = {}

enum ToolActionCallType {START, CONTINUE, STOP, CANCEL}

var action_name: String
var tool: Tool
var tool_user: Entity

var data: Dictionary
var action_key: String

var pressed: bool = false
var active: bool = false
var poll_continue: bool = false
var poll_stop: bool = false
var lockable: bool = true

var startup_end_time: float = 0

func _init(_action_name: String, _action_key: String,
	 _tool: Tool, _tool_user: Entity, _data := {}) -> void:
	
	action_name = _action_name
	action_key = _action_key
	tool = _tool
	tool_user = _tool_user
	data = _data
	
	tool.tool_actions[action_key] = self


# concise way to start/stop action if you already have a bool
# eg. for InputEvent.pressed
func do_action(is_start: bool, params: Dictionary = {}):
	if is_start:
		start_action(params)
	else:
		stop_action(params)


func start_action(_params: Dictionary = {}) -> void:
	pass
func continue_action(_params: Dictionary = {}) -> void:
	pass
func stop_action(_params: Dictionary = {}) -> void:
	pass


func start_action_server(_params: Dictionary = {}):
	pass
func continue_action_server(_params: Dictionary = {}):
	pass
func stop_action_server(_params: Dictionary = {}):
	pass


func cancel_action() -> void:
	active = false
	poll_continue = false
	poll_stop = false
	if is_instance_valid(tool):
		if tool.locking_action == self:
			tool.unlock()


func _to_string() -> String:
	return action_name


func get_target_pos(max_distance: float = 1000) -> Vector3:
	var camera: Camera3D = tool_user.get_viewport().get_camera_3d()
	var mouse_pos: Vector2
	if Player.orbital_camera:
		mouse_pos = Player.orbital_camera.get_mouse_pos()
	else:
		mouse_pos = tool_user.get_viewport().get_mouse_position()
	
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_target: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * max_distance

	var space_state := tool_user.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	query.exclude = [tool_user.get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	
	return result.position if result else ray_target


func is_action_valid() -> bool:
	if not is_instance_valid(tool) or not tool.is_inside_tree():
		return false
	if not is_instance_valid(tool_user) or not tool_user.is_inside_tree():
		return false
	return true


func check_action_valid() -> bool:
	var valid := is_action_valid()
	if not valid:
		cancel_action()
	return valid
