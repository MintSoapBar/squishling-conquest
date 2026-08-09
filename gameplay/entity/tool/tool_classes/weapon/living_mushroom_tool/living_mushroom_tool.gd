class_name MushroomMobTool
extends Tool

func _ready():
	super()
	tool_name = "mushroom_mob_tool"
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_1", self, tool_user, 
	{"magic" = "poison", "hide_circle" = true})


func get_action_origin() -> Vector3:
	var face: Node3D = tool_user.sprite.get_node("Model/Face")
	return face.global_position
