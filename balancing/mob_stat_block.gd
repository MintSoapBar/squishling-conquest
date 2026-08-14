class_name MobStatBlock

var max_health: float = 100
var walk_speed: float = 4


func _init(vals: Dictionary) -> void:
	for key in vals:
		self.set(key, vals.get(key))
