@tool
extends Control


@export_category("Functionality")
@export var action_name: String = "":
	set(val):
		action_name = val
		if is_inside_tree():
			label.text = action_name.capitalize()
@export var toggle_mode: bool = false:
	set(val):
		toggle_mode = val
		if is_inside_tree():
			button.toggle_mode = toggle_mode

@export_category("Appearance")
@export var button_diameter: float = 64:
	set(val):
		button_diameter = val
		if is_inside_tree():
			set_diameter(button_diameter)
@export var outline_thickness: float = 0.1:
	set(val):
		outline_thickness = val
		if is_inside_tree():
			set_outline_thickness(outline_thickness)


@onready var button: TextureButton = $Button
var normal_texture: GradientTexture2D
var normal_texture_gradient: Gradient
var pressed_texture: GradientTexture2D
var pressed_texture_gradient: Gradient
@onready var label: Label = $Button/Label

var is_down: bool = false


func _ready() -> void:
	assert(!action_name.is_empty(), "No action_name provided for mobile button " + str(get_path()))
	
	normal_texture = button.texture_normal
	normal_texture_gradient = normal_texture.gradient
	pressed_texture = button.texture_pressed
	pressed_texture_gradient = pressed_texture.gradient
	
	button.button_down.connect(on_button_down)
	button.button_up.connect(on_button_up)
	button.toggled.connect(on_toggled)
	
	label.text = action_name.capitalize()
	button.toggle_mode = toggle_mode
	set_diameter(button_diameter)


func action_press():
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	Input.parse_input_event(event)


func action_release():
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = false
	Input.parse_input_event(event)


func on_button_down():
	is_down = true
	if not toggle_mode:
		action_press()


func on_button_up():
	is_down = false
	if not toggle_mode:
		action_release()


func on_toggled(toggle_on: bool):
	if toggle_on:
		action_press()
	else:
		action_release()


func set_diameter(diameter: float):
	button.size = Vector2.ONE * diameter
	button.position = -button.size/2
	
	normal_texture.width = int(diameter*2)
	normal_texture.height = int(diameter*2)
	pressed_texture.width = int(diameter*2)
	pressed_texture.height = int(diameter*2)


func set_outline_thickness(thickness: float):
	normal_texture_gradient.set_offset(1, 1 - thickness)
	pressed_texture_gradient.set_offset(1, 1 - thickness)
