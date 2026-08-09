@tool
extends Node3D

@export_category("Stretch")
@export var stretch_direction: Vector3 = Vector3.ONE
@export var stretch_scale: float = 1.0

@export_category("Spin")
@export var core_spin_speed: float = 2
@export var plates_spin_speed: float = -1

var core_rotation: float = 0
var plates_rotation: float = 0

@export_category("Alpha")
@export var core_alpha: float = 0.75
@export var plates_alpha: float = 0.75

@export_category("Color")
@export var core_color: Color = Color(0, 1, 0)
@export var core_emission: Color = Color(0, 1, 0)
@export var core_emission_strength: float = 1

@export var plates_color: Color = Color(1, 1, 0)
@export var plates_emission: Color = Color(0, 1, 0)
@export var plates_emission_strength: float = 1

@onready var core: MeshInstance3D = $Core
@onready var plates: MeshInstance3D = $Plates

var core_shader: ShaderMaterial
var plates_shader: ShaderMaterial

func _ready() -> void:
	core_shader = core.material_override.duplicate()
	core.material_override = core_shader
	plates_shader = plates.material_override.duplicate()
	plates.material_override = plates_shader

func _process(delta: float) -> void:
	core_shader.set_shader_parameter("stretch_direction", stretch_direction)
	core_shader.set_shader_parameter("stretch_scale", stretch_scale)
	
	plates_shader.set_shader_parameter("stretch_direction", stretch_direction)
	plates_shader.set_shader_parameter("stretch_scale", stretch_scale)
	
	
	core_rotation = fmod(core_rotation + delta * core_spin_speed, 2 * PI)
	plates_rotation = fmod(plates_rotation + delta * plates_spin_speed, 2 * PI)
	
	core_shader.set_shader_parameter("rotation", core_rotation)
	plates_shader.set_shader_parameter("rotation", plates_rotation)
	
	
	core_shader.set_shader_parameter("alpha", core_alpha)
	plates_shader.set_shader_parameter("alpha", plates_alpha)
	
	
	core_shader.set_shader_parameter("color", core_color)
	core_shader.set_shader_parameter("emission", core_emission)
	core_shader.set_shader_parameter("emission_strength", core_emission_strength)
	
	plates_shader.set_shader_parameter("color", plates_color)
	plates_shader.set_shader_parameter("emission", plates_emission)
	plates_shader.set_shader_parameter("emission_strength", plates_emission_strength)
