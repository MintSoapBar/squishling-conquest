@tool
extends Control

@export var joystick_diameter: float = 150:
	set(val):
		joystick_diameter = val
		joystick_visual.set_joystick_diameter(joystick_diameter)
@export var action_left: String = "move_left"
@export var action_right: String = "move_left"
@export var action_up: String = "move_forward"
@export var action_down: String = "move_backward"

var tracking: bool = false
var tracking_index: int = 0
var move_direction: Vector2 = Vector2.ZERO
var move_weight: float = 0.0

@onready var joystick_visual = $JoystickVisual

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.is_pressed():
			if get_global_rect().has_point(touch_event.position):
				start_tracking(touch_event.index, event.position)
				get_viewport().set_input_as_handled()
		else:
			if tracking and touch_event.index == tracking_index:
				stop_tracking()
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if tracking and drag_event.index == tracking_index:
			update_tracking(drag_event.position)
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	joystick_visual.set_stick_position(move_direction, move_weight)


func update_tracking(touch_position: Vector2):
	var move_delta = touch_position - (global_position + size/2)
	move_direction = move_delta.normalized()
	move_weight = clamp(move_delta.length() / (joystick_diameter/2), 0, 1)
	
	if move_direction.x < 0:
		Input.action_press("move_left", -move_direction.x * move_weight)
		Input.action_release("move_right")
	if move_direction.x > 0:
		Input.action_press("move_right", move_direction.x * move_weight)
		Input.action_release("move_left")
	if move_direction.y < 0:
		Input.action_press("move_forward", -move_direction.y * move_weight)
		Input.action_release("move_backward")
	if move_direction.y > 0:
		Input.action_press("move_backward", move_direction.y * move_weight)
		Input.action_release("move_forward")


func start_tracking(index: int, touch_position: Vector2 = Vector2.ZERO):
	tracking = true
	tracking_index = index
	#joystick_visual.fill_color = Color(0, 1, 0)
	
	update_tracking(touch_position)

func stop_tracking():
	tracking = false
	#joystick_visual.fill_color = Color(1, 0, 0)
	
	move_direction = Vector2.ZERO
	move_weight = 0
	
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_forward")
	Input.action_release("move_backward")
