class_name MagicStaff
extends Tool

func _ready():
	super()
	tool_name = "magic_staff"
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_1", self, tool_user, 
	{"magic" = "fire"})
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_2", self, tool_user, 
	{"magic" = "water"})
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_3", self, tool_user, 
	{"magic" = "earth"})
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_4", self, tool_user, 
	{"magic" = "air"})
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_5", self, tool_user, 
	{"magic" = "light"})
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_6", self, tool_user, 
	{"magic" = "shadow"})
	
	ToolSkillAction.new("magic_blast_skill", 
	"skill_7", self, tool_user, 
	{"magic" = "poison", "hide_circle" = true})


func get_action_origin() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)
