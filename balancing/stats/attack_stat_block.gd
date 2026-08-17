class_name AttackStatBlock

var damage: float
var speed: float
var size: float

func _init(vals: Dictionary) -> void:
	for key in vals:
		self.set(key, vals.get(key))
