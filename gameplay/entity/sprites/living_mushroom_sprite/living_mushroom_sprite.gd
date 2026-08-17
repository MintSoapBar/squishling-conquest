@tool
class_name LivingMushroomSprite
extends Sprite

@export var body_color: Color = Color(0.965, 0.886, 0.627, 1.0):
	set(val):
		body_color = val
		if is_node_ready():
			update_body_color()
@export var cap_color: Color = Color(0.761, 0.0, 0.0, 1.0):
	set(val):
		cap_color = val
		if is_node_ready():
			update_cap_color()
@export var gills_color: Color = Color(0.678, 0.502, 0.196, 1.0):
	set(val):
		gills_color = val
		if is_node_ready():
			update_gills_color()

@onready var body: MeshInstance3D = $Model/Body
var body_material: StandardMaterial3D
var cap_material: StandardMaterial3D
var gills_material: StandardMaterial3D


func _ready() -> void:
	body_material = body.get_surface_override_material(0).duplicate()
	cap_material = body.get_surface_override_material(1).duplicate()
	gills_material = body.get_surface_override_material(2).duplicate()
	
	body.set_surface_override_material(0, body_material)
	body.set_surface_override_material(1, cap_material)
	body.set_surface_override_material(2, gills_material)


func update_body_color():
	body_material.albedo_color = body_color


func update_cap_color():
	cap_material.albedo_color = cap_color


func update_gills_color():
	gills_material.albedo_color = gills_color
