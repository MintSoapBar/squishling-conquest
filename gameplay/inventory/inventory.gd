class_name Inventory

var groups: Dictionary[String, Group] = {}

# TODO: implement inventory system from cursed expanse here

func _init(group_sizes: Dictionary[String, int] = {Hotbar = 9}):
	for name in group_sizes:
		var size = group_sizes[name]
		groups[name] = Group.new(name, size)


func add_stack(new_stack: Stack) -> bool:
	var groups_arr: Array[Group] = groups.values()
	groups_arr.sort_custom(Group.compare)
	
	for group in groups_arr:
		var stacks := group.stacks
		for i in stacks.size():
			var stack := stacks[i]
			if stack == null:
				stacks[i] = new_stack
				return true
			elif stack.is_same_as(new_stack):
				stack.size += new_stack.size
				return true
	
	return false


class Group:
	var name: String
	var size: int
	var stacks: Array[Stack]
	var stack_priority = 1
	
	static func compare(a: Group, b: Group):
		var comp_priority = a.stack_priority - b.stack_priority
		if comp_priority == 0:
			return a.name.casecmp_to(b.name) < 0
		return comp_priority < 0
	
	
	func _init(_name: String, _size: int):
		name = _name
		size = _size
		stacks = []
		stacks.resize(size)
