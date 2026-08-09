@tool
class_name MagicCircle
extends Node3D

const MAGIC_CIRCLE = preload("uid://c42woetoisxse")

signal faded_out

var color: Color
var layers: Array[MeshInstance3D] = []


static func create_magic_circle(magic: String) -> MagicCircle:
	var new_circle: MagicCircle = MAGIC_CIRCLE.instantiate()
	new_circle.initialize()
	new_circle.set_magic(magic)
	
	return new_circle


func _ready() -> void:
	initialize()
	#set_magic("fire")


var initialized: bool = false
func initialize() -> void:
	if initialized:
		return
	initialized = true
	for i in range(2):
		layers.append(get_node("Layer" + str(i)))
		layers[i].mesh = layers[i].mesh.duplicate()
		layers[i].material_override = layers[i].material_override.duplicate()


func _process(delta: float) -> void:
	var prev_scale = scale
	basis = basis.orthonormalized()
	
	var look = -basis.z
	var up = Vector3.UP
	if up.is_equal_approx(look):
		up = get_viewport().get_camera_3d().global_basis.y
	basis = basis.slerp(Basis.looking_at(look, up), 0.1)
	
	scale = prev_scale
	layers[1].rotation.z += delta


func set_magic(magic: String):
	color = MagicVisuals.magic_colors[magic][0]
	var layers_path = (get_script() as Script).get_path().replace("magic_circle.gd", "layers/")
	var layer_0_path = layers_path + "layer_0/" + magic + ".png"
	if not FileAccess.file_exists(layer_0_path):
		layer_0_path = layer_0_path.replace(magic, "fire")
	layers[0].material_override.albedo_texture = load(layer_0_path)
	
	for layer in layers:
		layer.material_override.albedo_color = color


func fade_in(duration: float) -> void:
	for layer in layers:
		var color_tween := create_tween()
		color_tween.tween_property(
			layer.material_override, 
			"albedo_color", 
			Color(color.r, color.g, color.b, 1), 
			duration
		)
		
		layer.scale *= 1.5
		create_tween().tween_property(layer, "scale", Vector3.ONE, duration)


func fade_out(duration: float, delay: float = 0) -> void:
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	for layer in layers:
		var color_tween := create_tween()
		layer.material_override.albedo_color = Color(color.r, color.g, color.b, 1)
		color_tween.tween_property(
			layer.material_override, 
			"albedo_color", 
			Color(color.r, color.g, color.b, 0), 
			duration
		)
	
	await get_tree().create_timer(duration).timeout
	faded_out.emit()
