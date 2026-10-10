class_name MushroomMobTool
extends Tool

func _ready():
	super()
	tool_name = "mushroom_mob_tool"


func get_action_origin() -> Transform3D:
	var face: Node3D = tool_user.sprite.get_node("Model/Face")
	return face.global_transform.translated_local(Vector3(0, 0, -0.5))
