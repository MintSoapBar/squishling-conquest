@tool
class_name SlashVFX
extends Node3D

const SLASH_VFX = preload("uid://ccpvm0lk3khw0")

@export var test_fade_out: bool = false:
	set(val):
		test_fade_out = val
		if test_fade_out == true:
			test_fade_out = false
			fade_out()
@export var test_update_meshes: bool = false:
	set(val):
		test_update_meshes = val
		if test_update_meshes == true:
			test_update_meshes = false
			update_meshes()

@export var radius: float = 1:
	set(val):
		radius = val
		if Engine.is_editor_hint() and is_node_ready():
			update_meshes()
@export var depth: float = 0.1:
	set(val):
		depth = val
		if Engine.is_editor_hint() and is_node_ready():
			update_meshes()
@export var depth_curve = Curve.new():
	set(val):
		depth_curve = val
		if Engine.is_editor_hint() and is_node_ready():
			update_meshes()
@export var end_angle: float = PI * 2/3:
	set(val):
		end_angle = val
		if Engine.is_editor_hint() and is_node_ready():
			update_meshes()

@onready var edge: CrescentMesh = $Edge
@onready var middle: CrescentMesh = $Middle
@onready var inside: CrescentMesh = $Inside

var edge_material: StandardMaterial3D
var middle_material: StandardMaterial3D
var inside_material: StandardMaterial3D


static func create_slash(_radius: float, _depth: float, _end_angle: float) -> SlashVFX:
	var new_slash_vfx: SlashVFX = SLASH_VFX.instantiate()
	new_slash_vfx.radius = _radius
	new_slash_vfx.depth = _depth
	new_slash_vfx.end_angle = _end_angle
	
	return new_slash_vfx


func _ready() -> void:
	edge_material = edge.get_surface_override_material(0).duplicate()
	middle_material = middle.get_surface_override_material(0).duplicate()
	inside_material = inside.get_surface_override_material(0).duplicate()
	
	edge.set_surface_override_material(0, edge_material)
	middle.set_surface_override_material(0, middle_material)
	inside.set_surface_override_material(0, inside_material)
	
	edge.depth_curve = depth_curve
	middle.depth_curve = depth_curve
	inside.depth_curve = depth_curve
	
	update_meshes()


func fade_out():
	edge_material.albedo_color.a = 1
	middle_material.albedo_color.a = 0.5
	inside_material.albedo_color.a = 0.5
	
	var material_tween := create_tween()
	material_tween.set_parallel(true)
	material_tween.set_trans(Tween.TRANS_EXPO)
	material_tween.tween_property(edge_material, "albedo_color:a", 0, 1)
	material_tween.tween_property(middle_material, "albedo_color:a", 0, 0.7)
	material_tween.tween_property(inside_material, "albedo_color:a", 0, 0.5)
	
	if not Engine.is_editor_hint():
		material_tween.finished.connect(queue_free)


func update_meshes():
	for crescent: CrescentMesh in [edge, middle, inside]:
		crescent.radius = radius
		crescent.depth = depth
		crescent.depth_curve = depth_curve
		crescent.end_angle = end_angle
		crescent.update()
