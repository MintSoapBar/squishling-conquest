class_name LivingBottleTool
extends Tool

func _ready():
	super()
	tool_name = "living_bottle_tool"


func get_action_origin() -> Transform3D:
	var cork: Node3D = tool_user.sprite.get_node("Model/WineBottleBody/Cork")
	return cork.global_transform.translated_local(Vector3(0, 0, -0.5))
