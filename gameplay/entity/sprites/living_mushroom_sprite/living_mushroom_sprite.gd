@tool
class_name LivingMushroomSprite
extends Sprite

const modeled_stalk_height: float = 3
const modeled_stalk_radius: float = 1.15
const modeled_cap_height: float = 1.3
const modeled_cap_connection_height: float = 0.6
const modeled_cap_radius: float = 2.5

@export_category("Sizing")
@export var stalk_height: float = 1:
	set(val):
		stalk_height = val
		if is_node_ready():
			update_stalk_height()
@export var stalk_radius: float = 0.35:
	set(val):
		stalk_radius = val
		if is_node_ready():
			update_stalk_radius()
@export var cap_height: float = 0.5:
	set(val):
		cap_height = val
		cap_connection_height = cap_height * (modeled_cap_connection_height / modeled_cap_height)
		if is_node_ready():
			update_cap_height()
var cap_connection_height: float = cap_height * (modeled_cap_connection_height / modeled_cap_height)
@export var cap_radius: float = 0.8:
	set(val):
		cap_radius = val
		if is_node_ready():
			update_cap_radius()

@export_category("Colors")
@export var stalk_color: Color = Color("f6e2a0ff"):
	set(val):
		stalk_color = val
		if is_node_ready():
			update_stalk_color()
@export var cap_color: Color = Color("c20000ff"):
	set(val):
		cap_color = val
		if is_node_ready():
			update_cap_color()
@export var gills_color: Color = Color("ad8032ff"):
	set(val):
		gills_color = val
		if is_node_ready():
			update_gills_color()

@onready var cap: MeshInstance3D = $Model/MushroomBody/Cap
@onready var stalk: MeshInstance3D = $Model/MushroomBody/Stalk
var stalk_material: StandardMaterial3D
var cap_material: StandardMaterial3D
var gills_material: StandardMaterial3D
@onready var stalk_collider: NestedCollisionShape3D = $StalkCollider
@onready var cap_collider_1: NestedCollisionShape3D = $CapCollider1
@onready var cap_collider_2: NestedCollisionShape3D = $CapCollider2
var stalk_collider_shape: CapsuleShape3D
var cap_collider_1_shape: CylinderShape3D
var cap_collider_2_shape: CylinderShape3D

func _ready() -> void:
	stalk_material = stalk.get_surface_override_material(0).duplicate()
	cap_material = cap.get_surface_override_material(0).duplicate()
	gills_material = cap.get_surface_override_material(1).duplicate()
	
	stalk.set_surface_override_material(0, stalk_material)
	cap.set_surface_override_material(0, cap_material)
	cap.set_surface_override_material(1, gills_material)
	
	stalk_collider_shape = stalk_collider.shape.duplicate()
	cap_collider_1_shape = cap_collider_1.shape.duplicate()
	cap_collider_2_shape = cap_collider_2.shape.duplicate()
	stalk_collider.shape = stalk_collider_shape
	cap_collider_1.shape = cap_collider_1_shape
	cap_collider_2.shape = cap_collider_2_shape
	
	stalk_collider.reparent_to_collision_object_3d.call_deferred()
	cap_collider_1.reparent_to_collision_object_3d.call_deferred()
	cap_collider_2.reparent_to_collision_object_3d.call_deferred()


func update_stalk_height():
	stalk.scale.y = stalk_height/modeled_stalk_height
	cap.position.y = stalk_height
	update_status_bar_billboard()
	update_stalk_collider()
	update_cap_colliders()


func update_stalk_radius():
	var scl = stalk_radius/modeled_stalk_radius
	stalk.scale.x = scl
	stalk.scale.z = scl
	update_stalk_collider()


func update_cap_height():
	cap.scale.y = cap_height/modeled_cap_height
	update_status_bar_billboard()
	update_cap_colliders()


func update_cap_radius():
	var scl = cap_radius/modeled_cap_radius
	cap.scale.x = scl
	cap.scale.z = scl
	update_cap_colliders()


func update_stalk_collider():
	stalk_collider.position.y = stalk_height/2
	stalk_collider_shape.height = stalk_height
	stalk_collider_shape.radius = stalk_radius


func update_status_bar_billboard():
	status_bar_billboard.position.y = stalk_height + cap_height


func update_cap_colliders():
	cap_collider_1.position.y = stalk_height - cap_connection_height/2
	cap_collider_1_shape.height = cap_connection_height
	cap_collider_1_shape.radius = cap_radius * 0.9
	
	cap_collider_2.position.y = stalk_height + (cap_height - cap_connection_height)/3
	cap_collider_2_shape.height = (cap_height - cap_connection_height) * 2/3
	cap_collider_2_shape.radius = cap_radius * 0.6


func update_stalk_color():
	stalk_material.albedo_color = stalk_color


func update_cap_color():
	cap_material.albedo_color = cap_color


func update_gills_color():
	gills_material.albedo_color = gills_color
