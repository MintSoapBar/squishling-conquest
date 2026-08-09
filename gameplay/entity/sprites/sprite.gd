@abstract
class_name Sprite
extends Node3D

var entity: Entity
var model: Node3D

var tool: Tool


@rpc("any_peer", "call_local")
func equip_tool(new_tool):
	if tool:
		tool.queue_free()
	
	tool = new_tool
	
	if tool:
		tool.tool_user = entity
		$Hand.add_child(tool)
		
		var handle: Node3D = tool.get_node_or_null("Handle")
		if handle:
			tool.position = -handle.position
