class_name Dummy
extends Mob

var total_damage: float = 0

@onready var total_damage_label: Label3D = $TotalDamageLabel


func on_damaged(amount: float, attributes: Dictionary):
	super(amount, attributes)
	
	total_damage += amount
	total_damage_label.text = "%.2f" % total_damage
