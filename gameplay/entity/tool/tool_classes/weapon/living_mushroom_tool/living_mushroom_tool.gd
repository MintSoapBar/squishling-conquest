class_name MushroomMobTool
extends Tool

func _ready():
	super()
	tool_name = "mushroom_mob_tool"


func get_action_origin() -> Vector3:
	var face: Node3D = tool_user.sprite.get_node("Model/Face")
	return face.global_position - face.global_basis.z * 0.5
