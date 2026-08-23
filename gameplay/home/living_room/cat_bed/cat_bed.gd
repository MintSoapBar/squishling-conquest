@tool
extends Node3D


@export var outside_material: StandardMaterial3D:
	set(val):
		outside_material = val
		if is_node_ready():
			update_outside_material()
@export var inside_seat_material: StandardMaterial3D:
	set(val):
		inside_seat_material = val
		if is_node_ready():
			update_inside_seat_material()
@export var inside_wall_material: StandardMaterial3D:
	set(val):
		inside_wall_material = val
		if is_node_ready():
			update_inside_wall_material()

@onready var cat_bed: MeshInstance3D = $CatBed


func _ready() -> void:
	update_outside_material()
	update_inside_seat_material()
	update_inside_wall_material()


func update_outside_material():
	cat_bed.set_surface_override_material(0, outside_material)


func update_inside_seat_material():
	cat_bed.set_surface_override_material(1, inside_seat_material)


func update_inside_wall_material():
	cat_bed.set_surface_override_material(2, inside_wall_material)
