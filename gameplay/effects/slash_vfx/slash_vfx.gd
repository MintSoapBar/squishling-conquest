@tool
extends Node3D

@export var test: bool = false:
	set(val):
		test = val
		if test == true:
			test = false
			fade_out()

@onready var edge: CrescentMesh = $Edge
@onready var middle: CrescentMesh = $Middle
@onready var inside: CrescentMesh = $Inside

var edge_material: StandardMaterial3D
var middle_material: StandardMaterial3D
var inside_material: StandardMaterial3D


func _ready() -> void:
	edge_material = edge.get_surface_override_material(0).duplicate()
	middle_material = middle.get_surface_override_material(0).duplicate()
	inside_material = inside.get_surface_override_material(0).duplicate()
	
	edge.set_surface_override_material(0, edge_material)
	middle.set_surface_override_material(0, middle_material)
	inside.set_surface_override_material(0, inside_material)


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
