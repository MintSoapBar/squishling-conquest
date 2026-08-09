class_name Tool
extends Node3D


signal locked
signal unlocked


# KEY_MAP and MOUSE_MAP are fallbacks for when the strings MAP_NAMES
# have not been bound as an InputAction
static var DEFAULT_ACTION_BINDING_KEY_MAP: Dictionary[String, Key] = {
	"skill_1": KEY_Q,
	"skill_2": KEY_E,
	"skill_3": KEY_R,
	"skill_4": KEY_T,
	"skill_5": KEY_G,
	"skill_6": KEY_Z,
	"skill_7": KEY_X,
	"skill_8": KEY_C,
	"skill_9": KEY_V,
}

static var DEFAULT_ACTION_BINDING_MOUSE_MAP: Dictionary[String, int] = {
	"tool_primary": MOUSE_BUTTON_LEFT
}

static var tool_registry: Dictionary[String, PackedScene] = {}

var data: Dictionary
var tool_name: String
var tool_user: Entity

var tool_actions: Dictionary[String, ToolAction] = {}
var locking_action: ToolAction = null


static func initialize_registry():
	Entity.register_scenes(
		tool_registry, 
		(Tool as GDScript).resource_path.replace("tool.gd", "tool_classes"), 
		scene_inherits_tool
	)
	Entity.debug_prints("Registered tool scenes:", tool_registry.keys())


static var tool_script = Tool as Script
static func script_inherits_tool(script: Script) -> bool:
	var current = script
	while current != null:
		if current == tool_script:
			return true
		current = current.get_base_script()
	return false


static func scene_inherits_tool(scene: Node) -> bool:
	return script_inherits_tool(scene.get_script())


static func create_tool(_data = {}) -> Tool:
	assert(tool_registry.size() > 0, "Initialize tool registry before creating any tools")
	
	var new_name = _data.tool_name
	
	assert(new_name, "Tool data must contain name " + str(_data))
	assert(tool_registry.has(new_name), 
		new_name + " not found in tool registry " + str(tool_registry))
	
	var new_tool = tool_registry[new_name].instantiate()
	new_tool.initialize(_data)
	
	return new_tool


static func from_stack(stack: Stack):
	return create_tool({
		tool_name = stack.name
	})


static func from_name(_tool_name: String):
	return create_tool({
		tool_name = _tool_name
	})


func initialize(_data: Dictionary):
	data = _data


func _ready() -> void:
	assert(scene_file_path, 
		"This script must be instantiated from its scene, not with .new().")


func _unhandled_input(event: InputEvent) -> void:
	if tool_user != Player.local_player:
		return
	if event.is_echo():
		return
	
	var player := tool_user as Player
	
	if not player.blocking:
		if (locking_action 
			and input_event_triggers_action(event, locking_action)):
			
			var action: ToolAction = locking_action
			
			if action.pressed and not event.is_pressed():
				action.pressed = false
				
				if action.poll_stop:
					action.stop_action({target_position = get_target_pos()})
		else:
			for action_key in tool_actions:
				var action = tool_actions[action_key]
				
				if locking_action and action.lockable:
					continue
				if not input_event_triggers_action(event, action):
					continue
				
				if event.is_pressed():
					if action.pressed:
						continue
					action.pressed = true
					action.start_action({target_position = get_target_pos()})
				else:
					if not action.pressed:
						continue
					action.pressed = false
					if action.poll_stop:
						action.stop_action()
	
	# sink input
	for action_key in tool_actions:
		var action = tool_actions[action_key]
		if input_event_triggers_action(event, action):
				get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if tool_user != Player.local_player:
		return
	
	for action_key in tool_actions:
		var action = tool_actions[action_key]
		if action.poll_continue:
			action.continue_action({target_position = get_target_pos()})


@rpc("any_peer", "call_local")
func request_tool_action_call(call_type: ToolAction.ToolActionCallType,
	action_key: String, params: Dictionary = {}):
	
	var peer := multiplayer.get_unique_id()
	var sender := multiplayer.get_remote_sender_id()
	var origin_peer := tool_user.get_multiplayer_authority()
	
	if sender != origin_peer and peer != (1 if Entity.server_authority_enabled() else origin_peer):
		assert(false, str(sender) + " tried to request tool action for origin peer "
			+ str(origin_peer) + " to peer") 
	
	var action: ToolAction = tool_actions.get(action_key)
	if not action:
		push_warning("No action found for key ", action_key, 
			" in tool actions ", str(tool_actions))
		return
	
	match call_type:
		ToolAction.ToolActionCallType.START:
			action.start_action_server(params)
		ToolAction.ToolActionCallType.CONTINUE:
			action.continue_action_server(params)
		ToolAction.ToolActionCallType.STOP:
			action.stop_action_server(params)
		ToolAction.ToolActionCallType.CANCEL:
			action.cancel_action_server()


func bind_action(action_key: String, action: ToolAction):
	var old_action: ToolAction = tool_actions.get(action_key)
	if old_action:
		old_action.free()
	
	tool_actions[action_key] = action
	action.action_key = action_key


func get_target_pos(max_distance: float = 1000) -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2
	if Player.orbital_camera:
		mouse_pos = Player.orbital_camera.get_mouse_pos()
	else:
		mouse_pos = get_viewport().get_mouse_position()
	
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_target: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * max_distance

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	query.exclude = [tool_user.get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	
	var target_pos := result.position as Vector3 if result else ray_target
	return target_pos


func input_event_triggers_action(event: InputEvent, action: ToolAction) -> bool:
	if InputMap.has_action(action.action_key) and event.is_action(action.action_key):
		return true
	else:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if (key_event.keycode 
				== DEFAULT_ACTION_BINDING_KEY_MAP.get(action.action_key)):
				
				return true
		elif event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			if (mouse_event.button_index 
				== DEFAULT_ACTION_BINDING_MOUSE_MAP.get(action.action_key)):
				
				return true
	return false


func is_locked() -> bool:
	return locking_action != null


func lock(_locking_action: ToolAction) -> void:
	assert(not is_locked())
	locking_action = _locking_action
	locked.emit()


func unlock():
	assert(is_locked())
	locking_action = null
	unlocked.emit()


func get_action_origin() -> Vector3:
	return global_position
