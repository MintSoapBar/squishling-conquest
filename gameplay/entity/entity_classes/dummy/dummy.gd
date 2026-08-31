class_name Dummy
extends Mob

var total_damage: float = 0

@onready var total_damage_label: Label3D = $TotalDamageLabel


func initialize(_data: Dictionary) -> void:
	super(_data)
	
	set_total_damage(data.get("total_damage", 0))


func on_damaged(amount: float, attributes: Dictionary):
	super(amount, attributes)
	
	if is_network_authority():
		set_total_damage.rpc(total_damage + amount)


@rpc("authority", "call_local")
func set_total_damage(amount: float):
	total_damage = amount
	data.total_damage = total_damage
	total_damage_label.text = "%.2f" % total_damage
