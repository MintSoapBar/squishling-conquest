@tool
class_name LivingBottleSprite
extends Sprite

const modeled_bottle_height: float = 3
const modeled_bottle_radius: float = 0.5
const modeled_cork_height: float = 4
const modeled_cork_radius: float = 0.15

@export_category("Sizing")
@export var bottle_height: float = 3:
	set(val):
		bottle_height = val
		if is_node_ready():
			update_bottle_height()
@export var bottle_radius: float = 0.5:
	set(val):
		bottle_radius = val
		if is_node_ready():
			update_bottle_radius()

@export_category("Colors")
@export var bottle_color: Color = Color("2d1000ff"):
	set(val):
		bottle_color = val
		if is_node_ready():
			update_bottle_color()
@export var label_color: Color = Color("a3a3a3ff"):
	set(val):
		label_color = val
		if is_node_ready():
			update_label_color()
@export var cork_color: Color = Color("63341dff"):
	set(val):
		cork_color = val
		if is_node_ready():
			update_cork_color()

@onready var face: Marker3D = $Model/Face

@onready var bottle: MeshInstance3D = $Model/WineBottleBody/Bottle
@onready var cork: MeshInstance3D = $Model/WineBottleBody/Cork
var bottle_material: StandardMaterial3D
var label_material: StandardMaterial3D
var cork_material: StandardMaterial3D

@onready var body_collider: NestedCollisionShape3D = $BodyCollider
@onready var neck_collider: NestedCollisionShape3D = $NeckCollider
var body_collider_shape: CylinderShape3D
var neck_collider_shape: CylinderShape3D

func _ready() -> void:
	super()
	
	bottle_material = bottle.get_surface_override_material(0).duplicate()
	label_material = bottle.get_surface_override_material(1).duplicate()
	cork_material = cork.get_surface_override_material(0).duplicate()
	
	bottle.set_surface_override_material(0, bottle_material)
	bottle.set_surface_override_material(1, label_material)
	cork.set_surface_override_material(0, cork_material)
	
	body_collider_shape = body_collider.shape.duplicate()
	neck_collider_shape = neck_collider.shape.duplicate()
	body_collider.shape = body_collider_shape
	neck_collider.shape = neck_collider_shape
	
	body_collider.reparent_to_collision_object_3d.call_deferred()
	neck_collider.reparent_to_collision_object_3d.call_deferred()
	
	update_bottle_height()
	update_bottle_radius()
	update_bottle_color()
	update_label_color()
	update_cork_color()


func update_bottle_height():
	bottle.scale.y = bottle_height/modeled_bottle_height
	bottle.position.y = 0
	
	cork.scale.y = bottle_height/modeled_bottle_height
	cork.position.y = bottle_height * 2.9/3
	
	face.position.y = 1.25/3 * bottle_height
	
	body_collider_shape.height = 1.9/3 * bottle_height
	body_collider.position.y = body_collider_shape.height/2
	
	neck_collider_shape.height = 1.1/3 * bottle_height
	neck_collider.position.y = body_collider_shape.height + neck_collider_shape.height/2
	
	status_bar_billboard.position.y = bottle_height + base_status_bar_billboard_offset


func update_bottle_radius():
	bottle.scale.x = bottle_radius/modeled_bottle_radius
	bottle.scale.z = bottle.scale.x
	
	cork.scale.x = bottle.scale.x
	cork.scale.z = bottle.scale.z
	
	face.position.z = -0.48/0.5 * bottle_radius
	
	body_collider_shape.radius = bottle_radius
	neck_collider_shape.radius = bottle_radius * 0.4


func update_bottle_color():
	bottle_material.albedo_color = bottle_color


func update_label_color():
	label_material.albedo_color = label_color


func update_cork_color():
	cork_material.albedo_color = cork_color
