extends Control


func _ready() -> void:
	if OS.has_feature("mobile"):
		pass
	else:
		queue_free()
