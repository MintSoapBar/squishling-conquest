class_name Sword
extends Tool

func _ready():
	super()
	tool_name = "sword"
	
	ToolSkillAction.new("slash_skill", 
	"skill_1", self, tool_user)


func get_action_origin() -> Transform3D:
	return global_transform.translated_local(Vector3(0, 0.5, 0))
