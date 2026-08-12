@tool
class_name CrosshairCursor
extends Control

@onready var right: ColorRect = $Right
@onready var bottom: ColorRect = $Bottom
@onready var left: ColorRect = $Left
@onready var top: ColorRect = $Top
var hairs: Array[ColorRect]

@export var hair_gap: int = 1:
	set(val):
		hair_gap = val
		update_hair_gap()
@export var hair_length: int = 10:
	set(val):
		hair_length = val
		update_hair_length()
@export var hair_thickness: int = 1:
	set(val):
		hair_thickness = val
		update_hair_thickness()


func _ready():
	hairs = [right, bottom, left, top]


var orbital_camera: Node
func set_orbital_camera(camera):
	if orbital_camera:
		orbital_camera.mouse_lock_changed.disconnect(on_camera_mouse_lock_changed)
	visible = camera.is_locked()
	camera.mouse_lock_changed.connect(on_camera_mouse_lock_changed)
	orbital_camera = camera


func on_camera_mouse_lock_changed(mouse_locked: bool):
	position = orbital_camera.get_mouse_pos()
	visible = mouse_locked


func update_hair_gap():
	for hair in hairs:
		hair.pivot_offset.x = -0.5 - hair_gap
		hair.position.x = 1 + hair_gap


func update_hair_length():
	for hair in hairs:
		hair.size.x = hair_length


func update_hair_thickness():
	for hair in hairs:
		hair.pivot_offset.y = hair_thickness/2.0
		hair.position.y = -(hair_thickness - 1)/2.0
		hair.size.y = hair_thickness
