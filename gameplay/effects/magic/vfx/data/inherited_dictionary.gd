class_name InheritedDictionary

var parents: Array[InheritedDictionary]
var data: Dictionary


func _init(_parents: Array[InheritedDictionary] = [], _data: Dictionary = {}) -> void:
	parents = _parents
	data = _data


func _get(property: StringName) -> Variant:
	var val = data.get(property)
	if val != null:
		return val
	
	for parent in parents:
		var parent_val = parent[property]
		if parent_val != null:
			return parent_val
	
	return val


func _set(property: StringName, value: Variant) -> bool:
	data.set(property, value)
	return true
