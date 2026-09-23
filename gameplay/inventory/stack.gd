class_name Stack

var name: String
var size: int
var data: Dictionary


func _init(_name: String, _size: int, _data: Dictionary = {}):
	name = _name
	size = _size
	data = _data


func is_same_as(other_stack: Stack):
	if name != other_stack.name:
		return false
	return data.recursive_equal(other_stack.data, 99)
