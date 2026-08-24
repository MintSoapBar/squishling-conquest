@tool
extends Node3D


@export var rug_material: ShaderMaterial:
	set(val):
		rug_material = val
		if is_node_ready():
			update_rug_material()

@onready var rug: MeshInstance3D = $Rug


func _ready() -> void:
	update_rug_material()


func update_rug_material():
	rug.set_surface_override_material(0, rug_material)
