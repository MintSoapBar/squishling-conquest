@tool
extends Control

@export_category("Sizing")
@export var ring_thickness: float = 0.1:
	set(val):
		ring_thickness = val
		ring_texture_gradient.set_offset(1, 1 - ring_thickness)
@export var stick_size: float = 0.4:
	set(val):
		stick_size = val
		stick_texture_gradient.set_offset(1, stick_size)
@export var stick_outline_thickness: float = 0.1:
	set(val):
		stick_outline_thickness = val
		stick_texture_gradient.set_offset(1, stick_size - stick_outline_thickness)

@export_category("Colors")
@export var fill_color: Color = Color(1, 1, 1, 0.2):
	set(val):
		fill_color = val
		ring_texture_gradient.set_color(0, fill_color)
@export var ring_color: Color = Color(1, 1, 1, 0.5):
	set(val):
		ring_color = val
		ring_texture_gradient.set_color(1, ring_color)
@export var stick_color: Color = Color(1, 1, 1, 0.75):
	set(val):
		stick_color = val
		stick_texture_gradient.set_color(0, stick_color)
@export var stick_outline_color: Color = Color(1, 1, 1, 0.5):
	set(val):
		stick_outline_color = val
		stick_texture_gradient.set_color(1, stick_outline_color)

var joystick_diameter: float = 150

@onready var ring: TextureRect = $Ring
var ring_texture: GradientTexture2D
var ring_texture_gradient: Gradient
@onready var stick: TextureRect = $Stick
var stick_texture: GradientTexture2D
var stick_texture_gradient: Gradient


func _ready() -> void:
	ring_texture = ring.texture
	ring_texture_gradient = ring_texture.gradient
	stick_texture = stick.texture
	stick_texture_gradient = stick_texture.gradient


func set_stick_position(direction: Vector2, weight: float):
	stick.position = -stick.size/2 + direction * joystick_diameter/2 * weight


func set_joystick_diameter(diameter: float):
	joystick_diameter = diameter
	ring.size = Vector2.ONE * joystick_diameter
	ring.position = -ring.size/2
	stick.size = Vector2.ONE * joystick_diameter
	stick.position = -stick.size/2
	
	# x2 for mobile scaling
	ring_texture.width = int(joystick_diameter*2)
	ring_texture.height = int(joystick_diameter*2)
	stick_texture.width = int(joystick_diameter*2)
	stick_texture.height = int(joystick_diameter*2)
