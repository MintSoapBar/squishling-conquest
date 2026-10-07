class_name InheritedDictionary

var _parents: Array[InheritedDictionary]
var _dictionary: Dictionary


func _init(parents: Array[InheritedDictionary] = [], dictionary: Dictionary = {}) -> void:
	_parents = parents
	_dictionary = dictionary


func _to_string() -> String:
	return str(_dictionary)


func add_parent(parent: InheritedDictionary):
	_parents.append(parent)


func get_value(key: StringName) -> Variant:
	var val = _dictionary.get(key)
	if val != null:
		return val
	
	for parent in _parents:
		var parent_val = parent.get_value(key)
		if parent_val != null:
			return parent_val
	
	return val


func set_value(key: StringName, value: Variant) -> bool:
	_dictionary.set(key, value)
	return true


func get_dictionary() -> Dictionary:
	return _dictionary


func replace_dictionary(new_dictionary: Dictionary) -> void:
	_dictionary = new_dictionary
