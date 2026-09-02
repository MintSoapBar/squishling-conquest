class_name HumanoidSprite
extends Sprite

@onready var body: MeshInstance3D = $Model/Body


@rpc("authority", "call_local")
func set_body_color(color := Color(1, 0, 1)):
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	body.material_override = material
