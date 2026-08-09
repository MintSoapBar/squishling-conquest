class_name Dummy
extends Mob

func initialize(_data: Dictionary) -> void:
	_data.max_health = INF
	super(_data)
