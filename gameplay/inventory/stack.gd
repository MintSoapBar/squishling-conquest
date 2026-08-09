class_name Stack

var name: String
var size: int
var data: Dictionary


func _init(_name: String, _size: int, _data: Dictionary = {}):
	name = _name
	size = _size
	data = _data


func is_same_as(o: Stack):
	if name != o.name:
		return false
	return data.recursive_equal(o.data, 99)
